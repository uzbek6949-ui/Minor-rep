"""Minor Rep uchun oddiy Telegram boti (GitHub Actions ichida ishlaydi).

Server talab qilmaydi: har safar ishga tushganda Telegramdan yangi
xabarlarni oladi, tugmalarga javob beradi va to'xtaydi.

Tugmalar:
  Oxirgi APK  — eng so'nggi release'dagi APK'ni yuboradi
  Yangi build — ushbu ishga tushishning o'zida yangi build boshlanadi
  Holat       — oxirgi build haqida qisqa ma'lumot

Faqat egasi (TELEGRAM_CHAT_ID) bilan muloqot qiladi — boshqa
foydalanuvchilarning xabarlari e'tiborsiz qoldiriladi.
"""

import json
import os
import subprocess
import sys
import urllib.parse
import urllib.request

TOKEN = os.environ["TELEGRAM_BOT_TOKEN"]
OWNER = str(os.environ["TELEGRAM_CHAT_ID"]).strip()
REPO = os.environ.get("GITHUB_REPOSITORY", "")
API = f"https://api.telegram.org/bot{TOKEN}"

KEYBOARD = {
    "inline_keyboard": [
        [{"text": "📥 Oxirgi APK", "callback_data": "apk"}],
        [
            {"text": "🔄 Yangi build", "callback_data": "build"},
            {"text": "ℹ️ Holat", "callback_data": "status"},
        ],
    ]
}

MENU_TEXT = (
    "*Minor Rep*\n\n"
    "📥 *Oxirgi APK* — tayyor faylni shu yerga yuboraman\n"
    "🔄 *Yangi build* — kodni qaytadan yig'aman (~7 daqiqa), "
    "tayyor bo'lgach APK o'zi keladi\n"
    "ℹ️ *Holat* — oxirgi build haqida"
)


def call(method: str, params: dict) -> dict:
    """Telegram API'ga oddiy (fayl yubormaydigan) so'rov."""
    data = urllib.parse.urlencode(params).encode()
    request = urllib.request.Request(f"{API}/{method}", data=data)
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            return json.load(response)
    except Exception as error:  # tarmoq uzilsa ham bot yiqilmasin
        print(f"{method} xatosi: {error}", file=sys.stderr)
        return {"ok": False}


def send(text: str, keyboard: bool = False) -> None:
    params = {"chat_id": OWNER, "text": text, "parse_mode": "Markdown"}
    if keyboard:
        params["reply_markup"] = json.dumps(KEYBOARD)
    call("sendMessage", params)


def run(command: list) -> tuple:
    result = subprocess.run(command, capture_output=True, text=True)
    return result.returncode, result.stdout.strip(), result.stderr.strip()


def send_latest_apk() -> None:
    """Oxirgi release'dagi arm64 APK'ni yuklab olib, Telegramga yuboradi."""
    send("Oxirgi APK qidirilmoqda...")
    code, out, err = run(
        ["gh", "release", "list", "--limit", "1", "--json", "tagName"]
    )
    if code != 0 or not out:
        send(f"Release topilmadi.\n`{err[:200]}`")
        return

    tag = json.loads(out)[0]["tagName"]
    os.makedirs("apk", exist_ok=True)
    code, _, err = run(
        [
            "gh", "release", "download", tag,
            "--pattern", "*arm64.apk",
            "--dir", "apk",
            "--clobber",
        ]
    )
    files = [f for f in os.listdir("apk") if f.endswith(".apk")] if code == 0 else []
    if not files:
        send(f"APK yuklab olinmadi.\n`{err[:200]}`")
        return

    path = os.path.join("apk", files[0])
    size_mb = os.path.getsize(path) / (1024 * 1024)
    caption = (
        f"{files[0]} ({size_mb:.0f} MB)\n\n"
        "Faylni bosib o'rnating. Eski versiyani avval o'chiring."
    )
    code, _, err = run(
        [
            "curl", "-sS", "-f",
            "-F", f"chat_id={OWNER}",
            "-F", f"caption={caption}",
            "-F", f"document=@{path}",
            f"{API}/sendDocument",
        ]
    )
    if code != 0:
        send(f"Fayl yuborilmadi: `{err[:200]}`")


def send_status() -> None:
    code, out, _ = run(
        [
            "gh", "run", "list",
            "--workflow", "build-apk.yml",
            "--limit", "1",
            "--json", "status,conclusion,createdAt,displayTitle",
        ]
    )
    if code != 0 or not out:
        send("Holat aniqlanmadi.")
        return
    run_info = json.loads(out)[0]
    status = run_info.get("conclusion") or run_info.get("status")
    nice = {
        "success": "✅ muvaffaqiyatli",
        "failure": "❌ xato bilan tugadi",
        "in_progress": "⏳ hozir ketyapti",
        "queued": "⏳ navbatda",
        "cancelled": "⛔️ bekor qilindi",
    }.get(status, status)
    send(
        f"*Oxirgi build:* {nice}\n"
        f"_{run_info.get('displayTitle', '')}_\n"
        f"{run_info.get('createdAt', '')}"
    )


def main() -> None:
    updates = call("getUpdates", {"timeout": 0, "limit": 50})
    results = updates.get("result", []) if updates.get("ok") else []
    if not results:
        print("Yangi xabar yo'q.")
        return

    last_id = results[-1]["update_id"]
    build_requested = False

    for update in results:
        message = update.get("message") or {}
        callback = update.get("callback_query") or {}
        chat_id = str(
            (message.get("chat") or callback.get("message", {}).get("chat", {})).get(
                "id", ""
            )
        )
        # Faqat egasiga javob beramiz.
        if chat_id != OWNER:
            continue

        if callback:
            call("answerCallbackQuery", {"callback_query_id": callback["id"]})
            action = callback.get("data")
            if action == "apk":
                send_latest_apk()
            elif action == "status":
                send_status()
            elif action == "build":
                build_requested = True
                send("Build boshlandi — tayyor bo'lgach APK shu yerga keladi (~7 daqiqa).")
        elif message.get("text"):
            text = message["text"].strip().lower()
            if text in ("/start", "/menu", "menu", "boshlash"):
                send(MENU_TEXT, keyboard=True)
            elif text == "/apk":
                send_latest_apk()
            elif text == "/status":
                send_status()
            else:
                send("Quyidagi tugmalardan foydalaning:", keyboard=True)

    # Shu xabarlarni "o'qildi" deb belgilaymiz, aks holda keyingi safar
    # yana qayta ishlanadi.
    call("getUpdates", {"offset": last_id + 1, "timeout": 0})

    output = os.environ.get("GITHUB_OUTPUT")
    if output:
        with open(output, "a", encoding="utf-8") as handle:
            handle.write(f"build={'true' if build_requested else 'false'}\n")
    print(f"Bajarildi. Build so'raldimi: {build_requested}. Repo: {REPO}")


if __name__ == "__main__":
    main()
