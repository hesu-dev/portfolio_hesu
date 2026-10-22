# 민희수 포트폴리오

Flutter Web으로 만든 민희수의 반응형 개발자 포트폴리오입니다. 화면 너비에 따라 단순히 크기만 바꾸지 않고, 각 기기에 어울리는 Apple 인터페이스로 전환됩니다.

- 데스크톱(`1024px` 이상): 창, 메뉴 막대, Dock을 갖춘 macOS 데스크톱
- 태블릿(`600px` 이상, `1024px` 미만): 홈 화면과 앱 화면 중심의 iPadOS 인터페이스
- 모바일(`600px` 미만): 안전 영역과 홈 인디케이터를 반영한 iPhone 인터페이스

iPhone·iPad 홈 화면은 전체 스크롤 없이 고정되며, 짧은 화면에서는 아이콘 크기를 조정합니다.
Dock 위의 **검색**을 누르거나 홈을 아래로 스와이프하면 **Siri 제안**과 앱 검색 화면이 열립니다.
마우스 휠을 아래로 내려도 열 수 있습니다. 앱 이름을 검색해 실행하거나 **취소**·Escape로
홈에 돌아올 수 있으며, 열린 앱 내부의 스크롤은 그대로 사용할 수 있습니다.

기존 GitHub Pages 배포는 중단하고 개인 Cloudflare 계정의 Workers Static Assets로 호스팅합니다.
웹사이트: [희수 포트폴리오](https://portfolio-hesu.portfolio-hesu.workers.dev/)
웹사이트 배포는 운영 빌드 후 Wrangler로 수행합니다. `./deploy.sh 3` 자체는 빌드까지만 실행합니다.

## 기술 스택

- Flutter / Dart
- Material 3 및 코드로 직접 구현한 Apple 스타일 컴포넌트
- `url_launcher`를 사용한 외부 링크 연결
- Flutter 위젯 테스트
- Cloudflare Workers Static Assets 정적 웹 호스팅 및 GitHub 실시간 조회 Worker

## 개발·운영 환경과 실행

Flutter SDK의 `flutter`, `dart`가 PATH에 등록된 환경에서 실행합니다.
스크립트는 어느 디렉터리에서 호출해도 저장소 루트를 기준으로 동작합니다.

```bash
./deploy.sh
```

처음 표시되는 메뉴에서 실행 방식을 선택합니다.

| 선택 | 환경 | 동작 |
| --- | --- | --- |
| `1` | 개발 | Chrome을 열고 `http://localhost:8080`에서 debug 실행 및 hot reload |
| `2` | 운영 | 연결된 Android/iPhone 실기기에 release 빌드 설치 및 앱 실행 |
| `3` | 운영 웹 | Cloudflare 정적 호스팅용 웹 빌드만 생성. 계정 연결·업로드 없음 |

2번은 에뮬레이터·시뮬레이터와 데스크톱을 제외합니다. 실기기가 한 대면 바로
실행하고, 여러 대면 휴대폰 선택 메뉴를 표시합니다. 기기가 없거나 선택이
올바르지 않으면 빌드하지 않고 종료합니다. 의존성 설치는 `flutter run`이 처리합니다.

```bash
./deploy.sh 1                         # 메뉴를 생략하고 Chrome 실행
./deploy.sh 2                         # 메뉴를 생략하고 실기기 릴리스 실행
./deploy.sh 3                         # 정적 웹 호스팅용 운영 빌드만 준비
WEB_PORT=9090 ./deploy.sh 1           # localhost 포트 변경
WEB_DEVICE=web-server ./deploy.sh 1   # 표시된 URL을 원하는 브라우저에서 직접 열기
./deploy.sh --help
```

기본 웹 실행에는 Chrome이 필요합니다. 다른 브라우저는 `web-server`를 사용합니다.
웹 서버는 로컬 컴퓨터의 `localhost`에 연결됩니다. 기본 포트 `8080`을 사용할 수
없으면 빈 포트를 자동 선택하고 실제 URL을 출력합니다. `WEB_PORT`를 지정한 경우에는
해당 포트를 그대로 사용하므로 사용 중이라면 다른 포트를 지정해 주세요.
실행 중 `r`은 hot reload,
`q`는 종료입니다. 휴대폰에서 실행한 앱을 유지한 채 Flutter 연결만 종료하려면
`d`로 detach할 수 있으며, 릴리스 실행에서는 hot reload를 지원하지 않습니다.

Android는 USB 디버깅과 컴퓨터 연결 허용이 필요합니다. 현재 프로젝트는
기기 직접 설치를 위해 release에도 개발용 키로 서명합니다. 스토어 배포용 서명은
별도로 설정해야 합니다. iPhone은 macOS/Xcode, 컴퓨터 신뢰, 개발자 모드와
유효한 서명 팀·프로비저닝이 필요합니다. 인식 여부는 `flutter devices`,
개발 도구 상태는 `flutter doctor`로 확인할 수 있습니다.

### iPhone 서명 설정

iOS의 `Runner`와 `RunnerTests`는 Debug/Profile/Release 모두 자동 서명과
`KFJ33YX67Z` 팀을 사용합니다. 앱 Bundle ID는 `com.example.portfolioHesu`입니다.
개발 인증서가 키체인에 있어도 Xcode에 팀 계정이 없거나 해당 Bundle ID·기기에
맞는 개발 프로비저닝 프로파일이 없으면 실기기 빌드가 실패합니다.

`No Accounts` 또는 `No profiles for 'com.example.portfolioHesu'`가 발생하면:

1. Xcode → Settings → Apple Accounts에서 해당 팀의 Apple 계정으로 로그인합니다.
2. `open ios/Runner.xcworkspace`로 워크스페이스를 엽니다.
3. Runner 타깃 → Signing & Capabilities에서 **Automatically manage signing**과
   **Team**을 확인합니다. 개발 인증서와 같은 `KFJ33YX67Z` 팀이어야 합니다.
4. 연결된 iPhone을 실행 대상으로 선택하고 **Product → Build**를 실행합니다.
   Xcode가 이 Bundle ID와 기기에 맞는 개발 프로파일을 생성·다운로드합니다.
   Bundle ID가 다른 팀에 이미 등록되어 있다는 오류가 나오면 Runner와
   RunnerTests의 Bundle ID를 함께 변경하고 다시 빌드합니다.
5. 아래 명령으로 운영 설정의 서명된 릴리스 빌드를 확인한 뒤 `./deploy.sh 2`로
   기기에 설치·실행합니다.

```bash
flutter build ios --release --dart-define-from-file=config/production.json
./deploy.sh 2
```

컴파일만 점검하려면 다음 명령을 사용합니다.

```bash
flutter build ios --release --no-codesign --dart-define-from-file=config/production.json
```

서명되지 않은 결과물은
iPhone에 설치할 수 없으므로 실기기 서명 오류의 해결 여부는 위의 서명된 빌드로
확인해야 합니다. 계정 로그인 정보·인증서 개인 키·프로파일은 저장소에 추가하지 않습니다.
자세한 절차는 [Flutter iOS 개발 환경 안내](https://docs.flutter.dev/platform-integration/ios/setup)를
참고하세요.

별도로 `resource fork, Finder information, or similar detritus not allowed`가
발생하면 `xattr -lr build/ios`와 `xattr -lr build/native_assets`로 빌드 산출물의
확장 속성을 확인합니다. Finder 메타데이터는 코드 서명을 방해합니다.
산출물에서 `com.apple.FinderInfo`·`com.apple.ResourceFork`를 제거하고 다시 빌드하며,
File Provider가 속성을 계속 생성한다면 동기화되지 않는 로컬 경로에 저장소를
복사하여 빌드하거나, `build/ios`와 `build/native_assets`를 `~/Library/Caches` 아래
새 디렉터리에 심볼릭 링크로 연결합니다. 기존 디렉터리를 이동하면 File Provider
속성이 따라올 수 있으므로 새 캐시를 생성합니다. `flutter clean` 후에는 링크를
다시 설정해야 합니다. [Apple의 관련 안내](https://developer.apple.com/library/archive/qa/qa1940/_index.html)를
참고하세요.

### 환경 파일

| 설정 | `config/development.json` | `config/production.json` |
| --- | --- | --- |
| `APP_ENV` | `development` | `production` |

`lib/config/app_config.dart`의 `AppConfig.environment`로 컴파일 시 환경을 읽습니다.
디버그 리본은 개발·운영 및 빌드 모드와 관계없이 항상 숨깁니다.
GitHub 기여 기록 조회 주소는 `GITHUB_CONTRIBUTIONS_URL`로 지정합니다.
지정하지 않으면 현재 Cloudflare API를 사용합니다. Cloudflare API 구현과 배포 설정은
`backend/`에 있으며, 운영 설정은 개인 Cloudflare 계정에 배포한
`https://portfolio-hesu-api.portfolio-hesu.workers.dev/api/github/contributions`를 사용합니다.
설정 파일을 수정했다면 실행을 종료한 뒤 다시 실행해야 합니다.
이 값들은 앱에 포함되므로 비밀 키나 토큰을 저장하지 않습니다.

수동 실행도 같은 설정 파일을 사용합니다.

```bash
flutter run -d chrome --web-hostname=localhost --web-port=8080 --dart-define-from-file=config/development.json
flutter run -d <device-id> --release --dart-define-from-file=config/production.json
```

설정을 생략한 직접 실행은 debug/profile에서 개발, release에서 운영을 기본값으로
사용합니다. `deploy.sh`는 기본값에 의존하지 않고 환경 파일을 명시합니다.
다른 SDK가 필요하면 `FLUTTER_BIN`과 `DART_BIN`으로 실행 파일 경로를 지정합니다.

실행 처리는 추가 패키지 없이 `tool/deploy.dart`의 Dart 표준 라이브러리로 수행합니다.
Flutter의 [웹 실행 안내](https://docs.flutter.dev/platform-integration/web/setup)와
[빌드 모드 안내](https://docs.flutter.dev/testing/build-modes)를 참고할 수 있습니다.

## GitHub 기여 달력 갱신

Git 화면을 열 때마다 Cloudflare API가 `hesu-dev`의 GitHub 원본 기여 달력을 직접 조회합니다.
중간 공개 API나 저장된 DB·기여 기록 JSON은 조회 경로에서 사용하지 않습니다.
데스크톱에서 최소화한 Git 창을 다시 열 때도 갱신하며, 달력 오른쪽의
새로고침 버튼으로 직접 갱신할 수 있습니다. 조회 시각은 화면에 노출하지 않습니다.
요청에는 `Cache-Control: no-cache`를 지정하며 인증 정보는 전송하지 않습니다.
Worker는 `cache: no-store`와 요청마다 다른 쿼리를 사용하고, API 응답도
`Cache-Control: no-store`로 반환합니다. 응답의 `source`는 GitHub 원본 주소,
`fetchedAt`은 해당 요청에서 원본을 읽은 시각입니다.

GitHub 프로필의 **Contribution settings → Private contributions**를 켜면
비공개 저장소의 기여 횟수도 합산해 가져옵니다. 한 번 설정하면 매번 다시 설정할
필요가 없으며 저장소 이름이나 코드를 공개하지 않습니다. 설정을 끄면 비공개 기여는
실시간 조회에 포함되지 않습니다. 화면에는 공개·비공개 기여의 합산 달력을 표시합니다.
GitHub 자체 집계에는 반영 지연이 있을 수 있어 조회 시각과 마지막 기여 시각은
다릅니다. 네트워크 오류 또는 10초 시간 초과 시에는 오류와 **다시 불러오기**를
표시하며 저장 기록으로 대체하지 않습니다. 웹 빌드에서도 기여 기록을 미리 수집하지 않습니다.
인증 정보나 저장소 상세는 웹 빌드에 포함되지 않습니다.

## 검증하기

```bash
flutter test
flutter analyze
```

## 파일 앱

홈 화면의 **파일** 폴더에서 회사·개인 프로젝트와 유틸리티 앱을 탐색합니다.
**파일** 섹션에는 음악, 사진, 이메일, 휴지통이 있으며, 태블릿·모바일에서는 프린터,
데스크톱에서는 설정을 함께 표시합니다. 기본 위치는 **파일**이고, 태블릿·모바일은
하단의 `최근 항목 → 파일 → 회사 → 개인` 메뉴로 이동합니다. 최근 항목에는 프로젝트와
파일 섹션의 바로가기를 함께 표시합니다.

모바일 홈 아이콘은 `프로필 → 자기소개 → 파일 → 프로젝트 → 터미널 → git → 스킬 → 설정`
순서이며, 하단 Dock에서도 설정에 바로 접근할 수 있습니다.

더보기에서 아이콘·목록 보기와 이름·종류·날짜·태그 오름차순 정렬을 선택합니다.
폴더마다 설정을 따로 유지하며 기본값은 아이콘 보기와 종류 정렬입니다. 바로가기의
날짜는 2020년 12월 이전의 고정된 예시 날짜, 태그는 파일 분류이며 프로젝트 기간과
기술 스택은 실제 등록 데이터를 사용합니다. 크기는 정보가 없어 비활성화합니다.

## 사진 앱

하단 **보관함 / 앨범** 탭으로 이동하며, 앨범 표지 → 앨범 사진 → 사진 상세 순서로 탐색합니다.
보관함과 앨범 표지·상세는 `assets/photos/img1.png`부터 `img12.png`까지 같은 파일을 사용합니다.
같은 경로의 파일을 교체한 뒤 다시 빌드하면 반영됩니다. 파일별 제목과 앨범 매핑은
[사진 교체 안내](assets/photos/README.md)를 참고하세요.

## 프로젝트 앱

**프로젝트**는 Safari 시작 페이지 형태로 즐겨찾기와 개인·회사 프로젝트 카드를 보여줍니다.
상단 검색창에서 프로젝트 이름·설명·기술을 검색하고, 이미지·제목·설명 카드에서
상세 리포트를 열 수 있습니다. 뒤로·앞으로 및 시작 페이지 버튼으로 탐색합니다.
파일 폴더에서 프로젝트를 열어도 같은 상세 리포트를 사용합니다. 상단에는 앱 아이콘과
제목·작업 기간, 아이콘형 외부 링크를 표시하고, 기술 스택과 프로젝트 구조를 먼저
보여 줍니다. 구조 요약에는 다이어그램에 포함된 구성 요소의 이름과 역할을 함께 표시합니다.
상세에서는 핵심 기술·기술 의사결정·트러블슈팅을 읽고, 아이콘과 연결선으로
아키텍처를 확인할 수 있습니다. 다이어그램은 전체 화면에서 확대·이동할 수 있으며,
모바일에서는 가로 스크롤도 지원합니다. 구현·설계·확인된 기술 구성의 범위와
근거 자료는 [프로젝트 기술 근거](docs/projects/project-engineering-evidence.md)에 정리했습니다.

## PDF 저장 및 인쇄

데스크톱의 홈 화면·Dock 또는 모바일 파일 폴더의 **프린터**를 누르면 이력서, 자기소개서,
프로젝트를 합친 A4 문서가 새 탭의 브라우저 기본 PDF 뷰어에서 열립니다.
원래 도구 모음과 페이지 미리보기를 유지하며, 왼쪽 아래의 작은 **뒤로** 버튼으로
포트폴리오로 돌아갈 수 있습니다. 자기소개서에는 **자기소개** 화면과 같은
Flutter 개발자 소개글을 사용합니다.

한글 글꼴을 문서에 포함하며, PDF 뷰어를 지원하지 않거나 PDF 생성에 실패한
브라우저에서는 **PDF 저장 / 인쇄** 버튼이 있는 HTML 인쇄 문서로 연결됩니다.
브라우저 메뉴에서 인쇄할 때는 확대된 화면 대신 A4 HTML 문서를 사용합니다.
팝업이 차단된 경우 이 사이트의 팝업을 허용한 뒤 다시 클릭해 주세요.

## 웹 빌드와 배포

### 웹·iOS 공용 Cloudflare API

`backend/worker.mjs`는 `GET /health`와 `GET /api/github/contributions`를 제공합니다.
배포 주소는 [portfolio-hesu-api](https://portfolio-hesu-api.portfolio-hesu.workers.dev/health)이며
개인 계정 `hs0647@naver.com`에 배포되어 있습니다. `backend/wrangler.json`의 계정 ID로
배포 대상을 고정합니다.
기여 기록은 `https://github.com/users/hesu-dev/contributions`에서 요청할 때마다 직접 가져오며, 클라이언트가 전달한 URL이나
인증 정보는 업스트림으로 전달하지 않습니다. 8초 내에 응답하지 않거나 조회에 실패하면
502를 반환하며, Flutter는 저장 기록 대신 오류와 재시도를 표시합니다.

개인 계정은 별도 Wrangler 프로필로 인증하여 기존 회사 계정 인증과 구분합니다.
인증 화면의 개인 계정과 배포 계정을 확인한 뒤 실행합니다.

```bash
node --test backend/worker.test.mjs
npx wrangler auth create portfolio-hesu-personal
npx wrangler deploy --config backend/wrangler.json --profile portfolio-hesu-personal
```

`config/production.json`의 `GITHUB_CONTRIBUTIONS_URL`에는 배포된 HTTPS API 주소가
설정되어 있습니다. 다른 Worker로 이전하면 이 값을 함께 변경합니다. 이 주소는 공개 API
주소이며 비밀 키를 포함하지 않습니다. 설정을 반영한 iPhone 운영 앱 설치는 `./deploy.sh 2`로
진행합니다. App Store/TestFlight 업로드는 이 명령에 포함되지 않습니다.

검증 명령:

```bash
flutter test test/portfolio/github_contributions_loader_test.dart --dart-define=GITHUB_CONTRIBUTIONS_URL=https://portfolio-api.example/api/github/contributions
npx wrangler deploy --config backend/wrangler.json --dry-run
```

### 정적 웹 빌드

Cloudflare Workers Static Assets에서 도메인 루트로 서비스하도록 `/` base 경로로 빌드합니다.

```bash
./deploy.sh 3
# 또는 빌드 진입점을 직접 실행
dart run tool/build_web.dart
```

이 빌드 진입점은 현재 저장소의 최근 Git 커밋 8개를 터미널의 `git log`에
주입하고 `config/production.json`을 적용한 뒤 Flutter Web 릴리스 빌드를 실행합니다. 결과물 디렉터리는
`build/web`입니다.

### Cloudflare 정적 호스팅 설정

저장소 루트의 `wrangler.json`은 다음 항목만 설정합니다.

- Worker 이름: `portfolio-hesu`
- 배포 계정: 개인 계정 ID로 고정
- 업로드할 정적 파일: `build/web`
- SPA 탐색: 파일과 일치하지 않는 페이지 이동은 `index.html`로 처리

정적 웹 설정에는 별도 서버 코드나 비밀 키를 포함하지 않습니다.
설정 방식은 [Cloudflare SPA 안내](https://developers.cloudflare.com/workers/static-assets/routing/single-page-application/)를 따릅니다.

**`./deploy.sh 3`은 운영 웹 빌드까지만 실행합니다.** Wrangler 설치·실행,
Cloudflare 로그인, 브라우저 열기, 계정 조회, 원격 Worker 생성·업로드는 하지 않습니다.

공개 웹사이트 배포에는 아래 명령을 별도로 실행합니다. 이 단계에는 Node.js/npm과 Wrangler가 필요합니다.
브라우저 계정을 사용하지 않으려면 개인 계정의 `CLOUDFLARE_API_TOKEN`과 `CLOUDFLARE_ACCOUNT_ID`를
프로세스 환경 변수로 제공할 수 있습니다. 토큰은 저장소나 Flutter 설정 파일에 넣지 않습니다.

```bash
npx wrangler deploy --config wrangler.json --profile portfolio-hesu-personal
```

현재 로그인된 Chrome 프로필은 빌드 준비 과정에서 사용하지 않습니다.
GitHub Pages 자동 배포 워크플로는 제거된 상태입니다.

### main 자동 운영 배포

`.github/workflows/cloudflare-production.yml`은 `main` 푸시마다 다음을 실행합니다.

1. Flutter 3.38.9와 Node.js 24 설치, 의존성 복원
2. `flutter analyze`, `flutter test`, Worker 테스트
3. `config/production.json`으로 웹 릴리즈 빌드
4. 개인 Cloudflare 계정의 API와 웹사이트 순서로 배포
5. 운영 웹사이트와 API 상태 확인

테스트·빌드가 실패하면 배포하지 않습니다. 배포 작업은 동시에 실행하지 않으며,
다른 브랜치나 PR은 운영 배포를 실행하지 않습니다. GitHub Actions 화면에서 수동 실행도 가능합니다.
iOS 실기기 설치·App Store 업로드는 이 워크플로에 포함되지 않습니다.

GitHub 저장소의 Actions 시크릿 `CLOUDFLARE_API_TOKEN`에는 개인 계정의 배포용 API 토큰을
등록합니다. 개인 계정의 Workers Scripts 편집 권한과 Account Settings 읽기 권한만 사용하며,
토큰은 코드·Flutter 설정·빌드 산출물에 넣지 않습니다. 로컬 Wrangler 로그인 프로필은 CI에서
사용하지 않습니다.

## 디자인 및 상표 고지

이 포트폴리오는 Apple 기기의 인터페이스에서 영감을 받아 독립적으로 제작한 프로젝트입니다. Apple과 제휴하거나 보증받지 않았습니다. Slack과 제휴하거나 보증받지 않았습니다.

화면, 아이콘, 구성 요소는 프로젝트 안에서 코드로 새로 구현했으며 Apple 또는 Slack 제품의 원본 자산을 포함하지 않습니다. 각 제품명과 상표는 해당 권리자의 자산입니다.
