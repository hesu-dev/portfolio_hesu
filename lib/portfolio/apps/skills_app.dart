import 'package:flutter/material.dart';

import '../data/portfolio_data.dart';
import '../theme/apple_theme.dart';
import '../widgets/apple_selection_control.dart';

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
  static const double _wideBreakpoint = 680;

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
            leading: const Icon(Icons.tag_rounded, color: AppleTheme.indigo),
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
                          !widget.compact &&
                          constraints.maxWidth >= _wideBreakpoint;
                      return wide ? _buildWide(context) : _buildCompact();
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWide(BuildContext context) {
    return Row(
      children: <Widget>[
        _WorkspaceRail(
          groups: widget.data.skillGroups,
          selectedIndex: _selectedIndex,
        ),
        SizedBox(
          width: widget.tablet ? 200 : 224,
          child: _CategorySidebar(
            groups: widget.data.skillGroups,
            selectedIndex: _selectedIndex,
            onSelected: _selectCategory,
          ),
        ),
        Expanded(
          child: Container(
            key: const Key('skills-channel-detail'),
            color: AppleTheme.canvas(context),
            child: _SkillDetail(
              group: widget.data.skillGroups[_selectedIndex],
              compact: false,
            ),
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

class _WorkspaceRail extends StatelessWidget {
  const _WorkspaceRail({required this.groups, required this.selectedIndex});

  final List<PortfolioSkillGroup> groups;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    final dark = AppleTheme.isDark(context);
    return Container(
      key: const Key('skills-workspace-rail'),
      width: 68,
      color: dark ? const Color(0xFF1D0921) : const Color(0xFF321035),
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: ExcludeSemantics(
        child: Column(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'S',
                style: TextStyle(
                  color: Color(0xFF4A154B),
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: 36,
              height: 1,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 13),
            for (final entry in groups.indexed) ...<Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: selectedIndex == entry.$1 ? 38 : 34,
                height: selectedIndex == entry.$1 ? 38 : 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selectedIndex == entry.$1
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(
                    selectedIndex == entry.$1 ? 11 : 17,
                  ),
                  border: selectedIndex == entry.$1
                      ? Border.all(color: Colors.white.withValues(alpha: 0.72))
                      : null,
                ),
                child: Text(
                  _firstCharacter(entry.$2.title),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 9),
            ],
          ],
        ),
      ),
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
    final background = AppleTheme.isDark(context)
        ? const Color(0xFF2E0C32)
        : const Color(0xFF4A154B);
    const foreground = Color(0xFFF9F5F9);

    return Container(
      key: const Key('skills-channel-sidebar'),
      decoration: BoxDecoration(
        color: background,
        border: Border(
          right: BorderSide(
            color: Colors.white.withValues(alpha: 0.15),
            width: 0.7,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 18, 16, 7),
            child: Text(
              'Portfolio Skills',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 16, 8),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: foreground.withValues(alpha: 0.88),
                  size: 17,
                ),
                const SizedBox(width: 4),
                const Text(
                  'Channels',
                  style: TextStyle(
                    color: foreground,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 14),
              children: <Widget>[
                for (final entry in groups.indexed)
                  _CategoryButton(
                    group: entry.$2,
                    selected: selectedIndex == entry.$1,
                    onTap: () => onSelected(entry.$1),
                    compact: false,
                    navigation: true,
                  ),
              ],
            ),
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
    final background = AppleTheme.isDark(context)
        ? const Color(0xFF2E0C32)
        : const Color(0xFF4A154B);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.15),
            width: 0.7,
          ),
        ),
      ),
      child: SingleChildScrollView(
        key: const Key('skills-channel-picker'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          children: <Widget>[
            for (final entry in groups.indexed) ...<Widget>[
              _CategoryButton(
                group: entry.$2,
                selected: selectedIndex == entry.$1,
                onTap: () => onSelected(entry.$1),
                compact: true,
                navigation: true,
              ),
              if (entry.$1 != groups.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryButton extends StatelessWidget {
  const _CategoryButton({
    required this.group,
    required this.selected,
    required this.onTap,
    required this.compact,
    required this.navigation,
  });

  final PortfolioSkillGroup group;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;
  final bool navigation;

  @override
  Widget build(BuildContext context) {
    final foreground = navigation
        ? selected
              ? Colors.white
              : const Color(0xFFF0E6F0)
        : AppleTheme.primaryLabel(context);

    return AppleSelectionControl(
      key: Key('skills-category-${group.title}'),
      semanticsLabel: 'Select skill category ${group.title}',
      selected: selected,
      onPressed: onTap,
      borderRadius: BorderRadius.circular(compact ? 999 : 8),
      focusColor: navigation ? Colors.white : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minHeight: 44),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 10,
          vertical: compact ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: selected
              ? (AppleTheme.isDark(context)
                    ? const Color(0xFF1D0921)
                    : const Color(0xFF321035))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(compact ? 999 : 8),
          border: compact
              ? Border.all(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.86)
                      : Colors.white.withValues(alpha: 0.3),
                )
              : null,
        ),
        child: Row(
          mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
          children: <Widget>[
            Text(
              '#',
              style: TextStyle(
                color: foreground.withValues(alpha: 0.84),
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 7),
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
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
          ],
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
    return SingleChildScrollView(
      key: const Key('skills-list'),
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 26,
        compact ? 16 : 24,
        compact ? 14 : 26,
        28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _ChannelHeader(group: group, compact: compact),
          for (final entry in group.skills.indexed) ...<Widget>[
            Divider(
              height: compact ? 17 : 21,
              color: AppleTheme.separator(context).withValues(alpha: 0.7),
            ),
            _SkillMessageRow(
              group: group,
              skill: entry.$2,
              index: entry.$1,
              compact: compact,
            ),
          ],
        ],
      ),
    );
  }
}

class _ChannelHeader extends StatelessWidget {
  const _ChannelHeader({required this.group, required this.compact});

  final PortfolioSkillGroup group;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 2 : 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.tag_rounded,
                size: compact ? 20 : 23,
                color: AppleTheme.primaryLabel(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  group.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: compact ? 19 : 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            '${group.skills.length} skills in this channel',
            style: AppleTheme.caption(context),
          ),
        ],
      ),
    );
  }
}

class _SkillMessageRow extends StatelessWidget {
  const _SkillMessageRow({
    required this.group,
    required this.skill,
    required this.index,
    required this.compact,
  });

  final PortfolioSkillGroup group;
  final String skill;
  final int index;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = <Color>[
      const Color(0xFF1264A3),
      const Color(0xFF611F69),
      const Color(0xFF087F5B),
      const Color(0xFFA44500),
    ];
    final color = colors[index % colors.length];

    return Semantics(
      key: Key('skill-item-$skill'),
      container: true,
      label: '$skill, ${group.title} skill',
      readOnly: true,
      child: ExcludeSemantics(
        child: Container(
          key: Key('skills-message-row-$skill'),
          constraints: const BoxConstraints(minHeight: 52),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 2 : 6,
            vertical: compact ? 3 : 5,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _firstCharacter(skill).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      skill,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: compact ? 15 : 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Skill in ${group.title}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppleTheme.caption(context),
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

String _firstCharacter(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? '#' : String.fromCharCode(trimmed.runes.first);
}
