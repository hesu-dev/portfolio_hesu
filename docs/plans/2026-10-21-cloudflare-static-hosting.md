# Cloudflare Static Hosting Preparation Implementation Plan

**Goal:** `./deploy.sh`에서 Cloudflare 정적 호스팅용 웹 빌드를 준비하되 계정 인증이나 원격 배포는 실행하지 않는다.

**Architecture:** 기존 shell → Dart 실행 구조와 1·2번 메뉴를 유지한다. 3번은 기존 `tool/build_web.dart`를 호출하고 성공한 경우에만 산출물 및 나중에 직접 실행할 Wrangler 명령을 안내한다. `wrangler.json`은 `build/web`과 SPA fallback만 설정하며 계정·도메인·서버 코드를 포함하지 않는다.

**Tech Stack:** POSIX shell, Dart 표준 라이브러리, Flutter Web, Cloudflare Workers Static Assets.

## 1. 실행 계약을 먼저 검증

- `test/tool/deploy_test.dart`에 메뉴/인자 3번의 빌드 호출과 실패 코드 전달 검증을 추가한다.
- Dart 빌드 명령은 임시 실행 파일로 대체하고, Wrangler·브라우저 실행은 금지하는 대역으로 감지한다.
- `flutter test test/tool/deploy_test.dart`로 새 동작이 없어 실패하는지 확인한다.

## 2. 최소 구현

- `tool/deploy.dart`에 3번과 빌드 성공 후 안내를 추가한다. 로그인·배포 명령은 출력만 한다.
- `deploy.sh` 설명을 실행 도구 전체 역할에 맞춘다.
- `wrangler.json`에 정적 산출물 경로와 SPA fallback을 설정한다.
- `.gitignore`에 Wrangler의 로컬 캐시 경로를 추가한다.

## 3. 문서와 검증

- `README.md`의 기본 호스팅 설명을 Vercel 준비에서 Cloudflare 정적 호스팅 준비로 변경한다.
- 개발 및 실기기 실행 안내를 보존하고, 3번이 계정에 연결하지 않는다는 점을 명시한다.
- 배포·빌드 도구 테스트, 변경한 Dart 파일 분석, shell 문법 검사를 실행한다.
- 개인 계정 인증, 원격 Workers 생성·업로드, 실제 배포는 수행하지 않는다.
