@Tags(<String>['preview'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:minor_rep/models/song.dart';
import 'package:minor_rep/theme/app_theme.dart';
import 'package:minor_rep/utils/formatters.dart';
import 'package:minor_rep/widgets/album_art.dart';
import 'package:minor_rep/widgets/app_bottom_nav.dart';
import 'package:minor_rep/widgets/mini_player_bar.dart';
import 'package:minor_rep/widgets/player_controls.dart';
import 'package:minor_rep/widgets/song_row.dart';
import 'package:minor_rep/widgets/waveform_progress.dart';

/// Dizaynni ko'z bilan tekshirish uchun "golden" rasmlar.
///
/// Yangilash: flutter test --update-goldens test/design_preview_test.dart
/// Natija: test/preview/*.png
///
/// Bu testlar ko'rinishni rasmga oladi — ilovaning haqiqiy holatiga bog'liq
/// emas, shuning uchun plaginlarsiz ishlaydi.
Future<void> _loadFonts() async {
  final loader = FontLoader(AppTheme.fontFamily);
  for (final name in <String>[
    'Poppins-Regular',
    'Poppins-Medium',
    'Poppins-SemiBold',
    'Poppins-Bold',
  ]) {
    final bytes = await File('assets/fonts/$name.ttf').readAsBytes();
    loader.addFont(Future<ByteData>.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
  await _loadMaterialIcons();
}

/// Ikonkalar rasmda ko'rinishi uchun Flutter SDK'dagi shriftni yuklaymiz.
/// Topilmasa — test baribir ishlaydi (ikonkalar bo'sh kvadrat bo'lib chiqadi).
Future<void> _loadMaterialIcons() async {
  final flutterRoot =
      Platform.environment['FLUTTER_ROOT'] ??
      (Platform.resolvedExecutable.contains('/bin/cache/')
          ? Platform.resolvedExecutable.split('/bin/cache/').first
          : null);
  if (flutterRoot == null) return;
  final file = File(
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (!file.existsSync()) return;
  final loader = FontLoader('MaterialIcons')..addFont(
    Future<ByteData>.value(ByteData.view((await file.readAsBytes()).buffer)),
  );
  await loader.load();
}

Song _song(String title, String artist, int seconds, {bool favorite = false}) =>
    Song(
      id: '$title-$artist',
      filePath: '/music/$title.mp3',
      title: title,
      artist: artist,
      album: 'Lightdream',
      durationMs: seconds * 1000,
      isFavorite: favorite,
    );

Widget _frame(Widget child, {bool dark = false}) => MediaQuery(
  data: const MediaQueryData(size: Size(390, 844)),
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: dark ? AppTheme.dark() : AppTheme.light(),
    home: child,
  ),
);

void main() {
  setUpAll(_loadFonts);

  // Har bir ekran ikki mavzuda rasmga olinadi: yorug' va qora.
  for (final dark in <bool>[false, true]) {
    final suffix = dark ? ' (qora)' : ' (yorug’)';

    testWidgets('pleer ekrani ko’rinishi$suffix', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final song = _song('Unsayable', 'Brambles', 172, favorite: true);

      await tester.pumpWidget(
        _frame(
          dark: dark,
          Scaffold(
            body: SafeArea(
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
                    child: Row(
                      children: <Widget>[
                        const IconButton(
                          onPressed: null,
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 30,
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Hozir ijroda',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.queue_music_rounded, size: 26),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(28, 4, 28, 20),
                      child: Column(
                        children: <Widget>[
                          const SizedBox(height: 16),
                          AlbumArt(
                            song: song,
                            size: 302,
                            radius: AppRadii.artwork,
                            shadow: AppShadows.artwork(
                              dark ? Brightness.dark : Brightness.light,
                            ),
                          ),
                          const SizedBox(height: 34),
                          Row(
                            children: <Widget>[
                              const IconButton(
                                onPressed: null,
                                icon: Icon(Icons.favorite),
                              ),
                              Expanded(
                                child: Column(
                                  children: <Widget>[
                                    Text(
                                      song.title,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 25,
                                        fontWeight: FontWeight.w700,
                                        height: 1.15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${song.displayArtist} • ${song.album}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        color:
                                            dark
                                                ? AppColors.darkInkSoft
                                                : AppColors.inkSoft,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: null,
                                icon: Icon(
                                  Icons.more_horiz_rounded,
                                  color:
                                      dark
                                          ? AppColors.darkInkSoft
                                          : AppColors.inkSoft,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 26),
                          WaveformProgress(
                            seed: song.id,
                            position: const Duration(seconds: 64),
                            duration: song.duration,
                            onSeek: (_) {},
                          ),
                          const SizedBox(height: 14),
                          const PlayerControls(
                            isPlaying: false,
                            shuffleEnabled: false,
                            loopMode: LoopMode.off,
                          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.subject_rounded,
                                  size: 19,
                                ),
                                label: const Text('Lyrics'),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.queue_music_rounded,
                                  size: 19,
                                ),
                                label: Text(songCountLabel(8)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('preview/player${dark ? '-dark' : ''}.png'),
      );
    });

    testWidgets('bosh ekran ko’rinishi$suffix', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final songs = <Song>[
        _song('To Speak Of Solitude', 'Brambles', 261),
        _song('Unsayable', 'Brambles', 172, favorite: true),
        _song('In The Androgynous Dark', 'Brambles', 283),
        _song('Salt Photographs', 'Brambles', 414),
        _song('Pink And Golden Billows', 'Brambles', 178),
      ];

      await tester.pumpWidget(
        _frame(
          dark: dark,
          Scaffold(
            appBar: AppBar(
              titleSpacing: 20,
              title: const Text('Minor Rep'),
              actions: <Widget>[
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.favorite_border_rounded),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.swap_vert_rounded),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.add_rounded),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        songCountLabel(songs.length),
                        style: TextStyle(
                          fontSize: 13.5,
                          color:
                              dark ? AppColors.darkInkSoft : AppColors.inkSoft,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.play_circle_outline_rounded,
                                size: 21,
                              ),
                              label: const Text('Ijro'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.shuffle_rounded, size: 19),
                              label: const Text('Tasodifiy'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(top: 4),
                    children: <Widget>[
                      for (var i = 0; i < songs.length; i++)
                        SongRow(
                          song: songs[i],
                          isCurrent: i == 1,
                          isPlaying: i == 1,
                          onTap: () {},
                          onMenu: () {},
                        ),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                MiniPlayerBar(
                  song: songs[1],
                  isPlaying: true,
                  progress: 0.37,
                  onTap: () {},
                  onPlayPause: () {},
                  onFavorite: () {},
                ),
                const AppBottomNav(
                  currentIndex: 0,
                  onChanged: _noop,
                  items: <AppBottomNavItem>[
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
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('preview/home${dark ? '-dark' : ''}.png'),
      );
    });
  }

  // Ochilish (splash) ekrani — bitta ko'rinish, mavzuga bog'liq emas.
  testWidgets('ochilish ekrani ko\u2019rinishi', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(
      _frame(
        dark: true,
        Scaffold(
          backgroundColor: Colors.black,
          body: SizedBox.expand(
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Image.asset('assets/images/splash.jpg', fit: BoxFit.contain),
                Positioned(
                  bottom: 42,
                  child: SizedBox(
                    width: 110,
                    child: LinearProgressIndicator(
                      minHeight: 2,
                      backgroundColor: Colors.white.withValues(alpha: 0.20),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    // Rasm haqiqatan yuklanishi uchun (test muhitida avtomatik bo'lmaydi).
    await tester.runAsync(() async {
      for (final element in find.byType(Image).evaluate()) {
        await precacheImage((element.widget as Image).image, element);
      }
    });
    await tester.pump(const Duration(milliseconds: 300));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('preview/splash.png'),
    );
  });
}

void _noop(int value) {}
