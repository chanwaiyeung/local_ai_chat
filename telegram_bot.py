import json
import base64
from datetime import datetime
from pathlib import Path

from telegram import Update
from telegram.ext import Application, CommandHandler, MessageHandler, filters, ContextTypes
from openai import OpenAI

# ====================== 設定 ======================
TOKEN = "8638032374:AAFmO_V0JM_nkBbHq16pbWgwIVHmUQtXoBU"

CONFIG_FILE = Path("config.json")

def load_config():
    if CONFIG_FILE.exists():
        try:
            return json.loads(CONFIG_FILE.read_text(encoding="utf-8"))
        except:
            return {}
    return {}

config = load_config()
client = OpenAI(api_key=config.get("openai_api_key"))

# ====================== Vision 分析 ======================
async def analyze_with_vision(photo_file, update: Update):
    try:
        await update.message.reply_text("🔄 正在下載照片...")
        photo_bytes = await photo_file.download_as_bytearray()
        base64_image = base64.b64encode(photo_bytes).decode('utf-8')

        await update.message.reply_text("🔄 正在呼叫 GPT-4o-mini 分析...")

        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": "你是一位專業的生活與財務助理。用繁體中文分析照片（食物、收據等），提取類別、金額並給建議。"},
                {"role": "user", "content": [
                    {"type": "text", "text": "請詳細分析這張照片並幫我記帳"},
                    {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{base64_image}"}}
                ]}
            ],
            max_tokens=500
        )

        analysis = response.choices[0].message.content
        return analysis

    except Exception as e:
        error_msg = f"❌ 分析失敗：{str(e)}"
        print(error_msg)
        return error_msg + "\n\n💡 提示：請確認 API Key 額度是否足夠"

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("👋 **My Food Coach Bot (OpenAI 版) 已上線！**\n\n📸 傳照片給我試試看～")

async def handle_photo(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("📸 收到照片，正在處理...")
    photo_file = await context.bot.get_file(update.message.photo[-1].file_id)
    analysis = await analyze_with_vision(photo_file, update)
    await update.message.reply_text(analysis)
    await update.message.reply_text("✅ 分析完成！")

def main():
    app = Application.builder().token(TOKEN).build()
    app.add_handler(CommandHandler("start", start))
    app.add_handler(MessageHandler(filters.PHOTO, handle_photo))

    print("🤖 My Food Coach Bot (OpenAI gpt-4o-mini) 運行中... (Ctrl+C 停止)")
    app.run_polling()

if __name__ == "__main__":
    if not config.get("openai_api_key"):
        print("⚠️ 警告：config.json 中沒有 openai_api_key")
    main()
