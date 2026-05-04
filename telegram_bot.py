import streamlit as st
import logging
from telegram import Update
from telegram.ext import Application, CommandHandler, MessageHandler, filters, ContextTypes
import asyncio
import json
from pathlib import Path
from datetime import datetime

# ====================== 設定 ======================
TOKEN = "8638032374:AAFmO_V0JM_nkBbHq16pbWgwIVHmUQtXoBU"   # ← 真實 Token

# 載入 Vision Prompt（重用我們之前做的）
try:
    from utils.vision_prompt import VISION_SYSTEM_PROMPT
except ImportError:
    VISION_SYSTEM_PROMPT = "你是一位專業的生活助理，請分析這張照片並提供實用建議。"

logging.basicConfig(level=logging.INFO)

# ====================== 指令處理 ======================
async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text(
        "👋 歡迎使用 Personal Hub Telegram Bot！\n\n"
        "功能：\n"
        "• 傳照片 → 自動分析與記帳\n"
        "• /expense 查看本月支出\n"
        "• /health 查看健康概況\n"
        "• /help 顯示所有指令"
    )

async def help_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("開發中... 更多功能即將上線！")

async def handle_photo(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """接收照片 → 呼叫 Vision LLM 分析"""
    await update.message.reply_text("📸 收到照片，正在智能分析...")

    # TODO: 後續串 Vision LLM + 自動記帳
    await update.message.reply_text(
        "✅ 分析完成！\n\n"
        "這是範例回覆（後續會接真實 Vision LLM）\n"
        "類別：飲食\n金額：NT$185\n建議：這筆消費合理，但可以多比較價格。"
    )

# ====================== 主程式 ======================
def main():
    app = Application.builder().token(TOKEN).build()

    app.add_handler(CommandHandler("start", start))
    app.add_handler(CommandHandler("help", help_command))
    app.add_handler(MessageHandler(filters.PHOTO, handle_photo))

    print("🤖 Telegram Bot 已啟動...")
    app.run_polling()

if __name__ == "__main__":
    main()
