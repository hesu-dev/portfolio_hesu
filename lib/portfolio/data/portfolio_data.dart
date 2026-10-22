import 'project_architecture.dart';
import 'project_diagrams.dart';
import 'portfolio_introduction.dart';

class PortfolioIdentity {
  const PortfolioIdentity({
    required this.name,
    required this.englishName,
    required this.email,
    required this.githubUrl,
    required this.headline,
    required this.biography,
    this.introduction,
  });

  final String name;
  final String englishName;
  final String email;
  final String githubUrl;
  final String headline;
  final String biography;
  final String? introduction;
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
  affiliation('소속'),
  work('업무'),
  features('기능'),
  coreTechnology('핵심 기술'),
  technicalDecision('기술 의사결정'),
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
    PortfolioArchitectureDiagram? diagram,
    PortfolioArchitecturePresentation presentation =
        PortfolioArchitecturePresentation.components,
  }) {
    return PortfolioProjectArchitecture.constant(
      title: title,
      description: description,
      nodes: List<String>.unmodifiable(nodes),
      diagram: diagram,
      presentation: presentation,
    );
  }

  const PortfolioProjectArchitecture.constant({
    required this.title,
    required this.description,
    required this.nodes,
    this.diagram,
    this.presentation = PortfolioArchitecturePresentation.components,
  });

  final String title;
  final String description;
  final List<String> nodes;
  final PortfolioArchitectureDiagram? diagram;
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
  String get introduction => identity.introduction ?? identity.biography;
  String get mailUrl => 'mailto:${identity.email}';
  String get monogram => _deriveMonogram(identity);
  String get terminalPrompt => r'Portfolio: ~$';
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
    introduction,
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
    introduction: portfolioIntroduction,
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
      description:
          '채팅 로그를 JSON으로 변환하는 Chrome 확장 프로그램과 '
          '스키마에 맞춰 로그를 보여주는 Flutter 리더 앱을 기획·디자인·개발한 개인 프로젝트입니다.',
      period: '2026.02 - 2026.05',
      technologies: <String>[
        'Flutter',
        'Dart',
        'JavaScript',
        'Codex',
        'GitHub',
        'Firebase Hosting',
      ],
      highlights: <String>[
        'UI/UX 기획 및 디자인',
        'JSON 파싱 및 채팅 로그 변환',
        'Flutter 프런트엔드 구현 및 이펙트 디자인',
        'Chrome 확장 프로그램 개발',
      ],
      architecture: PortfolioProjectArchitecture.constant(
        title: 'HTML 채팅 로그에서 Flutter 화면과 문서 내보내기까지',
        diagram: readingLogArchitecture,
        description:
            'Chrome 확장 프로그램으로 HTML 채팅 로그를 JSON으로 변환하고, '
            'Flutter 앱에서 JSON 스키마 구조에 따라 화면을 배치합니다. '
            '데이터는 PDF와 EPUB 형식으로 내보낼 수 있습니다.',
        presentation: PortfolioArchitecturePresentation.flow,
        nodes: <String>[
          'HTML 채팅 로그',
          'Chrome 확장 프로그램',
          'JSON 변환',
          '스키마 기반 Flutter 화면',
          'PDF · EPUB 내보내기',
        ],
      ),
      sections: <PortfolioProjectSection>[
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.affiliation,
          body: '개인',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.work,
          body: '기획·디자인·개발 및 스토어 출시를 진행했으며, 현재 운영 중입니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.features,
          body:
              '• Chrome 확장 프로그램의 HTML → JSON 변환\n'
              '• JSON 스키마 구조에 따른 Flutter 화면 배치\n'
              '• 언어 전환 및 다국어 설정\n'
              '• 데이터 양식의 PDF·EPUB 내보내기\n'
              '• 검색 기능 구현 및 검색 데이터 정비\n'
              '• 세이프 텍스트 검수 자동화\n'
              '• 백그라운드 오디오 기능\n'
              '• 이펙트 디자인\n'
              '• 기타 프런트엔드 기능 구현',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.coreTechnology,
          body:
              'Flutter·Dart로 채팅·eBook·소설 리더의 화면과 프로젝트 세션을 구성하고, Chrome 확장 프로그램은 HTML 대화 기록을 앱이 읽는 JSON으로 변환합니다. 네이티브 파일 열기는 Isolate.run에서 JSON 파싱과 초기 표시 데이터를 함께 준비합니다. 웹에서는 별도 isolate를 사용하지 않는 경로를 둡니다.\n\nPDF·EPUB 내보내기는 같은 프로젝트 데이터를 문서로 변환합니다. Android·iOS의 음성 재생은 MethodChannel 명령과 EventChannel 이벤트로 네이티브 TTS 런타임에 연결됩니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.technicalDecision,
          body:
              '파일 형식을 바꾸기보다 읽기·파싱 경로를 먼저 정리했습니다. 기존 project.json과 스키마를 유지하면 확장 프로그램 및 이미 저장된 로그와의 호환성을 지킬 수 있기 때문입니다. 파일을 반복해서 읽거나 전체 목록을 중복 순회하는 대신, 한 번의 디코딩 결과에 초기 커서와 화자 이미지 준비 정보를 묶었습니다.\n\n앱 상태를 부분적으로 교체하지 않고 준비된 결과를 일괄 반영한 뒤 이미지 갱신을 수행합니다. 이는 완전히 준비되기 전의 화면 상태 노출을 줄이는 구조입니다. 대신 파일 전체를 준비하는 비용은 남으므로, 임의로 지연 로딩이나 새로운 저장 형식까지 도입하지 않았습니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.problem,
          body:
              '큰 로그를 여는 경로에서 파일 재읽기, 목록의 중복 순회, UI 실행 흐름에 남은 디코딩 작업이 함께 나타났습니다. 별도로 백그라운드·잠금 화면에서 진행되는 TTS와 Flutter 화면의 재생 위치가 서로 다른 상태를 가질 수 있는 문제도 다뤘습니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.cause,
          body:
              '프로젝트 열기의 여러 단계가 필요한 정보를 각자 다시 만들면 같은 데이터를 여러 번 처리하게 됩니다. TTS에서는 Flutter와 네이티브가 모두 현재 재생 상태를 독립적으로 갱신할 때 늦게 도착한 이벤트가 최신 위치를 덮을 수 있습니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.solution,
          body:
              '파일 열기는 단일 디코딩 결과를 준비하고 성공한 경우에만 프로젝트 세션을 일괄 갱신하도록 구성했습니다. 클라우드 미러는 프로젝트 ID와 기대 revision이 일치할 때만 재사용하며, 미완성 미러는 사전 확인 경로를 통과합니다.\n\nTTS는 네이티브 런타임의 snapshot을 재생 상태의 기준으로 삼고 Flutter는 그 상태를 화면에 투영합니다. snapshotVersion과 queueRevision을 비교해 오래된 스냅샷·큐 이벤트가 현재 재생 위치를 되돌리지 않도록 처리합니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.evaluation,
          body:
              '회귀 테스트는 디코딩 후 원문 라인 수 유지, 초기 커서 범위 보정, 화자 이미지 준비 정보 생성을 확인합니다. 프로젝트 열기 테스트에서는 완전한 미러와 불완전한 미러의 사전 확인 경로를 구분합니다. TTS 테스트는 최신 snapshot의 반영과 오래된 snapshotVersion·queueRevision의 무시를 검증합니다.\n\n이는 현재 코드와 테스트에서 확인한 동작입니다. 실기기 개방 시간·메모리 절감률이나 운영 장애 감소율은 측정 결과가 없어 수치로 제시하지 않습니다.',
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
      title: 'Portfolio',
      category: PortfolioProjectCategory.personal,
      appIconAsset: 'assets/icons/settings-display-mode.svg',
      description:
          'macOS 데스크톱과 iPad·iPhone 홈 화면을 재현한 Flutter 포트폴리오입니다. '
          '경력·기술·프로젝트를 앱과 폴더 형태로 탐색하고, 파일과 Safari에서 같은 프로젝트 상세를 확인할 수 있습니다.',
      period: '2026.09 - 현재',
      technologies: <String>[
        'Flutter',
        'Dart',
        'Material 3',
        'Cupertino',
        'flutter_svg',
        'url_launcher',
        'http',
        'just_audio',
        'pdf',
        'Flutter Test',
      ],
      highlights: <String>[
        '화면 너비와 플랫폼에 따른 macOS·iPad·iPhone 반응형 셸',
        '파일과 Safari의 프로젝트 데이터·상세 보고서 공유',
        '테마·음악 공통 상태, GitHub 기여 기록 조회, 웹 PDF 저장·인쇄',
        '개발·운영 환경 분리와 iPhone 릴리스 빌드·설치·실행 검증',
      ],
      architecture: PortfolioProjectArchitecture.constant(
        title: '데이터·반응형 셸·앱 콘텐츠·외부 기능의 구성',
        diagram: portfolioArchitecture,
        description:
            'PortfolioApp이 PortfolioData와 테마·음악 컨트롤러를 반응형 셸에 전달합니다. '
            '셸은 기기에 맞는 화면과 선택한 앱을 표시하고, 파일·Safari는 SafariProjectPage를 공유합니다. '
            'GitHub 기여 기록은 외부 API에서 조회하며, PDF 생성과 인쇄는 웹 실행 경로에서 처리합니다.',
        presentation: PortfolioArchitecturePresentation.flow,
        nodes: <String>[
          'PortfolioData',
          'PortfolioApp',
          '공유 상태',
          '반응형 셸',
          '앱 콘텐츠',
          '프로젝트 상세',
          'GitHub 기여 기록',
          '웹 PDF 출력',
        ],
      ),
      sections: <PortfolioProjectSection>[
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.work,
          body:
              '개발자의 경력, 자기소개, 기술과 프로젝트를 Apple 스타일의 앱 화면으로 탐색하도록 구현했습니다. '
              '데스크톱의 창·메뉴 막대·Dock과 모바일의 홈·앱 전환을 각각 구성하고, 같은 포트폴리오 데이터를 화면과 출력 문서에 사용합니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.features,
          body:
              '데스크톱은 창 열기·최소화·복원과 Dock을 제공하고, iPad·iPhone은 홈 화면과 앱별 탐색 화면으로 전환됩니다. '
              '파일에는 최근 항목·개인·회사 프로젝트를 나누고, 폴더마다 아이콘·목록 보기와 정렬 상태를 독립적으로 유지합니다. '
              'Safari에서는 프로젝트 검색, 카드 탐색과 뒤로·앞으로 이동을 제공합니다.\n\n'
              '프로필·자기소개·스킬·터미널·사진·음악·설정 화면을 앱 단위로 구성했습니다. '
              '프로젝트 상세에는 아이콘·기간, 기술 스택, 구조도, 구성 요소 설명과 작업 링크를 표시합니다. '
              'GitHub 기여 기록은 화면을 열거나 새로고침할 때 조회하고, 실패하면 앱에 포함된 저장 기록을 표시합니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.coreTechnology,
          body:
              'Flutter와 Dart를 중심으로 Material 3·Cupertino 및 공통 Apple 스타일 위젯을 조합했습니다. '
              'AdaptivePortfolioShell은 1024px 이상에서 데스크톱, 600px 이상에서 iPad, 그 미만에서 iPhone 화면을 선택하며, '
              '모바일 브라우저에서는 넓은 화면도 모바일 셸을 사용합니다.\n\n'
              'PortfolioThemeController와 MusicController는 ChangeNotifier로 공통 상태를 전달합니다. '
              'flutter_svg는 SVG 아트워크, url_launcher는 외부 링크, http는 GitHub 기여 API 조회, '
              'just_audio는 음악 재생, pdf는 한글 글꼴을 포함한 출력 문서 생성에 사용합니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.technicalDecision,
          body:
              '기기마다 화면을 단순 축소하는 대신 탐색 방식에 맞는 셸을 분리했습니다. '
              '앱 콘텐츠는 PortfolioAppContent가 선택하고, 프로젝트 정보는 PortfolioData 한 곳에서 관리합니다. '
              '파일과 Safari가 SafariProjectPage를 공유하므로 소개·기술 스택·구조도를 수정하면 두 화면에 함께 반영됩니다.\n\n'
              '테마와 음악은 PortfolioApp에서 소유해 앱 화면을 바꿔도 같은 상태를 사용합니다. '
              'PDF·인쇄는 조건부 import로 웹과 네이티브 구현을 구분하고, 웹에서는 새 미리보기 창에 생성한 PDF와 인쇄용 HTML을 전달합니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.evaluation,
          body:
              '위젯 테스트로 반응형 화면 전환, 창·앱 탐색, 파일과 Safari의 상세 표시, 폴더별 보기·정렬과 링크 동작을 검증합니다. '
              '밝은·어두운 테마와 글자 크기 200%의 좁은 화면도 확인합니다. '
              'GitHub 조회 실패 시 저장 기록 사용, 음악 상태, PDF·인쇄 문서 생성은 별도 테스트로 다룹니다. '
              'iPhone에서는 운영 설정을 적용한 서명된 릴리스의 빌드·설치·실행을 확인했습니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.learning,
          body:
              '화면별 탐색 상태는 각 앱에 두고, 테마·음악처럼 앱을 넘나드는 상태는 공통 컨트롤러에 두었습니다. '
              '프로젝트 데이터와 상세 컴포넌트를 공유해 두 탐색 화면의 내용이 함께 갱신되도록 구성했습니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.relevance,
          body:
              'Flutter의 반응형 UI, 상태 소유권, 플랫폼별 기능 분기와 위젯 테스트를 하나의 서비스 화면에서 보여 주는 프로젝트입니다. '
              '외부 API 실패 처리부터 문서 생성과 실기기 릴리스까지 연결했습니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.outcome,
          body:
              '파일과 Safari에서 동일한 프로젝트를 탐색하고, 웹에서는 이력서·자기소개서·프로젝트를 PDF로 저장하거나 인쇄할 수 있습니다. '
              'iPhone 운영 릴리스를 빌드하고 설치·실행하는 흐름도 확인했습니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.note,
          body:
              'APP_ENV를 config/development.json과 config/production.json으로 나누고, '
              'Dart 실행 스크립트에서 개발 웹 실행과 운영 실기기 릴리스를 선택합니다. '
              '별도 인증·결제 서버 없이 포트폴리오 데이터와 자산을 앱에 포함하며, GitHub 기여 기록 조회만 외부 API에 요청합니다. '
              'PDF 저장·인쇄는 웹 브라우저에서 제공합니다.',
        ),
      ],
      links: <PortfolioProjectLink>[
        PortfolioProjectLink(
          label: 'GitHub',
          url: 'https://github.com/hesu-dev/portfolio_hesu',
        ),
      ],
    ),
    PortfolioProject.constant(
      title: 'AI 역량 검사',
      category: PortfolioProjectCategory.career,
      appIconAsset: 'assets/icons/projects/aiq.png',
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
        diagram: aiAssessmentArchitecture,
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
          kind: PortfolioProjectSectionKind.coreTechnology,
          body:
              'React·TypeScript가 응시·AI 협업·관리자·리포트 화면을 담당하고, Cloudflare Workers가 권한 검사와 대화·제출 API를 제공합니다. D1에는 대화 기록과 제출 시점의 스냅샷을 서버 정본으로 저장합니다. Queues는 채점을 비동기로 전달하고, 소비자는 D1에서 근거를 다시 읽어 OpenAI API로 구조화된 평가를 요청합니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.technicalDecision,
          body:
              '화면 복원용 상태와 채점 근거를 분리했습니다. 채점은 브라우저가 다시 보내는 대화가 아니라 제출 시점에 서버에 고정한 기록을 기준으로 수행합니다. Queue에는 전체 답안 대신 submissionId만 전달해, 재시도에서도 같은 서버 정본을 읽도록 했습니다.\n\nD1 저장과 Queue 전달을 하나의 트랜잭션으로 묶을 수 없으므로 먼저 제출을 영속 저장하고 나서 채점을 요청합니다. 이 구조는 즉시 결과를 보장하는 대신, 제출 접수와 채점 완료를 다른 상태로 다루고 복구 작업으로 미전달 건을 다시 전달하도록 합니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.problem,
          body:
              'AI를 활용하는 과정과 판단 근거를 평가하려면 답안·프롬프트·진단 결과가 같은 제출 기록을 가리켜야 했습니다. 특히 제출 접수, 외부 AI 채점, 결과 조회가 다른 시점에 완료되므로 네트워크 실패와 재시도에도 이미 제출한 기록을 잃지 않는 흐름이 필요했습니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.cause,
          body:
              'D1 저장은 성공했지만 Queue 전송이 실패하거나 성공 여부를 알 수 없는 경우가 있습니다. 이때 제출 자체를 실패로 돌리면 이미 접수된 답안과 사용자 화면이 달라집니다. 반대로 중복 전달이나 늦게 끝난 채점을 무조건 기록하면 최신 결과를 덮을 수 있습니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.solution,
          body:
              'D1에 대화와 제출 스냅샷을 저장한 뒤 Queue에 제출 ID를 전달합니다. Queue 전송 실패 시에도 저장된 접수 결과를 유지하고, 예약 실행 복구 작업이 미처리 제출을 다시 전달합니다. 채점 소비자는 처리권을 lease로 확보하고 D1 정본을 읽어 평가합니다.\n\n결과를 쓸 때는 처리 중 발급받은 claim token과 현재 상태가 일치하는지 조건부로 확인합니다. 중복 전달되거나 처리권이 만료된 이전 작업이 뒤늦게 끝나도 다른 작업의 결과를 덮지 않도록 제한했습니다. 기업별 조회 권한과 개인·조직 리포트는 이 저장된 결과에 연결됩니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.evaluation,
          body:
              '실패 조건을 재현한 테스트에서 DB 저장 실패 시 접수하지 않는지, Queue 전송 실패 후에도 영속 저장된 접수 응답을 유지하는지, 전달 상태가 모호한 재시도에서 기존 queued 제출을 다시 보낼 수 있는지 확인합니다. 완료된 제출은 기존 접수 결과를 유지해 불필요한 중복 큐잉을 피합니다.\n\n채점 소비자에는 제한된 시도 횟수·처리 기한과 claim token 조건부 갱신이 있습니다. 이는 구현과 회귀 테스트로 확인한 복구 경로이며, 실제 고객 환경의 장애 건수나 처리 시간 개선율을 측정한 운영 성과는 아닙니다.',
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
      architecture: PortfolioProjectArchitecture.constant(
        title: '확인된 기술 구성과 담당 범위',
        description: '확인된 기술 구성입니다. 세부 연동 구조는 아직 문서화되지 않았습니다.',
        diagram: aiSwitchArchitecture,
        nodes: <String>['React 화면', 'TypeScript 코드'],
      ),
      sections: <PortfolioProjectSection>[
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.coreTechnology,
          body: 'React·TypeScript로 구성된 AI Switch 홈페이지의 화면 코드 유지보수를 담당했습니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.technicalDecision,
          body: '기술 선정 배경과 대안 비교에 대한 상세 기록은 준비 중입니다.',
        ),
      ],
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
      architecture: PortfolioProjectArchitecture.constant(
        title: '점검 보고서와 사진 첨부의 별도 전송 흐름',
        description:
            'Provider로 점검 화면의 상태를 관리하고 JSON API로 업무 데이터를 전송합니다. 사진은 별도 multipart로 전달하며, 실패한 사진은 로컬 캐시에서 다시 업로드합니다.',
        diagram: blueMentorArchitecture,
        nodes: <String>[
          'Flutter 점검 화면',
          'Provider 상태 관리',
          'HTTP JSON API',
          '로컬 파일 · Hive 캐시',
          'Dio 사진 업로드',
          'Firebase 관찰',
        ],
      ),
      sections: <PortfolioProjectSection>[
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.work,
          body: '기계 점검 안전 설비 보고서 작성 앱 기획 및 개발',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.coreTechnology,
          body:
              'Flutter·Dart로 기계 점검과 보고서 입력 화면을 구현하고, Provider의 로그인·대시보드·상세 점검 상태를 화면에 연결했습니다. 업무 데이터는 공통 HTTP 모듈에서 JSON으로 전송하고, 사진은 Dio의 multipart 요청으로 업로드합니다.\n\n업로드하지 못한 사진의 파일 경로와 점검 항목 정보는 Hive 캐시에 보관합니다. Firebase Analytics는 화면 이동 관찰에, Crashlytics는 Flutter 오류 기록에 연결됩니다. 기존 프로젝트 기술 기록에는 Node.js가 포함되며, 그림은 확인한 앱과 API 경계까지 표시합니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.technicalDecision,
          body:
              '코드에서 확인되는 구조는 보고서 JSON 요청과 사진 multipart 전송의 분리입니다. 사진 전송이 실패해도 해당 파일과 점검 항목 정보를 캐시에 남기고 별도로 다시 업로드하는 흐름이 있습니다. 공통 HTTP 모듈은 인증 만료 시 토큰을 갱신한 재시도를 1회로 제한합니다.\n\n이 설명은 구현을 바탕으로 정리한 설계 해석입니다. 당시 대안 비교 기록은 없지만, 현재 코드에서 확인되는 책임 분리는 화면 상태 관리, 업무 API 호출, 사진 전송·복구입니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.problem,
          body:
              '프로젝트 수정 이력에는 사진 업로드 후 로딩 표시가 끝나지 않는 문제를 개선한 기록이 있습니다. 네트워크 오류가 발생했을 때도 사용자가 점검 화면으로 돌아가고 실패한 사진을 다시 전송할 수 있는 흐름이 필요했습니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.cause,
          body:
              '수정 전후 코드를 비교하면 업로드 예외 경로에서 실패 처리와 제출 중 상태 해제가 충분히 연결되지 않았습니다. 사진 전송 결과와 화면의 로딩 상태를 각각 관리하면서, 예외가 정상 완료 경로를 건너뛰면 로딩 표시가 남을 수 있었습니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.solution,
          body:
              '프로젝트에서는 업로드 예외 시 실패 사진 처리 함수를 호출하고, 제출 중 상태를 해제하는 경로를 보강했습니다. 일부 제출 경로는 finally에서 로딩 상태를 정리합니다. 현재 코드에도 네트워크 오류 시 실패 안내와 재업로드 화면 이동, 캐시 유지 흐름이 남아 있습니다.\n\n사진 업로드는 기본 15초의 취소 토큰을 두고 Socket·Dio 예외를 공통 네트워크 오류로 전달합니다. 재업로드에 성공한 사진만 캐시에서 제거하므로 실패한 첨부를 다시 선택할 수 있습니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.evaluation,
          body:
              '2024-01-18의 “이미지 업로드 무한 로딩 개선” 커밋과 현재 오류·캐시 처리 코드를 함께 확인했습니다. 이 수정은 팀 프로젝트의 변경 이력이며 개인이 해당 커밋을 직접 작성한 성과로 제시하지 않습니다.\n\n해당 경로를 검증하는 전용 회귀 테스트는 확인되지 않았습니다. 따라서 검증 범위는 수정 이력과 코드의 제어 흐름이며, 실제 장애 감소율이나 자동 테스트 통과 실적을 주장하지 않습니다.',
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
      appIconAsset: 'assets/icons/projects/iris.svg',
      description: '범부처통합연구지원시스템 R&D 참여: 3D 증강현실 기반 교량 점검 시스템 개발',
      period: '2022.12 - 2023.12',
      technologies: <String>['React', 'Unity', 'MySQL'],
      highlights: <String>[
        'R&D 시스템 개발 참여 · 기여도 30% (임시 예시)',
        '3D 증강현실 기반 교량 점검 시스템 연구 개발 참여',
        'React·Unity·MySQL 기술 구성을 활용한 개발 협업',
      ],
      architecture: PortfolioProjectArchitecture.constant(
        title: '확인된 기술 구성과 담당 범위',
        description: '확인된 기술 구성입니다. 세부 연동 구조는 아직 문서화되지 않았습니다.',
        diagram: irisArchitecture,
        nodes: <String>['React', 'Unity', 'MySQL'],
      ),
      sections: <PortfolioProjectSection>[
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.work,
          body: '범부처통합연구지원시스템 R&D 참여: 3D 증강현실 기반 교량 점검 시스템 개발',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.coreTechnology,
          body: 'React·Unity·MySQL로 구성된 3D 증강현실 기반 교량 점검 R&D 개발에 참여했습니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.technicalDecision,
          body: '기술 선정 배경과 대안 비교에 대한 상세 기록은 준비 중입니다.',
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
      screenshots: <PortfolioProjectScreenshot>[
        PortfolioProjectScreenshot(
          asset: 'assets/screenshots/iris/01.png',
          caption: 'IRIS 통합업무포털의 연구과제 참여 내역',
          aspectRatio: 2680 / 808,
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
      architecture: PortfolioProjectArchitecture.constant(
        title: '확인된 기술 구성과 담당 범위',
        description: '확인된 기술 구성입니다. 세부 연동 구조는 아직 문서화되지 않았습니다.',
        diagram: aiBverArchitecture,
        nodes: <String>['Flutter 앱', 'Dart', 'PHP'],
      ),
      sections: <PortfolioProjectSection>[
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.work,
          body: 'AI-beaver 애플리케이션 개발 및 유지보수',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.coreTechnology,
          body:
              'Flutter·Dart·PHP 환경에서 AI-beaver 애플리케이션 개발과 공개된 Android 서비스의 유지보수에 참여했습니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.technicalDecision,
          body: '기술 선정 배경과 대안 비교에 대한 상세 기록은 준비 중입니다.',
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
      architecture: PortfolioProjectArchitecture.constant(
        title: '확인된 기술 구성과 담당 범위',
        description: '확인된 기술 구성입니다. 세부 연동 구조는 아직 문서화되지 않았습니다.',
        diagram: hiddenTagArchitecture,
        nodes: <String>['Java 페이지 코드', 'Apache 환경'],
      ),
      sections: <PortfolioProjectSection>[
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.work,
          body: 'HiddenTag 애플리케이션 페이지 유지보수',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.coreTechnology,
          body:
              'Java·Apache 환경에서 HiddenTag 애플리케이션의 기존 서비스 페이지 수정과 유지보수에 참여했습니다.',
        ),
        PortfolioProjectSection(
          kind: PortfolioProjectSectionKind.technicalDecision,
          body: '기술 선정 배경과 대안 비교에 대한 상세 기록은 준비 중입니다.',
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
