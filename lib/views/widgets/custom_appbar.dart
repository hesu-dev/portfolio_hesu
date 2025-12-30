import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<(String, GlobalKey)> nav;
  final void Function(GlobalKey) jumpTo;
  final ThemeMode mode;
  final VoidCallback toggleTheme;

  const CustomAppBar({
    super.key,
    required this.nav,
    required this.jumpTo,
    required this.mode,
    required this.toggleTheme,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 600) {
      return AppBar(
        title: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(onTap: () {}, child: const Text("")),
                Row(
                  children: nav
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: TextButton(
                            onPressed: () => jumpTo(e.$2),
                            child: Text(e.$1),
                          ),
                        ),
                      )
                      .toList(),
                ),
                ThemeSwitch(mode: mode, toggle: toggleTheme),
              ],
            ),
          ),
        ),
      );
    }

    return AppBar(
      title: const SizedBox.shrink(), // 내용 제거
    );
  }
}

class ThemeSwitch extends StatelessWidget {
  final ThemeMode mode;
  final VoidCallback toggle;

  const ThemeSwitch({super.key, required this.mode, required this.toggle});

  @override
  Widget build(BuildContext context) {
    return Switch(value: mode == ThemeMode.dark, onChanged: (v) => toggle());
  }
}
