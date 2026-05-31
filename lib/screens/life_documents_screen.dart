// lib/screens/life_documents_screen.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/book_controller.dart';
import '../controllers/expense_controller.dart';
import '../controllers/health_controller.dart';
import '../controllers/wealth_controller.dart';
import '../main.dart'; // import globalOllama
import '../models/expense.dart';
import '../services/personal_rag_service.dart';

enum ActiveTool {
  none,
  finance,
  health,
  books,
  ocr,
  annualReview,
  travel,
}

class LifeDocumentsScreen extends StatefulWidget {
  final ExpenseController expenseController;
  final WealthController wealthController;
  final HealthController healthController;
  final BookController bookController;
  final PersonalRagService? ragService;

  const LifeDocumentsScreen({
    super.key,
    required this.expenseController,
    required this.wealthController,
    required this.healthController,
    required this.bookController,
    this.ragService,
  });

  @override
  State<LifeDocumentsScreen> createState() => _LifeDocumentsScreenState();
}

class _LifeDocumentsScreenState extends State<LifeDocumentsScreen> {
  ActiveTool _activeTool = ActiveTool.none;
  bool _isLoading = false;
  String _generatedResult = '';

  // Controllers for config fields
  final TextEditingController _customInstructionsController =
      TextEditingController();
  final TextEditingController _ocrTextController = TextEditingController();
  final TextEditingController _travelDestController = TextEditingController();

  // Selected config values
  String _selectedBookId = 'all';
  String _selectedTravelBudget = '輕奢享受';
  String _selectedTravelStyle = '美食Shopping與休閒';

  @override
  void dispose() {
    _customInstructionsController.dispose();
    _ocrTextController.dispose();
    _travelDestController.dispose();
    super.dispose();
  }

  void _clearState() {
    setState(() {
      _generatedResult = '';
      _isLoading = false;
      _customInstructionsController.clear();
      _ocrTextController.clear();
      _travelDestController.clear();
      _selectedBookId = 'all';
      _selectedTravelBudget = '輕奢享受';
      _selectedTravelStyle = '美食Shopping與休閒';
    });
  }

  // --- Data Gatherers ---

  String _gatherFinanceData() {
    final now = DateTime.now();
    final expenses =
        widget.expenseController.getMonthlyExpenses(now.year, now.month);
    final expenseSummary =
        widget.expenseController.getMonthlySummary(now.year, now.month);
    final wealthTotals = widget.wealthController.getCurrentTotalByCurrency();

    final buf = StringBuffer();
    buf.writeln('【${now.year}年${now.month}月 家庭財務數據摘要】');
    buf.writeln();
    buf.writeln('--- 支出明細 (本月共 ${expenses.length} 筆) ---');
    if (expenses.isEmpty) {
      buf.writeln('無支出紀錄');
    } else {
      for (final e in expenses) {
        buf.writeln(
            '- 日期: ${e.date.toIso8601String().substring(0, 10)}, 金額: ${e.amount} ${e.currency}, 分類: ${e.category}, 商戶: ${e.merchant}, 備註: ${e.notes}');
      }
      buf.writeln();
      buf.writeln('--- 各幣別支出總計 ---');
      for (final entry in expenseSummary.entries) {
        buf.writeln('- ${entry.key}: ${entry.value}');
      }
    }

    buf.writeln();
    buf.writeln('--- 資產與淨值明細 ---');
    if (wealthTotals.isEmpty) {
      buf.writeln('無資產紀錄');
    } else {
      for (final entry in wealthTotals.entries) {
        buf.writeln('- 幣別: ${entry.key}, 總金額: ${entry.value}');
      }
      final assets = widget.wealthController.getAllRecords();
      buf.writeln();
      buf.writeln('--- 各項資產明細 ---');
      for (final a in assets) {
        buf.writeln(
            '- 資產名稱: ${a.assetName}, 金額: ${a.amount} ${a.currency}, 類型: ${a.assetType}, 備註: ${a.notes}');
      }
    }
    return buf.toString();
  }

  String _gatherHealthData() {
    final records = widget.healthController.getRecordsLastNDays(30);
    final stats = widget.healthController.getStats(lastNDays: 30);

    final buf = StringBuffer();
    buf.writeln('【近 30 天個人健康數據摘要】');
    buf.writeln();
    buf.writeln('- 總記錄筆數: ${stats.recordCount} 筆');
    if (stats.avgWeight != null) {
      buf.writeln(
          '- 體重: 平均 ${stats.avgWeight!.toStringAsFixed(1)} kg (最低: ${stats.minWeight!.toStringAsFixed(1)}, 最高: ${stats.maxWeight!.toStringAsFixed(1)})');
    }
    if (stats.avgSystolic != null) {
      buf.writeln(
          '- 平均血壓: ${stats.avgSystolic!.toStringAsFixed(0)}/${stats.avgDiastolic!.toStringAsFixed(0)} mmHg');
    }
    if (stats.avgHeartRate != null) {
      buf.writeln('- 平均靜止心率: ${stats.avgHeartRate!.toStringAsFixed(0)} bpm');
    }
    buf.writeln(
        '- 近30天總步數: ${stats.totalSteps} 步 (有記錄的天數: ${stats.stepsCount} 天)');
    if (stats.avgSleepHours != null) {
      buf.writeln('- 平均睡眠時間: ${stats.avgSleepHours!.toStringAsFixed(1)} 小時');
    }

    buf.writeln();
    buf.writeln('--- 每日健康日誌明細 ---');
    if (records.isEmpty) {
      buf.writeln('無近 30 天健康記錄');
    } else {
      for (final r in records) {
        final parts = <String>[];
        if (r.weight != null) parts.add('體重 ${r.weight}kg');
        if (r.systolic != null) {
          parts.add('血壓 ${r.systolic}/${r.diastolic} mmHg');
        }
        if (r.heartRate != null) parts.add('心率 ${r.heartRate} bpm');
        if (r.steps != null) parts.add('步數 ${r.steps}步');
        if (r.sleepHours != null) parts.add('睡眠 ${r.sleepHours}小時');
        if (r.notes.isNotEmpty) parts.add('備註: ${r.notes}');
        buf.writeln(
            '- 日期: ${r.date.toIso8601String().substring(0, 10)}: ${parts.join("，")}');
      }
    }
    return buf.toString();
  }

  String _gatherReadingData() {
    final books = widget.bookController.getAllBooks();
    final buf = StringBuffer();
    if (_selectedBookId == 'all') {
      buf.writeln('【個人書庫與讀書心得總覽】');
      buf.writeln();
      for (final b in books) {
        buf.writeln('- 書名: ${b.title}');
        buf.writeln(
            '  作者: ${b.author}, 分類: ${b.category}, 評分: ${b.rating ?? "未評分"}');
        if (b.notes.isNotEmpty) {
          buf.writeln('  筆記與心得: ${b.notes}');
        }
        buf.writeln();
      }
    } else {
      final b = books.firstWhere((element) => element.id == _selectedBookId,
          orElse: () => books.first);
      buf.writeln('【專屬讀書筆記與心得整理】');
      buf.writeln('- 書名: ${b.title}');
      buf.writeln('- 作者: ${b.author}');
      buf.writeln('- 分類: ${b.category}');
      buf.writeln('- 評分: ${b.rating ?? "未評分"}');
      buf.writeln('- 新增時間: ${b.addedAt.toIso8601String().substring(0, 10)}');
      buf.writeln('- 閱讀狀態: ${b.isRead ? "已讀完" : (b.isReading ? "閱讀中" : "待讀")}');
      buf.writeln('- 用戶心得筆記:\n${b.notes}');
    }
    return buf.toString();
  }

  String _gatherAnnualData() {
    final now = DateTime.now();
    final expenses = widget.expenseController.expenses;
    final wealthTotals = widget.wealthController.getCurrentTotalByCurrency();
    final healthRecords = widget.healthController.getAllRecords();
    final books = widget.bookController.getAllBooks();

    final buf = StringBuffer();
    buf.writeln('【${now.year}年度個人生活數據匯總】');
    buf.writeln();
    buf.writeln('--- 財務支出總覽 ---');
    buf.writeln('- 全年總支出筆數: ${expenses.length} 筆');
    final expSum = <String, double>{};
    for (final e in expenses) {
      expSum.update(e.currency, (v) => v + e.amount, ifAbsent: () => e.amount);
    }
    for (final entry in expSum.entries) {
      buf.writeln(
          '  * 總支出金額 (${entry.key}): ${entry.value.toStringAsFixed(0)}');
    }

    buf.writeln();
    buf.writeln('--- 年度資產配置現況 ---');
    for (final entry in wealthTotals.entries) {
      buf.writeln('  * 淨值現況 (${entry.key}): ${entry.value.toStringAsFixed(0)}');
    }

    buf.writeln();
    buf.writeln('--- 年度健康指標統計 ---');
    buf.writeln('- 年度總健康量測筆數: ${healthRecords.length} 筆');
    final stats = widget.healthController.getStats();
    if (stats.avgWeight != null) {
      buf.writeln('  * 平均體重: ${stats.avgWeight!.toStringAsFixed(1)} kg');
    }
    if (stats.avgSystolic != null) {
      buf.writeln(
          '  * 平均血壓: ${stats.avgSystolic!.toStringAsFixed(0)}/${stats.avgDiastolic!.toStringAsFixed(0)} mmHg');
    }
    buf.writeln('  * 全年總累計步數: ${stats.totalSteps} 步');
    if (stats.avgSleepHours != null) {
      buf.writeln('  * 平均睡眠時數: ${stats.avgSleepHours!.toStringAsFixed(1)} 小時');
    }

    buf.writeln();
    buf.writeln('--- 年度閱讀與學習成就 ---');
    final finishedBooks = books.where((b) => b.isRead).toList();
    buf.writeln(
        '- 全年已讀完書籍數: ${finishedBooks.length} 本 (總書庫共 ${books.length} 本)');
    for (final b in finishedBooks) {
      buf.writeln('  * 《${b.title}》- 評分: ${b.rating ?? "未評分"}');
    }

    return buf.toString();
  }

  // --- Prompts Builders ---

  String _buildFinancePrompt(String rawData, String userInstructions) {
    return '''
你是本機個人 AI 財務顧問。
請根據以下提供的本月家庭收支 (Expense) 與資產 (Wealth) 數據，產生一份詳細、美觀、結構清晰的「家庭財務月報」。
這份報告將會被複製並貼上到 Microsoft Word 或 WPS Writer 中，因此請使用標準且易讀的 Markdown 格式輸出。

報告中應包含：
1. 財務現況總覽 (淨資產與本月支出總計)
2. 支出分析 (包含高額支出、主要消費分類與建議優化點)
3. 資產配置分析 (資產比例評估)
4. 具體理財改善建議 (3點具體可執行的建議)

${userInstructions.isNotEmpty ? "用戶額外要求：\n$userInstructions\n" : ""}
數據來源：
$rawData
''';
  }

  String _buildHealthPrompt(String rawData, String userInstructions) {
    return '''
你是本機個人 AI 健康顧問。
請根據以下提供的近 30 天個人健康量測紀錄 (體重、血壓、心率、步數、睡眠)，撰寫一份清晰、專業且易讀的「健康紀錄分析與改善建議」摘要報告。
這份報告將會被個人查閱並整理，請使用標準 Markdown 格式輸出。

報告中應包含：
1. 健康狀態總評 (各項指標平均值與是否在正常範圍內)
2. 趨勢與異常值分析 (例如體重變化趨勢、血壓波動情況、步數與睡眠達成率)
3. 具體改善與追蹤建議 (至少3點，關於運動、睡眠或飲食的具體建議)

${userInstructions.isNotEmpty ? "用戶額外要求：\n$userInstructions\n" : ""}
數據來源：
$rawData
''';
  }

  String _buildReadingPrompt(String rawData, String userInstructions) {
    return '''
你是本機 AI 讀書筆記助理。
請根據以下提供的讀書筆記與心得內容，產生一份精美、結構化的「讀書筆記與知識提取總結」。
請使用標準 Markdown 格式輸出。

報告中應包含：
1. 書籍基本資訊與評分總結
2. 心得與核心觀點提煉 (從用戶的粗糙筆記中提煉出深刻的洞察)
3. 知識點延伸與具體應用建議 (讀完這本書後，如何應用在日常工作或生活中)

${userInstructions.isNotEmpty ? "用戶額外要求：\n$userInstructions\n" : ""}
數據來源：
$rawData
''';
  }

  String _buildOcrPrompt(String rawOcrText, String userInstructions) {
    return '''
你是本機 AI 收據結構化分析專家。
請幫我分析以下收據或發票的原始文字 (通常是 OCR 掃描結果)，提取出其中的開支品項、金額、商戶與日期。
請做兩件事：
1. 產生一份清晰的「發票收據結構化明細」表格。
2. **非常重要**：在報告的最後，以一個標準的 JSON 陣列格式輸出這筆開支（如果有多個品項，可以分成多個開支物件，或者合併成一個），格式如下：

```json
[
  {
    "amount": 90.0,
    "currency": "TWD",
    "category": "餐飲",
    "merchant": "全家便利商店",
    "notes": "咖啡、麵包",
    "paymentMethod": "cash"
  }
]
```
JSON 中的 category 建議為以下分類之一：餐飲, 交通, 購物, 娛樂, 居住, 醫療, 教育, 理財, 其他。

${userInstructions.isNotEmpty ? "用戶額外要求：\n$userInstructions\n" : ""}
收據原始文字：
$rawOcrText
''';
  }

  String _buildAnnualPrompt(String rawData, String userInstructions) {
    return '''
你是本機 AI 個人年度回顧分析師。
請根據以下提供的年度生活綜合數據 (包含全年財務支出、年底資產、年度健康統計、年度閱讀清單)，為用戶整理撰寫一份深度、溫馨且具啟發性的「年度個人生活與成長回顧報告」。
請使用標準 Markdown 格式輸出。

報告中應包含：
1. 財務與資產年度回顧 (包含年度消費模式分析與資產配置總結)
2. 健康生活年度總評 (針對體重、步數、血壓、睡眠等，提供生活作息評估)
3. 知識學習與自我成長回顧 (針對年度讀書清單的閱讀廣度與評分)
4. 新年度生活與理財具體展望 (3項平衡生活的具體建議)

${userInstructions.isNotEmpty ? "用戶額外要求：\n$userInstructions\n" : ""}
數據來源：
$rawData
''';
  }

  String _buildTravelPrompt(
    String dest,
    String budget,
    String style,
    String userInstructions,
  ) {
    return '''
你是本機 AI 旅遊行程規劃師。
請根據以下目的地、預算與風格，產生一份可直接貼到文件中的旅遊計畫書。
請使用標準 Markdown 格式輸出。

報告中應包含：
1. 行程總覽與每日重點
2. 每日早午晚建議行程
3. 交通與住宿規劃建議
4. 預算分配與注意事項
5. 備案與雨天行程

${userInstructions.isNotEmpty ? "用戶額外要求：\n$userInstructions\n" : ""}
目的地與天數：$dest
預算規模：$budget
風格喜好：$style
''';
  }

  Future<void> _startGeneration() async {
    final instructions = _customInstructionsController.text.trim();
    setState(() {
      _isLoading = true;
      _generatedResult = '';
    });

    String prompt = '';
    switch (_activeTool) {
      case ActiveTool.finance:
        prompt = _buildFinancePrompt(_gatherFinanceData(), instructions);
        break;
      case ActiveTool.health:
        prompt = _buildHealthPrompt(_gatherHealthData(), instructions);
        break;
      case ActiveTool.books:
        prompt = _buildReadingPrompt(_gatherReadingData(), instructions);
        break;
      case ActiveTool.ocr:
        prompt = _buildOcrPrompt(_ocrTextController.text.trim(), instructions);
        break;
      case ActiveTool.annualReview:
        prompt = _buildAnnualPrompt(_gatherAnnualData(), instructions);
        break;
      case ActiveTool.travel:
        prompt = _buildTravelPrompt(
          _travelDestController.text.trim().isEmpty
              ? '東京5天4夜'
              : _travelDestController.text.trim(),
          _selectedTravelBudget,
          _selectedTravelStyle,
          instructions,
        );
        break;
      default:
        break;
    }

    if (prompt.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final stream = globalOllama.generate(prompt);
      await for (final token in stream) {
        if (!mounted) return;
        setState(() {
          _generatedResult += token;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _generatedResult = '生成失敗，發生錯誤：\n$e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _importOcrExpenses() async {
    final messenger = ScaffoldMessenger.of(context);
    final responseText = _generatedResult;
    final startTag = '```json';
    final endTag = '```';

    String jsonText = '';
    if (responseText.contains(startTag)) {
      final parts = responseText.split(startTag);
      if (parts.length > 1) {
        final subParts = parts[1].split(endTag);
        jsonText = subParts[0].trim();
      }
    } else {
      final startIdx = responseText.indexOf('[');
      final endIdx = responseText.lastIndexOf(']');
      if (startIdx != -1 && endIdx != -1 && endIdx > startIdx) {
        jsonText = responseText.substring(startIdx, endIdx + 1).trim();
      }
    }

    if (jsonText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未偵測到結構化 JSON 資料，無法自動匯入。')),
      );
      return;
    }

    try {
      final list = jsonDecode(jsonText) as List<dynamic>;
      int count = 0;
      for (final item in list) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(item as Map);
        final expense = Expense(
          amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
          currency: map['currency'] as String? ?? 'TWD',
          category: map['category'] as String? ?? '其他',
          merchant: map['merchant'] as String? ?? '',
          notes: map['notes'] as String? ?? '',
          paymentMethod: map['paymentMethod'] as String? ?? 'cash',
          date: DateTime.now(),
        );
        await widget.expenseController.saveExpense(expense);
        count++;
      }
      messenger.showSnackBar(
        SnackBar(content: Text('✅ 成功匯入 $count 筆開支記錄！')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('解析 JSON 失敗：$e')),
      );
    }
  }

  // --- UI Builders ---

  Widget _buildGridCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color.withValues(alpha: 0.1),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridMode() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.0,
      children: [
        _buildGridCard(
          title: '家庭財務月報',
          subtitle: '產生本月收支與淨值報告',
          icon: Icons.account_balance_wallet_outlined,
          color: Colors.green,
          onTap: () => setState(() => _activeTool = ActiveTool.finance),
        ),
        _buildGridCard(
          title: '健康紀錄摘要',
          subtitle: '整理近 30 天健康趨勢建議',
          icon: Icons.favorite_border_outlined,
          color: Colors.redAccent,
          onTap: () => setState(() => _activeTool = ActiveTool.health),
        ),
        _buildGridCard(
          title: '讀書筆記整理',
          subtitle: '萃取書庫心得與實用知識點',
          icon: Icons.menu_book_outlined,
          color: Colors.brown,
          onTap: () => setState(() => _activeTool = ActiveTool.books),
        ),
        _buildGridCard(
          title: '收據 OCR 匯入',
          subtitle: '解析收據文字並一鍵匯入記帳',
          icon: Icons.document_scanner_outlined,
          color: Colors.indigo,
          onTap: () => setState(() => _activeTool = ActiveTool.ocr),
        ),
        _buildGridCard(
          title: '個人年度回顧',
          subtitle: '整年度生活、健康、讀書總結',
          icon: Icons.calendar_today_outlined,
          color: Colors.orange,
          onTap: () => setState(() => _activeTool = ActiveTool.annualReview),
        ),
        _buildGridCard(
          title: '旅遊計畫書',
          subtitle: '自動規劃每日推薦行程預算',
          icon: Icons.explore_outlined,
          color: Colors.teal,
          onTap: () => setState(() => _activeTool = ActiveTool.travel),
        ),
      ],
    );
  }

  Widget _buildToolConfigHeader() {
    String title = '';
    String desc = '';
    Widget customInputs = const SizedBox.shrink();

    switch (_activeTool) {
      case ActiveTool.finance:
        title = '家庭財務月報';
        desc = '系統將自動匯總本月的記帳紀錄與目前的資產配置，由 AI 撰寫成一份 Word 可貼上的排版報告。';
        break;
      case ActiveTool.health:
        title = '健康紀錄摘要';
        desc = '系統將自動拉取近 30 天的體重、血壓、心率、步數、睡眠，由 AI 整合分析健康趨勢並提供指引。';
        break;
      case ActiveTool.books:
        title = '讀書筆記整理';
        desc = '整理您的讀書心得，轉化為結構化的核心論點與知識點。';
        final books = widget.bookController.getAllBooks();
        customInputs = DropdownButtonFormField<String>(
          initialValue: _selectedBookId,
          decoration: const InputDecoration(
            labelText: '選擇要整理的書籍',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem(value: 'all', child: Text('所有書籍')),
            ...books.map(
                (b) => DropdownMenuItem(value: b.id, child: Text(b.title))),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedBookId = val);
            }
          },
        );
        break;
      case ActiveTool.ocr:
        title = '收據 OCR 結構化匯入';
        desc = '請將收據的 OCR 原始文字貼在下方，系統將解析出開支明細，並提供一鍵存入記帳資料庫的功能。';
        customInputs = TextField(
          controller: _ocrTextController,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: '貼上收據/發票 OCR 原始文字',
            hintText: '全家 2026/05/29 飲用水 20, 拿鐵 55, 合計 75 元',
            border: OutlineInputBorder(),
          ),
        );
        break;
      case ActiveTool.annualReview:
        title = '個人年度回顧';
        desc = '整合您全年度的所有支出類別比例、年底資產、年度健康狀態統計以及讀完書籍，產生深度的生活總回顧。';
        break;
      case ActiveTool.travel:
        title = '旅遊計畫書生成器';
        desc = '讓 AI 為您規劃完美的每日旅遊行程。';
        customInputs = Column(
          children: [
            TextField(
              controller: _travelDestController,
              decoration: const InputDecoration(
                labelText: '目的地與天數',
                hintText: '例如：東京 5 天 4 夜',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedTravelBudget,
                    decoration: const InputDecoration(
                      labelText: '預算規模',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: '萬元有找', child: Text('萬元有找')),
                      DropdownMenuItem(value: '輕奢享受', child: Text('輕奢享受')),
                      DropdownMenuItem(value: '頂級度假', child: Text('頂級度假')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedTravelBudget = val);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedTravelStyle,
                    decoration: const InputDecoration(
                      labelText: '風格喜好',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: '深度文化之旅', child: Text('深度文化之旅')),
                      DropdownMenuItem(
                          value: '美食Shopping與休閒', child: Text('美食Shopping與休閒')),
                      DropdownMenuItem(value: '親子育樂行程', child: Text('親子育樂行程')),
                      DropdownMenuItem(
                          value: '戶外大自然與冒險', child: Text('戶外大自然與冒險')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedTravelStyle = val);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        );
        break;
      default:
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() => _activeTool = ActiveTool.none);
                _clearState();
              },
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(desc, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        const SizedBox(height: 16),
        if (customInputs != const SizedBox.shrink()) ...[
          customInputs,
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _customInstructionsController,
          decoration: const InputDecoration(
            labelText: '額外指示/要求 (可留空)',
            hintText: '例如：使用繁體中文、加入幽默語氣、針對交通支出多分析',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _startGeneration,
                icon: const Icon(Icons.auto_awesome),
                label: Text(_isLoading ? '生成中...' : '開始產生文件'),
              ),
            ),
            if (_activeTool == ActiveTool.ocr &&
                _generatedResult.isNotEmpty &&
                !_isLoading) ...[
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _importOcrExpenses,
                  icon: const Icon(Icons.download),
                  label: const Text('一鍵匯入記帳'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.indigo,
                  ),
                ),
              ),
            ],
          ],
        ),
        const Divider(height: 32),
      ],
    );
  }

  Widget _buildPaperPreview() {
    if (_generatedResult.isEmpty && !_isLoading) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        alignment: Alignment.center,
        child: Text(
          '尚未產生報告內容。\n請調整上方參數並點選「開始產生文件」。',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600, height: 1.4),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.article_outlined, color: Colors.blueAccent),
                const SizedBox(width: 8),
                const Text(
                  '文件預覽 (Paper Preview)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy),
                  tooltip: '複製全文',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _generatedResult));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已將文件內容複製到剪貼簿！')),
                    );
                  },
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),
            _isLoading && _generatedResult.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : SelectionArea(
                    child: Text(
                      _generatedResult,
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 14,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                    ),
                  ),
            if (_isLoading && _generatedResult.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AI 正在寫入中...',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNone = _activeTool == ActiveTool.none;

    return Scaffold(
      appBar: AppBar(
        title: const Text('生活文件應用 (Life Document Apps)'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isNone
              ? _buildGridMode()
              : ListView(
                  children: [
                    _buildToolConfigHeader(),
                    _buildPaperPreview(),
                    const SizedBox(height: 40),
                  ],
                ),
        ),
      ),
    );
  }
}
