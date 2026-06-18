# repo-release

로컬 프로젝트를 GitHub에 **일관되고 안전하게** 출시하는 [Claude Code](https://claude.com/claude-code) 스킬.

레포를 매번 같은 컨벤션으로 만들고 · 비밀키·개인정보를 사전 스캔으로 거르고 · Conventional Commits로 커밋하고 · semver 태그와 GitHub Release까지 한 흐름으로 처리한다. `git remote` 유무로 **신규 레포 생성 / 기존 레포 업데이트**를 자동으로 가른다.

## 무엇을 하나

- **신규/업데이트 자동 감지** — `remote` 없으면 새 레포 생성, 있으면 변경분 푸시 경로.
- **보안 게이트** — 푸시·생성 전 반드시 통과. [gitleaks](https://github.com/gitleaks/gitleaks)가 있으면 git history까지 스캔하고, 없으면 내장 정규식 fallback(OpenAI/Anthropic/AWS/GitHub/Google/Slack 키 패턴, private key, 추적 중인 `.env`/`*.pem` 류, 절대경로에 박힌 사용자명)으로 검사한다. **발견 시 즉시 중단.**
- **버전 관리** — semver bump를 변경 규모로 제안(확정은 사람), annotated tag + GitHub Release.
- **일관성** — 계정·레포명 규칙·라이선스를 매번 동일하게 적용.
- **안전** — 원격에 올리기 직전 무엇이 올라가는지 요약하고 최종 확인을 받는다. 키 값은 스캔 출력에서 `--redact`/`[REDACTED]`로 가려 화면에 노출하지 않는다.

## 구성

| 파일 | 역할 |
|------|------|
| `SKILL.md` | 워크플로우 본체 (Claude이 읽고 따르는 절차) |
| `scripts/preflight_scan.sh` | 결정적 보안 스캔 (gitleaks 우선, 정규식 fallback) |

## 설치

Claude Code 스킬 디렉토리에 복사하면 끝:

```bash
git clone https://github.com/xixwxx/repo_release.git ~/.claude/skills/repo-release
# (선택) 더 넓은 커버리지를 위해
brew install gitleaks
```

## 사용

Claude Code 세션에서 출시 의도를 말하면 자동 발동한다:

> "깃헙에 올려줘" · "레포 만들어서 올려줘" · "버전 올려서 릴리스" · "출시해줘" · `/repo-release`

보안 스캔만 따로 돌리고 싶으면:

```bash
bash scripts/preflight_scan.sh
```

## 커스터마이징

이 스킬은 제작자의 개인 컨벤션을 하드코딩한다 — GitHub 계정 `xixwxx`, 라이선스 MIT, 레포명 `snake_case`. 포크해서 쓸 때는 `SKILL.md`의 **§1 컨벤션** 섹션을 본인 것으로 바꿔라.

## 라이선스

[MIT](LICENSE)
