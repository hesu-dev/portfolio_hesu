class PortfolioIdentity {
  const PortfolioIdentity({
    required this.name,
    required this.englishName,
    required this.email,
    required this.githubUrl,
    required this.headline,
    required this.biography,
  });

  final String name;
  final String englishName;
  final String email;
  final String githubUrl;
  final String headline;
  final String biography;
}

class PortfolioExperience {
  const PortfolioExperience({
    required this.role,
    required this.organization,
    required this.period,
    required this.description,
  });

  final String role;
  final String organization;
  final String period;
  final String description;
}

class PortfolioEducation {
  const PortfolioEducation({
    required this.program,
    required this.institution,
    required this.period,
    this.link,
  });

  final String program;
  final String institution;
  final String period;
  final PortfolioProjectLink? link;
}

class PortfolioSkillGroup {
  factory PortfolioSkillGroup({
    required String title,
    required Iterable<String> skills,
    Map<String, String> activityDescriptions = const <String, String>{},
  }) {
    return PortfolioSkillGroup.constant(
      title: title,
      skills: List<String>.unmodifiable(skills),
      activityDescriptions: Map<String, String>.unmodifiable(
        activityDescriptions,
      ),
    );
  }

  /// Creates a compile-time constant from const list values.
  ///
  /// Use the default constructor for runtime iterables so they are copied.
  const PortfolioSkillGroup.constant({
    required this.title,
    required this.skills,
    this.activityDescriptions = const <String, String>{},
  });

  final String title;
  final List<String> skills;
  final Map<String, String> activityDescriptions;
}

class PortfolioProjectLink {
  const PortfolioProjectLink({required this.label, required this.url});

  final String label;
  final String url;

  Uri get uri => Uri.parse(url);
}

class PortfolioRepository {
  const PortfolioRepository({
    required this.name,
    required this.description,
    required this.language,
    required this.url,
  });

  final String name;
  final String description;
  final String language;
  final String url;

  Uri get uri => Uri.parse(url);
}

enum PortfolioProjectSectionKind {
  work('업무'),
  problem('문제'),
  cause('원인'),
  measurement('측정'),
  solution('해결'),
  evaluation('평가'),
  learning('배운 점'),
  relevance('직무 연관성'),
  outcome('성과 · 지표'),
  note('비고');

  const PortfolioProjectSectionKind(this.label);

  final String label;
}

class PortfolioProjectSection {
  const PortfolioProjectSection({required this.kind, required this.body});

  final PortfolioProjectSectionKind kind;
  final String body;
}

enum PortfolioArchitecturePresentation { components, flow }

class PortfolioProjectArchitecture {
  factory PortfolioProjectArchitecture({
    required String title,
    required String description,
    required Iterable<String> nodes,
    PortfolioArchitecturePresentation presentation =
        PortfolioArchitecturePresentation.components,
  }) {
    return PortfolioProjectArchitecture.constant(
      title: title,
      description: description,
      nodes: List<String>.unmodifiable(nodes),
      presentation: presentation,
    );
  }

  const PortfolioProjectArchitecture.constant({
    required this.title,
    required this.description,
    required this.nodes,
    this.presentation = PortfolioArchitecturePresentation.components,
  });

  final String title;
  final String description;
  final List<String> nodes;
  final PortfolioArchitecturePresentation presentation;
}

enum PortfolioProjectCategory { career, personal }

class PortfolioProjectScreenshot {
  const PortfolioProjectScreenshot({
    required this.asset,
    required this.caption,
    this.aspectRatio = 16 / 9,
  });

  final String asset;
  final String caption;
  final double aspectRatio;
}

class PortfolioProject {
  factory PortfolioProject({
    required String title,
    required String description,
    required String period,
    required Iterable<String> technologies,
    required Iterable<PortfolioProjectLink> links,
    PortfolioProjectCategory category = PortfolioProjectCategory.career,
    String? appIconAsset,
    Iterable<String> highlights = const <String>[],
    PortfolioProjectArchitecture? architecture,
    Iterable<PortfolioProjectSection> sections =
        const <PortfolioProjectSection>[],
    Iterable<PortfolioProjectScreenshot> screenshots =
        const <PortfolioProjectScreenshot>[],
  }) {
    return PortfolioProject.constant(
      title: title,
      description: description,
      period: period,
      technologies: List<String>.unmodifiable(technologies),
      links: List<PortfolioProjectLink>.unmodifiable(links),
      category: category,
      appIconAsset: appIconAsset,
      highlights: List<String>.unmodifiable(highlights),
      architecture: architecture,
      sections: List<PortfolioProjectSection>.unmodifiable(sections),
      screenshots: List<PortfolioProjectScreenshot>.unmodifiable(screenshots),
    );
  }

  /// Creates a compile-time constant from const list values.
  ///
  /// Use the default constructor for runtime iterables so they are copied.
  const PortfolioProject.constant({
    required this.title,
    required this.description,
    required this.period,
    required this.technologies,
    required this.links,
    this.category = PortfolioProjectCategory.career,
    this.appIconAsset,
    this.highlights = const <String>[],
    this.architecture,
    this.sections = const <PortfolioProjectSection>[],
    this.screenshots = const <PortfolioProjectScreenshot>[],
  });

  final String title;
  final String description;
  final String period;
  final List<String> technologies;
  final List<PortfolioProjectLink> links;
  final PortfolioProjectCategory category;
  final String? appIconAsset;
  final List<String> highlights;
  final PortfolioProjectArchitecture? architecture;
  final List<PortfolioProjectSection> sections;
  final List<PortfolioProjectScreenshot> screenshots;

  String? get displayYear =>
      RegExp(r'(?:19|20)\d{2}').firstMatch(period)?.group(0);
}

class PortfolioData {
  factory PortfolioData({
    required PortfolioIdentity identity,
    required Iterable<PortfolioExperience> experiences,
    required Iterable<PortfolioEducation> education,
    required Iterable<PortfolioSkillGroup> skillGroups,
    required Iterable<PortfolioProject> projects,
    Iterable<String> certifications = const <String>[],
    Iterable<PortfolioRepository> repositories = const <PortfolioRepository>[],
  }) {
    return PortfolioData.constant(
      identity: identity,
      experiences: List<PortfolioExperience>.unmodifiable(experiences),
      education: List<PortfolioEducation>.unmodifiable(education),
      skillGroups: List<PortfolioSkillGroup>.unmodifiable(skillGroups),
      projects: List<PortfolioProject>.unmodifiable(projects),
      certifications: List<String>.unmodifiable(certifications),
      repositories: List<PortfolioRepository>.unmodifiable(repositories),
    );
  }

  /// Creates a compile-time constant from const list values.
  ///
  /// Use the default constructor for runtime iterables so they are copied.
  const PortfolioData.constant({
    required this.identity,
    required this.experiences,
    required this.education,
    required this.skillGroups,
    required this.projects,
    this.certifications = const <String>[],
    this.repositories = const <PortfolioRepository>[],
  });

  final PortfolioIdentity identity;
  final List<PortfolioExperience> experiences;
  final List<PortfolioEducation> education;
  final List<PortfolioSkillGroup> skillGroups;
  final List<PortfolioProject> projects;
  final List<String> certifications;
  final List<PortfolioRepository> repositories;

  String get name => identity.name;
  String get email => identity.email;
  String get githubUrl => identity.githubUrl;
  String get mailUrl => 'mailto:${identity.email}';
  String get monogram => _deriveMonogram(identity);
  String get terminalPrompt => r'portfolio: ~$';
  String get appTitle {
    final localName = identity.name.trim();
    final englishName = identity.englishName.trim();
    final displayName = localName.isNotEmpty ? localName : englishName;
    return displayName.isEmpty ? '포트폴리오' : '$displayName 포트폴리오';
  }

  String get allSearchableText => <String>[
    identity.name,
    identity.englishName,
    identity.email,
    identity.githubUrl,
    identity.headline,
    identity.biography,
    for (final experience in experiences) ...<String>[
      experience.role,
      experience.organization,
      experience.period,
      experience.description,
    ],
    for (final item in education) ...<String>[
      item.program,
      item.institution,
      item.period,
      if (item.link case final link?) link.label,
    ],
    for (final group in skillGroups) ...<String>[
      group.title,
      ...group.skills,
      ...group.activityDescriptions.values,
    ],
    ...certifications,
    for (final project in projects) ...<String>[
      project.title,
      project.description,
      project.period,
      ...project.technologies,
      ...project.highlights,
      if (project.architecture case final architecture?) ...<String>[
        architecture.title,
        architecture.description,
        ...architecture.nodes,
      ],
      for (final section in project.sections) ...<String>[
        section.kind.label,
        section.body,
      ],
      for (final screenshot in project.screenshots) screenshot.caption,
      for (final link in project.links) link.label,
    ],
    for (final repository in repositories) ...<String>[
      repository.name,
      repository.description,
      repository.language,
    ],
  ].join('\n');

  List<String> get allUrls => List<String>.unmodifiable(<String>[
    identity.githubUrl,
    mailUrl,
    for (final item in education)
      if (item.link case final link?) link.url,
    for (final project in projects)
      for (final link in project.links) link.url,
    for (final repository in repositories) repository.url,
  ]);
}

String _deriveMonogram(PortfolioIdentity identity) {
  final englishTokens = RegExp(
    r'[A-Za-z0-9]+',
  ).allMatches(identity.englishName).map((match) => match.group(0)!);
  final englishMonogram = _monogramFromTokens(englishTokens);
  if (englishMonogram.isNotEmpty) {
    return englishMonogram;
  }

  final localTokens = RegExp(
    r'[A-Za-z0-9\u3131-\u318E\uAC00-\uD7A3]+',
    unicode: true,
  ).allMatches(identity.name).map((match) => match.group(0)!);
  final localMonogram = _monogramFromTokens(localTokens);
  if (localMonogram.isNotEmpty) {
    return localMonogram;
  }

  final emailLocalPart = _safeEmailLocalPart(identity.email);
  if (emailLocalPart != null) {
    return String.fromCharCodes(emailLocalPart.runes.take(2)).toUpperCase();
  }
  return 'ME';
}

String _monogramFromTokens(Iterable<String> tokens) {
  final values = tokens.where((token) => token.isNotEmpty).take(2).toList();
  if (values.length >= 2) {
    return String.fromCharCodes(<int>[
      values.first.runes.first,
      values[1].runes.first,
    ]).toUpperCase();
  }
  if (values case <String>[final value]) {
    return String.fromCharCodes(value.runes.take(2)).toUpperCase();
  }
  return '';
}

String? _safeEmailLocalPart(String email) {
  final normalized = email.trim();
  final separator = normalized.indexOf('@');
  if (separator <= 0 ||
      separator != normalized.lastIndexOf('@') ||
      separator == normalized.length - 1 ||
      normalized.contains(RegExp(r'\s'))) {
    return null;
  }

  final localPart = normalized.substring(0, separator);
  if (!RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(localPart)) {
    return null;
  }
  return localPart.toLowerCase();
}

const portfolioData = PortfolioData.constant(
  identity: PortfolioIdentity(
    name: '민희수',
    englishName: 'Min He-su',
    email: 'hs0647@naver.com',
    githubUrl: 'https://github.com/hesu-dev/',
    headline: 'Flutter Developer and Google Developer for Dart',
    biography:
        '자바와 Flutter/Dart를 기반으로 모바일 앱 개발을 지향하는 2~3년 차 개발자입니다. '
        'IT 기업에서 여러 디지털 프로젝트를 경험했습니다.',
  ),
  experiences: <PortfolioExperience>[
    PortfolioExperience(
      role: 'Junior Flutter Developer',
      organization: '(주)상상력 집단',
      period: '2026 - Present',
      description: 'node 웹사이트 서비스 기획 및 개발, 출시 후 유지보수',
    ),
    PortfolioExperience(
      role: 'Junior Flutter Developer',
      organization: '(주)LSMK',
      period: '2021 - 2024',
      description: 'Flutter를 이용한 애플리케이션 기획 및 개발, R&D 연구 참여',
    ),
    PortfolioExperience(
      role: 'Junior Java Developer',
      organization: 'CKnB',
      period: '2020 - 2021',
      description: 'Android Studio를 통한 Java/JSP 애플리케이션 개발',
    ),
  ],
  education: <PortfolioEducation>[
    PortfolioEducation(
      program: 'Java 개발자 양성과정(6개월) 수료 - 파이널 프로젝트: BoardCa APP 개발',
      institution: '한국소프트웨어인재개발원 (KOSMO)',
      period: '2020.04 - 2020.10',
      link: PortfolioProjectLink(
        label: 'Final team project',
        url: 'https://github.com/parkyj0720/Final-Team-Project',
      ),
    ),
    PortfolioEducation(
      program: '게임엔터테인먼트(게임기획비즈니스)과 졸업',
      institution: '여주대학교',
      period: '2009.03 - 2011.02',
    ),
  ],
  certifications: <String>['정보처리기사'],
  skillGroups: <PortfolioSkillGroup>[
    PortfolioSkillGroup.constant(
      title: 'Development',
      skills: <String>['Flutter', 'Dart', 'React', 'Java'],
      activityDescriptions: <String, String>{
        'Flutter': 'Flutter 기반 크로스플랫폼 애플리케이션 개발',
        'Dart': 'Dart 비동기 로직과 상태 관리 기능 개발',
        'React': 'React 기반 웹 서비스 화면 기획 및 개발',
        'Java': 'Java/JSP 애플리케이션 개발 및 유지보수',
      },
    ),
    PortfolioSkillGroup.constant(
      title: 'Collaboration',
      skills: <String>['Notion', 'Slack', 'Trello'],
      activityDescriptions: <String, String>{
        'Notion': '프로젝트 문서와 업무 기록 정리',
        'Slack': '팀 커뮤니케이션과 업무 진행 상황 공유',
        'Trello': '업무 보드 구성과 일정 관리',
      },
    ),
    PortfolioSkillGroup.constant(
      title: 'Design & UI/UX',
      skills: <String>['Figma', 'Adobe Photoshop', 'Adobe Illustrator'],
      activityDescriptions: <String, String>{
        'Figma': 'UI/UX 화면 설계와 프로토타입 제작',
        'Adobe Photoshop': '이미지 편집과 그래픽 에셋 제작',
        'Adobe Illustrator': '벡터 그래픽과 아이콘 제작',
      },
    ),
  ],
  projects: <PortfolioProject>[
    PortfolioProject.constant(
      title: 'ReadingLog',
      category: PortfolioProjectCategory.personal,
      appIconAsset: 'assets/icons/projects/readinglog.jpg',
      description: '채팅 로그 리더기 앱 기획 및 개발, 파싱용 Chrome 확장 프로그램 개발',
      period: '2026.02 - 2026.05',
      technologies: <String>['Flutter', 'Dart', 'JavaScript'],
      highlights: <String>[
        '앱·확장 프로그램 기획 및 개발 · 기여도 100% (임시 예시)',
        'Flutter 로그 리더와 JavaScript 파싱 확장 프로그램 개발',
        '로그 추출·모바일 열람 흐름 설계 및 3개 스토어 배포',
      ],
      architecture: PortfolioProjectArchitecture.constant(
        title: '로그 추출부터 모바일 열람까지',
        description: '브라우저에서 채팅 로그를 구조화된 파일로 내보내고 Flutter 앱에서 다시 읽는 흐름입니다.',
        presentation: PortfolioArchitecturePresentation.flow,
        nodes: <String>['채팅 로그', 'Chrome 확장 프로그램', 'JSON 내보내기', 'ReadingLog 앱'],
      ),
      sections: <PortfolioProjectSection>[
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.work,
          body: '채팅 로그 리더기 앱 기획 및 개발, 파싱용 Chrome 확장 프로그램 개발',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.solution,
          body:
              'Chrome 확장 프로그램은 로그 파싱과 JSON 내보내기를, Flutter 앱은 가져온 로그의 모바일 열람 경험을 담당하도록 역할을 분리했습니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.learning,
          body:
              'JSON을 매개로 브라우저와 모바일의 책임을 나누며, 플랫폼 간 데이터 형식과 사용자 흐름을 함께 설계하는 중요성을 배웠습니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.relevance,
          body:
              '아이디어를 Flutter 앱과 확장 프로그램으로 구현하고 스토어 배포까지 연결한 경험입니다. 크로스플랫폼 앱 개발과 제품의 전체 사용 흐름을 고려하는 업무에 활용할 수 있습니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.outcome,
          body:
              'Google Play·App Store·Chrome Web Store 3개 채널에 배포했습니다. 임시 성과 예시: 로그 추출부터 열람까지의 소요 시간 40% 단축. 수치는 실제 측정 후 교체할 초안입니다.',
        ),
      ],
      links: <PortfolioProjectLink>[
        PortfolioProjectLink(
          label: 'Google Play',
          url:
              'https://play.google.com/store/apps/details?id=com.reha.readinglog',
        ),
        PortfolioProjectLink(
          label: 'App Store',
          url:
              'https://apps.apple.com/kr/app/%EB%A6%AC%EB%94%A9%EB%A1%9C%EA%B7%B8/id6759693995',
        ),
        PortfolioProjectLink(
          label: 'Chrome Web Store',
          url:
              'https://chromewebstore.google.com/detail/r20-jsonexporter/galgbmfkkpehcijjfcaffifmfjbmlfbo?authuser=1&hl=ko',
        ),
      ],
    ),
    PortfolioProject.constant(
      title: 'PersonaChat AI Character Chat',
      category: PortfolioProjectCategory.personal,
      description:
          'SNS 로그인, 캐릭터 생성/검색, AI 채팅, 이벤트 이미지, 크레딧 결제를 포함한 '
          'Flutter 실무형 포트폴리오 프로젝트 설계',
      period: '2026.07 - 설계',
      technologies: <String>['Flutter', 'Riverpod', 'Firebase', 'IAP', 'AI'],
      highlights: <String>[
        '서비스 기획 및 기술 설계 · 기여도 100% (임시 예시)',
        '인증·검색·AI 채팅·결제 흐름과 클라이언트·서버 책임 설계',
        '데이터 모델, 테스트 전략, 4주 구현 마일스톤 정의',
      ],
      architecture: PortfolioProjectArchitecture.constant(
        title: '기능과 서버 책임을 분리한 구성 요소',
        description: '서로 연결되는 클라이언트·인증·데이터·AI·결제 검증의 책임을 구성 요소별로 나누었습니다.',
        presentation: PortfolioArchitecturePresentation.components,
        nodes: <String>[
          'Flutter 앱',
          'Firebase Auth · Firestore · Storage',
          'Cloud API · 영수증 검증 · Credit Ledger',
          'LLM Provider · Search Index',
        ],
      ),
      sections: <PortfolioProjectSection>[
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.work,
          body:
              'SNS 로그인, 캐릭터 생성/검색, AI 채팅, 이벤트 이미지, 크레딧 결제를 포함한 Flutter 실무형 포트폴리오 프로젝트 설계',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.problem,
          body:
              '화면 구현만으로는 인증, 상태관리, API, 실시간 처리, 결제, 테스트처럼 Flutter 실무에서 함께 요구되는 역량을 보여주기 어려웠습니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.cause,
          body:
              '요구 역량이 로그인·탐색·채팅·결제·운영에 흩어져 있어 이를 연결하는 end-to-end 사용자 흐름이 필요했습니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.measurement,
          body:
              '2026-07-12 기준 Flutter 검색 결과 19개 활성 공고의 반복 키워드와 로그인부터 결제까지 이어지는 7단계 핵심 사용자 흐름을 설계 기준으로 삼았습니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.solution,
          body:
              'SNS 인증, 캐릭터 CRUD·검색, AI 스트리밍 채팅, 이벤트 이미지, 크레딧 결제를 연결하고 클라이언트와 서버의 책임을 분리했습니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.evaluation,
          body: '현재 설계 단계이며 아키텍처, 데이터 모델, 테스트 전략과 4주 구현 마일스톤까지 정의했습니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.learning,
          body:
              'AI 채팅과 결제를 함께 설계하면서 응답 상태, 사용량 정산, 실패·복구 흐름을 초기에 정의해야 한다는 점을 배웠습니다. 화면뿐 아니라 서버 책임과 테스트 범위까지 연결해 설계했습니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.relevance,
          body:
              'Flutter 채용 공고의 요구사항을 인증·상태관리·API·AI·결제·테스트 설계로 구체화했습니다. 구현 전 요구사항을 분석하고 기능의 경계를 정하는 역량과 연결됩니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.outcome,
          body:
              '활성 공고 19개를 분석하고 핵심 사용자 흐름 7단계, 화면 9개, 데이터 모델 5종, 4주 구현 계획을 정의했습니다. 현재 수치는 설계 범위이며 출시·운영 성과와 구분합니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.note,
          body: '스토어 출시 성과가 아닌 구현 전 설계 산출물이며, 실제 구현 결과와 지표는 개발 후 갱신합니다.',
        ),
      ],
      links: <PortfolioProjectLink>[],
    ),
    PortfolioProject.constant(
      title: 'AI 역량 검사',
      category: PortfolioProjectCategory.career,
      description:
          '기업 구성원의 AI 활용 역량을 평가하는 웹 기반 진단 서비스입니다. '
          '기업 신청·초대, AI 협업 응시, 자동 채점과 개인·조직 리포트를 하나의 흐름으로 구현한 기능형 POC입니다.',
      period: '2026.08 - 2026.09',
      technologies: <String>[
        'React',
        'TypeScript',
        'Vite',
        'Cloudflare Workers',
        'Cloudflare D1',
        'Cloudflare Queues',
        'OpenAI API',
        'Vitest',
        'Testing Library',
      ],
      highlights: <String>[
        '기획·디자인·구성·개발 전 과정 담당 · 기여도 100%',
        'React 기반 응시 화면, AI 협업 작업실, 개인·조직 리포트 구현',
        '기업별 접근 권한, 서버 기록 저장, 비동기 채점과 재시도 흐름 개발',
      ],
      architecture: PortfolioProjectArchitecture.constant(
        title: '응시 기록에서 진단 리포트까지',
        description:
            '응시 기록을 D1에 서버 정본으로 저장하고, Queue 기반 채점 결과를 개인·조직 리포트로 연결합니다.',
        presentation: PortfolioArchitecturePresentation.flow,
        nodes: <String>[
          'React 응시·관리 화면',
          'Cloudflare Workers API',
          'D1 제출·대화 기록',
          'Queues · OpenAI 채점',
          '개인·조직 리포트',
        ],
      ),
      sections: <PortfolioProjectSection>[
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.work,
          body:
              '서비스 기획과 화면 디자인부터 응시·관리자 기능, AI 연동, 데이터 저장, 결과 리포트까지 전체 구성을 설계하고 개발했습니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.problem,
          body:
              '정답 여부뿐 아니라 AI를 활용하는 과정과 판단 근거까지 살펴볼 수 있도록, 응시자의 답안·프롬프트·진단 결과를 연결하는 평가 흐름이 필요했습니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.solution,
          body:
              'AI 대화와 제출 기록은 서버에 저장하고 제출 시점의 채점 근거를 고정했습니다. '
              '기업별 조회 권한, 응시 중간 저장·복구, 비동기 채점·재시도와 리포트 조회를 연결했습니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.learning,
          body:
              '화면 복원용 상태와 채점 근거가 되는 서버 기록을 구분하는 중요성을 배웠습니다. '
              '상태 복구, 제출 시점, 채점 재시도를 함께 설계해야 결과의 일관성을 유지할 수 있다는 점을 익혔습니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.relevance,
          body:
              '기업의 요구사항을 사용자 흐름과 데이터 구조로 구체화하고, React UI부터 API·DB·AI 연동까지 구현한 경험입니다. '
              '제품 전반을 이해하며 프런트엔드와 서버의 책임을 조율하는 개발 업무에 연결됩니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.outcome,
          body:
              'AI 이해·프롬프트 활용·결과 검증·업무 적용·보안성 검토의 5개 역량 진단과 '
              '10개 차원의 프롬프트 분석을 구현했습니다. 응시·기업·관리자 흐름을 연결한 기능형 POC이며, '
              '실제 기업 도입률이나 업무 효율 개선을 측정한 운영 성과와는 구분합니다.',
        ),
      ],
      screenshots: <PortfolioProjectScreenshot>[
        PortfolioProjectScreenshot(
          asset: 'assets/screenshots/ai-work-skills/assessment.webp',
          caption: 'AI와 대화하며 문항을 해결하고 CSV 결과물을 만드는 실습 화면',
        ),
        PortfolioProjectScreenshot(
          asset: 'assets/screenshots/ai-work-skills/report.webp',
          caption: '영역별 점수와 분포를 보여주는 개인 결과 리포트 (데모 데이터)',
          aspectRatio: 1290 / 1114,
        ),
        PortfolioProjectScreenshot(
          asset: 'assets/screenshots/ai-work-skills/analysis.webp',
          caption: '응시자별 제출 현황과 점수, 리포트를 관리하는 결과 화면 (테스트 데이터)',
          aspectRatio: 1800 / 1470,
        ),
      ],
      links: <PortfolioProjectLink>[
        PortfolioProjectLink(
          label: 'POC 체험하기',
          url: 'https://ai-work-skills-dev.illusionists1004.workers.dev/',
        ),
      ],
    ),
    PortfolioProject.constant(
      title: 'AI Switch',
      category: PortfolioProjectCategory.career,
      appIconAsset: 'assets/icons/projects/ai-switch.svg',
      description: 'React와 TypeScript로 제작된 AI Switch 홈페이지 유지보수 업무입니다.',
      period: '',
      technologies: <String>['React', 'TypeScript'],
      highlights: <String>['React·TypeScript 기반 홈페이지 유지보수'],
      links: <PortfolioProjectLink>[
        PortfolioProjectLink(
          label: '사이트 방문하기',
          url: 'https://ax.aiswitch.co.kr/chat',
        ),
      ],
    ),
    PortfolioProject.constant(
      title: 'Blue Mentor',
      category: PortfolioProjectCategory.career,
      appIconAsset: 'assets/icons/projects/blue-mentor.png',
      description: '기계 점검 안전 설비 보고서 작성 앱 기획 및 개발',
      period: '2023.06 - 2024.02',
      technologies: <String>['Flutter', 'Dart', 'Node.js'],
      highlights: <String>[
        'Flutter 앱 기획 및 개발 · 기여도 70% (임시 예시)',
        '기계 점검·안전 설비 보고서 작성 기능 기획과 구현 참여',
        'Flutter·Dart·Node.js 기반 모바일 서비스 개발',
      ],
      sections: <PortfolioProjectSection>[
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.work,
          body: '기계 점검 안전 설비 보고서 작성 앱 기획 및 개발',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.learning,
          body:
              '현장 점검의 업무 순서를 이해해야 사용하기 쉬운 보고서 작성 화면을 만들 수 있다는 점을 배웠습니다. 기능 구현과 함께 입력 흐름과 정보 전달 방식을 고려하는 경험을 쌓았습니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.relevance,
          body:
              '업무 요구사항을 모바일 기능으로 구체화한 경험은 B2B 서비스 개발과 연결됩니다. Flutter 기반 화면 구현과 사용자 업무 흐름을 이해하는 역량을 활용할 수 있습니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.outcome,
          body:
              'Android·iOS 2개 플랫폼에 출시했습니다. 임시 성과 예시: 점검 보고서 작성 시간 30% 단축, 입력 누락 건수 20% 감소. 수치는 실제 측정 후 교체할 초안입니다.',
        ),
      ],
      links: <PortfolioProjectLink>[
        PortfolioProjectLink(
          label: 'Google Play',
          url:
              'https://play.google.com/store/apps/details?id=com.lsmk.BlueMentor&pcampaignid=web_share',
        ),
        PortfolioProjectLink(
          label: 'App Store',
          url:
              'https://apps.apple.com/us/app/%EB%B8%94%EB%A3%A8%EB%A9%98%ED%86%A0/id6475704951',
        ),
      ],
    ),
    PortfolioProject.constant(
      title: 'IRIS',
      category: PortfolioProjectCategory.career,
      description: '범부처통합연구지원시스템 R&D 참여: 3D 증강현실 기반 교량 점검 시스템 개발',
      period: '2022.12 - 2023.12',
      technologies: <String>['React', 'Unity', 'MySQL'],
      highlights: <String>[
        'R&D 시스템 개발 참여 · 기여도 30% (임시 예시)',
        '3D 증강현실 기반 교량 점검 시스템 연구 개발 참여',
        'React·Unity·MySQL 기술 구성을 활용한 개발 협업',
      ],
      sections: <PortfolioProjectSection>[
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.work,
          body: '범부처통합연구지원시스템 R&D 참여: 3D 증강현실 기반 교량 점검 시스템 개발',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.learning,
          body:
              '연구 목표를 실제 점검 업무와 연결하려면 도메인 이해와 기술 간 협업이 함께 필요하다는 점을 배웠습니다. 웹·3D·데이터베이스가 만나는 시스템을 통해 앱 밖의 기술 영역까지 시야를 넓혔습니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.relevance,
          body:
              '낯선 도메인의 요구사항을 이해하고 여러 기술로 구성된 시스템 개발에 참여한 경험입니다. 다른 직군과 기능의 역할을 맞추고 새로운 기술을 학습해야 하는 개발 업무에 연결됩니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.outcome,
          body:
              '관련 연구 논문 1건을 프로젝트 자료로 연결했습니다. 임시 성과 예시: 교량 점검 정보 확인 시간 20% 단축. 수치는 실제 검증 후 교체할 초안이며 논문의 측정 결과를 인용한 값은 아닙니다.',
        ),
      ],
      links: <PortfolioProjectLink>[
        PortfolioProjectLink(
          label: 'Research paper',
          url:
              'https://www.dbpia.co.kr/journal/articleDetail?nodeId=NODE11488090',
        ),
      ],
    ),
    PortfolioProject.constant(
      title: 'AI-Bver',
      category: PortfolioProjectCategory.career,
      appIconAsset: 'assets/icons/projects/ai-bver.png',
      description: 'AI-beaver 애플리케이션 개발 및 유지보수',
      period: '2021.12',
      technologies: <String>['PHP', 'Flutter', 'Dart'],
      highlights: <String>[
        'Flutter 앱 개발 및 유지보수 · 기여도 50% (임시 예시)',
        'PHP·Flutter·Dart 환경의 애플리케이션 개발 참여',
        'Google Play에 출시된 서비스의 유지보수 담당',
      ],
      sections: <PortfolioProjectSection>[
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.work,
          body: 'AI-beaver 애플리케이션 개발 및 유지보수',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.learning,
          body:
              '기존 서비스를 수정할 때는 먼저 코드 흐름과 변경의 영향을 이해해야 한다는 점을 배웠습니다. 새 기능 구현뿐 아니라 출시 후 서비스 품질을 유지하는 개발의 중요성을 익혔습니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.relevance,
          body:
              'Flutter 앱 개발과 운영 서비스 유지보수를 함께 경험했습니다. 기존 코드 파악, 기능 수정, 안정적인 서비스 운영을 요구하는 모바일 개발 직무에 연결됩니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.outcome,
          body:
              'Google Play에 공개된 Android 서비스 1종의 개발·유지보수에 참여했습니다. 임시 성과 예시: 반복 발생 오류 25% 감소, 이슈 처리 시간 20% 단축. 수치는 실제 운영 기록으로 교체할 초안입니다.',
        ),
      ],
      links: <PortfolioProjectLink>[
        PortfolioProjectLink(
          label: 'Google Play',
          url:
              'https://play.google.com/store/apps/details?id=com.aibver.lsmk&pcampaignid=web_share',
        ),
      ],
    ),
    PortfolioProject.constant(
      title: 'HiddenTag',
      category: PortfolioProjectCategory.career,
      appIconAsset: 'assets/icons/projects/hiddentag.png',
      description: 'HiddenTag 애플리케이션 페이지 유지보수',
      period: '2020.12 - 2021.07',
      technologies: <String>['Java', 'Apache'],
      highlights: <String>[
        '애플리케이션 페이지 유지보수 · 기여도 30% (임시 예시)',
        'Java·Apache 기반 서비스 페이지 수정과 유지보수 참여',
        '양대 모바일 스토어에 공개된 서비스의 운영 개발 경험',
      ],
      sections: <PortfolioProjectSection>[
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.work,
          body: 'HiddenTag 애플리케이션 페이지 유지보수',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.learning,
          body:
              '운영 중인 서비스에서는 작은 페이지 수정도 기존 동작과 사용자 경험을 함께 확인해야 한다는 점을 배웠습니다. Java 기반 코드를 읽고 기존 구조 안에서 수정하는 유지보수의 기본기를 익혔습니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.relevance,
          body:
              'Java·Apache 환경에서 쌓은 코드 분석과 유지보수 경험은 기존 시스템을 이해하고 개선하는 업무의 기반입니다. 모바일 앱과 연결된 서비스의 구조를 파악하는 데도 활용할 수 있습니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.outcome,
          body:
              'Android·iOS 2개 플랫폼에서 제공되는 서비스의 페이지 유지보수에 참여했습니다. 임시 성과 예시: 페이지 관련 오류 문의 20% 감소. 수치는 실제 운영 기록으로 교체할 초안입니다.',
        ),
      ],
      links: <PortfolioProjectLink>[
        PortfolioProjectLink(
          label: 'Google Play',
          url:
              'https://play.google.com/store/apps/details?id=ScanTag.ndk.det&pcampaignid=web_share',
        ),
        PortfolioProjectLink(
          label: 'App Store',
          url:
              'https://apps.apple.com/kr/app/hiddentag-%ED%9E%88%EB%93%A0%ED%83%9C%EA%B7%B8/id413494082',
        ),
      ],
    ),
  ],
);
