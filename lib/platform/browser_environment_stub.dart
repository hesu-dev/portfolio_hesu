import 'browser_environment_interface.dart';

class StubBrowserEnvironment implements BrowserEnvironment {
  @override
  bool get isPrintMode => false;

  @override
  Stream<bool> get onPrintModeChanged => const Stream<bool>.empty();

  @override
  int loadPageIndex() => 0;

  @override
  void savePageIndex(int index) {}
}

BrowserEnvironment createBrowserEnvironment() => StubBrowserEnvironment();
