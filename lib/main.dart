// ignore_for_file: deprecated_member_use

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portfolio_hesu/views/sections/contact/contact_block.dart';
import 'package:portfolio_hesu/views/sections/project/post.dart';
import 'package:portfolio_hesu/views/sections/project/project.dart';
import 'package:portfolio_hesu/views/widgets/animation/bounce_arrow_btn.dart';
import 'package:portfolio_hesu/views/widgets/custom_appbar.dart';
import 'package:portfolio_hesu/views/widgets/custom_drawer.dart';
import 'package:portfolio_hesu/views/widgets/section.dart';
import 'package:portfolio_hesu/views/sections/hello/hello.dart';
import 'package:portfolio_hesu/views/sections/about/about.dart';
import 'dart:html' as html;

void main() => runApp(const PortfolioClone());

class PortfolioClone extends StatefulWidget {
  const PortfolioClone({super.key});
  @override
  State<PortfolioClone> createState() => _PortfolioCloneState();
}

class _PortfolioCloneState extends State<PortfolioClone> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final _homeKey = GlobalKey();
  final _aboutKey = GlobalKey();
  final _projectsKey = GlobalKey();
  final _contactKey = GlobalKey();

  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    final saved = html.window.localStorage['pageIndex'];
    _currentPage = int.tryParse(saved ?? '0') ?? 0;
    _pageController = PageController(initialPage: _currentPage);
  }

  void _savePage(int index) {
    _currentPage = index;
    html.window.localStorage['pageIndex'] = index.toString();
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  ThemeMode _mode = ThemeMode.dark;

  void _jumpTo(GlobalKey key) {
    if (key == _homeKey) _goToPage(0);
    if (key == _aboutKey) _goToPage(1);
    if (key == _projectsKey) _goToPage(2);
    if (key == _contactKey) _goToPage(3);
  }

  @override
  Widget build(BuildContext context) {
    final nav = [
      ('Home', _homeKey),
      ('about', _aboutKey),
      ('Projects', _projectsKey),
      ('contact', _contactKey),
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
        appBar: CustomAppBar(
          nav: nav,
          jumpTo: _jumpTo,
          mode: _mode,
          toggleTheme: () => setState(() {
            _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
          }),
        ),
        drawer: MediaQuery.of(context).size.width <= 768
            ? CustomDrawer(
                nav: nav,
                jumpTo: (key) {
                  _jumpTo(key);
                  _scaffoldKey.currentState?.closeDrawer();
                },
              )
            : null,
        body: RawKeyboardListener(
          autofocus: true,
          focusNode: FocusNode(),
          onKey: (RawKeyEvent event) {
            if (event is RawKeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                if (_currentPage < 5) _goToPage(_currentPage + 1);
              }
              if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                if (_currentPage > 0) _goToPage(_currentPage - 1);
              }
            }
          },

          child: Listener(
            onPointerSignal: (pointerSignal) {
              if (pointerSignal is PointerScrollEvent) {
                if (pointerSignal.scrollDelta.dy > 0) {
                  if (_currentPage < 5) _goToPage(_currentPage + 1);
                } else {
                  if (_currentPage > 0) _goToPage(_currentPage - 1);
                }
              }
            },

            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: PageView(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  onPageChanged: _savePage,
                  children: [
                    Section(
                      key: _homeKey,
                      callback: () => _goToPage(1),
                      up: false,
                      child: Padding(
                        padding: EdgeInsetsGeometry.symmetric(vertical: 100),
                        child: const Hello(),
                      ),
                    ),
                    Section(
                      key: _aboutKey,
                      callback: () => _goToPage(2),
                      up: false,
                      child: const Aboutme(),
                    ),
                    Section(
                      key: _projectsKey,
                      callback: () => _goToPage(3),
                      up: false,
                      child: ProjectTxt(),
                    ),
                    Section(
                      key: _contactKey,
                      callback: () => _goToPage(0),
                      up: true,
                      child: const ContactSection(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
