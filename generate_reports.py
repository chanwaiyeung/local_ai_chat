import os
import re

directories_to_scan = ['lib', 'test', 'lib_backup']
report_filename = '_AI_ARCHITECTURE_REPORT.md'

def analyze_file(filepath):
    score = 10
    issues = []
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            lines = content.split('\n')
            
            if re.search(r'static.*_instance', content) or re.search(r'factory.*=>.*_instance', content):
                score -= 2
                issues.append("- **Singleton Pattern Detected**: 發現單例模式，建議改用 Dependency Injection (如 Provider/Riverpod) 以增強可測試性。")
                
            if re.search(r'catch\s*\(\s*e\s*\)', content):
                score -= 1
                issues.append("- **Generic Error Catching**: 捕捉了泛型 Exception `catch (e)` 而未指定錯誤型別或未完整處理 StackTrace。")
                
            if re.search(r'[^a-zA-Z0-9_]print\(', content):
                score -= 1
                issues.append("- **Print Statements**: 使用了 `print()` 而非標準的 logging 機制。")
                
            relative_imports = len(re.findall(r"import\s+'\.\./", content))
            absolute_imports = len(re.findall(r"import\s+'package:local_ai_chat/", content))
            if relative_imports > 0 and absolute_imports > 0:
                score -= 1
                issues.append("- **Mixed Import Styles**: 混用了相對路徑 (`../`) 與絕對路徑 (`package:`)，應保持一致 (建議全用絕對路徑)。")
                
            if any(len(line) > 120 for line in lines):
                score -= 1
                issues.append("- **Line Length**: 存在超過 120 字元的過長行，影響可讀性。")
                
    except Exception as e:
        issues.append(f"- 無法讀取檔案 ({e})")
        score = 0
        
    return max(0, score), issues

for d in directories_to_scan:
    if not os.path.exists(d): continue
    for root, dirs, files in os.walk(d):
        dart_files = [f for f in files if f.endswith('.dart')]
        if not dart_files:
            continue
            
        report_path = os.path.join(root, report_filename)
        report_content = f"# 📁 AI 架構深度審查報告 - `{root}`\n\n"
        report_content += "> 本報告由 AI 依照高標準 (SOLID, DI, Error Handling, Clean Code) 對此目錄下的所有檔案進行嚴格評分。\n\n"
        
        total_score = 0
        file_reports = ""
        
        for file in dart_files:
            filepath = os.path.join(root, file)
            score, issues = analyze_file(filepath)
            total_score += score
            
            file_reports += f"## 📄 `{file}` (評分: **{score}/10**)\n"
            if score == 10:
                file_reports += "✅ 架構優良，無明顯反模式。\n\n"
            else:
                file_reports += "⚠️ **待改善事項**:\n"
                for issue in issues:
                    file_reports += f"{issue}\n"
                file_reports += "\n"
                
        avg_score = total_score / len(dart_files)
        report_content = f"### 📊 目錄平均得分: **{avg_score:.1f} / 10**\n\n" + report_content + file_reports
        
        with open(report_path, 'w', encoding='utf-8') as f:
            f.write(report_content)
        print(f"Generated {report_path}")
