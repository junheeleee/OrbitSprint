# Work Log

## 2026-05-15 ~ 2026-05-16

### Lumen Run

- Xcode 설치와 macOS/Xcode 버전 문제를 해결하는 흐름을 정리함.
- iOS Simulator 실행 문제를 해결함.
- `missing bundle id`, `CFBundleExecutable` 관련 설치 오류를 수정함.
- 실제 iPhone 테스트를 위한 signing/development team 흐름을 진행함.
- iPhone Developer Mode는 실제 기기 테스트 시 켜야 한다고 정리함.
- 사운드 토글과 실제 소리 재생 문제를 점검함.
- 게임 완성도를 App Store 배포 수준으로 올리기 위한 방향을 정리함.
- Git 관리와 GitHub 원격 연동을 진행함.
- README를 꾸미고 프로젝트 기록 기반을 만들기 시작함.
- 충돌 후 같은 위치에서 연속 사망하는 문제를 여러 차례 개선함.
- 궤도 조작 방식을 원버튼/투버튼으로 실험했고, 최종적으로 원버튼 방식으로 되돌림.
- 로딩 화면과 스타트 화면을 추가함.
- 2단계 궤도를 3단계로 확장함.
- 궤도 이동 패턴을 `1 -> 2 -> 3 -> 2 -> 1`로 설계함.
- 다른 레이어 장애물과 충돌하는 문제를 수정함.
- 진행 방향에 갑자기 생성되는 불공정 장애물 생성을 줄이는 방향으로 조정함.
- IP/세계관 통일, 피버 모드, 실드 시각화, 배경음 템포 개선을 진행함.

### Gangnam Dream

- Claude 임시 폴더의 Godot 프로젝트를 `/Users/junheelee/Documents/Game/gangnam_dream`으로 가져옴.
- Godot 4.6 기준 프로젝트로 정리함.
- JSON 기반 콘텐츠 구조를 추가함.
- `DataRegistry`, `GameState`, `EventManager`, `NewsManager`, `SaveManager`, `MetaProgression`을 구성함.
- 투자, 직업, 관계, 아이템, 엔딩 시스템을 분리함.
- Football Manager 스타일의 대시보드 UI를 동적으로 생성하도록 구성함.
- 시작 화면, 저장 슬롯, 특성 선택 UI를 추가함.
- Godot 파서 오류를 여러 차례 해결함.
- Godot 4.6에서 문제가 된 typed function syntax, inferred variable typing, lambda filter를 제거함.
- `trait` 파라미터명이 파서 문제를 일으킬 가능성이 있어 `selected_trait`로 변경함.
- 글씨가 세로로 보이는 UI 문제를 해결하기 위해 자동 줄바꿈과 최소 너비를 조정함.
- 버튼 클릭이 안 되는 문제를 해결하기 위해 배경/모달 `mouse_filter`를 조정함.

## Blockers

### Gangnam Dream GitHub repo 생성

현재 세션에서는 다음 이유로 새 GitHub repo를 직접 만들지 못함:

- `gh` CLI 없음
- `hub` CLI 없음
- `brew` 없음
- `ssh -T git@github.com` 결과: `Permission denied (publickey)`
- 현재 노출된 GitHub connector는 기존 repository 파일 생성/수정 중심이며 새 repo 생성 도구가 없음

해결 방법:

1. GitHub 웹에서 `GangnamDream` repository를 한 번 생성
2. 생성 후 repo 주소를 알려주면 `gangnam_dream`만 별도 repo로 push
3. 또는 GitHub CLI 설치/로그인 후 `gh repo create` 사용