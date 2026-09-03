# 민희수 포트폴리오

Flutter Web으로 만든 민희수의 반응형 개발자 포트폴리오입니다. 화면 너비에 따라 단순히 크기만 바꾸지 않고, 각 기기에 어울리는 Apple 인터페이스로 전환됩니다.

- 데스크톱(`1024px` 이상): 창, 메뉴 막대, Dock을 갖춘 macOS 데스크톱
- 태블릿(`600px` 이상, `1024px` 미만): 홈 화면과 앱 화면 중심의 iPadOS 인터페이스
- 모바일(`600px` 미만): 안전 영역과 홈 인디케이터를 반영한 iPhone 인터페이스

현재 공개 페이지는 [GitHub Pages](https://hesu-dev.github.io/portfolio_hesu/)에서 확인할 수 있습니다.

## 기술 스택

- Flutter / Dart
- Material 3 및 코드로 직접 구현한 Apple 스타일 컴포넌트
- `url_launcher`를 사용한 외부 링크 연결
- Flutter 위젯 테스트
- GitHub Actions / GitHub Pages

## 로컬에서 실행하기

Flutter SDK와 Chrome이 설치된 환경에서 다음 명령을 실행합니다.

```bash
flutter pub get
flutter run -d chrome
```

## 검증하기

```bash
flutter test
flutter analyze
```

## 웹 빌드와 배포

현재 배포는 GitHub Pages를 유지하며, 저장소 하위 경로에서 실행되므로 저장소 이름을 포함한 `/portfolio_hesu/` base 경로로 빌드합니다.

```bash
flutter build web --release --base-href /portfolio_hesu/ --pwa-strategy=none
```

Flutter SDK가 PATH에 있는 로컬 또는 CI 환경에서 Vercel용 결과물을 확인할 때는 도메인 루트에서 실행되므로 `/` base 경로로 빌드합니다. Pages용 결과물을 그대로 Vercel에 올리거나 반대로 사용하면 정적 파일 경로가 어긋날 수 있으므로 배포 대상별 명령을 구분합니다.

```bash
flutter build web --release --base-href / --pwa-strategy=none
```

두 빌드 모두 결과물 디렉터리는 `build/web`입니다.

### 향후 Vercel 설정

Vercel 기본 빌드 이미지에는 Flutter SDK가 준비되어 있지 않다고 전제합니다. 따라서 저장소를 Vercel에 연결할 때는 [Build 설정](https://vercel.com/docs/builds/configure-a-build)에서 `Framework Preset`을 `Other`로 지정하고, 프로젝트 내부의 `.flutter` 디렉터리에 SDK를 먼저 설치합니다.

`Install Command`:

```bash
git clone --depth 1 --branch 3.38.9 https://github.com/flutter/flutter.git .flutter && ./.flutter/bin/flutter config --enable-web && ./.flutter/bin/flutter pub get
```

`Build Command`:

```bash
./.flutter/bin/flutter build web --release --base-href / --pwa-strategy=none
```

`Output Directory`:

```text
build/web
```

Flutter SDK는 검증한 `3.38.9` 태그로 고정해 Vercel의 반복 빌드 결과가 `stable` 브랜치 변경에 따라 달라지지 않게 합니다.

사전 빌드 정적 배포 대안도 있습니다. Flutter가 설치된 로컬 환경이나 별도 CI에서 위 루트 경로 명령으로 사전 빌드하고, 생성된 `build/web`을 별도의 Vercel 정적 프로젝트에 배포합니다. 이 경우 Vercel 안에서 Flutter SDK를 내려받을 필요가 없으며 소스 저장소 루트에는 생성물을 커밋하지 않습니다.

현재 작업에서는 GitHub Pages 배포를 유지하며 Vercel 프로젝트 생성, 배포, 도메인 연결 등 외부 설정을 변경하지 않습니다. Pages 배포 작업은 `gh-pages` 브랜치에 쓰므로 저장소 설정과 토큰 권한에 따라 `contents: write`가 필요할 수 있습니다. 현재 워크플로에서는 권한을 새로 확대하지 않으며, 활성화하기 전에 저장소 소유자가 필요한 권한을 직접 확인해야 합니다. Vercel로 이전할 때는 중복 배포를 막기 위해 Pages 워크플로를 비활성화하거나 삭제합니다.

## 디자인 및 상표 고지

이 포트폴리오는 Apple 기기의 인터페이스에서 영감을 받아 독립적으로 제작한 프로젝트입니다. Apple과 제휴하거나 보증받지 않았습니다. Slack과 제휴하거나 보증받지 않았습니다.

화면, 아이콘, 구성 요소는 프로젝트 안에서 코드로 새로 구현했으며 Apple 또는 Slack 제품의 원본 자산을 포함하지 않습니다. 각 제품명과 상표는 해당 권리자의 자산입니다.
