enum PortfolioAppId {
  about,
  skills,
  projects,
  terminal,
  thisMac,
  trash,
  github,
  mail,
  settings,
}

/// Apps exposed as launcher icons on the desktop and mobile home screens.
///
/// [PortfolioAppId.thisMac] remains only as an internal legacy route for shared
/// component coverage. Launchers and the system menu use
/// [PortfolioAppId.projects] as the single public project entry point.
const List<PortfolioAppId> portfolioLauncherAppIds = <PortfolioAppId>[
  PortfolioAppId.about,
  PortfolioAppId.skills,
  PortfolioAppId.projects,
  PortfolioAppId.terminal,
  PortfolioAppId.trash,
  PortfolioAppId.github,
  PortfolioAppId.mail,
  PortfolioAppId.settings,
];

const List<PortfolioAppId> portfolioDockAppIds = <PortfolioAppId>[
  PortfolioAppId.about,
  PortfolioAppId.skills,
  PortfolioAppId.projects,
  PortfolioAppId.terminal,
  PortfolioAppId.mail,
  PortfolioAppId.settings,
  PortfolioAppId.github,
];
