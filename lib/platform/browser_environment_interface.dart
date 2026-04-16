abstract class BrowserEnvironment {
  int loadPageIndex();
  void savePageIndex(int index);
  bool get isPrintMode;
  Stream<bool> get onPrintModeChanged;
}
