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
  }) {
    return PortfolioSkillGroup.constant(
      title: title,
      skills: List<String>.unmodifiable(skills),
    );
  }

  /// Creates a compile-time constant from const list values.
  ///
  /// Use the default constructor for runtime iterables so they are copied.
  const PortfolioSkillGroup.constant({
    required this.title,
    required this.skills,
  });

  final String title;
  final List<String> skills;
}

class PortfolioProjectLink {
  const PortfolioProjectLink({required this.label, required this.url});

  final String label;
  final String url;

  Uri get uri => Uri.parse(url);
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
  }) {
    return PortfolioProject.constant(
      title: title,
      description: description,
      period: period,
      technologies: List<String>.unmodifiable(technologies),
      links: List<PortfolioProjectLink>.unmodifiable(links),
      category: category,
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
  });

  final String title;
  final String description;
  final String period;
  final List<String> technologies;
  final List<PortfolioProjectLink> links;
  final PortfolioProjectCategory category;
}

class PortfolioData {
  factory PortfolioData({
    required PortfolioIdentity identity,
    required Iterable<PortfolioExperience> experiences,
    required Iterable<PortfolioEducation> education,
    required Iterable<PortfolioSkillGroup> skillGroups,
    required Iterable<PortfolioProject> projects,
  }) {
    return PortfolioData.constant(
      identity: identity,
      experiences: List<PortfolioExperience>.unmodifiable(experiences),
      education: List<PortfolioEducation>.unmodifiable(education),
      skillGroups: List<PortfolioSkillGroup>.unmodifiable(skillGroups),
      projects: List<PortfolioProject>.unmodifiable(projects),
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
  });

  final PortfolioIdentity identity;
  final List<PortfolioExperience> experiences;
  final List<PortfolioEducation> education;
  final List<PortfolioSkillGroup> skillGroups;
  final List<PortfolioProject> projects;

  String get name => identity.name;
  String get email => identity.email;
  String get githubUrl => identity.githubUrl;
  String get mailUrl => 'mailto:${identity.email}';
  String get monogram => _deriveMonogram(identity);
  String get terminalPrompt => '${_deriveTerminalUser(identity)}@portfolio ~ %';
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
    for (final group in skillGroups) ...<String>[group.title, ...group.skills],
    for (final project in projects) ...<String>[
      project.title,
      project.description,
      project.period,
      ...project.technologies,
      for (final link in project.links) link.label,
    ],
  ].join('\n');

  List<String> get allUrls => List<String>.unmodifiable(<String>[
    identity.githubUrl,
    mailUrl,
    for (final item in education)
      if (item.link case final link?) link.url,
    for (final project in projects)
      for (final link in project.links) link.url,
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

String _deriveTerminalUser(PortfolioIdentity identity) {
  final emailLocalPart = _safeEmailLocalPart(identity.email);
  if (emailLocalPart != null) {
    return emailLocalPart;
  }

  final englishTokens = RegExp(r'[A-Za-z0-9]+')
      .allMatches(identity.englishName)
      .map((match) => match.group(0)!.toLowerCase());
  final englishUser = englishTokens.join('-');
  return englishUser.isEmpty ? 'guest' : englishUser;
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
      organization: 'Freelance',
      period: '2026 - Present',
      description: 'Flutter를 이용한 애플리케이션 기획 및 개발',
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
  skillGroups: <PortfolioSkillGroup>[
    PortfolioSkillGroup.constant(
      title: 'Development',
      skills: <String>['Flutter', 'Dart', 'React', 'Java'],
    ),
    PortfolioSkillGroup.constant(
      title: 'Collaboration',
      skills: <String>['Notion', 'Slack', 'Trello'],
    ),
    PortfolioSkillGroup.constant(
      title: 'Design & UI/UX',
      skills: <String>['Figma', 'Adobe Photoshop', 'Adobe Illustrator'],
    ),
  ],
  projects: <PortfolioProject>[
    PortfolioProject.constant(
      title: 'PersonaChat AI Character Chat',
      category: PortfolioProjectCategory.personal,
      description:
          'SNS 로그인, 캐릭터 생성/검색, AI 채팅, 이벤트 이미지, 크레딧 결제를 포함한 '
          'Flutter 실무형 포트폴리오 프로젝트 설계',
      period: '2026.07 - 설계',
      technologies: <String>['Flutter', 'Riverpod', 'Firebase', 'IAP', 'AI'],
      links: <PortfolioProjectLink>[],
    ),
    PortfolioProject.constant(
      title: 'ReadingLog',
      category: PortfolioProjectCategory.personal,
      description: '채팅 로그 리더기 앱 기획 및 개발, 파싱용 Chrome 확장 프로그램 개발',
      period: '2026.02 - 2026.05',
      technologies: <String>['Flutter', 'Dart', 'JavaScript'],
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
      title: 'Blue Mentor',
      category: PortfolioProjectCategory.career,
      description: '기계 점검 안전 설비 보고서 작성 앱 기획 및 개발',
      period: '2023.06 - 2024.02',
      technologies: <String>['Flutter', 'Dart', 'Node.js'],
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
