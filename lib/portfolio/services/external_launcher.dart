import 'package:url_launcher/url_launcher.dart';

typedef ExternalLaunchCallback = Future<bool> Function(Uri uri);

abstract interface class ExternalLauncher {
  Future<bool> launch(Uri uri);
}

/// An injectable launcher for tests and platform-specific integrations.
final class CallbackExternalLauncher implements ExternalLauncher {
  const CallbackExternalLauncher(this.callback);

  final ExternalLaunchCallback callback;

  @override
  Future<bool> launch(Uri uri) => callback(uri);
}

/// Opens safe external links through `url_launcher` without leaking errors.
final class UrlLauncherExternalLauncher implements ExternalLauncher {
  const UrlLauncherExternalLauncher({
    ExternalLaunchCallback delegate = _launchExternally,
  }) : _delegate = delegate;

  final ExternalLaunchCallback _delegate;

  @override
  Future<bool> launch(Uri uri) async {
    try {
      if (!_isSupportedExternalUri(uri)) {
        return false;
      }
      return await _delegate(uri);
    } catch (_) {
      return false;
    }
  }
}

Future<bool> _launchExternally(Uri uri) {
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

bool _isSupportedExternalUri(Uri uri) {
  return switch (uri.scheme.toLowerCase()) {
    'http' ||
    'https' => uri.isAbsolute && uri.hasAuthority && uri.host.isNotEmpty,
    'mailto' => _isSupportedMailtoUri(uri),
    _ => false,
  };
}

bool _isSupportedMailtoUri(Uri uri) {
  if (!uri.isAbsolute || uri.hasAuthority) {
    return false;
  }

  final recipient = Uri.decodeComponent(uri.path).trim();
  final separator = recipient.indexOf('@');
  return separator > 0 &&
      separator == recipient.lastIndexOf('@') &&
      separator < recipient.length - 1 &&
      !recipient.contains(RegExp(r'\s'));
}
