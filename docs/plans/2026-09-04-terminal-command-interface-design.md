# 포트폴리오 터미널 명령 인터페이스 설계

## 목표

터미널을 장식용 화면이 아니라 포트폴리오 데이터를 탐색하는 작은 명령 인터페이스로 만든다. 첫 화면에는 `포트폴리오: ~$ help`와 명령·설명 2열 안내가 보이고, 이후 사용자는 같은 프롬프트에서 영문 명령을 입력해 결과를 확인한다.

## 명령 계약

- `help`: `flutter run`, `git log`, `git status`, `cat skills.md`, `ls`, `whoami`, `clear`, `help`와 한국어 설명을 고정 폭 2열로 출력한다.
- `flutter run`: 현재 포트폴리오가 실행 중이라는 Flutter 이스터 에그를 출력한다. 기존 `npm run dev`는 제거한다.
- `git log`: 배포 시점에 저장한 실제 저장소의 최근 커밋 스냅샷을 최신순으로 출력한다. 정적 웹에서 로컬 Git을 실행하거나 인증 없는 GitHub API에 의존하지 않는다.
- `git status`: `dev`와 `origin/dev`가 일치하는 깨끗한 작업 상태를 터미널 형식으로 출력한다.
- `cat skills.md`: 공용 `PortfolioData`의 전체 기술 그룹을 출력한다.
- `ls`: 공용 프로젝트 중 `PortfolioProjectCategory.personal`인 항목만 출력한다.
- `whoami`: 민희수의 공용 프로필 정보를 출력한다.
- `clear`: 입력한 `clear` 명령을 포함해 transcript를 완전히 비우고 빈 프롬프트와 커서만 남긴다.

## 입력과 표현

터미널은 위쪽 스크롤 transcript와 아래쪽 입력 행을 유지한다. 입력 행에는 `포트폴리오: ~$` 프롬프트와 실제 `TextField`의 점멸 커서만 보인다. placeholder, 전송 아이콘, 입력 박스 외곽선, 별도 배경, hover·selection 강조는 사용하지 않는다. Enter 또는 모바일 키보드의 전송 액션으로 실행하며, 터미널을 열거나 명령을 실행·초기화하거나 터미널 본문을 다시 누르면 입력란으로 포커스를 돌려 점멸 커서를 유지한다.

첫 transcript는 사용자가 `help`를 실행한 상태와 동일하게 구성한다. 명령명은 영어, 설명은 한국어로 정렬한다. `clear` 이후에는 첫 안내도 다시 나타나지 않는다. 긴 출력은 기존 공용 touch·mouse scroll 동작을 그대로 사용한다.

## 검증

엔진 테스트로 명령 목록, `npm run dev` 제거, 개인 프로젝트 필터, 최근 커밋 순서, `clear` 플래그를 검증한다. 위젯 테스트로 초기 `help` transcript가 입력보다 위에 있는지, 고정 프롬프트, placeholder·전송 버튼 부재, 자동 포커스·점멸 커서 설정, 포커스 복귀, Enter 실행과 완전 초기화를 검증한다. 기존 Light/Dark 대비, iPhone/iPad/desktop overflow, touch·mouse scroll 회귀 테스트를 함께 실행한다.
