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
                {"role": "system", "content": """你是一位極其細心、專業的超市收據記帳助理。

請從照片中**精準提取**以下資訊，並用繁體中文回覆：

**文字分析部分**（先顯示給使用者看）：
- 商店名稱
- 總金額（CAD）
- 逐項明細（商品名稱、單價、數量、小計）
- 主要消費類別
- 簡短實用建議

**同時必須輸出標準 JSON**（放在最後，用 ```json 包起來）：
{
  "store": "商店名稱",
  "total": 總金額,
  "category": "主要類別（例如：飲食、日用品、蔬果）",
  "items": [
    {
      "name": "完整商品名稱",
      "price": 單價,
      "quantity": 數量,
      "subtotal": 小計
    }
  ],
  "description": "簡短描述"
}

請務必準確辨識每個商品名稱，不要遺漏。金額請使用數字。"""},
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
