# Minor Rep 🎵

**Minor Rep** — Flutter'da yozilgan shaxsiy, **offline** musiqa pleeri.
Login/parol yo'q, server yo'q, internet talab qilinmaydi — barcha ma'lumot
faqat telefoningizda (lokal Hive bazasida) saqlanadi.

Android va iOS uchun bitta kod bazasi.

---

## Imkoniyatlar

### 🎧 Musiqa boshqaruvi
- Telefon xotirasidan `mp3`, `m4a`, `aac`, `wav`, `flac`, `ogg`, `opus`,
  `aiff`, `wma` fayllarini **bir vaqtda bir nechta** tanlab yuklash
  (`file_picker`).
- Fayl ilova papkasiga ko'chiriladi — ilovani qayta ochganda ham yo'l
  amal qiladi (iOS'da bu muhim). **Asl fayl hech qachon o'chirilmaydi.**
- Har bir qo'shiq uchun: nomi, ijrochisi, albomi, janri, davomiyligi va
  albom rasmi.
- **ID3 teglari avtomatik o'qiladi** (ID3v2.2/2.3/2.4 va ID3v1): nom,
  ijrochi, albom, janr, davomiylik (`TLEN`), albom rasmi (`APIC`) va hatto
  ichiga joylangan qo'shiq so'zlari (`USLT`). Buning uchun qo'shimcha paket
  emas, ilova ichidagi sof Dart parser ishlatiladi
  (`lib/services/id3_reader.dart`).
- Teg bo'lmasa: nom fayl nomidan olinadi, davomiylik pleer orqali
  aniqlanadi, qolganini qo'lda tahrirlash mumkin.

### ▶️ Pleer
- Play / pause, keyingi / oldingi, **progress bar** (surib ko'chirish bilan).
- **Shuffle** (tasodifiy tartib) va **repeat** (o'chirilgan → barchasi →
  bitta qo'shiq).
- **Fon rejimi**: ekran o'chirilganda ham musiqa to'xtamaydi, bildirishnoma
  (Android) va boshqaruv markazi (iOS) orqali boshqariladi
  (`just_audio` + `just_audio_background`).
- Navbat (queue) ro'yxati — istalgan qo'shiqqa o'tish.
- "Oldingi" tugmasi 3 sekunddan keyin qo'shiqni boshidan boshlaydi.

### 📝 Lyrics (qo'shiq so'zlari)
- Pleer ekranida **Lyrics** tugmasi.
- Matnni qo'lda yozish yoki qo'yib (paste) qo'shish, keyinchalik tahrirlash.
- Matn bor qo'shiqlar ro'yxatda alohida belgi bilan ko'rsatiladi.
- Matn darhol lokal bazaga saqlanadi.

### 📂 Playlistlar
- Yangi playlist yaratish, nomini o'zgartirish, o'chirish.
- Qo'shiqlarni qo'shish (bir vaqtda bir nechta) va olib tashlash
  (chapga surib yuborish ham ishlaydi).
- Playlist ichida qo'shiqlar tartibini o'zgartirish (uzoq bosib surish).
- Playlistni to'liq yoki tasodifiy tartibda ijro etish.

### 🔍 Qidiruv va filtr
- Nom, ijrochi, albom va janr bo'yicha qidiruv (bir nechta so'z bilan).
- **Janr** va **playlist** bo'yicha filtr (chip'lar).
- Tartiblash: nomi, ijrochisi, yangi qo'shilganlar, davomiyligi bo'yicha.
- Sevimlilar (❤️) ro'yxati.

### 📱 Ekranlar
| Ekran | Fayl |
|---|---|
| Bosh ekran — barcha qo'shiqlar | `lib/screens/songs_screen.dart` |
| Playlistlar | `lib/screens/playlists_screen.dart` |
| Playlist ichi | `lib/screens/playlist_detail_screen.dart` |
| Qidiruv | `lib/screens/search_screen.dart` |
| Pleer (katta albom rasmi) | `lib/screens/player_screen.dart` |
| Lyrics | `lib/screens/lyrics_screen.dart` |
| Qo'shiqni tahrirlash | `lib/screens/song_edit_screen.dart` |

Har bir ekran pastida **mini pleer** turadi.

---

## Ishga tushirish

Android va iOS papkalari repozitoriyada va **fon rejimi uchun allaqachon
sozlangan** (ruxsatlar, `AudioService`, `UIBackgroundModes`) — qo'shimcha
qo'lda o'zgartirish kerak emas.

```bash
# Flutter 3.29 yoki yangiroq kerak
flutter --version

flutter pub get
flutter run
```

iOS'da birinchi marta:

```bash
cd ios && pod install && cd ..
flutter run
```

**`docs/SETUP.md`** — platforma sozlamalari nima uchun kerakligi, nimalar
allaqachon qilingani va tez-tez uchraydigan muammolar ro'yxati.

### Testlar

```bash
flutter analyze   # 0 ogohlantirish
flutter test      # 21 test
```

Testlar: ID3 parser (v2.3 freymlari, UTF-16/UTF-8, APIC, USLT, ID3v1,
buzilgan va mavjud bo'lmagan fayllar), modellar (saqlash/tiklash),
formatlash va widget'lar.

> Loyiha Flutter 3.35.5 (Dart 3.9.2) da tekshirildi: `flutter analyze` —
> xatosiz, `flutter test` — 21/21 o'tdi. Haqiqiy qurilmada (APK/IPA) build
> qilish Android SDK / Xcode talab qiladi.

---

## Texnik qarorlar

| Mavzu | Qaror | Sababi |
|---|---|---|
| Audio | `just_audio` + `just_audio_background` | Gapless ijro, navbat, fon rejimi, iOS+Android |
| Baza | `hive` (`Map` ko'rinishida) | Tez, lokal, `build_runner` kerak emas |
| Holat | `provider` (`ChangeNotifier`) | Oddiy va shaffof, 2 ta controller yetarli |
| Fayl tanlash | `file_picker` | Ikki platformada ham tizim dialogi |
| Teg o'qish | ilova ichidagi `Id3Reader` | Qo'shimcha bog'liqlik yo'q, testlar bilan qoplangan |

Barcha paketlar bepul va ochiq manbali.

### Arxitektura

```
lib/
├── main.dart                 # JustAudioBackground + Hive init, Provider
├── models/                   # Song, Playlist (toMap/fromMap)
├── services/
│   ├── id3_reader.dart       # sof Dart ID3v1/ID3v2 parser
│   ├── metadata_service.dart # teg + davomiylik + albom rasmini saqlash
│   └── storage_service.dart  # Hive box'lari
├── state/
│   ├── library_controller.dart  # kutubxona, playlistlar, qidiruv, import
│   └── player_controller.dart   # just_audio o'rami (shuffle/repeat/queue)
├── screens/                  # 7 ekran + root (bottom navigation)
├── widgets/                  # SongTile, MiniPlayer, AlbumArt, ...
├── theme/app_theme.dart      # Material 3, qora-binafsha uslub
└── utils/formatters.dart
```

### Ma'lumot qayerda saqlanadi

- Hive bazasi: ilovaning hujjatlar papkasi (`songs`, `playlists`,
  `settings` box'lari).
- Audio fayllar: `<app documents>/music/`
- Albom rasmlari: `<app documents>/artwork/`

Hammasi qurilma ichida; ilova o'chirilsa, bu ma'lumotlar ham o'chadi
(telefon xotirasidagi asl fayllaringiz joyida qoladi).

---

## Keyingi qadamlar (ixtiyoriy)

- Vaqt bo'yicha sinxronlanadigan lyrics (`.lrc`).
- Ekvalayzer va ijro tezligi (`setSpeed` allaqachon tayyor).
- Statistika: eng ko'p eshitilgan qo'shiqlar.
- Kutubxonani zaxiralash (eksport/import).
