# Platforma sozlamalari

> ✅ **Bu sozlamalar repozitoriyda allaqachon qilingan.** Hujjat quyidagi
> maqsadlarda saqlanadi: nima uchun kerakligini tushunish, loyihani noldan
> qayta yaratish yoki `android/` va `ios/` papkalarini qayta generatsiya
> qilgandan keyin tiklash.
>
> Bu sozlamalarsiz ilova ishlaydi, lekin **ekran o'chganda musiqa to'xtab
> qoladi**.

Allaqachon qilingan ishlar:

| Fayl | Nima qilingan |
|---|---|
| `android/app/src/main/AndroidManifest.xml` | `WAKE_LOCK`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`, `POST_NOTIFICATIONS`, `READ_MEDIA_AUDIO` ruxsatlari + `AudioService` xizmati va `MediaButtonReceiver` |
| `android/app/src/main/kotlin/.../MainActivity.kt` | `AudioServiceActivity` dan meros |
| `android/app/build.gradle.kts` | `minSdk = 23` |
| `ios/Runner/Info.plist` | `UIBackgroundModes: audio`, hujjat brauzeri va galereya ruxsati matni |

Qolgan yagona qo'lda qadam — iOS uchun `pod install` (quyida, 2.2).

---

## 1. Android

### 1.1 `android/app/src/main/AndroidManifest.xml`

`<manifest>` ichida, `<application>` dan **oldin** quyidagi ruxsatlarni
qo'shing:

```xml
<!-- Fon rejimida ijro (just_audio_background) -->
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK" />
<!-- Android 13+ uchun ijro bildirishnomasi -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<!-- Audio fayllarni o'qish (Android 13+) -->
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
```

Android 12 va pastroq versiyalar uchun (ixtiyoriy):

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32" />
```

`<application>` ichida, `<activity>` dan **keyin** audio xizmat va
media tugmalari qabul qiluvchisini qo'shing:

```xml
<service
    android:name="com.ryanheise.audioservice.AudioService"
    android:foregroundServiceType="mediaPlayback"
    android:exported="true"
    tools:ignore="Instantiatable">
    <intent-filter>
        <action android:name="android.media.browse.MediaBrowserService" />
    </intent-filter>
</service>

<receiver
    android:name="com.ryanheise.audioservice.MediaButtonReceiver"
    android:exported="true"
    tools:ignore="Instantiatable">
    <intent-filter>
        <action android:name="android.intent.action.MEDIA_BUTTON" />
    </intent-filter>
</receiver>
```

`tools:` prefiksi ishlashi uchun `<manifest>` tegiga quyidagini qo'shing:

```xml
xmlns:tools="http://schemas.android.com/tools"
```

### 1.2 `android/app/src/main/.../MainActivity.kt`

`just_audio_background` `AudioServiceActivity` dan meros olishni talab qiladi:

```kotlin
package uz.minorrep.minor_rep   // o'zingizning package nomingiz

import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity : AudioServiceActivity()
```

### 1.3 `android/app/build.gradle.kts` (yoki `build.gradle`)

```kotlin
android {
    compileSdk = 35
    defaultConfig {
        minSdk = 23        // just_audio talabi
        targetSdk = 35
    }
}
```

---

## 2. iOS

### 2.1 `ios/Runner/Info.plist`

`<dict>` ichiga qo'shing:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>

<!-- Fayllar ilovasidan audio tanlash uchun -->
<key>UISupportsDocumentBrowser</key>
<true/>
<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>

<!-- Albom rasmini galereyadan tanlash uchun -->
<key>NSPhotoLibraryUsageDescription</key>
<string>Albom rasmini tanlash uchun galereyaga ruxsat kerak.</string>
```

### 2.2 `ios/Podfile`

`Podfile` birinchi iOS build'da generatsiya qilinadi. Ichidagi birinchi
qatorni tekshirib qo'ying (kerak bo'lsa izohdan chiqaring):

```ruby
platform :ios, '13.0'
```

So'ngra:

```bash
cd ios && pod install && cd ..
```

`just_audio` iOS 12+ talab qiladi; 13.0 — xavfsiz tanlov.

---

## 3. Tekshirish ro'yxati

- [ ] `flutter pub get` xatosiz tugadi
- [ ] Ilova ochildi, "Qo'shiq qo'shish" tugmasi fayl tanlash oynasini ochdi
- [ ] Qo'shiq ijro etilyapti, progress bar harakatlanadi
- [ ] **Ekranni o'chirdim — musiqa davom etdi** (fon rejimi ishlaydi)
- [ ] Bildirishnomadagi play/pause/next tugmalari ishlaydi
- [ ] Playlist yaratildi, qo'shiq qo'shildi
- [ ] Lyrics yozildi, saqlandi va qayta ochilganda joyida turdi

---

## 4. Tez-tez uchraydigan muammolar

| Muammo | Yechim |
|---|---|
| Ekran o'chganda musiqa to'xtaydi | `UIBackgroundModes` / `AudioService` qo'shilmagan (1.1, 2.1) |
| Android'da bildirishnoma chiqmaydi | `POST_NOTIFICATIONS` ruxsati berilmagan (Sozlamalar → Ilova) |
| `MainActivity` xatosi | `AudioServiceActivity` dan meros olinmagan (1.2) |
| `minSdkVersion` xatosi | `minSdk = 23` qilib qo'ying (1.3) |
| iOS'da fayl tanlab bo'lmaydi | `pod install` bajarilmagan yoki `platform :ios, '13.0'` yo'q |
