import streamlit as st
import json
import os
from pathlib import Path

# ====================== 設定檔管理 ======================
CONFIG_FILE = Path("config.json")

def load_config():
    """載入設定檔"""
    if CONFIG_FILE.exists():
        try:
            with open(CONFIG_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
        except:
            return {}
    return {}

def save_config(config: dict):
    """儲存設定檔"""
    try:
        with open(CONFIG_FILE, "w", encoding="utf-8") as f:
            json.dump(config, f, ensure_ascii=False, indent=2)
        return True
    except:
        return False

# ====================== Settings 頁面 ======================
def settings_page():
    st.set_page_config(page_title="Settings", page_icon="⚙️", layout="centered")
    
    st.title("⚙️ 設定中心")
    st.markdown("### 管理 API Keys、模型與應用程式偏好設定")

    config = load_config()

    # ====================== API Keys ======================
    with st.expander("🔑 API Keys", expanded=True):
        st.markdown("**輸入後點擊下方「儲存所有設定」即可生效**")

        col1, col2 = st.columns(2)
        
        with col1:
            openai_key = st.text_input(
                "🌐 OpenAI API Key",
                value=config.get("openai_api_key", ""),
                type="password",
                placeholder="sk-XXXXXXXXXXXXXXXXXXXX",
                help="用於 GPT-4o、GPT-4o-mini 等"
            )
            
            anthropic_key = st.text_input(
                "🦾 Anthropic API Key (Claude)",
                value=config.get("anthropic_api_key", ""),
                type="password",
                placeholder="sk-ant-...",
                help="用於 Claude 3.5 Sonnet"
            )

        with col2:
            # 支援 google_api_key 與 gemini_api_key 雙重讀取，避免名稱不一致導致讀不到
            gemini_val = config.get("google_api_key", config.get("gemini_api_key", ""))
            google_key = st.text_input(
                "🔍 Google Gemini API Key",
                value=gemini_val,
                type="password",
                placeholder="AIzaSy...",
                help="用於 Gemini 1.5 Pro / Flash"
            )

        # 設定狀態顯示
        st.markdown("**目前設定狀態**")
        cols = st.columns(3)
        
        if openai_key.strip():
            cols[0].success("✅ OpenAI")
        else:
            cols[0].error("❌ OpenAI")
            
        if anthropic_key.strip():
            cols[1].success("✅ Anthropic")
        else:
            cols[1].error("❌ Anthropic")
            
        if google_key.strip():
            cols[2].success("✅ Gemini")
        else:
            cols[2].error("❌ Gemini")

    # ====================== 模型選擇 ======================
    with st.expander("🧠 模型設定", expanded=True):
        st.subheader("聊天模型 (Chat)")
        chat_model = st.selectbox(
            "預設聊天模型",
            options=[
                "gpt-4o", "gpt-4o-mini", 
                "claude-3-5-sonnet-20240620",
                "gemini-1.5-pro", "gemini-1.5-flash"
            ],
            index=0
        )

        st.subheader("Vision 模型 (照片分析)")
        vision_model = st.selectbox(
            "Vision 模型",
            options=["gpt-4o", "claude-3-5-sonnet-20240620", "gemini-1.5-pro"],
            index=0
        )

    # ====================== 其他偏好 ======================
    with st.expander("🎨 其他偏好設定", expanded=False):
        theme = st.selectbox("介面主題", ["Light", "Dark", "System"], index=2)
        language = st.selectbox("介面語言", ["繁體中文", "English"], index=0)

    # ====================== 儲存按鈕 ======================
    col1, col2 = st.columns([4, 1])
    
    with col1:
        if st.button("💾 儲存所有設定", type="primary", use_container_width=True):
            new_config = {
                "openai_api_key": openai_key.strip(),
                "anthropic_api_key": anthropic_key.strip(),
                "google_api_key": google_key.strip(),
                "gemini_api_key": google_key.strip(), # 同步寫入雙名稱確保相容性
                "default_chat_model": chat_model,
                "default_vision_model": vision_model,
                "theme": theme,
                "language": language,
            }
            
            if save_config(new_config):
                st.success("✅ 設定已成功儲存！")
                st.rerun()
            else:
                st.error("❌ 儲存失敗，請檢查權限")

    with col2:
        if st.button("🔄 重置設定", use_container_width=True):
            if st.checkbox("確認要清除所有設定？", value=False):
                CONFIG_FILE.unlink(missing_ok=True)
                st.success("已清除設定")
                st.rerun()

    st.caption("💡 設定變更後請重新整理頁面或切換分頁生效")

# ====================== 主程式 ======================
if __name__ == "__main__":
    settings_page()
