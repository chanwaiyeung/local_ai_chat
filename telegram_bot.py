import json
from datetime import datetime
from pathlib import Path

from telegram import Update
from telegram.ext import Application, CommandHandler, MessageHandler, filters, ContextTypes

# ====================== 設定 ======================
TOKEN = "8638032374:AAFmO_V0JM_nkBbHq16pbWgwIVHmUQtXoBU"

# ====================== 模擬 Vision 分析 ======================
async def analyze_with_vision(photo_file):
    # 純模擬，不呼叫 OpenAI
    analysis = (
        "📸 **模擬 Vision 分析結果**\n\n"
        "• **類別**：飲食\n"
        "• **金額**：NT$168\n"
        "• **日期**：今天\n"
        "• **建議**：這筆消費看起來不錯！記得記錄下來追蹤每月支出喔～"
    )

    # 儲存記錄
    expense = {
        "date": datetime.now().isoformat(),
        "category": "飲食",
        "amount": 168,
        "note": "模擬 Bot 記帳",
        "source": "telegram"
    }
    
    EXPENSE_FILE = Path("data/telegram_expenses.json")
    EXPENSE_FILE.parent.mkdir(parents=True, exist_ok=True)
    
    expenses = json.loads(EXPENSE_FILE.read_text(encoding="utf-8")) if EXPENSE_FILE.exists() else []
    expenses.append(expense)
    EXPENSE_FILE.write_text(json.dumps(expenses, ensure_ascii=False, indent=2), encoding="utf-8")

    return analysis

# ====================== 指令 ======================
async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text(
        "👋 **My Food Coach Bot 已上線！（模擬模式）**\n\n"
        "📸 直接傳食物或收據照片給我即可測試\n"
        "/expense 查看記錄"
    )

async def handle_photo(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("📸 收到照片，正在分析...")
    photo_file = await context.bot.get_file(update.message.photo[-1].file_id)
    analysis = await analyze_with_vision(photo_file)
    await update.message.reply_text(analysis)
    await update.message.reply_text("✅ 已幫你記錄！")

async def expense_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    file = Path("data/telegram_expenses.json")
    if not file.exists():
        await update.message.reply_text("目前沒有記錄。")
        return
    expenses = json.loads(file.read_text(encoding="utf-8"))
    total = sum(e.get("amount", 0) for e in expenses)
    await update.message.reply_text(f"💰 目前總金額：NT${total:,}（{len(expenses)} 筆）")

# ====================== 主程式 ======================
def main():
    app = Application.builder().token(TOKEN).build()
    app.add_handler(CommandHandler("start", start))
    app.add_handler(CommandHandler("expense", expense_command))
    app.add_handler(MessageHandler(filters.PHOTO, handle_photo))

    print("🤖 My Food Coach Bot 運行中（模擬模式）... (Ctrl+C 停止)")
    app.run_polling()

if __name__ == "__main__":
    main()
