import base64
import json
from pathlib import Path
from telegram import Update
from telegram.ext import Application, CommandHandler, MessageHandler, filters, ContextTypes
from openai import OpenAI

TOKEN = "8638032374:AAFmO_V0JM_nkBbHq16pbWgwIVHmUQtXoBU"

# 載入 API Key
config = {}
config_path = Path("config.json")
if config_path.exists():
    config = json.loads(config_path.read_text(encoding="utf-8"))

client = OpenAI(api_key=config.get("openai_api_key"))

async def analyze_with_vision(photo_file, update):
    try:
        await update.message.reply_text("🔄 下載照片中...")
        photo_bytes = await photo_file.download_as_bytearray()
        base64_image = base64.b64encode(photo_bytes).decode('utf-8')

        await update.message.reply_text("🔄 呼叫 GPT-4o 分析中...")

        response = client.chat.completions.create(
            model="gpt-4o",
            messages=[
                {"role": "system", "content": "用繁體中文分析照片，提取類別、金額並給建議。"},
                {"role": "user", "content": [
                    {"type": "text", "text": "請幫我分析這張照片並記帳"},
                    {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{base64_image}"}}
                ]}
            ],
            max_tokens=400
        )

        analysis = response.choices[0].message.content
        return analysis

    except Exception as e:
        return f"❌ 分析失敗：{str(e)}"

# ====================== 指令 ======================
async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("👋 **My Food Coach Bot 除錯版已上線！**\n\n📸 傳一張食物或收據照片給我試試看！")

async def handle_photo(update: Update, context: ContextTypes.DEFAULT_TYPE):
    photo_file = await context.bot.get_file(update.message.photo[-1].file_id)
    analysis = await analyze_with_vision(photo_file, update)
    await update.message.reply_text(analysis)
    await update.message.reply_text("✅ 除錯版流程執行完畢！")

# ====================== 主程式 ======================
def main():
    app = Application.builder().token(TOKEN).build()
    app.add_handler(CommandHandler("start", start))
    app.add_handler(MessageHandler(filters.PHOTO, handle_photo))

    print("🤖 My Food Coach Bot 除錯版運行中... (按 Ctrl+C 停止)")
    app.run_polling()

if __name__ == "__main__":
    if not config.get("openai_api_key"):
        print("⚠️ 警告：config.json 中沒有 openai_api_key！")
    main()
