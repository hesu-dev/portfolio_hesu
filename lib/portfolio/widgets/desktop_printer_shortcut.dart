import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/portfolio_data.dart';
import '../printing/open_print_document.dart';

class DesktopPrinterShortcut extends StatelessWidget {
  const DesktopPrinterShortcut({
    required this.data,
    this.openDocument = openPrintDocument,
    super.key,
  });

  final PortfolioData data;
  final FutureOr<bool> Function(PortfolioData data) openDocument;

  Future<void> _open(BuildContext context) async {
    if (await openDocument(data) || !context.mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('인쇄 화면을 열지 못했어요'),
        content: Text(
          kIsWeb
              ? '브라우저의 팝업 차단을 해제한 뒤 프린터를 다시 눌러 주세요.'
              : 'PDF 저장과 인쇄는 웹 브라우저에서 포트폴리오를 열어 이용해 주세요.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '이력서 · 자기소개서 · 프로젝트 PDF 저장 / 인쇄',
      child: SizedBox(
        width: 91,
        child: TextButton(
          key: const Key('desktop-printer'),
          onPressed: () => _open(context),
          style: ButtonStyle(
            foregroundColor: const WidgetStatePropertyAll(Colors.white),
            overlayColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.focused)
                  ? Colors.white.withValues(alpha: 0.24)
                  : Colors.black.withValues(alpha: 0.16),
            ),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SvgPicture.asset(
                'assets/icons/printer.svg',
                width: 50,
                height: 50,
                excludeFromSemantics: true,
              ),
              const SizedBox(height: 6),
              const Text(
                '프린터',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  shadows: <Shadow>[
                    Shadow(
                      color: Color(0xB3000000),
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
