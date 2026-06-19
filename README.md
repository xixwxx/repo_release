# repo-release

로컬 프로젝트를 GitHub에 **일관되고 안전하게** 출시하는 [Claude Code](https://claude.com/claude-code) 스킬.

레포를 매번 같은 컨벤션으로 만들고 · 비밀키·개인정보를 사전 스캔으로 거르고 · Conventional Commits로 커밋하고 · semver 태그와 GitHub Release까지 한 흐름으로 처리한다. `git remote` 유무로 **신규 레포 생성 / 기존 레포 업데이트**를 자동으로 가른다.

## 왜 만들었나

이 도구들(Claude Code · git · GitHub)을 써본 지 한 달쯤 된 입문자가 만들었다.

GitHub에 뭔가 올릴 때마다 매번 같은 걸 손으로 반복했다 — 설명은 이렇게 저렇게 정리하고, 혹시 비밀키처럼 올리면 안 되는 게 섞여 있지 않은지 확인하고, 그제서야 올렸다.

레포를 새로 만들든 기존 걸 수정하든, **뭐가 바뀌었는지 · 뭘 만들었는지 · 커밋은 됐는지 확인하고, 푸시 직전에 최종 확인까지 거쳐야** 비로소 안심이 되는 성격이다. 그 반복 절차를 매번 손으로 하는 대신 하나의 흐름으로 묶고 싶어서 이 스킬을 만들었다.

거창한 자동화가 목적이 아니라, 올리기 전에 챙길 걸 빠뜨리지 않게 매번 같은 순서로 확인받는 것 — 그게 이 스킬이 하는 일이다.

아직 배우는 중이라 부족한 점이 많다. 피드백은 언제나 환영하고, 같은 입문자에게 알려주고 싶은 정보나 팁이 있다면 GitHub Issue로 편하게 남겨주면 정말 고맙겠다.

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
