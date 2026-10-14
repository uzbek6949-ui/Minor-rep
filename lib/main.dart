import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';

import 'screens/root_screen.dart';
import 'services/storage_service.dart';
import 'state/library_controller.dart';
import 'state/player_controller.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fon rejimi: ekran o'chirilganda ham ijro davom etadi va bildirishnoma
  // orqali boshqariladi (Android: foreground service, iOS: audio background).
  await JustAudioBackground.init(
    androidNotificationChannelId: 'uz.minorrep.audio',
    androidNotificationChannelName: 'Minor Rep',
    androidNotificationOngoing: true,
    androidStopForegroundOnPause: true,
  );

  // Lokal baza — internet va login talab qilinmaydi.
  await StorageService.instance.init();

  runApp(const MinorRepApp());
}

class MinorRepApp extends StatelessWidget {
  const MinorRepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LibraryController>(
          create: (_) => LibraryController()..load(),
        ),
        ChangeNotifierProvider<PlayerController>(
          create: (_) => PlayerController(),
        ),
      ],
      child: MaterialApp(
        title: 'Minor Rep',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        // Telefon sozlamasiga ergashadi: qora rejim yoqilgan bo'lsa — qora.
        themeMode: ThemeMode.system,
        home: const RootScreen(),
      ),
    );
  }
}
