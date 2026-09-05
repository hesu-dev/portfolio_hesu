enum PortfolioAppId {
  profile,
  about,
  introduction,
  skills,
  projects,
  terminal,
  music,
  photos,
  thisMac,
  trash,
  github,
  mail,
  settings,
}

/// Apps exposed through macOS launch surfaces.
///
/// [PortfolioAppId.thisMac] remains only as an internal legacy route for shared
/// component coverage. Launchers and the system menu use
/// [PortfolioAppId.projects] as the single public project entry point.
const List<PortfolioAppId> portfolioLauncherAppIds = <PortfolioAppId>[
  PortfolioAppId.about,
  PortfolioAppId.introduction,
  PortfolioAppId.skills,
  PortfolioAppId.projects,
  PortfolioAppId.terminal,
  PortfolioAppId.music,
  PortfolioAppId.github,
  PortfolioAppId.mail,
  PortfolioAppId.settings,
  PortfolioAppId.trash,
];

/// Apps placed in the macOS desktop icon grid.
///
/// Trash is intentionally excluded because macOS keeps it in the Dock's
/// utility area instead of treating it as a desktop launcher.
const List<PortfolioAppId> portfolioMacDesktopLauncherAppIds = <PortfolioAppId>[
  PortfolioAppId.about,
  PortfolioAppId.introduction,
  PortfolioAppId.skills,
  PortfolioAppId.projects,
  PortfolioAppId.terminal,
  PortfolioAppId.music,
  PortfolioAppId.github,
  PortfolioAppId.mail,
  PortfolioAppId.settings,
];

/// Apps shown as tiles on both the iPhone and iPad home surfaces.
///
/// Profile is a mobile-only experience separate from the desktop About app,
/// while Photos provides the shared responsive gallery experience.
const List<PortfolioAppId> portfolioMobileLauncherAppIds = <PortfolioAppId>[
  PortfolioAppId.profile,
  PortfolioAppId.introduction,
  PortfolioAppId.skills,
  PortfolioAppId.projects,
  PortfolioAppId.terminal,
  PortfolioAppId.music,
  PortfolioAppId.photos,
  PortfolioAppId.github,
  PortfolioAppId.mail,
  PortfolioAppId.settings,
  PortfolioAppId.trash,
];

const List<PortfolioAppId> portfolioDockAppIds = <PortfolioAppId>[
  PortfolioAppId.about,
  PortfolioAppId.introduction,
  PortfolioAppId.skills,
  PortfolioAppId.projects,
  PortfolioAppId.terminal,
  PortfolioAppId.music,
  PortfolioAppId.github,
  PortfolioAppId.mail,
  PortfolioAppId.settings,
];
