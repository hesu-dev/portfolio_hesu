// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

import 'browser_environment_interface.dart';

class WebBrowserEnvironment implements BrowserEnvironment {
  WebBrowserEnvironment() : _printQuery = html.window.matchMedia('print');

  final html.MediaQueryList _printQuery;
  Stream<bool>? _printModeChanges;

  @override
  bool get isPrintMode => _printQuery.matches;

  @override
  Stream<bool> get onPrintModeChanged =>
      _printModeChanges ??= _printQuery.onChange
          .map((_) => _printQuery.matches)
          .asBroadcastStream();

  @override
  int loadPageIndex() =>
      int.tryParse(html.window.localStorage['pageIndex'] ?? '0') ?? 0;

  @override
  void savePageIndex(int index) {
    html.window.localStorage['pageIndex'] = index.toString();
  }
}

BrowserEnvironment createBrowserEnvironment() => WebBrowserEnvironment();
