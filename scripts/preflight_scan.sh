#!/usr/bin/env bash
# preflight_scan.sh — repo-release 보안 사전 스캔 게이트
#
# 비밀키(API key / token / private key)·개인정보가 GitHub에 올라가는 것을 차단한다.
# gitleaks 가 있으면 우선 사용(working tree + git history), 없으면 내장 정규식 fallback.
#
# 사용:   bash preflight_scan.sh [대상경로]      # 기본 = 현재 디렉토리
# 종료코드: 0 = 깨끗 / 1 = 의심 발견(푸시 중단) / 2 = 환경 오류
#
# 주의: fallback 출력은 비밀키 "값"을 절대 그대로 찍지 않는다([REDACTED]).
#       화면/transcript에 키가 남는 것 자체가 노출 사고이기 때문이다.

set -uo pipefail

TARGET="${1:-.}"
cd "$TARGET" 2>/dev/null || { echo "[scan] 대상 경로를 찾을 수 없음: $TARGET"; exit 2; }

FOUND=0

echo "== repo-release 보안 사전 스캔 =="
echo "[scan] 대상: $(pwd)"

# --- 환경 판별: git repo / remote 유무 ---
IS_GIT=0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 && IS_GIT=1
HAS_REMOTE=0
if [ "$IS_GIT" = 1 ] && git remote -v 2>/dev/null | grep -q .; then HAS_REMOTE=1; fi
if [ "$IS_GIT" = 1 ]; then
  [ "$HAS_REMOTE" = 1 ] && echo "[scan] 모드: 업데이트(remote 있음)" || echo "[scan] 모드: 신규(git repo, remote 없음)"
else
  echo "[scan] 모드: 신규(git repo 아님 — 워킹트리 전체 스캔)"
fi

# ============================================================
# 1) gitleaks 우선 (전용 도구 — 커버리지 가장 넓음, --redact 로 값 가림)
# ============================================================
if command -v gitleaks >/dev/null 2>&1; then
  echo "[scan] gitleaks 사용 (history 포함, 값은 redact)"
  if [ "$IS_GIT" = 1 ]; then
    gitleaks detect --no-banner --redact -v || FOUND=1
  else
    gitleaks detect --no-git --no-banner --redact -v || FOUND=1
  fi
  if [ "$FOUND" = 0 ]; then
    echo "[scan] 깨끗 — gitleaks 미검출."
    exit 0
  fi
  echo "[scan] 의심 발견 → 푸시 중단. 위 항목 처리 후 재스캔하라."
  exit 1
fi

# ============================================================
# 2) 내장 정규식 fallback (gitleaks 미설치)
# ============================================================
echo "[scan] gitleaks 미설치 → 내장 정규식 fallback (커버리지 더 낮음; 'brew install gitleaks' 권장)"

# 스캔 대상 파일 목록
if [ "$IS_GIT" = 1 ]; then
  FILES="$(git ls-files)"
else
  FILES="$(find . -type f -not -path './.git/*' 2>/dev/null)"
fi

# --- 2a) 위험 파일명 (값이 아니라 파일명이므로 그대로 표시해도 안전) ---
RISKY="$(printf '%s\n' "$FILES" | grep -Ei '(^|/)\.env([.][^/]*)?$|(^|/)credentials(\.[^/]*)?$|\.pem$|(^|/)id_rsa$|(^|/)id_dsa$|(^|/)\.npmrc$|\.pfx$|\.p12$|\.keystore$' || true)"
if [ -n "$RISKY" ]; then
  echo "[!] 비밀파일이 레포에 포함/추적되고 있음:"
  printf '%s\n' "$RISKY" | sed 's/^/      /'
  FOUND=1
fi

# --- 2b) 비밀키 콘텐츠 패턴 (값은 [REDACTED], 위치만 보고) ---
SECRET_RE='sk-ant-[A-Za-z0-9_-]{20,}|sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|AIza[0-9A-Za-z_-]{35}|xox[baprs]-[A-Za-z0-9-]{10,}|glpat-[A-Za-z0-9_-]{20,}|-----BEGIN [A-Z ]*PRIVATE KEY-----'
if [ "$IS_GIT" = 1 ]; then
  SHITS="$(git grep -nIE "$SECRET_RE" -- . 2>/dev/null || true)"
else
  SHITS="$(grep -rnIE --binary-files=without-match "$SECRET_RE" . --exclude-dir=.git 2>/dev/null || true)"
fi
if [ -n "$SHITS" ]; then
  echo "[!] 비밀키 패턴 의심 (값은 가림 — 해당 파일:라인을 직접 열어 확인하라):"
  # file:line:content → file:line  [REDACTED] 로 마스킹
  printf '%s\n' "$SHITS" | awk -F: 'NF>=3{print "      "$1":"$2"  [REDACTED secret match]"}'
  FOUND=1
fi

# --- 2c) 절대경로 사용자명 노출 (개인 환경 노출 — 검토 필요) ---
PATH_RE='/Users/[A-Za-z0-9._-]+/|/home/[A-Za-z0-9._-]+/|C:\\\\Users\\\\[A-Za-z0-9._-]+'
if [ "$IS_GIT" = 1 ]; then
  PHITS="$(git grep -nIE "$PATH_RE" -- . 2>/dev/null || true)"
else
  PHITS="$(grep -rnIE --binary-files=without-match "$PATH_RE" . --exclude-dir=.git 2>/dev/null || true)"
fi
if [ -n "$PHITS" ]; then
  echo "[~] 절대경로(사용자명 노출 가능) — 검토 필요 (최대 50건 표시):"
  printf '%s\n' "$PHITS" | sed 's/^/      /' | head -50
  FOUND=1
fi

# ============================================================
echo "------------------------------------------------------------"
if [ "$FOUND" = 0 ]; then
  echo "[scan] 깨끗 — 비밀키/비밀파일/경로노출 패턴 미발견."
  echo "[scan] (정규식 fallback은 커버리지 한계가 있다. 공개 전 'brew install gitleaks' 재스캔 권장.)"
  exit 0
else
  echo "[scan] 의심 발견 → 푸시 중단. 위 항목을 처리(.gitignore 추가 / git rm --cached / 키 회전)한 뒤 재스캔하라."
  exit 1
fi
