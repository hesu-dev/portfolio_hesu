# Main Branch Production Deployment Implementation Plan

**Goal:** `hesu-dev/portfolio_hesu`의 `main` 푸시마다 Flutter 웹과 실시간 GitHub API를 개인 Cloudflare 계정에 자동 배포한다.

**Architecture:** GitHub Actions 한 작업에서 Flutter 분석·테스트와 Worker 테스트를 통과한 후 기존 운영 빌드 도구를 실행한다. API, 웹 순서로 배포하며 배포 작업은 중첩 실행하지 않는다. 인증은 저장소의 `CLOUDFLARE_API_TOKEN` 시크릿을 사용한다.

**Tech Stack:** GitHub Actions, Flutter 3.38.9, Node.js 24, Wrangler 4.151.3.

1. `.github/workflows/cloudflare-production.yml`에 main 푸시와 수동 실행을 설정하고 검증·빌드·배포·접속 확인을 순서대로 실행한다.
2. actionlint로 문법을 확인하고 사용한 외부 액션은 확인된 커밋 SHA로 고정한다.
3. 개인 Cloudflare 계정에 한정된 배포 토큰을 GitHub Actions 시크릿에 등록한다. 토큰을 코드·로그·채팅에 출력하지 않는다.
4. 사용자가 승인한 현재 앱 변경 전체와 배포 설정을 커밋하고 main에 푸시한다. 첫 Actions 실행의 최종 결과와 운영 주소를 확인한다.
