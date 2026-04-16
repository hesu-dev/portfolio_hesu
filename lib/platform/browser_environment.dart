import 'browser_environment_interface.dart';
import 'browser_environment_stub.dart'
    if (dart.library.html) 'browser_environment_web.dart' as implementation;

export 'browser_environment_interface.dart';

BrowserEnvironment createBrowserEnvironment() =>
    implementation.createBrowserEnvironment();
