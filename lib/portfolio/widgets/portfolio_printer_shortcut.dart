import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/portfolio_data.dart';
import '../printing/open_print_document.dart';
import 'apple_app_label.dart';

class PortfolioPrinterShortcut extends StatelessWidget {
  const PortfolioPrinterShortcut({
    required this.data,
    this.openDocument = openPrintDocument,
    this.iconSize = 50,
    this.foregroundColor,
    this.showLabel = true,
    this.compact = false,
    this.buttonKey = const Key('desktop-printer'),
    super.key,
  });

  final PortfolioData data;
  final FutureOr<bool> Function(PortfolioData data) openDocument;
  final double iconSize;
  final Color? foregroundColor;
  final bool showLabel;
  final bool compact;
  final Key buttonKey;

  static Future<void> open(
    BuildContext context,
    PortfolioData data, {
    FutureOr<bool> Function(PortfolioData data) openDocument =
        openPrintDocument,
  }) async {
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
        width: showLabel ? 91 : iconSize + 12,
        height: showLabel ? null : iconSize + 8,
        child: TextButton(
          key: buttonKey,
          onPressed: () => open(context, data, openDocument: openDocument),
          style: ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(
              foregroundColor ?? Colors.white,
            ),
            overlayColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.focused)
                  ? Colors.white.withValues(alpha: 0.24)
                  : Colors.black.withValues(alpha: 0.16),
            ),
            minimumSize: const WidgetStatePropertyAll(Size.zero),
            padding: WidgetStatePropertyAll(
              EdgeInsets.symmetric(
                horizontal: showLabel ? (compact ? 5 : 7) : 6,
                vertical: showLabel ? (compact ? 4 : 6) : 4,
              ),
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
                width: iconSize,
                height: iconSize,
                excludeFromSemantics: showLabel,
                semanticsLabel: '프린터',
              ),
              if (showLabel) ...<Widget>[
                const SizedBox(height: 6),
                AppleAppLabel(
                  label: '프린터',
                  compact: compact,
                  color: foregroundColor ?? Colors.white,
                ),
                const SizedBox(height: 7),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
