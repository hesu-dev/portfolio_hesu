# Cloudflare Backend and iOS Release Implementation Plan

**Goal:** 개인 Cloudflare 계정에 공개 포트폴리오 웹사이트와 GitHub 실시간 조회 API를 배포하고 iPhone에 운영 앱을 설치한다.

**Architecture:** `portfolio-hesu` Worker는 Flutter 정적 웹을 제공하고 `portfolio-hesu-api` Worker는 매 요청마다 고정된 GitHub 원본 달력을 캐시 없이 조회한다. Flutter는 컴파일 환경 설정으로 API 주소를 받고, 실패 시 저장 기록 대신 오류와 재시도를 표시한다. 개인 계정과 iPhone 설치는 사용자 선택을 반영한다.

**Tech Stack:** Cloudflare Workers, JavaScript Web APIs, Node 기본 테스트, Flutter/Dart.

1. `backend/worker.test.mjs`에서 고정 경로, HTTP 메서드, 업스트림 실패 및 잘못된 응답 처리를 검사한다. `node --test backend/worker.test.mjs`로 실패를 확인하고 `backend/worker.mjs`를 구현한다.
2. `backend/wrangler.json`으로 API만 독립 배포할 수 있게 설정한다. 승인된 계정에 배포하고 health 및 실제 기여 기록 응답을 확인한다.
3. `lib/config/app_config.dart`와 기여 기록 로더에 `GITHUB_CONTRIBUTIONS_URL`을 연결한다. 사용자 지정 주소와 저장 기록을 읽지 않는 실패 동작을 검증한다.
4. 실제 배포 주소를 `config/production.json`에 설정하고 분석 및 테스트를 실행한다. 기존 실패는 별도로 기록하고 원인을 확인한다.
5. Flutter 웹 릴리즈를 `https://portfolio-hesu.portfolio-hesu.workers.dev/`에 배포하고 실제 렌더링을 확인한다. iOS 릴리즈 앱도 연결된 iPhone에 설치한다.
