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
/// [PortfolioAppId.thisMac] remains an internal project-hub route that can be
/// opened from the system menu, but is intentionally hidden to avoid showing a
/// second project launcher beside [PortfolioAppId.projects].
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
