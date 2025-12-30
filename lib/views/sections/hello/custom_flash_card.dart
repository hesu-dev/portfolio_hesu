// import 'package:flutter/material.dart';
// import 'dart:math';
// import 'package:flutter/material.dart';

// class CustomFlashCardScreen extends StatefulWidget {
//   const CustomFlashCardScreen({super.key});

//   @override
//   State<CustomFlashCardScreen> createState() => _CustomFlashCardScreenState();
// }

// class _CustomFlashCardScreenState extends State<CustomFlashCardScreen>
//     with TickerProviderStateMixin {
//   final List<Map<String, String>> _cards = [
//     {'question': 'Who created Helvetica', 'answer': 'Max Miedinger'},
//     {'question': 'Flutter is developed by?', 'answer': 'Google'},
//     {'question': 'Dart is a ___ language?', 'answer': 'Programming'},
//     {'question': 'StatefulWidget has ___?', 'answer': 'State'},
//     {'question': 'StatelessWidget has ___?', 'answer': 'No state'},
//   ];

//   late AnimationController _positionController;
//   late AnimationController _progressController;

//   double _position = 0.0;
//   int _currentIndex = 0;
//   bool _isFront = true;

//   @override
//   void initState() {
//     super.initState();

//     _positionController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 400),
//     );

//     _progressController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );

//     _progressController.value = _currentIndex / _cards.length;
//   }

//   @override
//   void dispose() {
//     _positionController.dispose();
//     _progressController.dispose();
//     super.dispose();
//   }

//   void _flipCard() {
//     setState(() {
//       _isFront = !_isFront;
//     });
//   }

//   void _onHorizontalDragUpdate(DragUpdateDetails details) {
//     setState(() {
//       _position += details.delta.dx;
//     });
//   }

//   void _onHorizontalDragEnd(DragEndDetails details) {
//     if (_position.abs() > 200) {
//       // 화면 밖으로 보내기
//       _positionController.forward(from: 0).then((_) {
//         setState(() {
//           _currentIndex = (_currentIndex + 1) % _cards.length;
//           _position = 0;
//           _isFront = true;
//           _progressController.animateTo(
//             _currentIndex / _cards.length,
//             duration: const Duration(milliseconds: 300),
//           );
//         });
//       });
//     } else {
//       // 원위치
//       setState(() {
//         _position = 0;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final cardData = _cards[_currentIndex];

//     return Scaffold(
//       backgroundColor: Colors.lightBlue[300],
//       body: SafeArea(
//         child: AnimatedBuilder(
//           animation: Listenable.merge([
//             _positionController,
//             _progressController,
//           ]),
//           builder: (context, child) {
//             final angle = (_position / 300).clamp(-1.0, 1.0) * pi / 8;
//             final scale = 0.95 + (_position.abs() / 1000).clamp(0, 0.05);
//             final bgColor = _position < 0
//                 ? Colors.red.withOpacity((_position.abs() / 200).clamp(0, 1))
//                 : Colors.green.withOpacity((_position.abs() / 200).clamp(0, 1));
//             final opacity = (_position.abs() / 200).clamp(0.0, 1.0);

//             return Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Expanded(
//                   child: Stack(
//                     alignment: Alignment.center,
//                     children: [
//                       Transform.scale(
//                         scale: scale,
//                         child: GestureDetector(
//                           onTap: _flipCard,
//                           onHorizontalDragUpdate: _onHorizontalDragUpdate,
//                           onHorizontalDragEnd: _onHorizontalDragEnd,
//                           child: Transform(
//                             transform: Matrix4.identity()
//                               ..setEntry(3, 2, 0.001)
//                               ..rotateY(
//                                 _isFront
//                                     ? (1 - _positionController.value) * 0
//                                     : pi * (_positionController.value),
//                               ),
//                             alignment: Alignment.center,
//                             child: Container(
//                               width: 300,
//                               height: 400,
//                               decoration: BoxDecoration(
//                                 color: Colors.white,
//                                 borderRadius: BorderRadius.circular(16),
//                                 boxShadow: [
//                                   BoxShadow(
//                                     color: Colors.black26,
//                                     blurRadius: 8,
//                                     offset: Offset(0, 4),
//                                   ),
//                                 ],
//                               ),
//                               alignment: Alignment.center,
//                               child: _isFront
//                                   ? Text(
//                                       cardData['question']!,
//                                       textAlign: TextAlign.center,
//                                       style: const TextStyle(
//                                         fontSize: 22,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     )
//                                   : Text(
//                                       cardData['answer']!,
//                                       textAlign: TextAlign.center,
//                                       style: const TextStyle(
//                                         fontSize: 22,
//                                         fontWeight: FontWeight.bold,
//                                         color: Colors.green,
//                                       ),
//                                     ),
//                             ),
//                           ),
//                         ),
//                       ),
//                       Container(
//                         width: 300,
//                         height: 400,
//                         decoration: BoxDecoration(
//                           color: bgColor.withOpacity(opacity),
//                           borderRadius: BorderRadius.circular(16),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 SizedBox(
//                   height: 60,
//                   child: CustomPaint(
//                     painter: RoundLinearProgressIndicator(
//                       progress: _progressController.value,
//                     ),
//                     child: Container(),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

// class RoundLinearProgressIndicator extends CustomPainter {
//   final double progress;

//   RoundLinearProgressIndicator({required this.progress});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final paintBackground = Paint()
//       ..color = Colors.white54
//       ..strokeCap = StrokeCap.round
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 8;

//     final paintProgress = Paint()
//       ..color = Colors.white
//       ..strokeCap = StrokeCap.round
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 8;

//     final path = Path()
//       ..moveTo(0, size.height / 2)
//       ..lineTo(size.width, size.height / 2);

//     canvas.drawPath(path, paintBackground);

//     final progressPath = Path()
//       ..moveTo(0, size.height / 2)
//       ..lineTo(size.width * progress, size.height / 2);

//     canvas.drawPath(progressPath, paintProgress);
//   }

//   @override
//   bool shouldRepaint(covariant RoundLinearProgressIndicator oldDelegate) =>
//       oldDelegate.progress != progress;
// }
