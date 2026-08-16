import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data/repositories/app_state.dart';
import '../features/collection/collection_page.dart';
import '../features/notebook/notebook_page.dart';
import '../features/records/records_page.dart';
import '../features/settings/settings_page.dart';
import 'ad_banner_slot.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.state});

  final AppState state;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      NotebookPage(state: widget.state),
      CollectionPage(state: widget.state),
      RecordsPage(state: widget.state),
      SettingsPage(state: widget.state),
    ];
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: index, children: pages),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NavigationBar(
            height: 70,
            selectedIndex: index,
            indicatorColor: const Color(0xFFFFE6EE),
            onDestinationSelected: (value) => setState(() => index = value),
            destinations: const [
              NavigationDestination(
                icon: Icon(CupertinoIcons.heart),
                label: '手帳',
              ),
              NavigationDestination(
                icon: Icon(CupertinoIcons.square_grid_2x2),
                label: 'コレクション',
              ),
              NavigationDestination(
                icon: Icon(CupertinoIcons.chart_bar),
                label: '記録・統計',
              ),
              NavigationDestination(
                icon: Icon(CupertinoIcons.gear_alt),
                label: '設定',
              ),
            ],
          ),
          const AdBannerSlot(),
        ],
      ),
    );
  }
}
