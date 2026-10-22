/// A schematic uses fixed coordinates so its connections remain readable while
/// the view fits, scrolls, or zooms the complete drawing.
class PortfolioArchitectureDiagram {
  const PortfolioArchitectureDiagram({
    required this.width,
    required this.height,
    required this.summary,
    required this.nodes,
    this.edges = const [],
    this.groups = const [],
  });

  final double width;
  final double height;
  final String summary;
  final List<PortfolioArchitectureNode> nodes;
  final List<PortfolioArchitectureEdge> edges;
  final List<PortfolioArchitectureGroup> groups;
}

class PortfolioArchitectureNode {
  const PortfolioArchitectureNode({
    required this.id,
    required this.label,
    this.detail = '',
    required this.icon,
    required this.x,
    required this.y,
  });

  final String id;
  final String label;
  final String detail;
  final String icon;

  /// Center of a 144 × 112 schematic node.
  final double x;
  final double y;
}

class PortfolioArchitectureEdge {
  const PortfolioArchitectureEdge({
    required this.from,
    required this.to,
    this.label = '',
    this.via = const [],
  });

  final String from;
  final String to;
  final String label;
  final List<PortfolioArchitecturePoint> via;
}

class PortfolioArchitecturePoint {
  const PortfolioArchitecturePoint(this.x, this.y);

  final double x;
  final double y;
}

class PortfolioArchitectureGroup {
  const PortfolioArchitectureGroup({
    required this.label,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final String label;
  final double x;
  final double y;
  final double width;
  final double height;
}
