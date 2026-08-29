import 'package:flutter/material.dart';

import '../theme/pp_theme.dart';
import '../widgets/pp_bottom_bar.dart';
import 'collection_screen.dart';
import 'home_screen.dart';
import 'journal_screen.dart';
import 'profile_screen.dart';
import 'scan_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  late int _index = widget.initialIndex;

  static const _pages = [
    HomeScreen(),
    CollectionScreen(),
    JournalScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PP.bone,
      extendBody: true,
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: PPBottomBar(
        currentIndex: _index,
        onSelect: (i) => setState(() => _index = i),
        onScan: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const ScanScreen())),
      ),
    );
  }
}
