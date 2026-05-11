// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '智讀館';

  @override
  String get tabRecords => '紀錄';

  @override
  String get tabAllocation => '配置';

  @override
  String get investmentFinance => '投資理財';

  @override
  String get noInvestmentRecords => '尚無投資紀錄';

  @override
  String get aiFinancialAdvisor => 'AI 理財顧問';

  @override
  String get totalAssets => '總資產';

  @override
  String get currencyLabel => '幣別：';

  @override
  String get moduleExpense => '日常開支';

  @override
  String get moduleContacts => '名片管理';

  @override
  String get moduleHealth => '健康紀錄';

  @override
  String get moduleWealth => '投資理財';

  @override
  String get moduleDashboardSoon => '完整儀表板';

  @override
  String get comingSoon => '即將推出';

  @override
  String expenseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 筆紀錄',
      zero: '尚未加入紀錄',
    );
    return '$_temp0';
  }

  @override
  String get saveButton => '儲存';

  @override
  String get cancelButton => '取消';

  @override
  String get deleteButton => '刪除';

  @override
  String get settings => '設定';

  @override
  String get language => '語言';

  @override
  String get languageZhTw => '繁體中文';

  @override
  String get languageZhCn => '簡體中文';

  @override
  String get languageEn => 'English';

  @override
  String get personalHubTitle => 'Personal Hub';

  @override
  String get modules => '模組';

  @override
  String dashboardTitle(int year, int month) {
    return '$year 年 $month 月總覽';
  }

  @override
  String get totalExpensesThisMonth => '本月總開支';

  @override
  String get noExpensesThisMonth => '本月暫無開支';

  @override
  String get totalContacts => '名片總數';

  @override
  String get healthRecords => '健康紀錄';

  @override
  String get investmentNetWorth => '投資淨值';

  @override
  String get quickAiQuery => '快速 AI 查詢';

  @override
  String featureNotEnabled(String feature) {
    return '$feature：尚未啟用，請等待後續 Phase';
  }

  @override
  String get aiQueryFeatureComingSoon => 'AI 跨模組查詢將於 Phase 6.3\'b 推出';

  @override
  String get noRecordsYet => '尚未加入紀錄';

  @override
  String get noContactsYet => '尚未加入名片';

  @override
  String recordCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 筆紀錄',
      zero: '尚未加入紀錄',
    );
    return '$_temp0';
  }

  @override
  String contactCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 張名片',
      zero: '尚未加入名片',
    );
    return '$_temp0';
  }

  @override
  String get wealth => '投資理財';

  @override
  String get assetAllocation => '資產配置';

  @override
  String get addRecord => '新增紀錄';

  @override
  String get netWorth => '投資淨值';

  @override
  String get totalLiabilities => '總負債';

  @override
  String get searchAssetHint => '搜尋資產 / 備註 / 標籤...';

  @override
  String get noDataToChart => '沒有可繪製的投資資料';

  @override
  String get addFirstRecordHint => '從「紀錄」分頁加入第一筆吧';

  @override
  String get netWorthOverview => '淨值總覽';

  @override
  String assetCountLabel(int count) {
    return '$count 項資產';
  }

  @override
  String get valuationNote => '依最新一筆估值合計（不跨幣別換算）';

  @override
  String get noData => '暫無資料';

  @override
  String get netWorthTrend => '淨值趨勢';

  @override
  String get needTwoDatesForChart => '需要至少兩個不同日期才能繪製趨勢';

  @override
  String get addInvestmentRecord => '新增投資紀錄';

  @override
  String get editInvestmentRecord => '編輯投資紀錄';

  @override
  String get valuationDate => '估值日期';

  @override
  String get assetClass => '資產類別';

  @override
  String get assetNameHint => '資產名稱（選填，例如 AAPL / 0050.TW）';

  @override
  String get amount => '金額';

  @override
  String get invalidAmountError => '請輸入有效金額';

  @override
  String get currency => '幣別';

  @override
  String get notes => '備註';

  @override
  String get tagsCommaSeparated => '標籤（逗號分隔）';

  @override
  String get aiHealthAdvisor => 'AI 健康顧問';

  @override
  String get searchHealthHint => '搜尋備註 / 標籤...';

  @override
  String get noHealthRecords => '尚無健康紀錄';

  @override
  String get noRecordsLast30Days => '最近 30 天暫無紀錄';

  @override
  String get last30DaysOverview => '最近 30 天概況';

  @override
  String recordCountUnit(int count) {
    return '$count 筆';
  }

  @override
  String get weight => '體重';

  @override
  String avgWeightStat(String val, int count) {
    return '平均 $val kg ($count 次)';
  }

  @override
  String get bloodPressure => '血壓';

  @override
  String avgBpStat(String sys, String dia, int count) {
    return '平均 $sys / $dia mmHg ($count 次)';
  }

  @override
  String get heartRate => '心率';

  @override
  String avgHeartRateStat(String val, int count) {
    return '平均 $val bpm ($count 次)';
  }

  @override
  String get steps => '步數';

  @override
  String totalStepsStat(String val, int count) {
    return '總計 $val 步 ($count 天)';
  }

  @override
  String get sleep => '睡眠';

  @override
  String avgSleepStat(String val, int count) {
    return '平均 $val 小時 ($count 次)';
  }

  @override
  String get noDataLabel => '(無資料)';

  @override
  String get addHealthRecord => '新增健康紀錄';

  @override
  String get editHealthRecord => '編輯健康紀錄';

  @override
  String get measurementDate => '測量日期';

  @override
  String get weightKg => '體重 (kg)';

  @override
  String get systolicMmHg => '收縮壓 (mmHg)';

  @override
  String get diastolicMmHg => '舒張壓 (mmHg)';

  @override
  String get heartRateBpm => '心率 (bpm)';

  @override
  String get sleepHours => '睡眠時數 (小時)';

  @override
  String get fillAtLeastOneMeasurement => '請至少填寫一項測量值或備註';

  @override
  String get trendCharts => '趨勢圖表';

  @override
  String get weightTrend => '體重趨勢 (kg)';

  @override
  String get systolicTrend => '收縮壓趨勢 (mmHg)';

  @override
  String get sleepHoursLabel => '睡眠時數';

  @override
  String get searchExpenseHint => '搜尋商家 / 分類 / 備註...';

  @override
  String get noMatchingExpenses => '沒有符合條件的開支';

  @override
  String get previousMonth => '上個月';

  @override
  String get nextMonth => '下個月';

  @override
  String yearMonthTitle(int year, int month) {
    return '$year 年 $month 月';
  }

  @override
  String monthlyTotal(String totalText) {
    return '本月合計：$totalText';
  }

  @override
  String categoryAmountChip(String label, String amount) {
    return '$label · $amount';
  }

  @override
  String get noMerchant => '(未填商家)';

  @override
  String get addExpense => '新增開支';

  @override
  String get editExpense => '編輯開支';

  @override
  String get merchant => '商家';

  @override
  String get category => '分類';

  @override
  String get defaultCategoriesLabel => '預設類別';

  @override
  String customCategoriesCount(int count) {
    return '已有 $count 個自訂類別';
  }

  @override
  String get paymentMethod => '付款方式';

  @override
  String get date => '日期';

  @override
  String get appearance => '外觀';

  @override
  String get theme => '主題';

  @override
  String get darkMode => '深色模式';

  @override
  String get lightMode => '淺色模式';

  @override
  String get systemDefault => '跟隨系統';

  @override
  String get mySkills => '我的技能庫';

  @override
  String get embeddingSettings => 'Embedding 設定';

  @override
  String get enterEmbeddingModelName => '請輸入 embedding model 名稱';

  @override
  String get modelInstalled => '已安裝';

  @override
  String get modelNotInstalled => '未安裝，請先用 Ollama pull 此 model';

  @override
  String get useCustomEmbeddingModel => '使用自訂 embedding model';

  @override
  String get customModelHint => '例如：mxbai-embed-large';

  @override
  String currentSelection(String model) {
    return '目前選擇：$model';
  }

  @override
  String get changeModelWarning =>
      '注意：更換 embedding model 會清空目前 vector store，請重新匯入文件。';

  @override
  String get retrievalMode => '檢索模式';

  @override
  String get denseMode => 'Dense：向量語意搜尋';

  @override
  String get sparseMode => 'Sparse：BM25 關鍵字搜尋';

  @override
  String get hybridMode => 'Hybrid：Dense + BM25 + RRF';

  @override
  String get applySettings => '套用設定';

  @override
  String get wealthExportCsv => '匯出 CSV';

  @override
  String get wealthCsvCopied => 'CSV 已複製到剪貼簿';

  @override
  String get personalHubHealthRecords => '健康紀錄';

  @override
  String get personalHubThisMonthExpense => '本月開支';

  @override
  String get wealthMonthlyReport => '本月報告';

  @override
  String get wealthThisMonthTotal => '本月總值';

  @override
  String get wealthLastMonthTotal => '上月總值';

  @override
  String get wealthChange => '變化';

  @override
  String get records => '筆紀錄';

  @override
  String get insightTitle => '一鍵生活洞察';

  @override
  String get insightSubtitle => '結合 Health 與 Wealth 雙核分析，打造您的專屬生活指南。';

  @override
  String get personalQueryTitle => 'Personal Hub AI 查詢';

  @override
  String get personalQueryHint => '問問你的 Personal Hub';

  @override
  String get personalQueryHintSub => '可以同時搜尋你的開支與名片紀錄。';

  @override
  String get skillsSearchHint => '搜尋技能...';

  @override
  String get skillsEmpty => '尚無技能卡';

  @override
  String get skillsEmptyHint => '使用 AI 回答後點擊「⭐ 儲存為技能」\n或點擊右上角雲端按鈕來生成';

  @override
  String get skillSaved => '已手動儲存為技能！';

  @override
  String get saveAsSkill => '儲存為技能';

  @override
  String get querySample1 => '上次跟王經理吃飯花了多少？';

  @override
  String get querySample2 => '我這個月在 7-11 花了多少？';

  @override
  String get querySample3 => 'Acme Corp 有哪些聯絡人？';

  @override
  String get addManually => '手動新增';

  @override
  String get skillsSubtitle => 'AI 學習記憶庫';

  @override
  String get settingsApiKeyRequired => '請先輸入 API Key';

  @override
  String get settingsTestingConnection => '測試連線中...';

  @override
  String get settingsCloudAiTitle => 'Cloud AI 服務 (Gemini)';

  @override
  String get settingsCloudAiDesc =>
      '設定您的 API Key 以啟用「雲端大模型教導本地小模型」與「Wealth 模組的照片掃描」功能。這將被妥善保存在本機。';

  @override
  String get settingsTestConnection => '測試連線';

  @override
  String get settingsTelegramTitle => 'Telegram 整合';

  @override
  String get settingsTelegramDesc =>
      '設定您的 Telegram Bot Token，讓 Local AI 成為您的隨身助理。可從 @BotFather 取得。';

  @override
  String get changeCurrency => '切換幣別';

  @override
  String get chatTitle => '對話';

  @override
  String get libraryTitle => '圖書館';

  @override
  String get libraryEmpty => '尚無項目';

  @override
  String get chatInputHint => '輸入訊息...';

  @override
  String get readingModeTitle => '閱讀模式';
}

/// The translations for Chinese, as used in China (`zh_CN`).
class AppLocalizationsZhCn extends AppLocalizationsZh {
  AppLocalizationsZhCn() : super('zh_CN');

  @override
  String get appTitle => '智读馆';

  @override
  String get tabRecords => '记录';

  @override
  String get tabAllocation => '配置';

  @override
  String get investmentFinance => '投资理财';

  @override
  String get noInvestmentRecords => '尚无投资记录';

  @override
  String get aiFinancialAdvisor => 'AI 理财顾问';

  @override
  String get totalAssets => '总资产';

  @override
  String get currencyLabel => '币别：';

  @override
  String get moduleExpense => '日常开支';

  @override
  String get moduleContacts => '名片管理';

  @override
  String get moduleHealth => '健康记录';

  @override
  String get moduleWealth => '投资理财';

  @override
  String get moduleDashboardSoon => '完整仪表板';

  @override
  String get comingSoon => '即将推出';

  @override
  String expenseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 笔记录',
      zero: '尚未加入记录',
    );
    return '$_temp0';
  }

  @override
  String get saveButton => '保存';

  @override
  String get cancelButton => '取消';

  @override
  String get deleteButton => '删除';

  @override
  String get settings => '设置';

  @override
  String get language => '语言';

  @override
  String get languageZhTw => '繁体中文';

  @override
  String get languageZhCn => '简体中文';

  @override
  String get languageEn => 'English';

  @override
  String get personalHubTitle => 'Personal Hub';

  @override
  String get modules => '模块';

  @override
  String dashboardTitle(int year, int month) {
    return '$year 年 $month 月总览';
  }

  @override
  String get totalExpensesThisMonth => '本月总开支';

  @override
  String get noExpensesThisMonth => '本月暂无开支';

  @override
  String get totalContacts => '名片总数';

  @override
  String get healthRecords => '健康记录';

  @override
  String get investmentNetWorth => '投资净值';

  @override
  String get quickAiQuery => '快速 AI 查询';

  @override
  String featureNotEnabled(String feature) {
    return '$feature：尚未启用，请等待后续 Phase';
  }

  @override
  String get aiQueryFeatureComingSoon => 'AI 跨模块查询将于 Phase 6.3\'b 推出';

  @override
  String get noRecordsYet => '尚未加入记录';

  @override
  String get noContactsYet => '尚未加入名片';

  @override
  String recordCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 笔记录',
      zero: '尚未加入记录',
    );
    return '$_temp0';
  }

  @override
  String contactCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 张名片',
      zero: '尚未加入名片',
    );
    return '$_temp0';
  }

  @override
  String get wealth => '投资理财';

  @override
  String get assetAllocation => '资产配置';

  @override
  String get addRecord => '新增记录';

  @override
  String get netWorth => '投资净值';

  @override
  String get totalLiabilities => '总负债';

  @override
  String get searchAssetHint => '搜索资产 / 备注 / 标签...';

  @override
  String get noDataToChart => '没有可绘制的投资数据';

  @override
  String get addFirstRecordHint => '从“记录”分页加入第一笔吧';

  @override
  String get netWorthOverview => '净值总览';

  @override
  String assetCountLabel(int count) {
    return '$count 项资产';
  }

  @override
  String get valuationNote => '依最新一笔估值合计（不跨币别换算）';

  @override
  String get noData => '暂无数据';

  @override
  String get netWorthTrend => '净值趋势';

  @override
  String get needTwoDatesForChart => '需要至少两个不同日期才能绘制趋势';

  @override
  String get addInvestmentRecord => '新增投资记录';

  @override
  String get editInvestmentRecord => '编辑投资记录';

  @override
  String get valuationDate => '估值日期';

  @override
  String get assetClass => '资产类别';

  @override
  String get assetNameHint => '资产名称（选填，例如 AAPL / 0050.TW）';

  @override
  String get amount => '金额';

  @override
  String get invalidAmountError => '请输入有效金额';

  @override
  String get currency => '币别';

  @override
  String get notes => '备注';

  @override
  String get tagsCommaSeparated => '标签（逗号分隔）';

  @override
  String get aiHealthAdvisor => 'AI 健康顾问';

  @override
  String get searchHealthHint => '搜索备注 / 标签...';

  @override
  String get noHealthRecords => '尚无健康记录';

  @override
  String get noRecordsLast30Days => '最近 30 天暂无记录';

  @override
  String get last30DaysOverview => '最近 30 天概况';

  @override
  String recordCountUnit(int count) {
    return '$count 笔';
  }

  @override
  String get weight => '体重';

  @override
  String avgWeightStat(String val, int count) {
    return '平均 $val kg ($count 次)';
  }

  @override
  String get bloodPressure => '血压';

  @override
  String avgBpStat(String sys, String dia, int count) {
    return '平均 $sys / $dia mmHg ($count 次)';
  }

  @override
  String get heartRate => '心率';

  @override
  String avgHeartRateStat(String val, int count) {
    return '平均 $val bpm ($count 次)';
  }

  @override
  String get steps => '步数';

  @override
  String totalStepsStat(String val, int count) {
    return '总计 $val 步 ($count 天)';
  }

  @override
  String get sleep => '睡眠';

  @override
  String avgSleepStat(String val, int count) {
    return '平均 $val 小时 ($count 次)';
  }

  @override
  String get noDataLabel => '(无数据)';

  @override
  String get addHealthRecord => '新增健康记录';

  @override
  String get editHealthRecord => '编辑健康记录';

  @override
  String get measurementDate => '测量日期';

  @override
  String get weightKg => '体重 (kg)';

  @override
  String get systolicMmHg => '收缩压 (mmHg)';

  @override
  String get diastolicMmHg => '舒张压 (mmHg)';

  @override
  String get heartRateBpm => '心率 (bpm)';

  @override
  String get sleepHours => '睡眠时数 (小时)';

  @override
  String get fillAtLeastOneMeasurement => '请至少填写一项测量值或备注';

  @override
  String get trendCharts => '趋势图表';

  @override
  String get weightTrend => '体重趋势 (kg)';

  @override
  String get systolicTrend => '收缩压趋势 (mmHg)';

  @override
  String get sleepHoursLabel => '睡眠时数';

  @override
  String get searchExpenseHint => '搜索商家 / 分类 / 备注...';

  @override
  String get noMatchingExpenses => '没有符合条件的开支';

  @override
  String get previousMonth => '上个月';

  @override
  String get nextMonth => '下个月';

  @override
  String yearMonthTitle(int year, int month) {
    return '$year 年 $month 月';
  }

  @override
  String monthlyTotal(String totalText) {
    return '本月合计：$totalText';
  }

  @override
  String categoryAmountChip(String label, String amount) {
    return '$label · $amount';
  }

  @override
  String get noMerchant => '(未填商家)';

  @override
  String get addExpense => '新增开支';

  @override
  String get editExpense => '编辑开支';

  @override
  String get merchant => '商家';

  @override
  String get category => '分类';

  @override
  String get defaultCategoriesLabel => '默认类别';

  @override
  String customCategoriesCount(int count) {
    return '已有 $count 个自定义类别';
  }

  @override
  String get paymentMethod => '付款方式';

  @override
  String get date => '日期';

  @override
  String get appearance => '外观';

  @override
  String get theme => '主题';

  @override
  String get darkMode => '深色模式';

  @override
  String get lightMode => '浅色模式';

  @override
  String get systemDefault => '跟随系统';

  @override
  String get mySkills => '我的技能库';

  @override
  String get embeddingSettings => 'Embedding 设置';

  @override
  String get enterEmbeddingModelName => '请输入 embedding model 名称';

  @override
  String get modelInstalled => '已安装';

  @override
  String get modelNotInstalled => '未安装，请先用 Ollama pull 此 model';

  @override
  String get useCustomEmbeddingModel => '使用自定义 embedding model';

  @override
  String get customModelHint => '例如：mxbai-embed-large';

  @override
  String currentSelection(String model) {
    return '目前选择：$model';
  }

  @override
  String get changeModelWarning =>
      '注意：更换 embedding model 会清空目前 vector store，请重新导入文件。';

  @override
  String get retrievalMode => '检索模式';

  @override
  String get denseMode => 'Dense：向量语义搜索';

  @override
  String get sparseMode => 'Sparse：BM25 关键字搜索';

  @override
  String get hybridMode => 'Hybrid：Dense + BM25 + RRF';

  @override
  String get applySettings => '应用设置';

  @override
  String get wealthExportCsv => '导出 CSV';

  @override
  String get wealthCsvCopied => 'CSV 已复制到剪贴板';

  @override
  String get personalHubHealthRecords => '健康记录';

  @override
  String get personalHubThisMonthExpense => '本月开支';

  @override
  String get wealthMonthlyReport => '本月报告';

  @override
  String get wealthThisMonthTotal => '本月总值';

  @override
  String get wealthLastMonthTotal => '上月总值';

  @override
  String get wealthChange => '变化';

  @override
  String get records => '条记录';

  @override
  String get insightTitle => '一键生活洞察';

  @override
  String get insightSubtitle => '结合 Health 与 Wealth 双核分析，打造您的专属生活指南。';

  @override
  String get personalQueryTitle => 'Personal Hub AI 查询';

  @override
  String get personalQueryHint => '问问你的 Personal Hub';

  @override
  String get personalQueryHintSub => '可以同时搜索你的开支与名片记录。';

  @override
  String get skillsSearchHint => '搜索技能...';

  @override
  String get skillsEmpty => '尚无技能卡';

  @override
  String get skillsEmptyHint => '使用 AI 回答后点击「⭐ 保存为技能」\n或点击右上角云端按钮来生成';

  @override
  String get skillSaved => '已手动保存为技能！';

  @override
  String get saveAsSkill => '保存为技能';

  @override
  String get querySample1 => '上次和王经理吃饭花了多少？';

  @override
  String get querySample2 => '我这个月在 7-11 花了多少？';

  @override
  String get querySample3 => 'Acme Corp 有哪些联系人？';

  @override
  String get addManually => '手动新增';

  @override
  String get skillsSubtitle => 'AI 学习记忆库';

  @override
  String get settingsApiKeyRequired => '请先输入 API Key';

  @override
  String get settingsTestingConnection => '测试连接中...';

  @override
  String get settingsCloudAiTitle => 'Cloud AI 服务 (Gemini)';

  @override
  String get settingsCloudAiDesc =>
      '设置您的 API Key 以启用“云端大模型教导本地小模型”与“Wealth 模组的照片扫描”功能。这将被妥善保存在本机。';

  @override
  String get settingsTestConnection => '测试连接';

  @override
  String get settingsTelegramTitle => 'Telegram 整合';

  @override
  String get settingsTelegramDesc =>
      '设置您的 Telegram Bot Token，让 Local AI 成为您的随身助理。可从 @BotFather 获取。';

  @override
  String get changeCurrency => '切换币别';

  @override
  String get chatTitle => '对话';

  @override
  String get libraryTitle => '图书馆';

  @override
  String get libraryEmpty => '暂无项目';

  @override
  String get chatInputHint => '输入消息...';

  @override
  String get readingModeTitle => '阅读模式';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get appTitle => '智讀館';

  @override
  String get tabRecords => '紀錄';

  @override
  String get tabAllocation => '配置';

  @override
  String get investmentFinance => '投資理財';

  @override
  String get noInvestmentRecords => '尚無投資紀錄';

  @override
  String get aiFinancialAdvisor => 'AI 理財顧問';

  @override
  String get totalAssets => '總資產';

  @override
  String get currencyLabel => '幣別：';

  @override
  String get moduleExpense => '日常開支';

  @override
  String get moduleContacts => '名片管理';

  @override
  String get moduleHealth => '健康紀錄';

  @override
  String get moduleWealth => '投資理財';

  @override
  String get moduleDashboardSoon => '完整儀表板';

  @override
  String get comingSoon => '即將推出';

  @override
  String expenseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 筆紀錄',
      zero: '尚未加入紀錄',
    );
    return '$_temp0';
  }

  @override
  String get saveButton => '儲存';

  @override
  String get cancelButton => '取消';

  @override
  String get deleteButton => '刪除';

  @override
  String get settings => '設定';

  @override
  String get language => '語言';

  @override
  String get languageZhTw => '繁體中文';

  @override
  String get languageZhCn => '簡體中文';

  @override
  String get languageEn => 'English';

  @override
  String get personalHubTitle => 'Personal Hub';

  @override
  String get modules => '模組';

  @override
  String dashboardTitle(int year, int month) {
    return '$year 年 $month 月總覽';
  }

  @override
  String get totalExpensesThisMonth => '本月總開支';

  @override
  String get noExpensesThisMonth => '本月暫無開支';

  @override
  String get totalContacts => '名片總數';

  @override
  String get healthRecords => '健康紀錄';

  @override
  String get investmentNetWorth => '投資淨值';

  @override
  String get quickAiQuery => '快速 AI 查詢';

  @override
  String featureNotEnabled(String feature) {
    return '$feature：尚未啟用，請等待後續 Phase';
  }

  @override
  String get aiQueryFeatureComingSoon => 'AI 跨模組查詢將於 Phase 6.3\'b 推出';

  @override
  String get noRecordsYet => '尚未加入紀錄';

  @override
  String get noContactsYet => '尚未加入名片';

  @override
  String recordCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 筆紀錄',
      zero: '尚未加入紀錄',
    );
    return '$_temp0';
  }

  @override
  String contactCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 張名片',
      zero: '尚未加入名片',
    );
    return '$_temp0';
  }

  @override
  String get wealth => '投資理財';

  @override
  String get assetAllocation => '資產配置';

  @override
  String get addRecord => '新增紀錄';

  @override
  String get netWorth => '投資淨值';

  @override
  String get totalLiabilities => '總負債';

  @override
  String get searchAssetHint => '搜尋資產 / 備註 / 標籤...';

  @override
  String get noDataToChart => '沒有可繪製的投資資料';

  @override
  String get addFirstRecordHint => '從「紀錄」分頁加入第一筆吧';

  @override
  String get netWorthOverview => '淨值總覽';

  @override
  String assetCountLabel(int count) {
    return '$count 項資產';
  }

  @override
  String get valuationNote => '依最新一筆估值合計（不跨幣別換算）';

  @override
  String get noData => '暫無資料';

  @override
  String get netWorthTrend => '淨值趨勢';

  @override
  String get needTwoDatesForChart => '需要至少兩個不同日期才能繪製趨勢';

  @override
  String get addInvestmentRecord => '新增投資紀錄';

  @override
  String get editInvestmentRecord => '編輯投資紀錄';

  @override
  String get valuationDate => '估值日期';

  @override
  String get assetClass => '資產類別';

  @override
  String get assetNameHint => '資產名稱（選填，例如 AAPL / 0050.TW）';

  @override
  String get amount => '金額';

  @override
  String get invalidAmountError => '請輸入有效金額';

  @override
  String get currency => '幣別';

  @override
  String get notes => '備註';

  @override
  String get tagsCommaSeparated => '標籤（逗號分隔）';

  @override
  String get aiHealthAdvisor => 'AI 健康顧問';

  @override
  String get searchHealthHint => '搜尋備註 / 標籤...';

  @override
  String get noHealthRecords => '尚無健康紀錄';

  @override
  String get noRecordsLast30Days => '最近 30 天暫無紀錄';

  @override
  String get last30DaysOverview => '最近 30 天概況';

  @override
  String recordCountUnit(int count) {
    return '$count 筆';
  }

  @override
  String get weight => '體重';

  @override
  String avgWeightStat(String val, int count) {
    return '平均 $val kg ($count 次)';
  }

  @override
  String get bloodPressure => '血壓';

  @override
  String avgBpStat(String sys, String dia, int count) {
    return '平均 $sys / $dia mmHg ($count 次)';
  }

  @override
  String get heartRate => '心率';

  @override
  String avgHeartRateStat(String val, int count) {
    return '平均 $val bpm ($count 次)';
  }

  @override
  String get steps => '步數';

  @override
  String totalStepsStat(String val, int count) {
    return '總計 $val 步 ($count 天)';
  }

  @override
  String get sleep => '睡眠';

  @override
  String avgSleepStat(String val, int count) {
    return '平均 $val 小時 ($count 次)';
  }

  @override
  String get noDataLabel => '(無資料)';

  @override
  String get addHealthRecord => '新增健康紀錄';

  @override
  String get editHealthRecord => '編輯健康紀錄';

  @override
  String get measurementDate => '測量日期';

  @override
  String get weightKg => '體重 (kg)';

  @override
  String get systolicMmHg => '收縮壓 (mmHg)';

  @override
  String get diastolicMmHg => '舒張壓 (mmHg)';

  @override
  String get heartRateBpm => '心率 (bpm)';

  @override
  String get sleepHours => '睡眠時數 (小時)';

  @override
  String get fillAtLeastOneMeasurement => '請至少填寫一項測量值或備註';

  @override
  String get trendCharts => '趨勢圖表';

  @override
  String get weightTrend => '體重趨勢 (kg)';

  @override
  String get systolicTrend => '收縮壓趨勢 (mmHg)';

  @override
  String get sleepHoursLabel => '睡眠時數';

  @override
  String get searchExpenseHint => '搜尋商家 / 分類 / 備註...';

  @override
  String get noMatchingExpenses => '沒有符合條件的開支';

  @override
  String get previousMonth => '上個月';

  @override
  String get nextMonth => '下個月';

  @override
  String yearMonthTitle(int year, int month) {
    return '$year 年 $month 月';
  }

  @override
  String monthlyTotal(String totalText) {
    return '本月合計：$totalText';
  }

  @override
  String categoryAmountChip(String label, String amount) {
    return '$label · $amount';
  }

  @override
  String get noMerchant => '(未填商家)';

  @override
  String get addExpense => '新增開支';

  @override
  String get editExpense => '編輯開支';

  @override
  String get merchant => '商家';

  @override
  String get category => '分類';

  @override
  String get defaultCategoriesLabel => '預設類別';

  @override
  String customCategoriesCount(int count) {
    return '已有 $count 個自訂類別';
  }

  @override
  String get paymentMethod => '付款方式';

  @override
  String get date => '日期';

  @override
  String get appearance => '外觀';

  @override
  String get theme => '主題';

  @override
  String get darkMode => '深色模式';

  @override
  String get lightMode => '淺色模式';

  @override
  String get systemDefault => '跟隨系統';

  @override
  String get mySkills => '我的技能庫';

  @override
  String get embeddingSettings => 'Embedding 設定';

  @override
  String get enterEmbeddingModelName => '請輸入 embedding model 名稱';

  @override
  String get modelInstalled => '已安裝';

  @override
  String get modelNotInstalled => '未安裝，請先用 Ollama pull 此 model';

  @override
  String get useCustomEmbeddingModel => '使用自訂 embedding model';

  @override
  String get customModelHint => '例如：mxbai-embed-large';

  @override
  String currentSelection(String model) {
    return '目前選擇：$model';
  }

  @override
  String get changeModelWarning =>
      '注意：更換 embedding model 會清空目前 vector store，請重新匯入文件。';

  @override
  String get retrievalMode => '檢索模式';

  @override
  String get denseMode => 'Dense：向量語意搜尋';

  @override
  String get sparseMode => 'Sparse：BM25 關鍵字搜尋';

  @override
  String get hybridMode => 'Hybrid：Dense + BM25 + RRF';

  @override
  String get applySettings => '套用設定';

  @override
  String get wealthExportCsv => '匯出 CSV';

  @override
  String get wealthCsvCopied => 'CSV 已複製到剪貼簿';

  @override
  String get personalHubHealthRecords => '健康紀錄';

  @override
  String get personalHubThisMonthExpense => '本月開支';

  @override
  String get wealthMonthlyReport => '本月報告';

  @override
  String get wealthThisMonthTotal => '本月總值';

  @override
  String get wealthLastMonthTotal => '上月總值';

  @override
  String get wealthChange => '變化';

  @override
  String get records => '筆紀錄';

  @override
  String get insightTitle => '一鍵生活洞察';

  @override
  String get insightSubtitle => '結合 Health 與 Wealth 雙核分析，打造您的專屬生活指南。';

  @override
  String get personalQueryTitle => 'Personal Hub AI 查詢';

  @override
  String get personalQueryHint => '問問你的 Personal Hub';

  @override
  String get personalQueryHintSub => '可以同時搜尋你的開支與名片紀錄。';

  @override
  String get skillsSearchHint => '搜尋技能...';

  @override
  String get skillsEmpty => '尚無技能卡';

  @override
  String get skillsEmptyHint => '使用 AI 回答後點擊「⭐ 儲存為技能」\n或點擊右上角雲端按鈕來生成';

  @override
  String get skillSaved => '已手動儲存為技能！';

  @override
  String get saveAsSkill => '儲存為技能';

  @override
  String get querySample1 => '上次跟王經理吃飯花了多少？';

  @override
  String get querySample2 => '我這個月在 7-11 花了多少？';

  @override
  String get querySample3 => 'Acme Corp 有哪些聯絡人？';

  @override
  String get addManually => '手動新增';

  @override
  String get skillsSubtitle => 'AI 學習記憶庫';

  @override
  String get settingsApiKeyRequired => '請先輸入 API Key';

  @override
  String get settingsTestingConnection => '測試連線中...';

  @override
  String get settingsCloudAiTitle => 'Cloud AI 服務 (Gemini)';

  @override
  String get settingsCloudAiDesc =>
      '設定您的 API Key 以啟用「雲端大模型教導本地小模型」與「Wealth 模組的照片掃描」功能。這將被妥善保存在本機。';

  @override
  String get settingsTestConnection => '測試連線';

  @override
  String get settingsTelegramTitle => 'Telegram 整合';

  @override
  String get settingsTelegramDesc =>
      '設定您的 Telegram Bot Token，讓 Local AI 成為您的隨身助理。可從 @BotFather 取得。';

  @override
  String get changeCurrency => '切換幣別';

  @override
  String get chatTitle => '對話';

  @override
  String get libraryTitle => '圖書館';

  @override
  String get libraryEmpty => '尚無項目';

  @override
  String get chatInputHint => '輸入訊息...';

  @override
  String get readingModeTitle => '閱讀模式';
}
