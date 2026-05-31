# Office Local AI VBA 範本使用指南

本目錄包含 Microsoft Office 與 WPS Office 的本機 AI 整合巨集模組 (`.bas`)，供快速匯入與配置使用。

## 📦 檔案結構
- `word_local_ai.bas`：Word / WPS Writer 巨集（包含文句摘要、語氣優化、會議紀錄整理）。
- `excel_local_ai.bas`：Excel / WPS Spreadsheets 巨集（包含公式生成、表格分析、月報摘要）。
- `outlook_local_ai.bas`：Outlook 郵件巨集（包含草擬回信、郵件摘要）。

---

## 🛠️ 匯入與配置說明

### 步驟 1：啟用開發人員工具
1. 開啟 Word 或 Excel。
2. 依序點選「檔案」→「選項」→「自訂功能區」。
3. 在右側清單中，勾選「開發人員」分頁，點擊「確定」。

### 步驟 2：匯入 VBA 模組
1. 開啟 Word/Excel，按 `Alt + F11` 組合鍵開啟 VBA 編輯器。
2. 點選選單列的「檔案」→「匯入檔案...」 (Import File)。
3. 選取本目錄下對應的 `.bas` 檔案（例如 `word_local_ai.bas`）。
4. 匯入後，您將在左側專案總管的「模組」資料夾下看到匯入的程式碼。

### 步驟 3：配置 API 憑證 (Token)
1. 展開匯入的模組，找到 `CallLocalAI` 函式。
2. 將以下程式碼中的 `YOUR_LOCAL_TOKEN` 替換成您在生活/教會APP設定頁面中產生的 Token：
   ```vba
   http.setRequestHeader "Authorization", "Bearer YOUR_LOCAL_TOKEN"
   ```
3. 按 `Ctrl + S` 儲存專案，關閉 VBA 編輯器。

### 步驟 4：設定快捷鍵或按鈕 (選用)
1. 在 Word 中，點擊「開發人員」分頁下的「巨集」。
2. 選取巨集（如 `LocalAI_WordSummarize`）並點擊「執行」以進行測試。
3. 您可以透過「自訂快速存取工具列」，為常用的 AI 巨集建立專屬的工具按鈕或鍵盤快捷鍵。

---

## ⚠️ 常見問題與安全性設定
1. **安全性警告（禁止巨集）**：
   - 如果巨集無法運行，請點擊「開發人員」分頁的「巨集安全性」，將設定調整為「停用所有巨集，並發出通知」或「啟用所有巨集 (不建議)」。
2. **WPS Office 相容性**：
   - WPS Office 需要先安裝 **WPS VBA 支援模組 (VBA Support Library)** 才能執行此巨集。請確保系統已安裝此環境。
3. **無法連線至 Server**：
   - 請確保生活APP或教會APP正在執行，且設定頁面中的 **Office Bridge** 開關已開啟，連接埠設定為 `61670`。
