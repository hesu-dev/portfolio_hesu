typedef IntroductionSection = ({String? title, List<String> paragraphs});

/// Numbered headings and explicit bullet lines; ordinary biographies stay text.
List<IntroductionSection> introductionSections(String text) {
  return [
    for (final block in text.trim().split(RegExp(r'\r?\n\s*\r?\n')))
      if (block.trim().isNotEmpty) _section(block.trim()),
  ];
}

IntroductionSection _section(String block) {
  final lines = block.split(RegExp(r'\r?\n'));
  if (!RegExp(r'^\d+\.\s+').hasMatch(lines.first)) {
    return (title: null, paragraphs: [block]);
  }
  return (
    title: lines.first,
    paragraphs: [
      for (final line in lines.skip(1))
        if (line.trim().isNotEmpty)
          line.trim().replaceFirst(RegExp(r'^[-•]\s+'), ''),
    ],
  );
}
