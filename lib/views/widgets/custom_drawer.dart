import 'package:flutter/material.dart';

class CustomDrawer extends StatelessWidget {
  final List<(String, GlobalKey)> nav;
  final void Function(GlobalKey) jumpTo;

  const CustomDrawer({super.key, required this.nav, required this.jumpTo});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(child: Text('He-su')),
          ...nav.map(
            (e) => ListTile(
              title: Text(e.$1.toUpperCase()),
              onTap: () => jumpTo(e.$2),
            ),
          ),
        ],
      ),
    );
  }
}
