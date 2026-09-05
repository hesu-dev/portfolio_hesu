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

class PortfolioProject {
  factory PortfolioProject({
    required String title,
    required String description,
    required String period,
    required Iterable<String> technologies,
    required Iterable<PortfolioProjectLink> links,
    PortfolioProjectCategory category = PortfolioProjectCategory.career,
    Iterable<String> highlights = const <String>[],
    PortfolioProjectArchitecture? architecture,
    Iterable<PortfolioProjectSection> sections =
        const <PortfolioProjectSection>[],
  }) {
    return PortfolioProject.constant(
      title: title,
      description: description,
      period: period,
      technologies: List<String>.unmodifiable(technologies),
      links: List<PortfolioProjectLink>.unmodifiable(links),
      category: category,
      highlights: List<String>.unmodifiable(highlights),
      architecture: architecture,
      sections: List<PortfolioProjectSection>.unmodifiable(sections),
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
    this.highlights = const <String>[],
    this.architecture,
    this.sections = const <PortfolioProjectSection>[],
  });

  final String title;
  final String description;
  final String period;
  final List<String> technologies;
  final List<PortfolioProjectLink> links;
  final PortfolioProjectCategory category;
  final List<String> highlights;
  final PortfolioProjectArchitecture? architecture;
  final List<PortfolioProjectSection> sections;

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
  repositories: <PortfolioRepository>[
    PortfolioRepository(
      name: 'portfolio_hesu',
      description: 'Flutter로 구현한 반응형 Apple 스타일 개발자 포트폴리오',
      language: 'Dart',
      url: 'https://github.com/hesu-dev/portfolio_hesu',
    ),
    PortfolioRepository(
      name: 'chrome_extension',
      description: '취미로 제작해 배포한 미니 프로그램',
      language: 'JavaScript',
      url: 'https://github.com/hesu-dev/chrome_extension',
    ),
    PortfolioRepository(
      name: 'code_study',
      description: '스터디와 매일 코드 쓰기 챌린지 기록',
      language: 'Dart',
      url: 'https://github.com/hesu-dev/code_study',
    ),
  ],
  projects: <PortfolioProject>[
    PortfolioProject.constant(
      title: 'ReadingLog',
      category: PortfolioProjectCategory.personal,
      description: '채팅 로그 리더기 앱 기획 및 개발, 파싱용 Chrome 확장 프로그램 개발',
      period: '2026.02 - 2026.05',
      technologies: <String>['Flutter', 'Dart', 'JavaScript'],
      highlights: <String>[
        '모바일 앱과 파싱용 Chrome 확장 프로그램을 함께 기획·개발',
        'Google Play·App Store·Chrome Web Store에 각각 배포',
        '로그 추출과 모바일 열람을 하나의 사용자 흐름으로 연결',
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
        '인증·검색·AI 채팅·크레딧 결제를 하나의 제품 흐름으로 설계',
        'Firebase·LLM adapter·서버 영수증 검증과 크레딧 원장을 분리',
        '단위·위젯·E2E 테스트와 CI 범위를 구현 전에 정의',
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
          kind: PortfolioProjectSectionKind.note,
          body: '스토어 출시 성과가 아닌 구현 전 설계 산출물이며, 실제 구현 결과와 지표는 개발 후 갱신합니다.',
        ),
      ],
      links: <PortfolioProjectLink>[],
    ),
    PortfolioProject.constant(
      title: 'Blue Mentor',
      category: PortfolioProjectCategory.career,
      description: '기계 점검 안전 설비 보고서 작성 앱 기획 및 개발',
      period: '2023.06 - 2024.02',
      technologies: <String>['Flutter', 'Dart', 'Node.js'],
      highlights: <String>[
        '기계 점검·안전 설비 보고서 작성 앱을 기획하고 개발',
        'Flutter·Dart 앱과 Node.js 기술 구성 사용',
        'Google Play와 App Store에 공개',
      ],
      sections: <PortfolioProjectSection>[
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.work,
          body: '기계 점검 안전 설비 보고서 작성 앱 기획 및 개발',
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
        '범부처통합연구지원시스템 R&D에 참여',
        '3D 증강현실 기반 교량 점검 시스템 개발',
        '연구 결과를 논문 링크로 공개',
      ],
      sections: <PortfolioProjectSection>[
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.work,
          body: '범부처통합연구지원시스템 R&D 참여: 3D 증강현실 기반 교량 점검 시스템 개발',
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
      description: 'AI-beaver 애플리케이션 개발 및 유지보수',
      period: '2021.12',
      technologies: <String>['PHP', 'Flutter', 'Dart'],
      highlights: <String>[
        'AI-beaver 애플리케이션 개발과 유지보수 참여',
        'PHP·Flutter·Dart 기술 구성 사용',
        'Google Play 공개 서비스 유지보수',
      ],
      sections: <PortfolioProjectSection>[
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.work,
          body: 'AI-beaver 애플리케이션 개발 및 유지보수',
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
      description: 'HiddenTag 애플리케이션 페이지 유지보수',
      period: '2020.12 - 2021.07',
      technologies: <String>['Java', 'Apache'],
      highlights: <String>[
        'HiddenTag 애플리케이션 페이지 유지보수',
        'Java·Apache 기반 환경에서 작업',
        'Google Play와 App Store에서 운영 중인 서비스 경험',
      ],
      sections: <PortfolioProjectSection>[
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.work,
          body: 'HiddenTag 애플리케이션 페이지 유지보수',
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
