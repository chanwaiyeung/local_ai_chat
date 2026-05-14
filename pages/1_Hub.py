import streamlit as st
import pandas as pd
import plotly.express as px
from datetime import datetime, timedelta
import json
from pathlib import Path

# ====================== 假資料 / 真資料載入 ======================
def load_expense_data():
    """載入或建立 Expense 資料"""
    data_file = Path("data/expenses.json")
    data_file.parent.mkdir(parents=True, exist_ok=True)
    if data_file.exists():
        return pd.read_json(data_file)
    
    # 示範資料（第一次使用時會產生）
    data = {
        "date": pd.date_range(end=datetime.today(), periods=30).tolist(),
        "category": ["飲食", "交通", "購物", "娛樂", "飲食", "醫療", "健身"] * 4 + ["飲食"],
        "amount": [180, 65, 450, 320, 95, 680, 1200] * 4 + [220],
        "note": ["午餐", "捷運", "衣服", "電影", "飲料", "看牙", "健身房月費"] * 4 + ["晚餐"]
    }
    df = pd.DataFrame(data)
    df.to_json(data_file, orient="records", date_format="iso")
    return df

def load_health_data():
    """載入或建立 Health 資料"""
    data_file = Path("data/health.json")
    data_file.parent.mkdir(parents=True, exist_ok=True)
    if data_file.exists():
        return pd.read_json(data_file)
    
    data = {
        "date": pd.date_range(end=datetime.today(), periods=14).tolist(),
        "weight": [72.5, 72.3, 72.1, 71.8, 72.0, 71.5, 71.7] * 2,
        "steps": [8500, 9200, 6800, 12400, 7500, 9800, 11000] * 2,
        "sleep_hours": [7.5, 6.8, 8.2, 7.0, 7.8, 6.5, 8.0] * 2,
        "mood": [8, 7, 9, 6, 8, 7, 9] * 2
    }
    df = pd.DataFrame(data)
    df.to_json(data_file, orient="records", date_format="iso")
    return df

# ====================== 視覺化元件 ======================
def expense_visualization():
    st.subheader("💰 支出概覽")
    df = load_expense_data()
    
    # 總覽指標
    total = df["amount"].sum()
    avg_daily = total / 30
    col1, col2, col3 = st.columns(3)
    col1.metric("本月總支出", f"NT${total:,.0f}", "▼ 12%")
    col2.metric("日均支出", f"NT${avg_daily:,.0f}")
    col3.metric("最大單筆", f"NT${df['amount'].max():,.0f}")

    # 圓餅圖 + 長條圖
    tab1, tab2 = st.tabs(["📊 類別占比", "📅 每日趨勢"])
    
    with tab1:
        fig_pie = px.pie(df, names="category", values="amount", 
                        title="支出類別分布", hole=0.4)
        st.plotly_chart(fig_pie, use_container_width=True)
    
    with tab2:
        daily = df.groupby(df["date"].dt.date)["amount"].sum().reset_index()
        fig_bar = px.bar(daily, x="date", y="amount", 
                        title="每日支出趨勢", color="amount")
        st.plotly_chart(fig_bar, use_container_width=True)

def health_visualization():
    st.subheader("❤️ 健康追蹤")
    df = load_health_data()
    
    col1, col2, col3, col4 = st.columns(4)
    col1.metric("平均體重", f"{df['weight'].mean():.1f} kg")
    col2.metric("平均步數", f"{df['steps'].mean():,.0f}")
    col3.metric("平均睡眠", f"{df['sleep_hours'].mean():.1f} 小時")
    col4.metric("平均心情", f"{df['mood'].mean():.1f}/10")

    tab1, tab2 = st.tabs(["📈 趨勢圖", "🥗 綜合分析"])
    
    with tab1:
        fig = px.line(df, x="date", y=["weight", "steps", "sleep_hours"], 
                     title="健康指標趨勢", markers=True)
        st.plotly_chart(fig, use_container_width=True)
    
    with tab2:
        st.info("💡 建議：本週平均步數偏低，建議增加每日活動量。睡眠品質不錯，繼續保持！")

# ====================== 主 Hub 呼叫方式 ======================
def render_hub_dashboard():
    st.title("🌟 Personal Hub")
    
    col_exp, col_health = st.columns(2)
    
    with col_exp:
        expense_visualization()
    
    with col_health:
        health_visualization()

# ====================== 執行 ======================
if __name__ == "__main__":
    render_hub_dashboard()
