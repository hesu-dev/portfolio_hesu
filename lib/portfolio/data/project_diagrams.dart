import 'project_architecture.dart';

const readingLogArchitecture = PortfolioArchitectureDiagram(
  width: 1000,
  height: 690,
  summary:
      'HTML 로그를 Chrome 확장 프로그램에서 JSON으로 변환합니다. '
      '파일을 읽은 Flutter 앱은 네이티브 백그라운드 디코딩 후 프로젝트 세션을 갱신하고, '
      '리더 화면과 PDF·EPUB 내보내기에 사용합니다. 웹은 같은 디코딩을 현재 실행 환경에서 처리합니다.',
  groups: [
    PortfolioArchitectureGroup(
      label: '로그 수집 · 휴대 가능한 파일',
      x: 28,
      y: 28,
      width: 944,
      height: 196,
    ),
    PortfolioArchitectureGroup(
      label: 'Flutter 앱 · 네이티브 실행 기준',
      x: 28,
      y: 284,
      width: 944,
      height: 376,
    ),
  ],
  nodes: [
    PortfolioArchitectureNode(
      id: 'html',
      label: 'HTML 채팅 로그',
      detail: '원본 대화 기록',
      icon: 'browser',
      x: 150,
      y: 130,
    ),
    PortfolioArchitectureNode(
      id: 'extension',
      label: 'Chrome 확장',
      detail: '로그 추출 · 변환',
      icon: 'extension',
      x: 380,
      y: 130,
    ),
    PortfolioArchitectureNode(
      id: 'json',
      label: '프로젝트 JSON',
      detail: '기존 스키마 유지',
      icon: 'json',
      x: 610,
      y: 130,
    ),
    PortfolioArchitectureNode(
      id: 'files',
      label: '파일 저장소',
      detail: '로컬 파일 · iCloud',
      icon: 'file',
      x: 850,
      y: 130,
    ),
    PortfolioArchitectureNode(
      id: 'decode',
      label: '디코딩',
      detail: '네이티브 Isolate.run',
      icon: 'dart',
      x: 850,
      y: 390,
    ),
    PortfolioArchitectureNode(
      id: 'session',
      label: '프로젝트 세션',
      detail: '준비한 데이터를 일괄 반영',
      icon: 'flutter',
      x: 600,
      y: 390,
    ),
    PortfolioArchitectureNode(
      id: 'reader',
      label: '리더 화면',
      detail: '채팅 · eBook · 소설',
      icon: 'flutter',
      x: 340,
      y: 390,
    ),
    PortfolioArchitectureNode(
      id: 'pdf',
      label: 'PDF 내보내기',
      detail: '페이지 문서 생성',
      icon: 'pdf',
      x: 600,
      y: 570,
    ),
    PortfolioArchitectureNode(
      id: 'epub',
      label: 'EPUB 내보내기',
      detail: '전자책 문서 생성',
      icon: 'epub',
      x: 850,
      y: 570,
    ),
  ],
  edges: [
    PortfolioArchitectureEdge(from: 'html', to: 'extension', label: '대화 추출'),
    PortfolioArchitectureEdge(from: 'extension', to: 'json', label: '스키마 변환'),
    PortfolioArchitectureEdge(from: 'json', to: 'files', label: '파일 저장'),
    PortfolioArchitectureEdge(from: 'files', to: 'decode', label: '파일 열기'),
    PortfolioArchitectureEdge(
      from: 'decode',
      to: 'session',
      label: '모델 · 초기 상태',
    ),
    PortfolioArchitectureEdge(from: 'session', to: 'reader', label: '화면 상태 반영'),
    PortfolioArchitectureEdge(from: 'session', to: 'pdf', label: '문서 데이터'),
    PortfolioArchitectureEdge(
      from: 'session',
      to: 'epub',
      label: '문서 데이터',
      via: [
        PortfolioArchitecturePoint(730, 480),
        PortfolioArchitecturePoint(850, 480),
      ],
    ),
  ],
);

const aiAssessmentArchitecture = PortfolioArchitectureDiagram(
  width: 1000,
  height: 630,
  summary:
      'React 화면은 Workers API를 통해 D1에 대화와 제출 스냅샷을 저장합니다. '
      '저장 완료 후 제출 ID만 Queue로 전달하고, 채점 소비자는 D1 원본을 다시 읽어 '
      'OpenAI로 채점합니다. 결과는 claim token 조건으로 D1에 기록하고 API를 통해 리포트로 조회합니다.',
  groups: [
    PortfolioArchitectureGroup(
      label: '브라우저',
      x: 24,
      y: 90,
      width: 182,
      height: 222,
    ),
    PortfolioArchitectureGroup(
      label: 'Cloudflare · 영속 저장과 비동기 처리',
      x: 238,
      y: 24,
      width: 738,
      height: 342,
    ),
    PortfolioArchitectureGroup(
      label: 'OpenAI API · 대화와 채점 요청 분리',
      x: 238,
      y: 426,
      width: 738,
      height: 178,
    ),
  ],
  nodes: [
    PortfolioArchitectureNode(
      id: 'react',
      label: 'React UI',
      detail: '응시 · 관리자 · 리포트',
      icon: 'react',
      x: 115,
      y: 200,
    ),
    PortfolioArchitectureNode(
      id: 'api',
      label: 'Workers API',
      detail: '인증 · 기록 · 제출 접수',
      icon: 'worker',
      x: 350,
      y: 200,
    ),
    PortfolioArchitectureNode(
      id: 'd1',
      label: 'D1',
      detail: '대화 · 제출 정본 · 결과',
      icon: 'storage',
      x: 600,
      y: 200,
    ),
    PortfolioArchitectureNode(
      id: 'queue',
      label: 'Queues',
      detail: '제출 ID만 전달',
      icon: 'queue',
      x: 850,
      y: 110,
    ),
    PortfolioArchitectureNode(
      id: 'grader',
      label: '채점 소비자',
      detail: 'lease · claim token',
      icon: 'worker',
      x: 850,
      y: 290,
    ),
    PortfolioArchitectureNode(
      id: 'chat',
      label: 'AI 협업 대화',
      detail: '응시 중 모델 응답',
      icon: 'ai',
      x: 350,
      y: 520,
    ),
    PortfolioArchitectureNode(
      id: 'grading',
      label: '구조화 채점',
      detail: '스냅샷 기반 평가',
      icon: 'ai',
      x: 850,
      y: 520,
    ),
  ],
  edges: [
    PortfolioArchitectureEdge(from: 'react', to: 'api', label: '응시 · 결과 조회'),
    PortfolioArchitectureEdge(from: 'api', to: 'd1', label: '먼저 저장'),
    PortfolioArchitectureEdge(
      from: 'api',
      to: 'queue',
      label: '저장 후 submissionId',
      via: [
        PortfolioArchitecturePoint(350, 70),
        PortfolioArchitecturePoint(740, 70),
      ],
    ),
    PortfolioArchitectureEdge(from: 'queue', to: 'grader', label: '비동기 전달'),
    PortfolioArchitectureEdge(
      from: 'grader',
      to: 'd1',
      label: '정본 읽기 · 조건부 기록',
      via: [
        PortfolioArchitecturePoint(720, 290),
        PortfolioArchitecturePoint(600, 290),
      ],
    ),
    PortfolioArchitectureEdge(from: 'api', to: 'chat', label: '대화 요청'),
    PortfolioArchitectureEdge(from: 'grader', to: 'grading', label: '채점 요청'),
  ],
);

const portfolioArchitecture = PortfolioArchitectureDiagram(
  width: 1000,
  height: 860,
  summary:
      'PortfolioApp이 공통 데이터와 테마·음악 상태를 반응형 셸에 전달합니다. '
      '선택한 앱 콘텐츠는 파일·Safari 공용 프로젝트 상세, GitHub 기여 기록 조회와 웹 PDF 출력으로 연결됩니다.',
  groups: [
    PortfolioArchitectureGroup(
      label: '데이터 · 앱 조립 · 공통 상태',
      x: 28,
      y: 28,
      width: 944,
      height: 194,
    ),
    PortfolioArchitectureGroup(
      label: '기기별 화면 · 앱 콘텐츠',
      x: 390,
      y: 270,
      width: 220,
      height: 370,
    ),
    PortfolioArchitectureGroup(
      label: '웹 문서 출력',
      x: 740,
      y: 684,
      width: 232,
      height: 150,
    ),
  ],
  nodes: [
    PortfolioArchitectureNode(
      id: 'data',
      label: 'PortfolioData',
      detail: '경력 · 기술 · 프로젝트',
      icon: 'dart',
      x: 150,
      y: 130,
    ),
    PortfolioArchitectureNode(
      id: 'app',
      label: 'PortfolioApp',
      detail: '데이터 · 컨트롤러 주입',
      icon: 'flutter',
      x: 500,
      y: 130,
    ),
    PortfolioArchitectureNode(
      id: 'state',
      label: '공유 상태',
      detail: '테마 · 음악 컨트롤러',
      icon: 'flutter',
      x: 850,
      y: 130,
    ),
    PortfolioArchitectureNode(
      id: 'shell',
      label: '반응형 셸',
      detail: 'macOS · iPad · iPhone',
      icon: 'browser',
      x: 500,
      y: 350,
    ),
    PortfolioArchitectureNode(
      id: 'content',
      label: '앱 콘텐츠',
      detail: '선택한 앱 화면 표시',
      icon: 'flutter',
      x: 500,
      y: 565,
    ),
    PortfolioArchitectureNode(
      id: 'github',
      label: 'GitHub 기여 기록',
      detail: 'API 조회 · 저장 기록 대체',
      icon: 'github',
      x: 150,
      y: 565,
    ),
    PortfolioArchitectureNode(
      id: 'report',
      label: '프로젝트 상세',
      detail: '파일 · Safari 공용 보고서',
      icon: 'file',
      x: 850,
      y: 565,
    ),
    PortfolioArchitectureNode(
      id: 'pdf',
      label: '웹 PDF 출력',
      detail: '한글 PDF · HTML 미리보기',
      icon: 'pdf',
      x: 850,
      y: 760,
    ),
  ],
  edges: [
    PortfolioArchitectureEdge(from: 'data', to: 'app', label: '공통 데이터'),
    PortfolioArchitectureEdge(from: 'app', to: 'state', label: '컨트롤러 소유'),
    PortfolioArchitectureEdge(from: 'app', to: 'shell', label: '데이터 · 공유 상태'),
    PortfolioArchitectureEdge(from: 'shell', to: 'content', label: '앱 선택'),
    PortfolioArchitectureEdge(
      from: 'content',
      to: 'github',
      label: '열기 · 새로고침',
    ),
    PortfolioArchitectureEdge(from: 'content', to: 'report', label: '프로젝트 선택'),
    PortfolioArchitectureEdge(
      from: 'content',
      to: 'pdf',
      label: '웹 프린터',
      via: [PortfolioArchitecturePoint(500, 760)],
    ),
  ],
);

// These older projects only have confirmed stack/role records. No inferred
// data flow, hosting provider, or deployment boundary is drawn.
const aiSwitchArchitecture = PortfolioArchitectureDiagram(
  width: 760,
  height: 250,
  summary: 'React 화면과 TypeScript 코드로 구성된 홈페이지의 확인된 기술입니다.',
  groups: [
    PortfolioArchitectureGroup(
      label: '홈페이지 유지보수 · 확인된 기술',
      x: 28,
      y: 24,
      width: 704,
      height: 198,
    ),
  ],
  nodes: [
    PortfolioArchitectureNode(
      id: 'react',
      label: 'React',
      detail: '홈페이지 화면 유지보수',
      icon: 'react',
      x: 250,
      y: 130,
    ),
    PortfolioArchitectureNode(
      id: 'typescript',
      label: 'TypeScript',
      detail: '타입 기반 화면 코드',
      icon: 'typescript',
      x: 510,
      y: 130,
    ),
  ],
);

const blueMentorArchitecture = PortfolioArchitectureDiagram(
  width: 1000,
  height: 670,
  summary:
      'Flutter 점검 화면은 Provider로 상태를 관리하고 HTTP JSON 요청으로 업무 API와 연결됩니다. 카메라·갤러리 사진은 Dio multipart로 전송하며, 실패한 사진의 경로와 점검 정보는 Hive 캐시에 보관합니다. 실패한 사진은 캐시에서 다시 선택하며, 성공한 파일만 캐시에서 제거합니다.',
  groups: [
    PortfolioArchitectureGroup(
      label: 'Flutter 앱 · 화면 / 상태 / 전송',
      x: 24,
      y: 24,
      width: 712,
      height: 590,
    ),
    PortfolioArchitectureGroup(
      label: '외부 서비스',
      x: 766,
      y: 24,
      width: 208,
      height: 590,
    ),
  ],
  nodes: [
    PortfolioArchitectureNode(
      id: 'ui',
      label: 'Flutter 점검 화면',
      detail: '점검 · 보고서 · 사진 첨부',
      icon: 'flutter',
      x: 140,
      y: 160,
    ),
    PortfolioArchitectureNode(
      id: 'provider',
      label: 'Provider',
      detail: '로그인 · 대시보드 상태',
      icon: 'dart',
      x: 395,
      y: 160,
    ),
    PortfolioArchitectureNode(
      id: 'http',
      label: 'HTTP JSON',
      detail: '업무 데이터 · 인증 재시도',
      icon: 'json',
      x: 630,
      y: 160,
    ),
    PortfolioArchitectureNode(
      id: 'api',
      label: '업무 API',
      detail: 'JSON · 사진 업로드',
      icon: 'server',
      x: 870,
      y: 280,
    ),
    PortfolioArchitectureNode(
      id: 'photo',
      label: '카메라 · 갤러리',
      detail: '현장 사진 촬영 · 선택',
      icon: 'file',
      x: 140,
      y: 400,
    ),
    PortfolioArchitectureNode(
      id: 'cache',
      label: '로컬 파일 · Hive',
      detail: '사진 경로 · 점검 정보',
      icon: 'storage',
      x: 395,
      y: 400,
    ),
    PortfolioArchitectureNode(
      id: 'upload',
      label: 'Dio Multipart',
      detail: '시간 제한 · 실패 후 재전송',
      icon: 'file',
      x: 630,
      y: 400,
    ),
    PortfolioArchitectureNode(
      id: 'firebase',
      label: 'Firebase',
      detail: 'Analytics · Crashlytics',
      icon: 'firebase',
      x: 870,
      y: 530,
    ),
  ],
  edges: [
    PortfolioArchitectureEdge(from: 'ui', to: 'provider', label: '상태 구독 · 변경'),
    PortfolioArchitectureEdge(from: 'provider', to: 'http', label: '조회 · 저장'),
    PortfolioArchitectureEdge(from: 'http', to: 'api', label: 'JSON 요청'),
    PortfolioArchitectureEdge(from: 'ui', to: 'photo', label: '사진 첨부'),
    PortfolioArchitectureEdge(from: 'photo', to: 'cache', label: '실패 사진 보관'),
    PortfolioArchitectureEdge(
      from: 'photo',
      to: 'upload',
      label: '촬영 · 선택 파일',
      via: [
        PortfolioArchitecturePoint(140, 490),
        PortfolioArchitecturePoint(630, 490),
      ],
    ),
    PortfolioArchitectureEdge(from: 'cache', to: 'upload', label: '선택 · 재업로드'),
    PortfolioArchitectureEdge(from: 'upload', to: 'api', label: '사진 전송'),
    PortfolioArchitectureEdge(
      from: 'ui',
      to: 'firebase',
      label: '화면 이벤트 · 오류',
      via: [
        PortfolioArchitecturePoint(40, 260),
        PortfolioArchitecturePoint(40, 555),
        PortfolioArchitecturePoint(755, 555),
      ],
    ),
  ],
);

const irisArchitecture = PortfolioArchitectureDiagram(
  width: 900,
  height: 250,
  summary: '3D 증강현실 기반 교량 점검 R&D의 React, Unity, MySQL 기술 구성입니다.',
  groups: [
    PortfolioArchitectureGroup(
      label: '교량 점검 R&D · 확인된 기술',
      x: 28,
      y: 24,
      width: 844,
      height: 198,
    ),
  ],
  nodes: [
    PortfolioArchitectureNode(
      id: 'react',
      label: 'React',
      detail: '웹 기술 구성',
      icon: 'react',
      x: 190,
      y: 130,
    ),
    PortfolioArchitectureNode(
      id: 'unity',
      label: 'Unity',
      detail: '3D · 증강현실 기술',
      icon: 'unity',
      x: 450,
      y: 130,
    ),
    PortfolioArchitectureNode(
      id: 'mysql',
      label: 'MySQL',
      detail: '데이터베이스 기술',
      icon: 'mysql',
      x: 710,
      y: 130,
    ),
  ],
);

const aiBverArchitecture = PortfolioArchitectureDiagram(
  width: 900,
  height: 250,
  summary: 'AI-beaver 개발·유지보수의 Flutter, Dart, PHP 기술 구성입니다.',
  groups: [
    PortfolioArchitectureGroup(
      label: '앱 개발 · 유지보수 · 확인된 기술',
      x: 28,
      y: 24,
      width: 844,
      height: 198,
    ),
  ],
  nodes: [
    PortfolioArchitectureNode(
      id: 'flutter',
      label: 'Flutter',
      detail: '애플리케이션 개발',
      icon: 'flutter',
      x: 190,
      y: 130,
    ),
    PortfolioArchitectureNode(
      id: 'dart',
      label: 'Dart',
      detail: '앱 구현 언어',
      icon: 'dart',
      x: 450,
      y: 130,
    ),
    PortfolioArchitectureNode(
      id: 'php',
      label: 'PHP',
      detail: '프로젝트 기술 구성',
      icon: 'php',
      x: 710,
      y: 130,
    ),
  ],
);

const hiddenTagArchitecture = PortfolioArchitectureDiagram(
  width: 760,
  height: 250,
  summary: 'HiddenTag 페이지 유지보수의 Java, Apache 환경입니다.',
  groups: [
    PortfolioArchitectureGroup(
      label: '애플리케이션 페이지 유지보수 · 확인된 기술',
      x: 28,
      y: 24,
      width: 704,
      height: 198,
    ),
  ],
  nodes: [
    PortfolioArchitectureNode(
      id: 'java',
      label: 'Java',
      detail: '서비스 페이지 코드',
      icon: 'java',
      x: 250,
      y: 130,
    ),
    PortfolioArchitectureNode(
      id: 'apache',
      label: 'Apache',
      detail: '서비스 운영 환경',
      icon: 'apache',
      x: 510,
      y: 130,
    ),
  ],
);
