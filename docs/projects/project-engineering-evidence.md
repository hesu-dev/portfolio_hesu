# 프로젝트 상세 설명의 근거와 범위

확인일: 2026-09-30

이 문서는 프로젝트 상세 화면의 핵심 기술, 기술 의사결정, 트러블슈팅 설명과
`lib/portfolio/data/project_diagrams.dart`의 연결선이 무엇을 근거로 작성되었는지 기록한다.
프로젝트에 표시된 기간은 기존 참여·설계 기간이다. 아래의 소스 확인일은 그 기간과 별개이며,
현재 확인 가능한 코드에 이후 변경이 포함될 수 있다.

소스와 테스트를 읽어 확인한 동작을 운영 장애 발생 이력이나 측정한 개선율로 해석하지 않는다.
아래의 회귀 테스트는 해당 프로젝트에 존재하는 검증 사례이며, 이 포트폴리오 작업에서
모든 원본 프로젝트 테스트를 새로 실행했다는 뜻은 아니다.

## ReadingLog

근거: 형제 저장소 `readinglog/front`의 소스·테스트(`f9802f7e`), 기존 포트폴리오의 출시·기능 기록.

| 설명 | 확인한 소스 |
| --- | --- |
| 프로젝트 JSON 파일을 읽어 디코딩 결과, 초기 커서, 화자 이미지 준비 정보를 한 번에 구성 | `lib/util/project/project_open_decode_isolate.dart`, `test/util/project/project_open_decode_isolate_test.dart` |
| 네이티브는 `Isolate.run`, 웹은 현재 실행 환경의 디코딩 경로 사용 | `lib/util/project/project_open_decode_isolate.dart` |
| 준비한 데이터의 일괄 반영, 성공 경로에서 후속 이미지 갱신 | `lib/util/project/project_open_service.dart` |
| 기대 project ID·revision과 일치하는 미러만 재사용, 불완전한 미러의 사전 확인 | `lib/util/project/project_open_service.dart`, `test/util/project/project_open_service_test.dart` |
| 같은 파싱 라인 데이터에서 PDF·EPUB 생성 | `lib/util/ebook/pdf_export.dart`, `lib/util/ebook/epub_export.dart` |
| 저장 포맷을 변경하지 않고 반복 읽기·목록 순회·UI 실행 흐름의 디코딩 비용을 먼저 줄이는 선택 | `docs/plans/_end/2026-04-02-project-open-single-read-plan.md` |
| Android·iOS의 MethodChannel 명령 및 EventChannel TTS 이벤트 | `lib/tts/native_tts_bridge_io.dart` |
| 네이티브 재생 상태의 queue/playback revision, snapshot version과 위치 | `lib/tts/native_tts_runtime.dart` |
| 최신 snapshot 반영, 오래된 snapshot·queue revision 무시 | `test/player/tts_player_authoritative_snapshot_test.dart` |
| 네이티브 상태를 기준으로 Flutter 화면 상태를 투영하는 책임 분리 | `docs/plans/_end/2026-04-16-native-tts-architecture-review-and-refactor-plan.md` |

HTML → Chrome 확장 → JSON 변환과 PDF·EPUB 내보내기는 기존 포트폴리오에 기록된 기능이다.
그림은 입력 파일 → 앱 내부 디코딩 → 세션 → 화면/문서 출력의 데이터 흐름을 보여 준다.
파일 저장소의 로컬/iCloud 표시는 확인 가능한 파일 열기 범위다. 과거 별도 백엔드 코드가
존재한다는 이유만으로 현재 Firebase 서버·데이터베이스 연결을 추가하지 않았다.

시간·메모리 벤치마크나 실제 장애 건수는 이번 근거에 없으므로 개선율을 적지 않았다.
TTS의 네이티브 채널 설명은 Android·iOS에 한정하며 모든 플랫폼에 일반화하지 않는다.

## AI 역량 검사

근거: 형제 저장소 `ai-work-skills-test`의 소스·테스트(`10d01235`).

| 설명 | 확인한 소스 |
| --- | --- |
| React → Workers API → D1 서버 정본, 제출 스냅샷 고정 | `docs/architecture/assessment-data-flow.md` |
| D1에 먼저 저장하고 Queue에는 submission ID만 전달 | `src/worker/assessmentSubmissionAcceptance.ts`, `docs/architecture/assessment-data-flow.md` |
| Queue 전송 실패에도 영속 저장된 접수 응답 유지 | `src/worker/assessmentSubmissionAcceptance.ts` |
| 복구 대상 제출 검색 및 재전달 | `src/worker/assessmentGradingRecovery.ts` |
| 소비자가 D1에서 다시 읽고 처리권 lease와 claim token으로 조건부 완료 처리 | `src/worker/assessmentGradingQueue.ts` |
| DB 실패, Queue 전송 실패, 전송 결과가 모호한 재시도, 완료된 제출의 재접수 | `tests/assessment-submission-acceptance.test.ts` |
| ID만 든 메시지의 처리권 확보와 채점 동작 | `tests/assessment-grading-queue.test.ts` |

그림의 API → Queue 화살표는 D1 저장 완료 후에 보내는 submission ID를 뜻한다.
D1이 직접 이벤트를 발행하는 구조로 그리지 않았다. 채점 소비자 → D1 연결은 정본 읽기와
조건부 결과 쓰기이며, 응시 화면은 API를 통해 결과를 조회한다. AI 협업 대화 요청과
비동기 채점 요청은 서로 다른 경로로 표시했다.

Queue 전송 실패 및 중복·지연 처리에 대한 설명은 코드와 테스트에서 확인한 방어 동작이다.
실제 운영에서 해당 장애가 몇 번 발생했고 얼마나 개선됐는지에 대한 주장은 포함하지 않는다.

## Portfolio

확인일: 2026-10-19. 근거: 현재 저장소의 실제 구현과 테스트.

기존 AI 캐릭터 채팅 설계 항목을 현재 포트폴리오 프로젝트로 교체했다.
이 항목의 구조도는 구현된 데이터 전달과 앱 선택 관계를 표시한다.

| 설명 | 확인한 소스 |
| --- | --- |
| 포트폴리오 데이터·테마·음악 컨트롤러 소유와 전달 | `lib/portfolio/portfolio_app.dart`, `lib/portfolio/data/portfolio_data.dart` |
| 600px·1024px 기준과 모바일 브라우저의 셸 선택 | `lib/portfolio/widgets/adaptive_portfolio_shell.dart` |
| 데스크톱 창·Dock과 모바일 홈·앱 탐색 | `lib/portfolio/macos/`, `lib/portfolio/mobile/` |
| 앱 콘텐츠 선택과 파일·Safari 공용 상세 | `lib/portfolio/apps/portfolio_app_content.dart`, `projects_app.dart`, `safari_app.dart`, `safari_project_page.dart` |
| 폴더별 아이콘·목록 보기 및 정렬 | `lib/portfolio/apps/projects_app.dart`, `test/portfolio/projects_view_options_test.dart` |
| ChangeNotifier 기반 테마·음악 상태 | `lib/portfolio/theme/portfolio_theme_controller.dart`, `lib/portfolio/music/music_controller.dart` |
| GitHub 기여 API 조회와 저장 자산 fallback | `lib/portfolio/services/github_contributions_loader.dart`, `test/portfolio/github_contributions_loader_test.dart` |
| 웹 PDF·HTML 미리보기, 네이티브 미지원 분기 | `lib/portfolio/printing/open_print_document.dart`, `open_print_document_web.dart`, `open_print_document_stub.dart` |
| 개발·운영 설정과 웹·실기기 실행 | `lib/config/app_config.dart`, `config/`, `tool/deploy.dart` |

프로젝트 기간은 현재 저장소의 최초 커밋이 있는 2026년 9월부터 현재로 표시한다.
기여율, 운영 사용자 수, 성능 개선율은 확인된 자료가 없어 추가하지 않았다.
구조도의 GitHub는 기여 기록 조회 기능이며 별도의 인증·결제·데이터베이스 서버를 의미하지 않는다.
웹 PDF 출력은 Flutter 네이티브의 인쇄 지원을 의미하지 않는다.
iPhone 운영 설정 릴리스는 이 작업에서 빌드·설치·실행을 확인했다.

## Blue Mentor

근거: 보관 중인 `lsmk/bm-app` 앱 소스(`70c5d6f6`)와 Git 변경 이력.
`pubspec.yaml`의 Blue Mentor 설명과 모바일 앱 식별자가 기존 포트폴리오 프로젝트와 일치한다.

| 설명 | 확인한 소스 |
| --- | --- |
| Hive 어댑터 등록, Provider의 로그인·대시보드·사진 캐시 상태 제공 | `lib/main.dart` |
| 화면 이동 Analytics 관찰, Flutter 오류의 Crashlytics 연결 | `lib/main.dart` |
| JSON 요청, 인증 만료 후 최대 1회 토큰 갱신·재시도, 무효 세션 초기화 | `lib/reusable/widgets/global_http.dart` |
| 파일 경로와 점검 항목 정보를 Hive에 추가·조회·삭제 | `lib/storage/CachedImgService.dart`, `lib/storage/model/CachedImg.dart` |
| 촬영·선택한 파일의 multipart 업로드 | `lib/reusable/utils/uploadLoaclImage.dart` |
| 캐시된 사진의 multipart 재업로드, 취소 토큰과 네트워크 오류 전달 | `lib/reusable/utils/uploadCachedImage.dart` |
| 실패 사진 보관·안내, 선택한 사진의 재업로드, 성공한 항목의 캐시 삭제 | `lib/ui/inspection/view/inspection.dart` |
| 이미지 업로드 무한 로딩 개선: 예외 시 실패 처리, 제출 상태 초기화 보강 | 2024-01-18 커밋 `d7f47d5bc4b342c581f63b32a95137415924a7cd` |

위 수정 커밋은 팀원의 작성 이력이다. 프로젝트에서 다룬 문제와 코드의 복구 흐름으로 설명하며,
사용자가 해당 커밋을 직접 작성했다거나 혼자 해결했다고 표시하지 않는다.
기술 의사결정 설명은 현재 코드에서 확인한 책임 분리에 대한 회고적 해석이며 ADR나 당시의
대안 비교 문서를 발견한 것으로 표현하지 않는다.

`test/widget_test.dart`는 Flutter 기본 카운터 예제 테스트다. 사진 전송·재업로드에 대한
회귀 테스트를 발견하지 못했으므로 구현과 변경 이력의 검토 범위까지만 주장한다.
전송 제한 시간은 구현된 기본값이지 실제 장애 복구 시간의 측정치가 아니다.

기존 기술 목록의 Node.js는 보존하되, 앱 소스만으로 서버 내부 런타임·DB·스토리지·호스팅을
확정하지 않는다. 다이어그램의 외부 업무 API는 일반적인 경계이며 특정 클라우드나
데이터베이스를 그리지 않는다. Firebase는 확인된 Analytics·Crashlytics 용도로만 표시한다.

## AI Switch · IRIS · AI-Bver · HiddenTag

근거: `lib/portfolio/data/portfolio_data.dart`에 이미 있던 참여 업무와 기술 목록.

상세 구현 코드나 의사결정 기록이 이번 자료에 없으므로 **확인된 구성 요소**만 그린다.
기술 이름만으로 API 연결 방향, AWS 등 특정 클라우드, DB, 배포 파이프라인을 추정하지 않는다.
기술 선정의 대안·판단 근거와 구체 장애 해결 과정은 원본 기록 확보 후 보완하도록 명시했다.

기존 데이터에 있던 역할·기간·스토어 링크·성과 문구는 보존했다. 기존에 “임시 예시” 또는
“초안”으로 표기된 기여율·정량 성과를 이번 작업의 검증된 기술 근거로 사용하지 않는다.

## 표시 원칙

- 아이콘은 기술과 구성 요소를 구분하기 위한 그림이며 공식 공급자 배포 구성을 암시하지 않는다.
- 데이터 흐름이 확인된 프로젝트만 방향과 전달 내용을 붙인 연결선을 사용한다.
- 설계도와 구현 구조도를 설명문에서 구분한다.
- 화면에는 개인 컴퓨터의 절대 경로나 검토용 저장소 위치를 노출하지 않는다.
