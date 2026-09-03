import 'package:flutter/material.dart';

import '../data/portfolio_data.dart';
import '../theme/apple_theme.dart';

class SkillsApp extends StatefulWidget {
  const SkillsApp({
    required this.data,
    this.compact = false,
    this.tablet = false,
    super.key,
  });

  final PortfolioData data;
  final bool compact;
  final bool tablet;

  @override
  State<SkillsApp> createState() => _SkillsAppState();
}

class _SkillsAppState extends State<SkillsApp> {
  int _selectedIndex = 0;

  @override
  void didUpdateWidget(covariant SkillsApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedIndex >= widget.data.skillGroups.length) {
      _selectedIndex = 0;
    }
  }

  void _selectCategory(int index) {
    if (index == _selectedIndex) {
      return;
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return AppleAppSurface(
      key: const Key('skills-app'),
      child: Column(
        children: <Widget>[
          AppleToolbar(
            title: 'Skills',
            subtitle: 'A categorized toolkit',
            compact: widget.compact,
            leading: const Icon(
              Icons.auto_awesome_rounded,
              color: AppleTheme.indigo,
            ),
          ),
          Expanded(
            child: widget.data.skillGroups.isEmpty
                ? const AppleEmptyState(
                    icon: Icons.folder_off_rounded,
                    title: 'No skill groups yet',
                    message: 'Skill categories will appear here.',
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final wide =
                          !widget.compact && constraints.maxWidth >= 680;
                      return wide ? _buildWide() : _buildCompact();
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWide() {
    return Row(
      children: <Widget>[
        SizedBox(
          width: widget.tablet ? 200 : 224,
          child: _CategorySidebar(
            groups: widget.data.skillGroups,
            selectedIndex: _selectedIndex,
            onSelected: _selectCategory,
          ),
        ),
        Expanded(
          child: _SkillDetail(
            group: widget.data.skillGroups[_selectedIndex],
            compact: false,
          ),
        ),
      ],
    );
  }

  Widget _buildCompact() {
    return Column(
      children: <Widget>[
        _CategoryStrip(
          groups: widget.data.skillGroups,
          selectedIndex: _selectedIndex,
          onSelected: _selectCategory,
        ),
        Expanded(
          child: _SkillDetail(
            group: widget.data.skillGroups[_selectedIndex],
            compact: true,
          ),
        ),
      ],
    );
  }
}

class _CategorySidebar extends StatelessWidget {
  const _CategorySidebar({
    required this.groups,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<PortfolioSkillGroup> groups;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppleTheme.panel(context),
        border: Border(
          right: BorderSide(color: AppleTheme.separator(context), width: 0.7),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
            child: Text(
              'CATEGORIES',
              style: AppleTheme.caption(context).copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
              ),
            ),
          ),
          for (final entry in groups.indexed)
            _CategoryButton(
              group: entry.$2,
              index: entry.$1,
              selected: selectedIndex == entry.$1,
              onTap: () => onSelected(entry.$1),
              compact: false,
            ),
        ],
      ),
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({
    required this.groups,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<PortfolioSkillGroup> groups;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppleTheme.panel(context),
        border: Border(
          bottom: BorderSide(color: AppleTheme.separator(context), width: 0.7),
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 58),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            children: <Widget>[
              for (final entry in groups.indexed) ...<Widget>[
                _CategoryButton(
                  group: entry.$2,
                  index: entry.$1,
                  selected: selectedIndex == entry.$1,
                  onTap: () => onSelected(entry.$1),
                  compact: true,
                ),
                if (entry.$1 != groups.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({
    required this.group,
    required this.index,
    required this.selected,
    required this.onTap,
    required this.compact,
  });

  final PortfolioSkillGroup group;
  final int index;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? (AppleTheme.isDark(context) ? Colors.white : const Color(0xFF153A70))
        : AppleTheme.primaryLabel(context);

    return Semantics(
      key: Key('skills-category-${group.title}'),
      container: true,
      label: 'Select skill category ${group.title}',
      selected: selected,
      button: true,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(compact ? 999 : 11),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            constraints: const BoxConstraints(minHeight: 44),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 13 : 10,
              vertical: compact ? 8 : 11,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? AppleTheme.blue.withValues(
                      alpha: AppleTheme.isDark(context) ? 0.27 : 0.13,
                    )
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(compact ? 999 : 11),
              border: compact
                  ? Border.all(
                      color: selected
                          ? AppleTheme.blue.withValues(alpha: 0.3)
                          : AppleTheme.separator(context),
                    )
                  : null,
            ),
            child: Row(
              mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
              children: <Widget>[
                Icon(
                  _categoryIcon(index),
                  color: selected ? AppleTheme.blue : foreground,
                  size: 18,
                ),
                const SizedBox(width: 8),
                if (compact)
                  Text(
                    group.title,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: foreground,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  )
                else
                  Expanded(
                    child: Text(
                      group.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: foreground,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SkillDetail extends StatelessWidget {
  const _SkillDetail({required this.group, required this.compact});

  final PortfolioSkillGroup group;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('skills-list'),
      padding: EdgeInsets.all(compact ? 16 : 28),
      children: <Widget>[
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AppleSectionTitle(
                  title: group.title,
                  subtitle: '${group.skills.length} tools and technologies',
                  icon: Icons.folder_open_rounded,
                ),
                SizedBox(height: compact ? 16 : 22),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    for (final entry in group.skills.indexed)
                      _SkillCard(
                        skill: entry.$2,
                        index: entry.$1,
                        compact: compact,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SkillCard extends StatelessWidget {
  const _SkillCard({
    required this.skill,
    required this.index,
    required this.compact,
  });

  final String skill;
  final int index;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = <Color>[
      AppleTheme.blue,
      AppleTheme.indigo,
      AppleTheme.green,
      AppleTheme.orange,
    ];
    final color = colors[index % colors.length];

    return SizedBox(
      key: Key('skill-item-$skill'),
      width: compact ? 148 : 190,
      child: AppleSurfaceCard(
        padding: EdgeInsets.all(compact ? 15 : 18),
        radius: 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(Icons.check_rounded, color: color, size: 21),
            ),
            const SizedBox(height: 13),
            Text(
              skill,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

IconData _categoryIcon(int index) {
  return switch (index % 3) {
    0 => Icons.code_rounded,
    1 => Icons.groups_rounded,
    _ => Icons.palette_rounded,
  };
}
