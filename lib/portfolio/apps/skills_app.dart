import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/portfolio_data.dart';
import '../theme/apple_theme.dart';
import '../widgets/apple_selection_control.dart';

const Map<String, String> _skillLogoAssets = <String, String>{
  'Flutter': 'assets/icons/skills/flutter.svg',
  'Dart': 'assets/icons/skills/dart.svg',
  'React': 'assets/icons/skills/react.svg',
  'Java': 'assets/icons/skills/java.svg',
  'Notion': 'assets/icons/skills/notion.svg',
  'Slack': 'assets/icons/skills/slack.svg',
  'Trello': 'assets/icons/skills/trello.svg',
  'Figma': 'assets/icons/skills/figma.svg',
  'Adobe Photoshop': 'assets/icons/skills/adobe-photoshop.svg',
  'Adobe Illustrator': 'assets/icons/skills/adobe-illustrator.svg',
};

const List<Color> _fallbackAvatarColors = <Color>[
  Color(0xFF1264A3),
  Color(0xFF611F69),
  Color(0xFF087F5B),
  Color(0xFFA44500),
];

class SkillsApp extends StatefulWidget {
  const SkillsApp({
    required this.data,
    this.compact = false,
    this.mobile = false,
    this.tablet = false,
    this.now,
    super.key,
  });

  final PortfolioData data;
  final bool compact;
  final bool mobile;
  final bool tablet;
  final DateTime Function()? now;

  @override
  State<SkillsApp> createState() => _SkillsAppState();
}

class _SkillsAppState extends State<SkillsApp> {
  int _selectedIndex = 0;
  int? _mobileSelectedIndex;

  @override
  void didUpdateWidget(covariant SkillsApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedIndex >= widget.data.skillGroups.length) {
      _selectedIndex = 0;
    }
    if (_mobileSelectedIndex case final selectedIndex?
        when selectedIndex >= widget.data.skillGroups.length) {
      _mobileSelectedIndex = null;
    }
  }

  void _selectCategory(int index) {
    if (index == _selectedIndex) {
      return;
    }
    setState(() => _selectedIndex = index);
  }

  void _openMobileCategory(int index) {
    setState(() => _mobileSelectedIndex = index);
  }

  void _closeMobileCategory() {
    setState(() => _mobileSelectedIndex = null);
  }

  @override
  Widget build(BuildContext context) {
    return AppleAppSurface(
      key: const Key('skills-app'),
      child: widget.data.skillGroups.isEmpty
          ? const AppleEmptyState(
              icon: Icons.folder_off_rounded,
              title: 'No skill groups yet',
              message: 'Skill categories will appear here.',
            )
          : widget.mobile && !widget.tablet
          ? _buildCompact(context)
          : _buildWide(context),
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
              key: ValueKey<String>(
                'skills-detail-$_selectedIndex-${widget.data.skillGroups[_selectedIndex].title}',
              ),
              group: widget.data.skillGroups[_selectedIndex],
              compact: false,
              now: (widget.now ?? DateTime.now)(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompact(BuildContext context) {
    return _MobileSkillsView(
      certifications: widget.data.certifications,
      groups: widget.data.skillGroups,
      dark: AppleTheme.isDark(context),
      selectedIndex: _mobileSelectedIndex,
      now: (widget.now ?? DateTime.now)(),
      onChannelSelected: _openMobileCategory,
      onBack: _closeMobileCategory,
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
              child: const Icon(
                Icons.workspace_premium_rounded,
                key: Key('skills-workspace-icon'),
                color: Color(0xFF4A154B),
                size: 22,
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
                child: Icon(
                  _workspaceIconForGroup(entry.$2.title),
                  key: Key('skills-workspace-group-icon-${entry.$2.title}'),
                  color: Colors.white,
                  size: 18,
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
                  '채널',
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

class _MobileSkillsView extends StatelessWidget {
  const _MobileSkillsView({
    required this.certifications,
    required this.groups,
    required this.dark,
    required this.selectedIndex,
    required this.now,
    required this.onChannelSelected,
    required this.onBack,
  });

  final List<String> certifications;
  final List<PortfolioSkillGroup> groups;
  final bool dark;
  final int? selectedIndex;
  final DateTime now;
  final ValueChanged<int> onChannelSelected;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final background = dark ? const Color(0xFF1A1D21) : const Color(0xFFF7F7F8);

    return ColoredBox(
      key: const Key('skills-mobile-surface'),
      color: background,
      child: selectedIndex == null
          ? _MobileSkillsChannelList(
              certifications: certifications,
              groups: groups,
              dark: dark,
              onChannelSelected: onChannelSelected,
            )
          : _MobileSkillChannelDetail(
              group: groups[selectedIndex!],
              dark: dark,
              now: now,
              onBack: onBack,
            ),
    );
  }
}

class _MobileSkillsChannelList extends StatelessWidget {
  const _MobileSkillsChannelList({
    required this.certifications,
    required this.groups,
    required this.dark,
    required this.onChannelSelected,
  });

  final List<String> certifications;
  final List<PortfolioSkillGroup> groups;
  final bool dark;
  final ValueChanged<int> onChannelSelected;

  @override
  Widget build(BuildContext context) {
    final primary = dark ? const Color(0xFFF8F8F8) : const Color(0xFF1D1C1D);
    final secondary = dark ? const Color(0xFFB5B7BA) : const Color(0xFF616061);

    return SingleChildScrollView(
      key: const Key('skills-list'),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
            child: Text(
              'Portfolio Skills',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: primary,
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SingleChildScrollView(
            key: const Key('skills-mobile-certification-strip'),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
            child: Row(
              children: <Widget>[
                for (final certification in certifications.take(1))
                  _MobileCertificationCard(
                    certification: certification,
                    dark: dark,
                  ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: dark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.1),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
            child: Row(
              children: <Widget>[
                Text(
                  '#',
                  style: TextStyle(
                    color: secondary,
                    fontSize: 25,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '채널',
                  style: TextStyle(
                    color: primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 28),
            child: Column(
              key: const Key('skills-mobile-channel-list'),
              children: <Widget>[
                for (final entry in groups.indexed)
                  _MobileSkillChannel(
                    group: entry.$2,
                    dark: dark,
                    onTap: () => onChannelSelected(entry.$1),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileCertificationCard extends StatelessWidget {
  const _MobileCertificationCard({
    required this.certification,
    required this.dark,
  });

  final String certification;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final primary = dark ? const Color(0xFFF8F8F8) : const Color(0xFF1D1C1D);
    final secondary = dark ? const Color(0xFFB5B7BA) : const Color(0xFF616061);

    return Semantics(
      key: Key('skills-mobile-certification-$certification'),
      label: '자격증 $certification',
      readOnly: true,
      child: ExcludeSemantics(
        child: Container(
          width: 242,
          constraints: const BoxConstraints(minHeight: 100),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF222529) : Colors.white,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: dark ? const Color(0xFF45484C) : const Color(0xFFD8D8DC),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF2EB67D),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '자격증',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: secondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      certification,
                      style: TextStyle(
                        color: primary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
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

class _MobileSkillChannel extends StatelessWidget {
  const _MobileSkillChannel({
    required this.group,
    required this.dark,
    required this.onTap,
  });

  final PortfolioSkillGroup group;
  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = dark ? const Color(0xFFE7E8E9) : const Color(0xFF29272A);

    return Semantics(
      key: Key('skills-mobile-channel-${group.title}'),
      label: '${group.title} 채널 열기',
      button: true,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '# ${group.title}',
                      style: TextStyle(
                        color: foreground,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: dark
                        ? const Color(0xFFB5B7BA)
                        : const Color(0xFF616061),
                    size: 22,
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

class _MobileSkillChannelDetail extends StatelessWidget {
  const _MobileSkillChannelDetail({
    required this.group,
    required this.dark,
    required this.now,
    required this.onBack,
  });

  final PortfolioSkillGroup group;
  final bool dark;
  final DateTime now;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('skills-mobile-channel-detail'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 16, 12),
          child: _SkillChannelHeader(
            group: group,
            headerKey: const Key('skills-mobile-channel-header'),
            leading: _MobileDetailBackButton(onBack: onBack),
          ),
        ),
        Divider(
          height: 1,
          color: dark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.1),
        ),
        Expanded(
          child: _SkillActivityFeed(
            group: group,
            now: now,
            scrollKey: const Key('skills-mobile-message-list'),
            dateKey: const Key('skills-mobile-message-date'),
            compact: true,
          ),
        ),
      ],
    );
  }
}

class _SkillActivityFeed extends StatelessWidget {
  const _SkillActivityFeed({
    required this.group,
    required this.now,
    required this.scrollKey,
    required this.dateKey,
    required this.compact,
    this.leading,
  });

  final PortfolioSkillGroup group;
  final DateTime now;
  final Key scrollKey;
  final Key dateKey;
  final bool compact;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final dark = AppleTheme.isDark(context);

    return ListView(
      key: scrollKey,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: EdgeInsets.fromLTRB(
        compact ? 16 : 26,
        compact ? 14 : 24,
        compact ? 16 : 26,
        28,
      ),
      children: <Widget>[
        if (leading case final header?) ...<Widget>[
          header,
          Divider(
            height: 21,
            color: AppleTheme.separator(context).withValues(alpha: 0.7),
          ),
        ],
        Container(
          key: dateKey,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Text(
            '오늘 · ${now.year}년 ${now.month}월 ${now.day}일',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: dark ? const Color(0xFFB5B7BA) : const Color(0xFF616061),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 14),
        for (final entry in group.skills.indexed) ...<Widget>[
          _SkillActivityMessage(group: group, skill: entry.$2, index: entry.$1),
          if (entry.$1 != group.skills.length - 1) const SizedBox(height: 22),
        ],
      ],
    );
  }
}

class _SkillChannelHeader extends StatelessWidget {
  const _SkillChannelHeader({
    required this.group,
    this.leading,
    this.headerKey,
  });

  final PortfolioSkillGroup group;
  final Widget? leading;
  final Key? headerKey;

  @override
  Widget build(BuildContext context) {
    final dark = AppleTheme.isDark(context);
    final primary = dark ? const Color(0xFFF8F8F8) : const Color(0xFF1D1C1D);
    final secondary = dark ? const Color(0xFFB5B7BA) : const Color(0xFF616061);
    final hasLeading = leading != null;

    return Column(
      key: headerKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            if (leading case final leading?) ...<Widget>[
              leading,
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                '# ${group.title}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: primary,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  height: 1.18,
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(left: hasLeading ? 52 : 0, top: 6),
          child: Wrap(
            spacing: 16,
            runSpacing: 4,
            children: <Widget>[
              Text(
                '1명의 멤버',
                style: TextStyle(
                  color: secondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '1개의 탭',
                style: TextStyle(
                  color: secondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MobileDetailBackButton extends StatelessWidget {
  const _MobileDetailBackButton({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const Key('skills-mobile-detail-back'),
      label: '채널 목록으로 돌아가기',
      button: true,
      onTap: onBack,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: 44,
          child: IconButton(
            onPressed: onBack,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppleTheme.primaryLabel(context),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _SkillActivityMessage extends StatelessWidget {
  const _SkillActivityMessage({
    required this.group,
    required this.skill,
    required this.index,
  });

  final PortfolioSkillGroup group;
  final String skill;
  final int index;

  @override
  Widget build(BuildContext context) {
    final dark = AppleTheme.isDark(context);
    final primary = dark ? const Color(0xFFF8F8F8) : const Color(0xFF1D1C1D);
    final secondary = dark ? const Color(0xFFB5B7BA) : const Color(0xFF616061);

    return Semantics(
      key: Key('skill-item-$skill'),
      container: true,
      explicitChildNodes: true,
      label: '$skill, ${group.title} 채널 활동',
      readOnly: true,
      child: Container(
        key: Key('skills-message-row-$skill'),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Semantics(
              key: Key('skills-message-avatar-$skill'),
              label: '$skill 프로필 사진',
              image: true,
              child: ExcludeSemantics(
                child: _SkillActivityAvatar(skill: skill, index: index),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 2,
                    children: <Widget>[
                      Text(
                        skill,
                        key: Key('skills-message-author-$skill'),
                        style: TextStyle(
                          color: primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      Text(
                        _messageTime(index),
                        key: Key('skills-message-time-$skill'),
                        style: TextStyle(
                          color: secondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _activityDescription(group, skill),
                    key: Key('skills-message-content-$skill'),
                    style: TextStyle(
                      color: primary,
                      fontSize: 15,
                      height: 1.42,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillActivityAvatar extends StatelessWidget {
  const _SkillActivityAvatar({required this.skill, required this.index});

  final String skill;
  final int index;

  @override
  Widget build(BuildContext context) {
    final logoAsset = _skillLogoAssets[skill];
    if (logoAsset == null) {
      return Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _fallbackAvatarColors[index % _fallbackAvatarColors.length],
          shape: BoxShape.circle,
        ),
        child: Text(
          _firstCharacter(skill).toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      );
    }

    return Container(
      width: 42,
      height: 42,
      padding: const EdgeInsets.all(7),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppleTheme.isDark(context)
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      child: SvgPicture.asset(
        logoAsset,
        key: Key('skills-message-logo-$skill'),
        fit: BoxFit.contain,
      ),
    );
  }
}

String _activityDescription(PortfolioSkillGroup group, String skill) {
  final description = group.activityDescriptions[skill]?.trim();
  if (description == null || description.isEmpty) {
    return '$skill 관련 학습과 프로젝트 작업을 진행했습니다.';
  }
  return description;
}

String _messageTime(int index) {
  final time = DateTime(2000, 1, 1, 9).add(Duration(minutes: index * 15));
  final period = time.hour < 12 ? '오전' : '오후';
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute $period';
}

class _SkillDetail extends StatelessWidget {
  const _SkillDetail({
    required this.group,
    required this.compact,
    required this.now,
    super.key,
  });

  final PortfolioSkillGroup group;
  final bool compact;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return _SkillActivityFeed(
      group: group,
      now: now,
      scrollKey: const Key('skills-list'),
      dateKey: const Key('skills-message-date'),
      compact: compact,
      leading: _SkillChannelHeader(group: group),
    );
  }
}

String _firstCharacter(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? '#' : String.fromCharCode(trimmed.runes.first);
}

IconData _workspaceIconForGroup(String title) {
  return switch (title) {
    'Development' => Icons.code_rounded,
    'Collaboration' => Icons.description_rounded,
    'Design & UI/UX' => Icons.draw_rounded,
    _ => Icons.tag_rounded,
  };
}
