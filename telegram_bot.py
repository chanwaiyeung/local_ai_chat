import json
import base64
from datetime import datetime
from pathlib import Path

from telegram import Update, ReplyKeyboardMarkup, KeyboardButton
from telegram.ext import Application, CommandHandler, MessageHandler, filters, ContextTypes, ConversationHandler
from openai import OpenAI

TOKEN = "8638032374:AAFmO_V0JM_nkBbHq16pbWgwIVHmUQtXoBU"

CONFIG_FILE = Path("config.json")
EXPENSE_FILE = Path("data/telegram_expenses.json")

def load_config():
    if CONFIG_FILE.exists():
        try:
            return json.loads(CONFIG_FILE.read_text(encoding="utf-8"))
        except:
            return {}
    return {}

config = load_config()
client = OpenAI(api_key=config.get("openai_api_key"))

# ====================== 自動解析 ======================
async def analyze_with_vision(photo_file, update: Update):
    try:
        await update.message.reply_text("🔄 正在分析收據...")
        
        photo_bytes = await photo_file.download_as_bytearray()
        base64_image = base64.b64encode(photo_bytes).decode('utf-8')

        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {"role": "system", "content": """你是一位非常細心的記帳助理。
請從收據照片中提取以下資訊，用**繁體中文**詳細回覆：

1. **商店名稱**
2. **總金額**
3. **主要類別**（飲食/購物/日用品/醫療/其他）
4. **逐項明細**（把所有商品都列出來，包括品名、單價、數量）
5. **簡短建議**

請同時以 JSON 格式輸出結構化資料（方便後續存檔）：
{
  "store": "商店名稱",
  "total": 總金額,
  "category": "主要類別",
  "items": [
    {"name": "商品名稱", "price": 單價, "quantity": 數量}
  ],
  "description": "簡短描述"
}
"""},
                {"role": "user", "content": [
                    {"type": "text", "text": "請分析這張收據"},
                    {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{base64_image}"}}
                ]}
            ],
            max_tokens=400
        )

        analysis = response.choices[0].message.content
        return analysis

    except Exception as e:
        return f"❌ 分析失敗：{str(e)}"

# ====================== 主處理 ======================
async def handle_photo(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("📸 收到照片，正在智能分析...")

    photo_file = await context.bot.get_file(update.message.photo[-1].file_id)
    result = await analyze_with_vision(photo_file, update)

    await update.message.reply_text(result)
    await update.message.reply_text("✅ 已分析完成！是否要記錄這筆支出？\n\n回覆「是」或「確認」即可記錄")

# ====================== 其他指令 ======================
async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text(
        "👋 **My Food Coach Bot 已優化！**\n\n"
        "📸 傳收據或食物照片給我\n"
        "我會自動分析並幫你記帳"
    )

def main():
    app = Application.builder().token(TOKEN).build()
    app.add_handler(CommandHandler("start", start))
    app.add_handler(MessageHandler(filters.PHOTO, handle_photo))

    print("🤖 My Food Coach Bot (優化版) 運行中... (Ctrl+C 停止)")
    app.run_polling()

if __name__ == "__main__":
    main()
