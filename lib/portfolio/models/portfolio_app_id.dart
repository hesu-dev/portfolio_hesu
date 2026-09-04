enum PortfolioAppId {
  profile,
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

/// Apps exposed as launcher icons on the macOS desktop surfaces.
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
/// Profile is a mobile-only experience separate from the desktop About app,
/// while Photos remains a placeholder for a future gallery experience.
const List<PortfolioAppId> portfolioMobileLauncherAppIds = <PortfolioAppId>[
  PortfolioAppId.profile,
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
