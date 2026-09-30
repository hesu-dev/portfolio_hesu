enum PortfolioAppId {
  profile,
  about,
  introduction,
  skills,
  projects,
  safari,
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
/// component coverage. [PortfolioAppId.projects] opens Files,
/// while [PortfolioAppId.safari] provides the browser presentation.
const List<PortfolioAppId> portfolioLauncherAppIds = <PortfolioAppId>[
  PortfolioAppId.about,
  PortfolioAppId.introduction,
  PortfolioAppId.skills,
  PortfolioAppId.projects,
  PortfolioAppId.safari,
  PortfolioAppId.terminal,
  PortfolioAppId.music,
  PortfolioAppId.photos,
  PortfolioAppId.github,
  PortfolioAppId.mail,
  PortfolioAppId.settings,
  PortfolioAppId.trash,
];

/// Apps placed in the macOS desktop icon grid.
///
/// Utility apps live in Files; the printer is appended by the desktop shell.
const List<PortfolioAppId> portfolioMacDesktopLauncherAppIds = <PortfolioAppId>[
  PortfolioAppId.about,
  PortfolioAppId.introduction,
  PortfolioAppId.projects,
  PortfolioAppId.safari,
  PortfolioAppId.terminal,
  PortfolioAppId.github,
  PortfolioAppId.skills,
];

/// Apps shown as tiles on both the iPhone and iPad home surfaces.
///
/// Profile is a mobile-only experience separate from the desktop About app.
const List<PortfolioAppId> portfolioMobileLauncherAppIds = <PortfolioAppId>[
  PortfolioAppId.profile,
  PortfolioAppId.introduction,
  PortfolioAppId.projects,
  PortfolioAppId.safari,
  PortfolioAppId.terminal,
  PortfolioAppId.github,
  PortfolioAppId.skills,
];

/// Utility apps opened from the Files section on every form factor.
const List<PortfolioAppId> portfolioFileAppIds = <PortfolioAppId>[
  PortfolioAppId.music,
  PortfolioAppId.photos,
  PortfolioAppId.mail,
  PortfolioAppId.settings,
  PortfolioAppId.trash,
];

const List<PortfolioAppId> portfolioDockAppIds = <PortfolioAppId>[
  PortfolioAppId.about,
  PortfolioAppId.introduction,
  PortfolioAppId.skills,
  PortfolioAppId.projects,
  PortfolioAppId.safari,
  PortfolioAppId.terminal,
  PortfolioAppId.music,
  PortfolioAppId.photos,
  PortfolioAppId.github,
  PortfolioAppId.mail,
  PortfolioAppId.settings,
];
