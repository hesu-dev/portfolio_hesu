import 'package:flutter/material.dart';

import '../theme/apple_theme.dart';
import 'apple_finder_icon.dart';

/// Shared list geometry for project folders, app shortcuts and the printer.
class AppleFinderListRow extends StatelessWidget {
  const AppleFinderListRow({
    required this.artwork,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.selected = false,
    this.artworkHasBackground = false,
    super.key,
  });

  final Widget artwork;
  final String title;
  // Null hides the metadata line; an empty string reserves the same line as
  // neighboring rows when a date/tag is unavailable.
  final String? subtitle;
  final bool selected;
  final bool artworkHasBackground;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: AppleFinderIcon(
                      size: 40,
                      selected: selected,
                      hasOwnBackground: artworkHasBackground,
                      child: artwork,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w500,
                                height: 1.25,
                              ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!.isEmpty ? '\u00a0' : subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppleTheme.caption(
                              context,
                            ).copyWith(height: 1.25),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
