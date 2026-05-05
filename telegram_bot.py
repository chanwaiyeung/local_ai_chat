import json
import asyncio
from datetime import datetime
from pathlib import Path

from telegram import Update
from telegram.ext import Application, CommandHandler, MessageHandler, filters, ContextTypes
import google.generativeai as genai
from PIL import Image
import io

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

# 設定 Gemini
if config.get("google_api_key"):
    genai.configure(api_key=config.get("google_api_key"))
    model = genai.GenerativeModel('gemini-1.5-flash')
else:
    print("⚠️ 警告：config.json 中沒有 google_api_key")
    model = None

# ====================== Vision 分析 ======================
async def analyze_with_vision(photo_file, update: Update):
    if not model:
        return "❌ Gemini API Key 未設定，請先在 Settings 頁面設定 Google Gemini API Key"

    try:
        await update.message.reply_text("🔄 正在下載照片...")
        photo_bytes = await photo_file.download_as_bytearray()
        
        await update.message.reply_text("🔄 正在呼叫 Gemini 1.5 Flash 分析...")

        image = Image.open(io.BytesIO(photo_bytes))

        response = model.generate_content([
            "你是一位專業的生活與財務助理。請用繁體中文分析這張照片（食物、收據等），告訴我這是什麼、可能的金額、類別，並給實用建議。",
            image
        ])

        analysis = response.text
        return analysis

    except Exception as e:
        error_msg = f"❌ Gemini 分析失敗：{str(e)}"
        print(error_msg)
        return error_msg + "\n\n💡 請確認 Google Gemini API Key 是否正確設定"

# ====================== 指令 ======================
async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("👋 **My Food Coach Bot (Gemini 版) 已上線！**\n\n📸 傳照片給我試試看～")

async def handle_photo(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("📸 收到照片，正在處理...")

    photo_file = await context.bot.get_file(update.message.photo[-1].file_id)
    analysis = await analyze_with_vision(photo_file, update)
    
    await update.message.reply_text(analysis)
    await update.message.reply_text("✅ 分析完成！")

async def expense_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("💰 目前 Telegram 記錄功能開發中...")

def main():
    app = Application.builder().token(TOKEN).build()
    app.add_handler(CommandHandler("start", start))
    app.add_handler(CommandHandler("expense", expense_command))
    app.add_handler(MessageHandler(filters.PHOTO, handle_photo))

    print("🤖 My Food Coach Bot (Gemini 版) 運行中... (Ctrl+C 停止)")
    app.run_polling()

if __name__ == "__main__":
    main()
