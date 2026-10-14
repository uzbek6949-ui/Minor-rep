import 'package:flutter/material.dart';

import '../widgets/app_bottom_nav.dart';
import '../widgets/mini_player.dart';
import 'playlists_screen.dart';
import 'search_screen.dart';
import 'songs_screen.dart';

/// Ilovaning asosiy "qobig'i": pastdagi navigatsiya + mini pleer.
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _index = 0;

  static const List<Widget> _pages = <Widget>[
    SongsScreen(),
    PlaylistsScreen(),
    SearchScreen(),
  ];

  static const List<AppBottomNavItem> _items = <AppBottomNavItem>[
    AppBottomNavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Bosh sahifa',
    ),
    AppBottomNavItem(
      icon: Icons.library_music_outlined,
      activeIcon: Icons.library_music_rounded,
      label: 'Playlistlar',
    ),
    AppBottomNavItem(
      icon: Icons.search_rounded,
      activeIcon: Icons.search_rounded,
      label: 'Qidiruv',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const MiniPlayer(),
          AppBottomNav(
            currentIndex: _index,
            onChanged: (value) => setState(() => _index = value),
            items: _items,
          ),
        ],
      ),
    );
  }
}
