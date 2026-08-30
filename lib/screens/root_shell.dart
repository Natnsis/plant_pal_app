import 'package:flutter/material.dart';

import '../api/app_prefs.dart';
import '../api/notif_channel.dart';
import '../api/plantpal_api.dart';
import '../theme/pp_theme.dart';
import '../widgets/pp_bottom_bar.dart';
import 'collection_screen.dart';
import 'home_screen.dart';
import 'journal_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import 'scan_screen.dart';

/// Lets any descendant switch the bottom-nav tab (e.g. Home's "See all
/// plants" link jumping to the Plants tab) without losing the shell.
class RootNav extends InheritedWidget {
  const RootNav({super.key, required this.goToTab, required super.child});

  final void Function(int index) goToTab;

  static RootNav? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RootNav>();

  @override
  bool updateShouldNotify(RootNav oldWidget) => false;
}

class RootShell extends StatefulWidget {
  const RootShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> with WidgetsBindingObserver {
  late int _index = widget.initialIndex;
  int? _lastUnread;
  int _lastShownNotifId = 0;

  static const _pages = [
    HomeScreen(),
    CollectionScreen(),
    JournalScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _primeNotificationPermission();
    _checkInbox();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _primeNotificationPermission();
      _checkInbox();
    }
  }

  /// Ask for notification permission on app open. If the user grants it,
  /// real reminders show on the phone. If they hard-deny it, we never ask
  /// again and stay silent. If they just dismiss the sheet, we ask again on
  /// a later open — up to a few times, then leave them alone.
  Future<void> _primeNotificationPermission() async {
    final status = await NotifChannel.status();
    if (status == NotifPermission.granted ||
        status == NotifPermission.denied) {
      return; // granted -> nothing to do; denied -> respect it, stay silent
    }
    // status == deniedCanRetry (user dismissed it before, or first run)
    final asks = await AppPrefs.instance.getInt('notif_asks');
    final lastIso = await AppPrefs.instance.getString('notif_last_ask');
    final last = lastIso == null ? null : DateTime.tryParse(lastIso);
    final recently =
        last != null && DateTime.now().difference(last) < const Duration(hours: 20);
    if (asks >= 4 || recently) return;

    await AppPrefs.instance.setInt('notif_asks', asks + 1);
    await AppPrefs.instance
        .setString('notif_last_ask', DateTime.now().toIso8601String());
    await NotifChannel.requestPermission();
  }

  /// Pulls the notification inbox the backend fills from each plant's care
  /// plan, shows a real phone notification for anything new, and an in-app
  /// banner as a fallback.
  Future<void> _checkInbox() async {
    try {
      final unread = await PlantPalApi.instance.unreadCount();
      if (!mounted) return;
      final prev = _lastUnread;
      _lastUnread = unread;

      if (prev == null || unread <= prev) return;

      final items = await PlantPalApi.instance
          .inbox(unreadOnly: true, limit: 6);
      if (!mounted) return;

      var newest = _lastShownNotifId;
      for (final it in items.where((i) => i.id > _lastShownNotifId)) {
        await NotifChannel.show(
          id: it.id,
          title: it.title.isEmpty ? 'PlantPal' : it.title,
          body: it.body,
        );
        if (it.id > newest) newest = it.id;
      }
      _lastShownNotifId = newest;
      if (!mounted) return;

      final added = unread - prev;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: PP.forest,
          content: Text(
            '$added plant${added == 1 ? '' : 's'} need attention',
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: PP.bone),
          ),
          action: SnackBarAction(
            label: 'View',
            textColor: PP.lime,
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const NotificationsScreen())),
          ),
        ));
    } catch (_) {
      // Offline / not signed in yet — ignore.
    }
  }

  void _goToTab(int i) {
    if (i >= 0 && i < _pages.length) setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return RootNav(
      goToTab: _goToTab,
      child: Scaffold(
        backgroundColor: PP.bone,
        extendBody: true,
        body: IndexedStack(index: _index, children: _pages),
        bottomNavigationBar: PPBottomBar(
          currentIndex: _index,
          onSelect: _goToTab,
          onScan: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const ScanScreen())),
        ),
      ),
    );
  }
}
