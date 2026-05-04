import logging
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

# ====================== 真實 Vision LLM 分析 ======================
async def analyze_with_vision(photo_file):
    try:
        # 下載照片並轉 base64
        photo_bytes = await photo_file.download_as_bytearray()
        base64_image = base64.b64encode(photo_bytes).decode('utf-8')

        response = client.chat.completions.create(
            model=config.get("default_vision_model", "gpt-4o"),
            messages=[
                {
                    "role": "system",
                    "content": "你是一位專業的個人財務與生活助理。請分析用戶上傳的照片（食物、收據、發票等），提取類別、金額、日期，並給出實用建議。用繁體中文回覆。"
                },
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": "請詳細分析這張照片並幫我記帳"},
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:image/jpeg;base64,{base64_image}"
                            }
                        }
                    ]
                }
            ],
            max_tokens=500
        )

        analysis = response.choices[0].message.content

        # 儲存記錄
        expense = {
            "date": datetime.now().isoformat(),
            "category": "待分類",   # 未來可從 LLM 解析
            "amount": 0,            # 未來可從 LLM 解析
            "note": analysis[:100], # 簡短備註
            "source": "telegram",
            "model_used": config.get("default_vision_model", "gpt-4o")
        }
        
        EXPENSE_FILE = Path("data/telegram_expenses.json")
        EXPENSE_FILE.parent.mkdir(parents=True, exist_ok=True)
        
        expenses = json.loads(EXPENSE_FILE.read_text(encoding="utf-8")) if EXPENSE_FILE.exists() else []
        expenses.append(expense)
        EXPENSE_FILE.write_text(json.dumps(expenses, ensure_ascii=False, indent=2), encoding="utf-8")

        return analysis

    except Exception as e:
        return f"❌ Vision 分析失敗：{str(e)}\n\n💡 請確認 config.json 中有正確的 OpenAI API Key"

# ====================== 指令處理 ======================
async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text(
        "👋 **My Food Coach Bot 已上線！**\n\n"
        "📸 **直接傳食物照片或收據** 給我\n"
        "我會使用 GPT-4o Vision 自動分析並記帳\n\n"
        "/expense 查看記錄\n"
        "/help 顯示說明"
    )

async def handle_photo(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("📸 收到照片，正在呼叫 GPT-4o Vision 分析...")

    photo = update.message.photo[-1]
    photo_file = await context.bot.get_file(photo.file_id)

    analysis = await analyze_with_vision(photo_file)
    
    await update.message.reply_text(analysis)
    await update.message.reply_text("✅ 已自動記錄到 Expense！")

async def expense_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    EXPENSE_FILE = Path("data/telegram_expenses.json")
    if not EXPENSE_FILE.exists():
        await update.message.reply_text("目前沒有記錄。")
        return
    
    expenses = json.loads(EXPENSE_FILE.read_text(encoding="utf-8"))
    total = sum(e.get("amount", 0) for e in expenses)
    
    await update.message.reply_text(
        f"💰 **Telegram 記錄總覽**\n"
        f"總筆數：{len(expenses)} 筆\n"
        f"總金額：NT${total:,}"
    )

# ====================== 主程式 ======================
def main():
    app = Application.builder().token(TOKEN).build()

    app.add_handler(CommandHandler("start", start))
    app.add_handler(CommandHandler("expense", expense_command))
    app.add_handler(MessageHandler(filters.PHOTO, handle_photo))

    print("🤖 My Food Coach Bot 正在運行... (Ctrl+C 停止)")
    print(f"使用 Vision 模型：{config.get('default_vision_model', 'gpt-4o')}")
    app.run_polling()

if __name__ == "__main__":
    if not config.get("openai_api_key"):
        print("⚠️ 警告：config.json 中沒有 OpenAI API Key，請先在 Streamlit Settings 設定！")
    main()
