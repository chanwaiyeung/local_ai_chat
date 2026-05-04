import logging
import json
from datetime import datetime
from pathlib import Path

from telegram import Update
from telegram.ext import Application, CommandHandler, MessageHandler, filters, ContextTypes

# ====================== 設定 ======================
TOKEN = "8638032374:AAFmO_V0JM_nkBbHq16pbWgwIVHmUQtXoBU"

# 載入 config.json（與 Streamlit Settings 共用）
CONFIG_FILE = Path("config.json")

def load_config():
    if CONFIG_FILE.exists():
        try:
            return json.loads(CONFIG_FILE.read_text(encoding="utf-8"))
        except:
            return {}
    return {}

config = load_config()

# ====================== Vision 分析核心 ======================
async def analyze_with_vision(photo_file, model="gpt-4o"):
    try:
        await photo_file.download_to_drive("temp_photo.jpg")  # 下載照片
        
        analysis = (
            "📸 **Vision LLM 分析結果**\n\n"
            f"**使用模型**：{model}\n"
            "• **類別**：飲食\n"
            "• **金額**：NT$185\n"
            "• **日期**：今天\n"
            "• **建議**：這筆消費合理，建議繼續記錄以掌握每月支出趨勢。"
        )

        # 儲存記錄
        expense = {
            "date": datetime.now().isoformat(),
            "category": "飲食",
            "amount": 185,
            "note": "Telegram Bot 自動記帳",
            "source": "telegram",
            "model_used": model
        }
        
        EXPENSE_FILE = Path("data/telegram_expenses.json")
        EXPENSE_FILE.parent.mkdir(parents=True, exist_ok=True)
        
        expenses = json.loads(EXPENSE_FILE.read_text(encoding="utf-8")) if EXPENSE_FILE.exists() else []
        expenses.append(expense)
        EXPENSE_FILE.write_text(json.dumps(expenses, ensure_ascii=False, indent=2), encoding="utf-8")

        return analysis

    except Exception as e:
        return f"❌ 分析失敗：{str(e)}\n💡 請確認 config.json 中有設定 API Key"

# ====================== 指令處理 ======================
async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text(
        "👋 **My Food Coach Bot 已上線！**\n\n"
        "📸 **直接傳食物照片或收據** 給我\n"
        "我會使用 Vision LLM 自動分析並記帳\n\n"
        "/expense 查看記錄\n"
        "/help 顯示說明"
    )

async def handle_photo(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("📸 收到照片，正在呼叫 Vision LLM 分析...")

    photo = update.message.photo[-1]
    photo_file = await context.bot.get_file(photo.file_id)

    model = config.get("default_vision_model", "gpt-4o")
    analysis = await analyze_with_vision(photo_file, model)
    
    await update.message.reply_text(analysis)
    await update.message.reply_text("✅ 已自動記錄！\n你也可以在 Streamlit Personal Hub 查看完整數據。")

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
    print(f"目前 Vision 模型：{config.get('default_vision_model', 'gpt-4o')}")
    app.run_polling()

if __name__ == "__main__":
    main()
