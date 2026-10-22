import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/project_architecture.dart';

const _nodeWidth = 144.0;
const _nodeHeight = 112.0;

/// An icon schematic: coordinates and labels scale together, while surrounding
/// controls retain the user's text size. The full drawing is also read aloud.
class ProjectArchitectureDiagram extends StatelessWidget {
  const ProjectArchitectureDiagram({required this.diagram, super.key});

  final PortfolioArchitectureDiagram diagram;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    key: const Key('architecture-diagram'),
    builder: (context, constraints) {
      final minimumScale = constraints.maxWidth >= 600 ? 0.5 : 0.78;
      final scale = (constraints.maxWidth / diagram.width).clamp(
        minimumScale,
        1.0,
      );
      final scrolls = diagram.width * scale > constraints.maxWidth;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: const Key('architecture-expand'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              icon: const Icon(Icons.open_in_full, size: 18),
              label: const Text('확대 보기'),
              onPressed: () => showDialog<void>(
                context: context,
                useSafeArea: false,
                builder: (context) => _ExpandedArchitecture(diagram: diagram),
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Semantics(
              label: _description(diagram),
              image: true,
              child: ExcludeSemantics(
                child: SingleChildScrollView(
                  key: const Key('architecture-scroll'),
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: diagram.width * scale,
                    height: diagram.height * scale,
                    child: FittedBox(
                      child: _ArchitectureCanvas(diagram: diagram),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (scrolls)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '좌우로 이동하거나 확대해서 볼 수 있습니다.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      );
    },
  );
}

String _description(PortfolioArchitectureDiagram diagram) {
  final names = {for (final node in diagram.nodes) node.id: node.label};
  return [
    diagram.summary,
    for (final node in diagram.nodes)
      '${node.label}${node.detail.isEmpty ? '' : ': ${node.detail}'}.',
    for (final edge in diagram.edges)
      '${names[edge.from] ?? edge.from} → ${names[edge.to] ?? edge.to}'
          '${edge.label.isEmpty ? '' : ': ${edge.label}'}.',
  ].join('\n');
}

class _ExpandedArchitecture extends StatefulWidget {
  const _ExpandedArchitecture({required this.diagram});

  final PortfolioArchitectureDiagram diagram;

  @override
  State<_ExpandedArchitecture> createState() => _ExpandedArchitectureState();
}

class _ExpandedArchitectureState extends State<_ExpandedArchitecture> {
  final _transformation = TransformationController();
  final _viewerKey = GlobalKey();

  @override
  void dispose() {
    _transformation.dispose();
    super.dispose();
  }

  void _zoom(double factor) {
    final box = _viewerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final scale = _transformation.value.getMaxScaleOnAxis();
    final ratio = (scale * factor).clamp(0.5, 5.0) / scale;
    final center = box.size.center(Offset.zero);
    _transformation.value = Matrix4.diagonal3Values(ratio, ratio, 1)
      ..setTranslationRaw(center.dx * (1 - ratio), center.dy * (1 - ratio), 0)
      ..multiply(_transformation.value);
  }

  @override
  Widget build(BuildContext context) => Dialog.fullscreen(
    child: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '아키텍처',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  key: const Key('architecture-close'),
                  tooltip: '아키텍처 닫기',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Expanded(
            child: Semantics(
              label: _description(widget.diagram),
              image: true,
              child: ExcludeSemantics(
                child: InteractiveViewer(
                  key: _viewerKey,
                  transformationController: _transformation,
                  minScale: 0.5,
                  maxScale: 5,
                  boundaryMargin: const EdgeInsets.all(80),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: FittedBox(
                        child: _ArchitectureCanvas(diagram: widget.diagram),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      key: const Key('architecture-zoom-out'),
                      tooltip: '아키텍처 축소',
                      constraints: const BoxConstraints.tightFor(
                        width: 48,
                        height: 48,
                      ),
                      icon: const Icon(Icons.remove),
                      onPressed: () => _zoom(1 / 1.5),
                    ),
                    IconButton(
                      key: const Key('architecture-zoom-reset'),
                      tooltip: '전체 아키텍처 보기',
                      constraints: const BoxConstraints.tightFor(
                        width: 48,
                        height: 48,
                      ),
                      icon: const Icon(Icons.fit_screen),
                      onPressed: () =>
                          _transformation.value = Matrix4.identity(),
                    ),
                    IconButton(
                      key: const Key('architecture-zoom-in'),
                      tooltip: '아키텍처 확대',
                      constraints: const BoxConstraints.tightFor(
                        width: 48,
                        height: 48,
                      ),
                      icon: const Icon(Icons.add),
                      onPressed: () => _zoom(1.5),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '버튼·핀치·스크롤로 확대 · 드래그로 이동',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _ArchitectureCanvas extends StatelessWidget {
  const _ArchitectureCanvas({required this.diagram});

  final PortfolioArchitectureDiagram diagram;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: diagram.width,
      height: diagram.height,
      child: CustomPaint(
        painter: _ArchitecturePainter(diagram, dark),
        child: Stack(
          children: [
            for (final node in diagram.nodes)
              Positioned(
                left: node.x - _nodeWidth / 2,
                top: node.y - _nodeHeight / 2,
                width: _nodeWidth,
                height: _nodeHeight,
                child: Column(
                  children: [
                    SizedBox(
                      height: 46,
                      child: _ArchitectureIcon(name: node.icon),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      node.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      textScaler: TextScaler.noScaling,
                      style: TextStyle(
                        color: dark
                            ? const Color(0xFFF1F3F7)
                            : const Color(0xFF233047),
                        fontSize: 13,
                        height: 1.15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (node.detail.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        node.detail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        textScaler: TextScaler.noScaling,
                        style: TextStyle(
                          color: dark
                              ? const Color(0xFFB4BFCE)
                              : const Color(0xFF5D6A7F),
                          fontSize: 11,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ArchitectureIcon extends StatelessWidget {
  const _ArchitectureIcon({required this.name});

  final String name;

  static const _assets = {
    'flutter': 'assets/icons/skills/flutter.svg',
    'react': 'assets/icons/skills/react.svg',
    'dart': 'assets/icons/skills/dart.svg',
    'java': 'assets/icons/skills/java.svg',
    'mysql': 'assets/icons/architecture/mysql.svg',
    'php': 'assets/icons/architecture/php.svg',
    'unity': 'assets/icons/architecture/unity.svg',
    'typescript': 'assets/icons/architecture/typescript.svg',
    'github': 'assets/icons/github.svg',
  };

  @override
  Widget build(BuildContext context) {
    final asset = _assets[name];
    if (asset != null) {
      return SvgPicture.asset(asset, width: 46, height: 46);
    }
    final (icon, color) = switch (name) {
      'browser' => (Icons.web_outlined, const Color(0xFF2583C9)),
      'extension' => (Icons.extension_outlined, const Color(0xFF6D61CC)),
      'json' => (Icons.data_object, const Color(0xFFDE9E23)),
      'file' => (Icons.insert_drive_file_outlined, const Color(0xFF5295C6)),
      'pdf' => (Icons.picture_as_pdf_outlined, const Color(0xFFD85C55)),
      'epub' => (Icons.menu_book_outlined, const Color(0xFF65A446)),
      'cloud' => (Icons.cloud_outlined, const Color(0xFF2583C9)),
      'server' => (Icons.dns_outlined, const Color(0xFFDB923E)),
      'worker' => (Icons.bolt, const Color(0xFFDD932C)),
      'queue' => (Icons.stacked_bar_chart, const Color(0xFFBB4D8C)),
      'storage' => (Icons.storage_outlined, const Color(0xFF549571)),
      'auth' => (Icons.verified_user_outlined, const Color(0xFF6582CD)),
      'firebase' => (Icons.local_fire_department, const Color(0xFFEBAC21)),
      'ai' => (Icons.auto_awesome, const Color(0xFF9470C9)),
      'node' => (Icons.hexagon_outlined, const Color(0xFF679B49)),
      'apache' => (Icons.public, const Color(0xFFBD5374)),
      'credit' => (Icons.credit_card, const Color(0xFF6487C1)),
      'store' => (Icons.storefront_outlined, const Color(0xFF609981)),
      _ => (Icons.hub_outlined, const Color(0xFF6688B8)),
    };
    return Icon(icon, size: 46, color: color);
  }
}

class _ArchitecturePainter extends CustomPainter {
  _ArchitecturePainter(this.diagram, this.dark);

  final PortfolioArchitectureDiagram diagram;
  final bool dark;

  Color get background =>
      dark ? const Color(0xFF171D26) : const Color(0xFFFAFBFD);
  Color get foreground =>
      dark ? const Color(0xFFB5C8DF) : const Color(0xFF526E8C);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final grid = Paint()..color = foreground.withValues(alpha: 0.08);
    for (double x = 0; x < size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    for (final group in diagram.groups) {
      final bounds = Rect.fromLTWH(group.x, group.y, group.width, group.height);
      final path = Path()
        ..addRRect(RRect.fromRectAndRadius(bounds, const Radius.circular(18)));
      final pen = Paint()
        ..color = foreground.withValues(alpha: 0.65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;
      for (final metric in path.computeMetrics()) {
        for (double start = 0; start < metric.length; start += 14) {
          canvas.drawPath(
            metric.extractPath(start, math.min(start + 7, metric.length)),
            pen,
          );
        }
      }
    }
    final nodes = {for (final node in diagram.nodes) node.id: node};
    final pen = Paint()
      ..color = foreground
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeJoin = StrokeJoin.round;
    for (final edge in diagram.edges) {
      final from = nodes[edge.from];
      final to = nodes[edge.to];
      if (from == null || to == null) continue;
      final points = _route(from, to, edge.via);
      if (points.length < 2) continue;
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, pen);
      final last = points.last;
      final direction = last - points[points.length - 2];
      final angle = math.atan2(direction.dy, direction.dx);
      final arrow = Path()
        ..moveTo(last.dx, last.dy)
        ..lineTo(
          last.dx - 9 * math.cos(angle - 0.45),
          last.dy - 9 * math.sin(angle - 0.45),
        )
        ..moveTo(last.dx, last.dy)
        ..lineTo(
          last.dx - 9 * math.cos(angle + 0.45),
          last.dy - 9 * math.sin(angle + 0.45),
        );
      canvas.drawPath(arrow, pen);
      if (edge.label.isNotEmpty) {
        var longest = 0.0;
        var labelAt = Offset.zero;
        for (var index = 1; index < points.length; index++) {
          final length = (points[index] - points[index - 1]).distance;
          if (length > longest) {
            longest = length;
            labelAt = (points[index] + points[index - 1]) / 2;
          }
        }
        _label(canvas, edge.label, labelAt);
      }
    }
    // Boundary titles sit over connectors so the text stays unobstructed.
    for (final group in diagram.groups) {
      _label(
        canvas,
        group.label,
        Offset(group.x + 20, group.y),
        centered: false,
        bold: true,
        maxWidth: math.max(1, group.width - 40),
      );
    }
  }

  void _label(
    Canvas canvas,
    String text,
    Offset at, {
    bool centered = true,
    bool bold = false,
    double maxWidth = 180,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: foreground,
          fontSize: bold ? 12 : 11,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: bold ? 1 : 2,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    final origin =
        at - Offset(centered ? painter.width / 2 : 0, painter.height / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        (origin & painter.size).inflate(4),
        const Radius.circular(4),
      ),
      Paint()..color = background,
    );
    painter.paint(canvas, origin);
  }

  @override
  bool shouldRepaint(_ArchitecturePainter oldDelegate) =>
      oldDelegate.diagram != diagram || oldDelegate.dark != dark;
}

List<Offset> _route(
  PortfolioArchitectureNode from,
  PortfolioArchitectureNode to,
  List<PortfolioArchitecturePoint> via,
) {
  final start = Offset(from.x, from.y);
  final end = Offset(to.x, to.y);
  List<Offset> points;
  if (via.isNotEmpty) {
    points = [start, for (final point in via) Offset(point.x, point.y), end];
    points[0] = _boundary(start, points[1]);
    points[points.length - 1] = _boundary(end, points[points.length - 2]);
  } else if ((end.dx - start.dx).abs() >= (end.dy - start.dy).abs()) {
    final sign = end.dx >= start.dx ? 1 : -1;
    final left = start + Offset(sign * (_nodeWidth / 2 + 4), 0);
    final right = end - Offset(sign * (_nodeWidth / 2 + 4), 0);
    final middle = (left.dx + right.dx) / 2;
    points = [left, Offset(middle, left.dy), Offset(middle, right.dy), right];
  } else {
    final sign = end.dy >= start.dy ? 1 : -1;
    final top = start + Offset(0, sign * (_nodeHeight / 2 + 4));
    final bottom = end - Offset(0, sign * (_nodeHeight / 2 + 4));
    final middle = (top.dy + bottom.dy) / 2;
    points = [top, Offset(top.dx, middle), Offset(bottom.dx, middle), bottom];
  }
  return [
    for (var i = 0; i < points.length; i++)
      if (i == 0 || points[i] != points[i - 1]) points[i],
  ];
}

Offset _boundary(Offset center, Offset toward) {
  final delta = toward - center;
  if (delta == Offset.zero) return center;
  final ratio = math.min(
    delta.dx == 0 ? double.infinity : (_nodeWidth / 2 + 4) / delta.dx.abs(),
    delta.dy == 0 ? double.infinity : (_nodeHeight / 2 + 4) / delta.dy.abs(),
  );
  return center + delta * ratio;
}
