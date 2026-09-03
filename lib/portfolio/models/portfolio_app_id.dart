enum PortfolioAppId {
  about,
  skills,
  projects,
  terminal,
  photos,
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
  PortfolioAppId.github,
  PortfolioAppId.mail,
  PortfolioAppId.settings,
  PortfolioAppId.trash,
];

/// Apps shown as tiles on both the iPhone and iPad home surfaces.
///
/// About stays available through the Notes profile card, while Photos is a
/// mobile-only placeholder for a future gallery experience.
const List<PortfolioAppId> portfolioMobileLauncherAppIds = <PortfolioAppId>[
  PortfolioAppId.skills,
  PortfolioAppId.projects,
  PortfolioAppId.terminal,
  PortfolioAppId.photos,
  PortfolioAppId.github,
  PortfolioAppId.mail,
  PortfolioAppId.settings,
  PortfolioAppId.trash,
];

const List<PortfolioAppId> portfolioDockAppIds = <PortfolioAppId>[
  PortfolioAppId.about,
  PortfolioAppId.skills,
  PortfolioAppId.projects,
  PortfolioAppId.terminal,
  PortfolioAppId.github,
  PortfolioAppId.mail,
  PortfolioAppId.settings,
];
