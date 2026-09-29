import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../models/portfolio_app_id.dart';
import '../theme/apple_theme.dart';
import 'apple_app_artwork.dart';

class PortfolioGuideButton extends StatefulWidget {
  const PortfolioGuideButton({
    required this.onOpenApp,
    this.onOpened,
    this.initialRight = 20,
    this.initialBottom = 28,
    super.key,
  });

  final ValueChanged<PortfolioAppId> onOpenApp;
  final VoidCallback? onOpened;
  final double initialRight;
  final double initialBottom;

  @override
  State<PortfolioGuideButton> createState() => _PortfolioGuideButtonState();
}

class _PortfolioGuideButtonState extends State<PortfolioGuideButton> {
  static const _buttonSize = 52.0;
  static const _entries = <(PortfolioAppId, String)>[
    (PortfolioAppId.introduction, '어떤 개발자인지 궁금하다면'),
    (PortfolioAppId.safari, '프로젝트를 자세히 보고 싶다면'),
    (PortfolioAppId.skills, '사용하는 기술이 궁금하다면'),
    (PortfolioAppId.github, '코드와 개발 기록을 보고 싶다면'),
    (PortfolioAppId.terminal, '키보드로 직접 체험하고 싶다면'),
  ];

  final _buttonFocus = FocusNode();
  Offset? _position;
  Offset _dragOffset = Offset.zero;
  bool _isOpen = false;

  @override
  void dispose() {
    _buttonFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final minX = padding.left + 8;
        final minY = padding.top + 8;
        final maxX = math.max(
          minX,
          constraints.maxWidth - padding.right - _buttonSize - 8,
        );
        final maxY = math.max(
          minY,
          constraints.maxHeight - padding.bottom - _buttonSize - 8,
        );
        Offset clamp(Offset value) =>
            Offset(value.dx.clamp(minX, maxX), value.dy.clamp(minY, maxY));
        final position = clamp(
          _position ??
              Offset(
                constraints.maxWidth -
                    padding.right -
                    _buttonSize -
                    widget.initialRight,
                constraints.maxHeight -
                    padding.bottom -
                    _buttonSize -
                    widget.initialBottom,
              ),
        );

        return Stack(
          children: <Widget>[
            Positioned(
              left: position.dx,
              top: position.dy,
              child: _buildMenu(
                context,
                onDragStart: (pointer) => _dragOffset = pointer - position,
                onDragUpdate: (pointer) => setState(() {
                  _position = clamp(pointer - _dragOffset);
                }),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenu(
    BuildContext context, {
    required ValueChanged<Offset> onDragStart,
    required ValueChanged<Offset> onDragUpdate,
  }) {
    final media = MediaQuery.of(context);
    final width = math.min(
      384.0,
      media.size.width - media.padding.horizontal - 32,
    );
    final foreground = AppleTheme.primaryLabel(context);

    return MenuAnchor(
      childFocusNode: _buttonFocus,
      consumeOutsideTap: true,
      alignmentOffset: Offset(-width, 8),
      style: MenuStyle(
        alignment: Alignment.bottomRight,
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: 8),
        ),
        backgroundColor: WidgetStatePropertyAll(AppleTheme.surface(context)),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(16),
        shadowColor: WidgetStatePropertyAll(
          Colors.black.withValues(alpha: 0.2),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppleTheme.separator(context), width: 0.7),
          ),
        ),
      ),
      onOpen: () {
        widget.onOpened?.call();
        setState(() => _isOpen = true);
      },
      onClose: () => setState(() => _isOpen = false),
      menuChildren: <Widget>[
        SizedBox(
          width: width,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            child: Semantics(
              header: true,
              child: Text(
                '포트폴리오 이용 안내',
                style: TextStyle(
                  color: foreground,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        for (var index = 0; index < _entries.length; index++) ...<Widget>[
          if (index > 0)
            Divider(
              height: 1,
              thickness: 0.6,
              indent: 16,
              endIndent: 16,
              color: AppleTheme.separator(context),
            ),
          MenuItemButton(
            autofocus: index == 0,
            onPressed: () => widget.onOpenApp(_entries[index].$1),
            style: ButtonStyle(
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
              foregroundColor: WidgetStatePropertyAll(foreground),
              textStyle: const WidgetStatePropertyAll(
                TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
            child: SizedBox(
              width: width - 40,
              child: Row(
                children: <Widget>[
                  ExcludeSemantics(
                    child: AppleAppArtwork(
                      appId: _entries[index].$1,
                      size: 26,
                      foregroundColor: foreground,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Text(_entries[index].$2)),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppleTheme.secondaryLabel(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
      builder: (context, controller, child) => Semantics(
        label: '포트폴리오 이용 안내',
        hint: '눌러서 안내 열기, 드래그하여 위치 이동',
        expanded: _isOpen,
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          dragStartBehavior: DragStartBehavior.down,
          onPanStart: (details) {
            controller.close();
            onDragStart(details.globalPosition);
          },
          onPanUpdate: (details) => onDragUpdate(details.globalPosition),
          child: IconButton(
            key: const Key('portfolio-guide-button'),
            focusNode: _buttonFocus,
            tooltip: _isOpen ? '이용 안내 닫기' : '이용 안내 열기',
            onPressed: () =>
                controller.isOpen ? controller.close() : controller.open(),
            style: IconButton.styleFrom(
              fixedSize: const Size(_buttonSize, _buttonSize),
              padding: const EdgeInsets.all(8),
              backgroundColor: const Color(0xBD292D2C),
              elevation: 8,
              shadowColor: Colors.black.withValues(alpha: 0.24),
              side: const BorderSide(color: Color(0x99505553)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            iconSize: 36,
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFCFDFC),
                border: Border.all(color: const Color(0xFFBFC4C0), width: 3),
                boxShadow: const <BoxShadow>[
                  BoxShadow(color: Color(0xFF737775), spreadRadius: 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
