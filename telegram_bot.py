import json
import base64
import os
from datetime import datetime
from pathlib import Path

from telegram import Update
from telegram.ext import Application, CommandHandler, MessageHandler, filters, ContextTypes
from openai import OpenAI

TOKEN = os.environ.get("TELEGRAM_BOT_TOKEN")
if not TOKEN:
    raise SystemExit("TELEGRAM_BOT_TOKEN env var required")
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
        await update.message.reply_text("🔄 正在下載照片...")
        photo_bytes = await photo_file.download_as_bytearray()
        base64_image = base64.b64encode(photo_bytes).decode('utf-8')

        await update.message.reply_text("🔄 正在呼叫 GPT-4o-mini 分析...")

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
                    {"type": "text", "text": "請詳細分析這張照片並幫我記帳"},
                    {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{base64_image}"}}
                ]}
            ],
            max_tokens=600
        )

        analysis = response.choices[0].message.content
        return analysis

    except Exception as e:
        error_msg = f"❌ 分析失敗：{str(e)}"
        print(error_msg)
        return error_msg + "\n\n💡 提示：請確認 API Key 額度是否足夠"

# ====================== 主處理 ======================
async def handle_photo(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("📸 收到照片，正在智能分析...")

    photo_file = await context.bot.get_file(update.message.photo[-1].file_id)
    analysis = await analyze_with_vision(photo_file, update)

    await update.message.reply_text(analysis)
    await update.message.reply_text("✅ 分析完成！\n\n是否要記錄這筆支出？\n請回覆 **是** 或 **確認**")

    # 把分析結果暫存到 user_data，等待確認
    context.user_data['pending_expense'] = analysis

async def handle_text(update: Update, context: ContextTypes.DEFAULT_TYPE):
    text = update.message.text.strip().lower()
    if text in ["是", "確認", "ok", "yes"]:
        if 'pending_expense' in context.user_data:
            expense = {
                "date": datetime.now().isoformat(),
                "source": "telegram",
                "raw_analysis": context.user_data['pending_expense'],
                "status": "confirmed"
            }
            
            EXPENSE_FILE.parent.mkdir(parents=True, exist_ok=True)
            expenses = json.loads(EXPENSE_FILE.read_text(encoding="utf-8")) if EXPENSE_FILE.exists() else []
            expenses.append(expense)
            EXPENSE_FILE.write_text(json.dumps(expenses, ensure_ascii=False, indent=2), encoding="utf-8")
            
            await update.message.reply_text("💾 已成功記錄這筆支出！\n你可以在 Streamlit Hub 查看所有記錄。")
            del context.user_data['pending_expense']
        else:
            await update.message.reply_text("目前沒有待確認的支出。")
    else:
        # 非確認字眼，且有待確認項目，則取消
        if 'pending_expense' in context.user_data:
            await update.message.reply_text("已取消記錄。")
            del context.user_data['pending_expense']

def main():
    app = Application.builder().token(TOKEN).build()
    app.add_handler(CommandHandler("start", lambda u,c: u.message.reply_text("👋 Bot 已上線！傳照片即可記帳")))
    app.add_handler(MessageHandler(filters.PHOTO, handle_photo))
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_text))

    print("🤖 My Food Coach Bot (自動記帳版) 運行中... (Ctrl+C 停止)")
    app.run_polling()

if __name__ == "__main__":
    main()
