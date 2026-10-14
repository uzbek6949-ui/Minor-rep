import 'dart:io';

import 'package:flutter/material.dart';

import '../models/song.dart';

/// Albom rasmi. Rasm bo'lmasa — chiroyli gradient va nota belgisi.
class AlbumArt extends StatelessWidget {
  const AlbumArt({
    super.key,
    required this.song,
    this.size = 52,
    this.radius = 12,
  });

  final Song? song;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final path = song?.artworkPath;
    final hasArt = path != null && File(path).existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child:
          hasArt
              ? Image.file(
                File(path),
                width: size,
                height: size,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (context, _, __) => _placeholder(scheme),
              )
              : _placeholder(scheme),
    );
  }

  Widget _placeholder(ColorScheme scheme) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            scheme.primary.withValues(alpha: 0.75),
            scheme.tertiary.withValues(alpha: 0.65),
          ],
        ),
      ),
      child: Icon(
        Icons.music_note_rounded,
        size: size * 0.45,
        color: Colors.white.withValues(alpha: 0.9),
      ),
    );
  }
}
