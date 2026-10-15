/**
 * Minor Rep — Telegram boti (Cloudflare Worker).
 *
 * Nima uchun: GitHub Actions'ning jadvali (cron) kafolatlanmagan — bot
 * bir necha soatda bir marta uyg'onardi. Worker esa doim tayyor turadi
 * va Telegram har bir bosishni to'g'ridan-to'g'ri shu yerga yuboradi,
 * shuning uchun javob ~1 soniyada keladi.
 *
 * Sozlash: cloudflare/README.md
 *
 * Kerakli "secret" o'zgaruvchilar (Cloudflare → Settings → Variables):
 *   BOT_TOKEN       — @BotFather bergan token
 *   OWNER_ID        — sizning Telegram ID raqamingiz (faqat sizga javob beradi)
 *   WEBHOOK_SECRET  — o'zingiz o'ylab topgan maxfiy so'z (webhook'ni himoyalaydi)
 *   GH_TOKEN        — GitHub fine-grained token (ixtiyoriy: APK va build uchun)
 *   GH_REPO         — "uzbek6949-ui/Minor-rep"
 *   GH_BRANCH       — "claude/flutter-music-app-13la66"
 */

const KEYBOARD = {
  inline_keyboard: [
    [{ text: "📥 Oxirgi APK", callback_data: "apk" }],
    [
      { text: "🔄 Yangi build", callback_data: "build" },
      { text: "ℹ️ Holat", callback_data: "status" },
    ],
  ],
};

const MENU_TEXT =
  "*Minor Rep*\n\n" +
  "📥 *Oxirgi APK* — tayyor faylni shu yerga yuboraman\n" +
  "🔄 *Yangi build* — kodni qaytadan yig'aman (~7 daqiqa)\n" +
  "ℹ️ *Holat* — oxirgi build haqida";

export default {
  async fetch(request, env, ctx) {
    if (request.method !== "POST") {
      return new Response("Minor Rep bot ishlayapti.", { status: 200 });
    }
    // Faqat Telegram yubora oladi: maxfiy so'z sarlavhada tekshiriladi.
    if (
      env.WEBHOOK_SECRET &&
      request.headers.get("X-Telegram-Bot-Api-Secret-Token") !== env.WEBHOOK_SECRET
    ) {
      return new Response("forbidden", { status: 403 });
    }

    let update;
    try {
      update = await request.json();
    } catch {
      return new Response("bad request", { status: 400 });
    }

    // Telegramga darhol "ok" qaytaramiz, ish esa fonda davom etadi.
    ctx.waitUntil(handle(update, env));
    return new Response("ok");
  },
};

async function handle(update, env) {
  const api = `https://api.telegram.org/bot${env.BOT_TOKEN}`;
  const message = update.message;
  const callback = update.callback_query;
  const chatId = String(
    message?.chat?.id ?? callback?.message?.chat?.id ?? ""
  );

  // Faqat egasiga javob beramiz.
  if (!chatId || chatId !== String(env.OWNER_ID)) return;

  if (callback) {
    await post(api, "answerCallbackQuery", { callback_query_id: callback.id });
    const action = callback.data;
    if (action === "apk") return sendLatestApk(api, chatId, env);
    if (action === "status") return sendStatus(api, chatId, env);
    if (action === "build") return startBuild(api, chatId, env);
    return;
  }

  const text = (message?.text ?? "").trim().toLowerCase();
  if (text === "/start" || text === "/menu" || text === "menu") {
    return post(api, "sendMessage", {
      chat_id: chatId,
      text: MENU_TEXT,
      parse_mode: "Markdown",
      reply_markup: JSON.stringify(KEYBOARD),
    });
  }
  if (text === "/apk") return sendLatestApk(api, chatId, env);
  if (text === "/status") return sendStatus(api, chatId, env);

  return post(api, "sendMessage", {
    chat_id: chatId,
    text: "Quyidagi tugmalardan foydalaning:",
    reply_markup: JSON.stringify(KEYBOARD),
  });
}

function post(api, method, params) {
  return fetch(`${api}/${method}`, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams(params),
  });
}

function say(api, chatId, text) {
  return post(api, "sendMessage", { chat_id: chatId, text });
}

function github(env, path, init = {}) {
  return fetch(`https://api.github.com${path}`, {
    ...init,
    headers: {
      Authorization: `Bearer ${env.GH_TOKEN}`,
      Accept: "application/vnd.github+json",
      "User-Agent": "minor-rep-bot",
      ...(init.headers ?? {}),
    },
  });
}

async function sendLatestApk(api, chatId, env) {
  if (!env.GH_TOKEN) {
    return say(api, chatId, "GH_TOKEN sozlanmagan — APK'ni ola olmayman.");
  }
  await say(api, chatId, "Oxirgi APK qidirilmoqda...");

  const releaseResponse = await github(env, `/repos/${env.GH_REPO}/releases/latest`);
  if (!releaseResponse.ok) {
    return say(api, chatId, `Release topilmadi (${releaseResponse.status}).`);
  }
  const release = await releaseResponse.json();
  const asset =
    release.assets?.find((item) => item.name.includes("arm64")) ??
    release.assets?.[0];
  if (!asset) return say(api, chatId, "Bu release'da APK yo'q.");

  const fileResponse = await github(
    env,
    `/repos/${env.GH_REPO}/releases/assets/${asset.id}`,
    { headers: { Accept: "application/octet-stream" } }
  );
  if (!fileResponse.ok) {
    return say(api, chatId, `Fayl yuklanmadi (${fileResponse.status}).`);
  }

  const blob = await fileResponse.blob();
  const form = new FormData();
  form.append("chat_id", chatId);
  form.append(
    "caption",
    `${asset.name} (${(asset.size / 1048576).toFixed(0)} MB)\n\n` +
      "Faylni bosib o'rnating. Eski versiyani avval o'chiring."
  );
  form.append("document", blob, asset.name);

  const sent = await fetch(`${api}/sendDocument`, { method: "POST", body: form });
  if (!sent.ok) {
    await say(api, chatId, `Telegram faylni qabul qilmadi (${sent.status}).`);
  }
}

async function startBuild(api, chatId, env) {
  if (!env.GH_TOKEN) {
    return say(api, chatId, "GH_TOKEN sozlanmagan — build boshlay olmayman.");
  }
  const response = await github(
    env,
    `/repos/${env.GH_REPO}/actions/workflows/build-apk.yml/dispatches`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ ref: env.GH_BRANCH }),
    }
  );
  if (response.status === 204) {
    return say(
      api,
      chatId,
      "Build boshlandi. Tayyor bo'lgach APK shu yerga o'zi keladi (~7 daqiqa)."
    );
  }
  const detail = await response.text();
  return say(api, chatId, `Build boshlanmadi (${response.status}). ${detail.slice(0, 150)}`);
}

async function sendStatus(api, chatId, env) {
  if (!env.GH_TOKEN) return say(api, chatId, "GH_TOKEN sozlanmagan.");
  const response = await github(
    env,
    `/repos/${env.GH_REPO}/actions/workflows/build-apk.yml/runs?per_page=1`
  );
  if (!response.ok) return say(api, chatId, `Holat olinmadi (${response.status}).`);

  const data = await response.json();
  const run = data.workflow_runs?.[0];
  if (!run) return say(api, chatId, "Hali birorta build bo'lmagan.");

  const states = {
    success: "✅ muvaffaqiyatli",
    failure: "❌ xato bilan tugadi",
    cancelled: "⛔️ bekor qilindi",
    in_progress: "⏳ hozir ketyapti",
    queued: "⏳ navbatda",
  };
  const state = states[run.conclusion ?? run.status] ?? run.status;
  return say(
    api,
    chatId,
    `Oxirgi build: ${state}\n${run.display_title}\n${run.created_at}`
  );
}
