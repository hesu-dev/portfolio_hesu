import 'package:flutter/material.dart';

/// Shared visual language for the adaptive portfolio surfaces.
abstract final class AppleTheme {
  static const Color blue = Color(0xFF0A84FF);
  static const Color buttonBlue = Color(0xFF0066CC);
  static const Color indigo = Color(0xFF5E5CE6);
  static const Color green = Color(0xFF30D158);
  static const Color orange = Color(0xFFFF9F0A);
  static const Color red = Color(0xFFFF453A);

  static const Color _lightCanvas = Color(0xFFF4F5F7);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightPanel = Color(0xFFF8F8FA);
  static const Color _darkCanvas = Color(0xFF121316);
  static const Color _darkSurface = Color(0xFF1C1D21);
  static const Color _darkPanel = Color(0xFF25262B);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData get lightTheme => light();

  static ThemeData get darkTheme => dark();

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: blue,
      brightness: brightness,
      surface: dark ? _darkSurface : _lightSurface,
    );
    final base = ThemeData(
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: dark ? _darkCanvas : _lightCanvas,
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
    );
    final primaryText = dark
        ? const Color(0xFFF5F5F7)
        : const Color(0xFF1D1D1F);
    final secondaryText = dark
        ? const Color(0xFFA8A8AE)
        : const Color(0xFF6E6E73);

    return base.copyWith(
      dividerColor: dark ? const Color(0xFF37383E) : const Color(0xFFD9D9DE),
      textTheme: base.textTheme.copyWith(
        displaySmall: TextStyle(
          color: primaryText,
          fontSize: 34,
          fontWeight: FontWeight.w700,
          height: 1.08,
          letterSpacing: -0.8,
        ),
        headlineSmall: TextStyle(
          color: primaryText,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          height: 1.15,
          letterSpacing: -0.35,
        ),
        titleLarge: TextStyle(
          color: primaryText,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.2,
          letterSpacing: -0.2,
        ),
        titleMedium: TextStyle(
          color: primaryText,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.25,
        ),
        bodyLarge: TextStyle(
          color: primaryText,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: primaryText,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.45,
        ),
        bodySmall: TextStyle(
          color: secondaryText,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.35,
        ),
        labelLarge: TextStyle(
          color: primaryText,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? _darkPanel : _lightPanel,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: blue, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: buttonBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: dark ? const Color(0xFF73B5FF) : buttonBlue,
          side: BorderSide(color: colorScheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        ),
      ),
    );
  }

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color canvas(BuildContext context) =>
      isDark(context) ? _darkCanvas : _lightCanvas;

  static Color surface(BuildContext context) =>
      isDark(context) ? _darkSurface : _lightSurface;

  static Color panel(BuildContext context) =>
      isDark(context) ? _darkPanel : _lightPanel;

  static Color primaryLabel(BuildContext context) =>
      isDark(context) ? const Color(0xFFF5F5F7) : const Color(0xFF1D1D1F);

  static Color secondaryLabel(BuildContext context) =>
      isDark(context) ? const Color(0xFFA8A8AE) : const Color(0xFF6E6E73);

  static Color separator(BuildContext context) =>
      isDark(context) ? const Color(0xFF38393F) : const Color(0xFFDADAE0);

  static Color subtleShadow(BuildContext context) =>
      Colors.black.withValues(alpha: isDark(context) ? 0.28 : 0.08);

  static Color pillBackground(BuildContext context, Color accent) {
    return Color.alphaBlend(
      accent.withValues(alpha: isDark(context) ? 0.2 : 0.1),
      surface(context),
    );
  }

  static Color pillForeground(BuildContext context) => primaryLabel(context);

  static Color selectionBackground(BuildContext context, Color accent) {
    return Color.alphaBlend(
      accent.withValues(alpha: isDark(context) ? 0.28 : 0.13),
      panel(context),
    );
  }

  static Color selectionForeground(BuildContext context) =>
      primaryLabel(context);

  static TextStyle largeTitle(BuildContext context) =>
      Theme.of(context).textTheme.displaySmall!;

  static TextStyle title(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge!;

  static TextStyle body(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium!;

  static TextStyle caption(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall!;
}

class AppleAppSurface extends StatelessWidget {
  const AppleAppSurface({required this.child, this.color, super.key});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? AppleTheme.canvas(context),
      child: SafeArea(child: child),
    );
  }
}

class AppleToolbar extends StatelessWidget {
  const AppleToolbar({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.compact = false,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppleTheme.surface(context).withValues(alpha: 0.94),
        border: Border(
          bottom: BorderSide(color: AppleTheme.separator(context), width: 0.6),
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: compact ? 54 : 62),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 20,
            vertical: compact ? 8 : 10,
          ),
          child: Row(
            children: <Widget>[
              if (leading case final icon?) ...<Widget>[
                icon,
                const SizedBox(width: 11),
              ],
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (!compact && subtitle != null)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppleTheme.caption(context),
                      ),
                  ],
                ),
              ),
              if (trailing case final action?) ...<Widget>[
                const SizedBox(width: 12),
                action,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AppleSurfaceCard extends StatelessWidget {
  const AppleSurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.color,
    this.radius = 20,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppleTheme.surface(context),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: AppleTheme.separator(context).withValues(alpha: 0.75),
          width: 0.7,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppleTheme.subtleShadow(context),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AppleSectionTitle extends StatelessWidget {
  const AppleSectionTitle({
    required this.title,
    this.subtitle,
    this.icon,
    super.key,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (icon case final sectionIcon?) ...<Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppleTheme.blue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(sectionIcon, color: AppleTheme.blue, size: 19),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle case final detail?) ...<Widget>[
                const SizedBox(height: 3),
                Text(detail, style: AppleTheme.caption(context)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class ApplePill extends StatelessWidget {
  const ApplePill({
    required this.label,
    this.icon,
    this.color = AppleTheme.blue,
    super.key,
  });

  final String label;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final foreground = AppleTheme.pillForeground(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppleTheme.pillBackground(context, color),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon case final pillIcon?) ...<Widget>[
              Icon(pillIcon, size: 14, color: foreground),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppleFeedbackBanner extends StatelessWidget {
  const AppleFeedbackBanner({
    required this.message,
    this.success = false,
    super.key,
  });

  final String message;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final color = success ? AppleTheme.green : AppleTheme.red;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            success ? Icons.check_circle_rounded : Icons.error_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: AppleTheme.body(
                context,
              ).copyWith(color: AppleTheme.primaryLabel(context), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class AppleEmptyState extends StatelessWidget {
  const AppleEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: AppleTheme.panel(context),
                shape: BoxShape.circle,
                border: Border.all(color: AppleTheme.separator(context)),
              ),
              child: Icon(
                icon,
                size: 38,
                color: AppleTheme.secondaryLabel(context),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 7),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: AppleTheme.body(
                  context,
                ).copyWith(color: AppleTheme.secondaryLabel(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
