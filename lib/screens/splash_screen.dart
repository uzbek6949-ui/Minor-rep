import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state/library_controller.dart';
import 'root_screen.dart';

/// Ilova ochilganda ko'rinadigan birinchi ekran.
///
/// Rasm ko'rsatilib turganda kutubxona fonda yuklanadi, shuning uchun
/// bosh ekran darhol to'la holda ochiladi.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  /// Rasm kamida shuncha vaqt ko'rinadi (kutubxona tezroq yuklansa ham).
  static const Duration minimumDuration = Duration(milliseconds: 1900);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Holat paneli oq bo'lsin — rasm qora.
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  Future<void> _open() async {
    final library = context.read<LibraryController>();
    final started = DateTime.now();

    // Kutubxona yuklanishini kutamiz (bo'sh bo'lsa ham tez tugaydi).
    while (library.isLoading && mounted) {
      await Future<void>.delayed(const Duration(milliseconds: 60));
    }

    final elapsed = DateTime.now().difference(started);
    final remaining = SplashScreen.minimumDuration - elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
    if (!mounted) return;

    SystemChrome.setSystemUIOverlayStyle(
      Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
    );

    await Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 550),
        pageBuilder: (_, __, ___) => const RootScreen(),
        transitionsBuilder:
            (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            // Rasm to'liq ko'rinadi (chetlari qirqilmaydi) — ustidagi yozuv
            // ham joyida qoladi. Foni qora bo'lgani uchun chekkalar bilinmaydi.
            Image.asset(
              'assets/images/splash.jpg',
              fit: BoxFit.contain,
              errorBuilder:
                  (_, __, ___) => const ColoredBox(color: Colors.black),
            ),
            Positioned(
              bottom: 42,
              child: SizedBox(
                width: 110,
                child: LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: Colors.white.withValues(alpha: 0.20),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
