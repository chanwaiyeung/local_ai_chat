import asyncio
import base64
import json
import io
from pathlib import Path
from telegram import Update
from telegram.ext import Application, CommandHandler, MessageHandler, filters, ContextTypes
import google.generativeai as genai
import PIL.Image

TOKEN = "8638032374:AAFmO_V0JM_nkBbHq16pbWgwIVHmUQtXoBU"

# 載入 API Key
config = {}
config_path = Path("config.json")
if config_path.exists():
    config = json.loads(config_path.read_text(encoding="utf-8"))

google_api_key = config.get("google_api_key")
if google_api_key:
    genai.configure(api_key=google_api_key)

async def analyze_with_vision(photo_file, update):
    try:
        if not google_api_key:
            return "❌ 系統錯誤：config.json 中沒有設定 google_api_key"

        await update.message.reply_text("🔄 下載照片中...")
        photo_bytes = await photo_file.download_as_bytearray()

        await update.message.reply_text("🔄 呼叫 Gemini (1.5 Flash) 分析中 (附帶重試機制)...")

        image = PIL.Image.open(io.BytesIO(photo_bytes))
        model = genai.GenerativeModel('gemini-1.5-flash')
        prompt = "你是一位專業的個人財務助理。用繁體中文分析照片，提取類別、金額並給建議。"

        max_retries = 3
        for attempt in range(max_retries):
            try:
                response = await model.generate_content_async([prompt, image])
                break
            except Exception as e:
                if "429" in str(e) or "quota" in str(e).lower() or "rate limit" in str(e).lower():
                    if attempt < max_retries - 1:
                        wait_time = (attempt + 1) * 3
                        await update.message.reply_text(f"⚠️ 觸發 Gemini API 限制，等待 {wait_time} 秒後重試...")
                        await asyncio.sleep(wait_time)
                        continue
                raise e

        analysis = response.text
        return analysis

    except Exception as e:
        return f"❌ 分析失敗：{str(e)}"

# ====================== 指令 ======================
async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("👋 **My Food Coach Bot (Gemini 版) 已上線！**\n\n📸 傳一張食物或收據照片給我試試看！")

async def handle_photo(update: Update, context: ContextTypes.DEFAULT_TYPE):
    photo_file = await context.bot.get_file(update.message.photo[-1].file_id)
    analysis = await analyze_with_vision(photo_file, update)
    await update.message.reply_text(analysis)
    await update.message.reply_text("✅ Gemini 流程執行完畢！")

# ====================== 主程式 ======================
def main():
    app = Application.builder().token(TOKEN).build()
    app.add_handler(CommandHandler("start", start))
    app.add_handler(MessageHandler(filters.PHOTO, handle_photo))

    print("🤖 My Food Coach Bot (Gemini 版) 運行中... (按 Ctrl+C 停止)")
    app.run_polling()

if __name__ == "__main__":
    if not google_api_key:
        print("⚠️ 警告：config.json 中沒有 google_api_key！請先在設定檔補上金鑰。")
    main()
