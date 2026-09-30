# 민희수 포트폴리오

Flutter Web으로 만든 민희수의 반응형 개발자 포트폴리오입니다. 화면 너비에 따라 단순히 크기만 바꾸지 않고, 각 기기에 어울리는 Apple 인터페이스로 전환됩니다.

- 데스크톱(`1024px` 이상): 창, 메뉴 막대, Dock을 갖춘 macOS 데스크톱
- 태블릿(`600px` 이상, `1024px` 미만): 홈 화면과 앱 화면 중심의 iPadOS 인터페이스
- 모바일(`600px` 미만): 안전 영역과 홈 인디케이터를 반영한 iPhone 인터페이스

기존 GitHub Pages 배포는 중단하고 Vercel 이전을 준비하고 있습니다.

## 기술 스택

- Flutter / Dart
- Material 3 및 코드로 직접 구현한 Apple 스타일 컴포넌트
- `url_launcher`를 사용한 외부 링크 연결
- Flutter 위젯 테스트
- Vercel 정적 웹 배포 준비

## 로컬에서 실행하기

Flutter SDK와 Chrome이 설치된 환경에서 다음 명령을 실행합니다.

```bash
flutter pub get
flutter run -d chrome
```

Git 화면의 기여 달력은 `hesu-dev`의 GitHub GraphQL 원본을 날짜별 횟수와
색상으로 저장한 스냅샷입니다. 비공개 기여까지 포함하려면 `hesu-dev`로 로그인한
GitHub CLI에 `read:user` 권한이 필요합니다.

```bash
gh auth refresh -h github.com -s read:user
dart run tool/refresh_github_contributions.dart
```

인증 정보나 저장소 상세는 웹 빌드에 포함되지 않습니다. 화면에 마지막 갱신일을
표시하며, `tool/build_web.dart`도 빌드 전에 갱신을 시도합니다. 인증 또는 네트워크를
사용할 수 없는 빌드 환경에서는 기존 스냅샷을 유지합니다.

## 검증하기

```bash
flutter test
flutter analyze
```

## PDF 저장 및 인쇄

데스크톱 바탕화면 왼쪽 위의 **프린터**를 한 번 클릭하면 이력서, 자기소개서,
프로젝트를 합친 A4 문서가 새 탭의 PDF 뷰어에서 열립니다. 뷰어의 저장 또는
인쇄 버튼을 사용하면 됩니다. 자기소개서에는 현재 프로필 소개글을 사용합니다.

한글 글꼴을 문서에 포함하며, PDF 뷰어를 지원하지 않거나 PDF 생성에 실패한
브라우저에서는 **PDF 저장 / 인쇄** 버튼이 있는 HTML 인쇄 문서로 연결됩니다.
팝업이 차단된 경우 이 사이트의 팝업을 허용한 뒤 다시 클릭해 주세요.

## 웹 빌드와 배포

Vercel은 도메인 루트에서 실행되므로 `/` base 경로로 빌드합니다.

```bash
dart run tool/build_web.dart
```

이 빌드 진입점은 현재 저장소의 최근 Git 커밋 8개를 터미널의 `git log`에
주입한 뒤 Flutter Web 릴리스 빌드를 실행합니다. 결과물 디렉터리는
`build/web`입니다.

### Vercel 설정

Vercel 기본 빌드 이미지에는 Flutter SDK가 준비되어 있지 않다고 전제합니다. 따라서 저장소를 Vercel에 연결할 때는 [Build 설정](https://vercel.com/docs/builds/configure-a-build)에서 `Framework Preset`을 `Other`로 지정하고, 프로젝트 내부의 `.flutter` 디렉터리에 SDK를 먼저 설치합니다.

`Install Command`:

```bash
git clone --depth 1 --branch 3.38.9 https://github.com/flutter/flutter.git .flutter && ./.flutter/bin/flutter config --enable-web && ./.flutter/bin/flutter pub get
```

`Build Command`:

```bash
./.flutter/bin/dart run tool/build_web.dart --flutter-bin ./.flutter/bin/flutter
```

`Output Directory`:

```text
build/web
```

Flutter SDK는 검증한 `3.38.9` 태그로 고정해 Vercel의 반복 빌드 결과가 `stable` 브랜치 변경에 따라 달라지지 않게 합니다.

사전 빌드 정적 배포 대안도 있습니다. Flutter가 설치된 로컬 환경이나 별도 CI에서 `dart run tool/build_web.dart`로 사전 빌드하고, 생성된 `build/web`을 별도의 Vercel 정적 프로젝트에 배포합니다. 이 경우 Vercel 안에서 Flutter SDK를 내려받을 필요가 없으며 소스 저장소 루트에는 생성물을 커밋하지 않습니다.

GitHub Pages 자동 배포 워크플로는 제거했습니다. Vercel 프로젝트 생성, 도메인 연결, 환경 설정은 실제 이전 시점에 별도로 진행합니다.

## 디자인 및 상표 고지

이 포트폴리오는 Apple 기기의 인터페이스에서 영감을 받아 독립적으로 제작한 프로젝트입니다. Apple과 제휴하거나 보증받지 않았습니다. Slack과 제휴하거나 보증받지 않았습니다.

화면, 아이콘, 구성 요소는 프로젝트 안에서 코드로 새로 구현했으며 Apple 또는 Slack 제품의 원본 자산을 포함하지 않습니다. 각 제품명과 상표는 해당 권리자의 자산입니다.
