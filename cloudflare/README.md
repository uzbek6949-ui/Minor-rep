# Telegram botni Cloudflare Worker'da ishga tushirish

Bot shu yerda ishlaganda tugmalarga **~1 soniyada** javob beradi.
Bepul, kartasiz. Sozlash bir marta, ~10 daqiqa.

> Nega kerak bo'ldi: avval bot GitHub Actions'da, jadval bo'yicha ishlardi.
> GitHub jadvalni kafolatlamaydi — amalda bot 5,5 soatda atigi 2 marta
> uyg'ondi, shuning uchun tugmalar "ishlamayotgandek" tuyuldi.

---

## 1. Cloudflare akkaunt

1. https://dash.cloudflare.com/sign-up — email va parol bilan ro'yxatdan o'ting
2. Emaildagi havolani bosib tasdiqlang

## 2. Worker yaratish

1. Chap menyudan **Workers & Pages** → **Create** → **Start with Hello World!** → **Deploy**
2. Nom: masalan `minor-rep-bot`
3. **Edit code** tugmasini bosing
4. Oynadagi hamma kodni o'chirib, shu repozitoriyadagi
   [`cloudflare/worker.js`](worker.js) faylining **to'liq matnini** qo'ying
5. **Deploy** tugmasini bosing

Tepada Worker manzili ko'rinadi, masalan:
`https://minor-rep-bot.<sizning-nomingiz>.workers.dev` — uni nusxalab oling.

## 3. Maxfiy o'zgaruvchilar

Worker sahifasida: **Settings** → **Variables and Secrets** → har biri uchun
**Add** → turi **Secret** (Text emas!) → nomi va qiymati:

| Nomi | Qiymati |
|---|---|
| `BOT_TOKEN` | @BotFather bergan token |
| `OWNER_ID` | Telegram ID raqamingiz (@userinfobot beradi) |
| `WEBHOOK_SECRET` | O'zingiz o'ylab topgan so'z, masalan `minor-rep-2026-xyz` |
| `GH_TOKEN` | GitHub token (4-bo'limda olasiz) |
| `GH_REPO` | `uzbek6949-ui/Minor-rep` |
| `GH_BRANCH` | `claude/flutter-music-app-13la66` |

Oxirida yana **Deploy** bosing.

## 4. GitHub token (APK va build tugmalari uchun)

1. https://github.com/settings/personal-access-tokens/new
2. **Token name:** `minor-rep-bot`
3. **Expiration:** 1 year
4. **Repository access:** *Only select repositories* → **Minor-rep**
5. **Permissions → Repository permissions:**
   - **Contents:** Read-only  (release fayllarini olish uchun)
   - **Actions:** Read and write  (build boshlash uchun)
6. **Generate token** → ko'ringan qiymatni nusxalab, Worker'dagi `GH_TOKEN`
   secret'iga qo'ying

> Tokenni hech kimga yubormang va chatga yozmang.

## 5. Telegramni Worker'ga ulash

Brauzerda shu manzilni oching (o'zingiznikini qo'yib):

```
https://api.telegram.org/bot<BOT_TOKEN>/setWebhook?url=<WORKER_URL>&secret_token=<WEBHOOK_SECRET>
```

Javobda `{"ok":true,...,"description":"Webhook was set"}` chiqsa — tayyor.

## 6. Tekshirish

Telegramda botga **`/start`** yozing — uchta tugma darhol chiqishi kerak:

- 📥 **Oxirgi APK** — tayyor faylni yuboradi
- 🔄 **Yangi build** — yangi build boshlaydi, tugagach APK o'zi keladi
- ℹ️ **Holat** — oxirgi build qanday tugagani

---

## Muammo bo'lsa

| Belgi | Sabab va yechim |
|---|---|
| `/start` ga javob yo'q | Webhook ulanmagan: 5-qadamni qayta bajaring. Tekshirish: `https://api.telegram.org/bot<TOKEN>/getWebhookInfo` |
| "GH_TOKEN sozlanmagan" | 4-qadamdagi token qo'shilmagan yoki Deploy bosilmagan |
| Release topilmadi (404) | Token'da Contents ruxsati yo'q yoki repo noto'g'ri |
| Build boshlanmadi (403) | Token'da Actions: Read and write ruxsati yo'q |
| Hech narsa, log ham yo'q | Cloudflare → Worker → **Logs** bo'limini oching, xato ko'rinadi |

## Eslatma

Webhook ulangandan keyin GitHub Actions'dagi eski bot (`.github/workflows/bot.yml`)
**ishlamaydi** — Telegram bir vaqtda ikkalasiga xabar bermaydi. Shu sababli uning
jadvali o'chirilgan; faylning o'zi zaxira sifatida qoldirilgan (webhook'ni
o'chirsangiz, uni qayta yoqish mumkin).

Build tugagach APK yuborish esa avvalgidek ishlayveradi — u Worker'ga bog'liq emas.
