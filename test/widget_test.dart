import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minor_rep/models/song.dart';
import 'package:minor_rep/widgets/album_art.dart';
import 'package:minor_rep/widgets/empty_state.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('EmptyState', () {
    testWidgets('sarlavha, matn va tugmani ko’rsatadi', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(
          EmptyState(
            icon: Icons.music_note_rounded,
            title: 'Kutubxona bo’sh',
            message: 'Audio fayl qo’shing',
            action: FilledButton(
              onPressed: () => tapped = true,
              child: const Text('Fayl tanlash'),
            ),
          ),
        ),
      );

      expect(find.text('Kutubxona bo’sh'), findsOneWidget);
      expect(find.text('Audio fayl qo’shing'), findsOneWidget);
      expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);

      await tester.tap(find.text('Fayl tanlash'));
      expect(tapped, isTrue);
    });

    testWidgets('matn va tugmasiz ham ishlaydi', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const EmptyState(icon: Icons.search_off_rounded, title: 'Topilmadi'),
        ),
      );
      expect(find.text('Topilmadi'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    });
  });

  group('AlbumArt', () {
    testWidgets('rasmsiz qo’shiq uchun o’rindosh ko’rsatiladi', (tester) async {
      final song = Song(
        id: '1',
        filePath: '/music/a.mp3',
        title: 'Test',
        artist: 'Test',
      );

      await tester.pumpWidget(_wrap(AlbumArt(song: song, size: 64)));

      expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('qo’shiq null bo’lsa ham yiqilmaydi', (tester) async {
      await tester.pumpWidget(_wrap(const AlbumArt(song: null)));
      expect(find.byType(AlbumArt), findsOneWidget);
    });
  });
}
