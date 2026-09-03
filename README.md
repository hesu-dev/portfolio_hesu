# 민희수 포트폴리오

Flutter Web으로 만든 민희수의 반응형 개발자 포트폴리오입니다. 화면 너비에 따라 단순히 크기만 바꾸지 않고, 각 기기에 어울리는 Apple 인터페이스로 전환됩니다.

- 데스크톱(`1024px` 이상): 창, 메뉴 막대, Dock을 갖춘 macOS 데스크톱
- 태블릿(`600px` 이상, `1024px` 미만): 홈 화면과 앱 화면 중심의 iPadOS 인터페이스
- 모바일(`600px` 미만): 안전 영역과 홈 인디케이터를 반영한 iPhone 인터페이스

현재 공개 페이지는 [GitHub Pages](https://hesu-dev.github.io/portfolio_hesu/)에서 확인할 수 있습니다.

## 기술 스택

- Flutter / Dart
- Material 3 및 Cupertino 아이콘
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

현재 배포는 GitHub Pages를 유지하며, 저장소 이름을 포함한 base 경로로 빌드합니다.

```bash
flutter build web --release --base-href /portfolio_hesu/ --pwa-strategy=none
```

향후 Vercel로 이전할 때는 루트 경로를 기준으로 빌드합니다.

```bash
flutter build web --release --base-href / --pwa-strategy=none
```

두 빌드 모두 결과물 디렉터리는 `build/web`입니다. Vercel에서는 위 루트 경로 빌드 명령과 `build/web` 출력 디렉터리를 사용하면 됩니다. 현재 작업에서는 Vercel 배포나 도메인 연결 등 외부 설정을 변경하지 않습니다.
