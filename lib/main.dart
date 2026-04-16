// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portfolio_hesu/platform/browser_environment.dart';
import 'package:portfolio_hesu/views/sections/about/about.dart';
import 'package:portfolio_hesu/views/sections/contact/contact_block.dart';
import 'package:portfolio_hesu/views/sections/project/project.dart';
import 'package:portfolio_hesu/views/widgets/custom_appbar.dart';
import 'package:portfolio_hesu/views/widgets/custom_drawer.dart';
import 'package:portfolio_hesu/views/widgets/section.dart';

void main() => runApp(PortfolioClone());

class PortfolioClone extends StatefulWidget {
  PortfolioClone({
    super.key,
    BrowserEnvironment? browserEnvironment,
  }) : browserEnvironment = browserEnvironment ?? createBrowserEnvironment();

  final BrowserEnvironment browserEnvironment;

  @override
  State<PortfolioClone> createState() => _PortfolioCloneState();
}

class _PortfolioCloneState extends State<PortfolioClone> {
  static const int _lastPageIndex = 2;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _aboutKey = GlobalKey();
  final _projectsKey = GlobalKey();
  final _contactKey = GlobalKey();

  late final PageController _pageController;
  StreamSubscription<bool>? _printModeSubscription;

  int _currentPage = 0;
  late bool _isPrintMode;
  ThemeMode _mode = ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    final savedPageIndex = widget.browserEnvironment.loadPageIndex();
    _currentPage = savedPageIndex < 0
        ? 0
        : savedPageIndex > _lastPageIndex
        ? _lastPageIndex
        : savedPageIndex;
    _pageController = PageController(initialPage: _currentPage);
    _isPrintMode = widget.browserEnvironment.isPrintMode;
    _printModeSubscription = widget.browserEnvironment.onPrintModeChanged.listen(
      _handlePrintModeChanged,
    );
  }

  @override
  void dispose() {
    _printModeSubscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _handlePrintModeChanged(bool isPrintMode) {
    if (!mounted || _isPrintMode == isPrintMode) return;
    setState(() {
      _isPrintMode = isPrintMode;
    });
  }

  void _savePage(int index) {
    _currentPage = index;
    widget.browserEnvironment.savePageIndex(index);
  }

  void _goToPage(int index) {
    if (_isPrintMode) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  void _toggleTheme() {
    setState(() {
      _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  void _jumpTo(GlobalKey key) {
    if (key == _aboutKey) _goToPage(0);
    if (key == _projectsKey) _goToPage(1);
    if (key == _contactKey) _goToPage(2);
  }

  List<Widget> _buildSections({required bool printMode}) {
    return [
      Section(
        key: _aboutKey,
        callback: printMode ? null : () => _goToPage(1),
        printMode: printMode,
        child: const Aboutme(),
      ),
      Section(
        key: _projectsKey,
        callback: printMode ? null : () => _goToPage(2),
        printMode: printMode,
        child: const ProjectTxt(),
      ),
      Section(
        key: _contactKey,
        callback: printMode ? null : () => _goToPage(0),
        up: true,
        printMode: printMode,
        child: const ContactSection(),
      ),
    ];
  }

  Widget _buildInteractiveBody() {
    return RawKeyboardListener(
      autofocus: true,
      focusNode: FocusNode(),
      onKey: (RawKeyEvent event) {
        if (event is! RawKeyDownEvent) return;
        if (event.logicalKey == LogicalKeyboardKey.arrowDown &&
            _currentPage < _lastPageIndex) {
          _goToPage(_currentPage + 1);
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowUp && _currentPage > 0) {
          _goToPage(_currentPage - 1);
        }
      },
      child: Listener(
        onPointerSignal: (pointerSignal) {
          if (pointerSignal is! PointerScrollEvent) return;
          if (pointerSignal.scrollDelta.dy > 0 && _currentPage < _lastPageIndex) {
            _goToPage(_currentPage + 1);
          } else if (pointerSignal.scrollDelta.dy <= 0 && _currentPage > 0) {
            _goToPage(_currentPage - 1);
          }
        },
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: PageView(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              onPageChanged: _savePage,
              children: _buildSections(printMode: false),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrintBody() {
    return SingleChildScrollView(
      child: Column(children: _buildSections(printMode: true)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nav = [
      ('About', _aboutKey),
      ('Projects', _projectsKey),
      ('Contact', _contactKey),
    ];

    return MaterialApp(
      title: 'Min he-su',
      debugShowCheckedModeBanner: false,
      themeMode: _mode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: const Color(0xFF25A77C),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        primaryColor: const Color(0xFF25A77C),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: Scaffold(
        key: _scaffoldKey,
        appBar: _isPrintMode
            ? null
            : CustomAppBar(
                nav: nav,
                jumpTo: _jumpTo,
                mode: _mode,
                toggleTheme: _toggleTheme,
              ),
        drawer: _isPrintMode || MediaQuery.of(context).size.width > 768
            ? null
            : CustomDrawer(
                nav: nav,
                jumpTo: (key) {
                  _jumpTo(key);
                  _scaffoldKey.currentState?.closeDrawer();
                },
              ),
        body: _isPrintMode ? _buildPrintBody() : _buildInteractiveBody(),
      ),
    );
  }
}
