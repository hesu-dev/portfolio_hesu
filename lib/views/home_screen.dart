// import 'package:flutter/gestures.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:portfolio_hesu/views/sections/about/about.dart';
// import 'package:portfolio_hesu/views/sections/contact/contact_block.dart';
// import 'package:portfolio_hesu/views/sections/hero/hello.dart';
// import 'package:portfolio_hesu/views/sections/project/project.dart';
// import 'dart:html' as html;

// import 'package:portfolio_hesu/views/widgets/section.dart';

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   final _homeKey = GlobalKey();
//   final _aboutKey = GlobalKey();
//   final _projectsKey = GlobalKey();
//   final _contactKey = GlobalKey();

//   late final PageController _pageController;
//   int _currentPage = 0;

//   @override
//   void initState() {
//     super.initState();
//     final saved = html.window.localStorage['pageIndex'];
//     _currentPage = int.tryParse(saved ?? '0') ?? 0;
//     _pageController = PageController(initialPage: _currentPage);
//   }

//   void _savePage(int index) {
//     _currentPage = index;
//     html.window.localStorage['pageIndex'] = index.toString();
//   }

//   void _goToPage(int index) {
//     _pageController.animateToPage(
//       index,
//       duration: const Duration(milliseconds: 400),
//       curve: Curves.easeOutCubic,
//     );
//   }

//   ThemeMode _mode = ThemeMode.dark;

//   void _jumpTo(GlobalKey key) {
//     if (key == _homeKey) _goToPage(0);
//     if (key == _aboutKey) _goToPage(1);
//     if (key == _projectsKey) _goToPage(2);
//     if (key == _contactKey) _goToPage(3);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final nav = [
//       ('Home', _homeKey),
//       ('about', _aboutKey),
//       ('Projects', _projectsKey),
//       ('contact', _contactKey),
//     ];

//     return RawKeyboardListener(
//       autofocus: true,
//       focusNode: FocusNode(),
//       onKey: (RawKeyEvent event) {
//         if (event is RawKeyDownEvent) {
//           if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
//             if (_currentPage < 5) _goToPage(_currentPage + 1);
//           }
//           if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
//             if (_currentPage > 0) _goToPage(_currentPage - 1);
//           }
//         }
//       },

//       child: Listener(
//         onPointerSignal: (pointerSignal) {
//           if (pointerSignal is PointerScrollEvent) {
//             if (pointerSignal.scrollDelta.dy > 0) {
//               if (_currentPage < 5) _goToPage(_currentPage + 1);
//             } else {
//               if (_currentPage > 0) _goToPage(_currentPage - 1);
//             }
//           }
//         },

//         child: SizedBox(
//           height: MediaQuery.of(context).size.height,
//           child: PageView(
//             controller: _pageController,
//             scrollDirection: Axis.vertical,
//             onPageChanged: _savePage,
//             children: [
//               Section(
//                 key: _homeKey,
//                 callback: () => _goToPage(1),
//                 up: false,
//                 child: Padding(
//                   padding: EdgeInsetsGeometry.symmetric(vertical: 100),
//                   child: const Hello(),
//                 ),
//               ),
//               Section(
//                 key: _aboutKey,
//                 callback: () => _goToPage(2),
//                 up: false,
//                 child: const Aboutme(),
//               ),
//               Section(
//                 key: _projectsKey,
//                 callback: () => _goToPage(3),
//                 up: false,
//                 child: ProjectTxt(),
//               ),
//               Section(
//                 key: _contactKey,
//                 callback: () => _goToPage(0),
//                 up: true,
//                 child: const ContactSection(),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
