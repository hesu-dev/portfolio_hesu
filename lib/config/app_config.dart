import 'package:flutter/foundation.dart';

abstract final class AppConfig {
  static const githubContributionsUrl = String.fromEnvironment(
    'GITHUB_CONTRIBUTIONS_URL',
    defaultValue:
        'https://portfolio-hesu-api.portfolio-hesu.workers.dev/api/github/contributions',
  );

  static const environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: kReleaseMode ? 'production' : 'development',
  );
}
