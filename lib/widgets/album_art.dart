import 'dart:io';

import 'package:flutter/material.dart';

import '../models/song.dart';
import '../theme/app_theme.dart';

/// Albom rasmi. Rasm bo'lmasa — nozik gradient va nota belgisi.
class AlbumArt extends StatelessWidget {
  const AlbumArt({
    super.key,
    required this.song,
    this.size = 52,
    this.radius = AppRadii.tile,
    this.shadow,
  });

  final Song? song;
  final double size;
  final double radius;

  /// Soya: katta rasm uchun [AppShadows.artwork], qatorlar uchun yengil.
  final List<BoxShadow>? shadow;

  @override
  Widget build(BuildContext context) {
    final path = song?.artworkPath;
    final hasArt = path != null && File(path).existsSync();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: hasArt
            ? Image.file(
                File(path),
                width: size,
                height: size,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (context, _, __) => _placeholder(context),
              )
            : _placeholder(context),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLight
              ? const <Color>[Color(0xFFDFE3EA), Color(0xFFC4CAD4)]
              : const <Color>[Color(0xFF272B32), Color(0xFF171A1F)],
        ),
      ),
      child: Icon(
        Icons.music_note_rounded,
        size: size * 0.42,
        color: isLight ? AppColors.inkSoft : AppColors.darkInkSoft,
      ),
    );
  }
}
