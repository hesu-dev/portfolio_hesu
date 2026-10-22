# Development / Production Deployment Implementation Plan

**Goal:** 개발·운영 설정을 분리하고 `./deploy.sh`에서 localhost 웹 실행 또는 실기기 릴리스 설치·실행을 선택한다.

**Architecture:** Flutter 기본 `--dart-define-from-file`로 `config/development.json`과 `config/production.json`을 주입한다. `AppConfig.environment`로 환경 이름을 읽으며 디버그 리본은 사용자 요청에 따라 항상 숨긴다. `deploy.sh`는 저장소 루트를 기준으로 Dart 표준 라이브러리로 작성한 실행 도구를 호출하며, Flutter의 JSON 기기 목록에서 지원되는 Android/iOS 실기기만 선택한다. 별도 패키지와 네이티브 flavor는 추가하지 않는다.

**Tech Stack:** POSIX shell, Dart `dart:io` / `dart:convert`, Flutter CLI, 기존 `flutter_test`.

## 1. 실행 계약 검증

- `test/tool/deploy_test.dart`: 실제 shell 진입점을 호출하되 Flutter 실행 파일만 임시 대역으로 대체한다.
- 개발 웹 옵션, 운영 릴리스 옵션, 여러 기기 선택, 에뮬레이터 제외, 잘못된 입력 및 Flutter 실패 전달을 검증한다.
- `test/tool/build_web_test.dart`에 운영 설정 주입 기대값을 추가하고 구현 전에 실패를 확인한다.

## 2. 환경과 실행 도구 구현

- `config/development.json`, `config/production.json`, `lib/config/app_config.dart`를 추가한다. `PortfolioApp`의 디버그 리본은 항상 숨긴다.
- `deploy.sh`, `tool/deploy.dart`를 추가한다. 1번은 개발 Chrome / localhost:8080, 2번은 운영 실기기 release를 기본값으로 사용한다.
- Chrome 외 브라우저는 `WEB_DEVICE=web-server`, 포트 변경은 `WEB_PORT`를 지원한다.
- 기본 8080 포트가 점유된 실제 환경을 확인하여, 기본 포트 사용 불가 시 빈 포트를 자동 선택한다.
- 기존 `tool/build_web.dart`에 운영 설정을 추가한다.

## 3. 검증과 문서

- 배포 분기 테스트, 개발·운영 설정을 각각 주입한 앱 테스트, `flutter analyze`, shell 문법 검사.
- 실제 localhost 응답 및 운영 웹 빌드를 확인한다. 실기기 설치는 연결 상태에 따라 확인 가능 여부를 명시한다.
- README에 선택 메뉴, 환경 파일, 수동 명령, Android USB 디버깅 및 iOS 서명 요구사항을 기록한다.
- 기존 작업 중인 변경을 유지하고 요청된 파일만 수정한다.
