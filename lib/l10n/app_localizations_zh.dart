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

  @override
  String get churchHubTitle => '會友管理';

  @override
  String get churchNoMembers => '目前尚無會友資料';

  @override
  String get churchAddMember => '新增會友';

  @override
  String get churchSearchHint => '搜尋姓名 / 電話';

  @override
  String get churchDirectoryTitle => '會友通訊錄';

  @override
  String get searchHint => '搜尋姓名 / 電話 / 小組 / 主日學 / 備註';

  @override
  String filterMemberCount(int count) {
    return '會友 ($count)';
  }

  @override
  String filterSeekerCount(int count) {
    return '非會友 ($count)';
  }

  @override
  String filterAllCount(int count) {
    return '全部 ($count)';
  }

  @override
  String filterMemberRegularCount(int count) {
    return '經常參加崇拜的會友 ($count)';
  }

  @override
  String filterSeekerRegularCount(int count) {
    return '經常參加崇拜的非會友 ($count)';
  }

  @override
  String filterMemberOccasionalCount(int count) {
    return '偶爾參加崇拜的會友 ($count)';
  }

  @override
  String filterSeekerOccasionalCount(int count) {
    return '偶爾參加崇拜的非會友 ($count)';
  }

  @override
  String filterMemberInactiveCount(int count) {
    return '久未參加崇拜的會友 ($count)';
  }

  @override
  String filterSeekerInactiveCount(int count) {
    return '久未參加崇拜的非會友 ($count)';
  }

  @override
  String get noSearchResults => '無符合搜尋條件嘅會友';

  @override
  String get emptyDirectory => '通訊錄空白';

  @override
  String get emptyDirectoryHint => '撳右下角加第一個會友';

  @override
  String personRowSmallGroup(String group) {
    return '小組:$group';
  }

  @override
  String personRowSundaySchool(String school) {
    return '主日學:$school';
  }

  @override
  String get historyTooltip => '歷史紀錄';

  @override
  String get closeCaseConfirmTitle => '結案';

  @override
  String closeCaseConfirmContent(String name) {
    return '將「$name」這個案件標記為已結案?';
  }

  @override
  String get closeCase => '結案';

  @override
  String get careDashboardTitle => '教會關懷中央看版';

  @override
  String tabMemberActive(int count) {
    return '會友 ($count)';
  }

  @override
  String tabNewcomerActive(int count) {
    return '新朋友 ($count)';
  }

  @override
  String tabVisitedHistory(int count) {
    return '已探訪者 ($count)';
  }

  @override
  String get careSearchHint => '搜尋會友姓名 / 緣由 / 備註';

  @override
  String addNewCaseLabel(String label) {
    return '新增$label案件';
  }

  @override
  String get alertRedTitle => '需要立刻處理';

  @override
  String get alertYellowTitle => '即將需要安排';

  @override
  String get alertGreenTitle => '在追蹤中';

  @override
  String get historyNoResults => '沒有符合的人';

  @override
  String get historyEmpty => '暫無探訪歷史';

  @override
  String get historyEmptyHint => '在會友 / 新朋友 tab 開新案件並記錄探訪後,會出現喺度';

  @override
  String get searchNoCaseResults => '沒有符合的案件';

  @override
  String tabEmptyCaseState(String label) {
    return '目前沒有$label案件';
  }

  @override
  String addNewCaseButton(String label) {
    return '新增$label案件';
  }

  @override
  String get today => '今天';

  @override
  String daysNoVisit(int days) {
    return '🕐 $days 天沒探訪';
  }

  @override
  String caseRowSummary(String reason, String urgency) {
    return '$reason  ·  $urgency優先';
  }

  @override
  String caseRowLastVisitPrefix(String visitedBy, String date) {
    return '上次:$visitedBy $date ';
  }

  @override
  String get noVisitRecorded => '尚未探訪過';

  @override
  String get detailsButton => '詳情';

  @override
  String get logVisitButton => '記探訪';

  @override
  String get editCaseTooltip => '編輯案件';

  @override
  String get closeCaseTooltip => '結案';

  @override
  String get statusActiveBadge => '進行中';

  @override
  String historyRowLastVisit(String visitedBy, String method, String date) {
    return '上次:$visitedBy · $method · $date';
  }

  @override
  String get historyNoVisitRecorded => '尚未探訪過';

  @override
  String historyRowStats(int totalVisits, int caseCount) {
    return '共 $totalVisits 次探訪 · $caseCount 個案件';
  }

  @override
  String daysAgo(int days) {
    return '$days 天前';
  }

  @override
  String weeksAgo(int weeks) {
    return '$weeks 週前';
  }

  @override
  String monthsAgo(int months) {
    return '$months 個月前';
  }

  @override
  String yearsAgo(int years) {
    return '$years 年前';
  }

  @override
  String saveFailed(String error) {
    return '儲存失敗:$error';
  }

  @override
  String get deleteConfirmTitle => '確認刪除';

  @override
  String get deleteConfirmContent => '此會友嘅通訊錄資料會被永久刪除(相關探訪案件不會刪除)。';

  @override
  String editPersonTitle(String label) {
    return '編輯$label';
  }

  @override
  String addPersonTitle(String label) {
    return '新增$label';
  }

  @override
  String get fieldNameLabel => '姓名 *';

  @override
  String get fieldNameRequired => '請輸入姓名';

  @override
  String get fieldPhoneLabel => '電話(可空)';

  @override
  String get fieldBirthdayLabel => '生日';

  @override
  String get sectionChurchLife => '教會生命';

  @override
  String get fieldBaptismDateLabel => '洗禮日期';

  @override
  String get fieldJoinDateLabel => '轉會 / 加入日期';

  @override
  String get fieldAttendanceLabel => '出席崇拜';

  @override
  String get sectionParticipation => '參與';

  @override
  String get fieldSmallGroupLabel => '所屬小組 / 團契';

  @override
  String get fieldSmallGroupHint => '例:週三長者團、夫婦團契 B 組';

  @override
  String get fieldSundaySchoolLabel => '主日學參與';

  @override
  String get fieldSundaySchoolHint => '例:成人 B 班 - 學生、兒童老師';

  @override
  String get sectionOthers => '其他';

  @override
  String get fieldCreatedByLabel => '建立者(傳道人姓名)';

  @override
  String get fieldNotesLabel => '備註(可空)';

  @override
  String get commonSaving => '儲存中...';

  @override
  String get defaultNewcomerReason => '新朋友';

  @override
  String get deleteCaseConfirmContent => '此案件和所有相關探訪記錄都會被永久刪除。';

  @override
  String get editCaseTitle => '編輯案件';

  @override
  String get addNewCaseTitle => '新增關懷案件';

  @override
  String get fieldNewcomerNameLabel => '新朋友姓名 *';

  @override
  String get fieldMemberNameLabel => '會友姓名 *';

  @override
  String get fieldReasonLabel => '緣由 *(例:住院、喪父、新朋友追蹤)';

  @override
  String get fieldReasonRequired => '請輸入緣由';

  @override
  String get fieldIdentityLabel => '身分';

  @override
  String get fieldUrgencyLabel => '優先程度';

  @override
  String get urgencyLegend => '高 = 3 天紅燈 / 中 = 7 天紅燈 / 低 = 14 天紅燈';

  @override
  String get notSet => '未設定';

  @override
  String get clear => '清除';

  @override
  String get aiHighlight => 'AI 高亮';

  @override
  String get aiNotes => 'AI 註記';

  @override
  String get aiGuidedReading => 'AI 導讀';

  @override
  String get aiMindMap => 'AI 思維導圖';

  @override
  String get aiWordCard => 'AI 單字';

  @override
  String get close => '關閉';

  @override
  String get generateFailed => '生成失敗，請稍後再試。';

  @override
  String get learningHub => '學習天地';

  @override
  String get learningHubSubtitle => '日文與英文學習工具';

  @override
  String get grammarAnalysis => '文法解析';

  @override
  String get inputSentenceHint => '請輸入日文句子進行解析...';

  @override
  String get vocabAnalysis => '單字解析';

  @override
  String get inputWordHint => '請輸入日文單字進行解析...';

  @override
  String get vocabAnalysisFailed => '單字解析失敗，請稍後再試。';

  @override
  String get sentenceGeneration => '例句生成';

  @override
  String get aiSentence => 'AI 例句';

  @override
  String get inputSentenceWordHint => '請輸入日文單字以生成例句...';

  @override
  String get sentenceGenerationFailed => '例句生成失敗，請稍後再試。';

  @override
  String get stopSpeaking => '停止朗讀';

  @override
  String get speakPronunciation => '語音朗讀';

  @override
  String get japaneseLab => '日文學習';

  @override
  String get englishLab => '英文學習';

  @override
  String get enGrammarAnalysis => '英文文法解析';

  @override
  String get enInputSentenceHint => '請輸入英文句子進行解析...';

  @override
  String get enVocabAnalysis => '英文單字解析';

  @override
  String get enInputWordHint => '請輸入英文單字...';

  @override
  String get enVocabAnalysisFailed => '英文單字解析失敗，請稍後再試。';

  @override
  String get enSentenceGeneration => '英文例句與測驗';

  @override
  String get enAiSentence => 'AI 英文例句與測驗';

  @override
  String get enInputSentenceWordHint => '請輸入英文單字以生成例句與測驗...';

  @override
  String get enSentenceGenerationFailed => '生成例句與測驗失敗，請稍後再試。';
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

  @override
  String get churchHubTitle => '会友管理';

  @override
  String get churchNoMembers => '暂无会友资料';

  @override
  String get churchAddMember => '新增会友';

  @override
  String get churchSearchHint => '搜索姓名 / 电话';

  @override
  String get churchDirectoryTitle => '會友通訊錄';

  @override
  String get searchHint => '搜尋姓名 / 電話 / 小組 / 主日學 / 備註';

  @override
  String filterMemberCount(int count) {
    return '會友 ($count)';
  }

  @override
  String filterSeekerCount(int count) {
    return '非會友 ($count)';
  }

  @override
  String filterAllCount(int count) {
    return '全部 ($count)';
  }

  @override
  String filterMemberRegularCount(int count) {
    return '經常參加崇拜的會友 ($count)';
  }

  @override
  String filterSeekerRegularCount(int count) {
    return '經常參加崇拜的非會友 ($count)';
  }

  @override
  String filterMemberOccasionalCount(int count) {
    return '偶爾參加崇拜的會友 ($count)';
  }

  @override
  String filterSeekerOccasionalCount(int count) {
    return '偶爾參加崇拜的非會友 ($count)';
  }

  @override
  String filterMemberInactiveCount(int count) {
    return '久未參加崇拜的會友 ($count)';
  }

  @override
  String filterSeekerInactiveCount(int count) {
    return '久未參加崇拜的非會友 ($count)';
  }

  @override
  String get noSearchResults => '無符合搜尋條件嘅會友';

  @override
  String get emptyDirectory => '通訊錄空白';

  @override
  String get emptyDirectoryHint => '撳右下角加第一個會友';

  @override
  String personRowSmallGroup(String group) {
    return '小組:$group';
  }

  @override
  String personRowSundaySchool(String school) {
    return '主日學:$school';
  }

  @override
  String get historyTooltip => '歷史紀錄';

  @override
  String get closeCaseConfirmTitle => '結案';

  @override
  String closeCaseConfirmContent(String name) {
    return '將「$name」這個案件標記為已結案?';
  }

  @override
  String get closeCase => '結案';

  @override
  String get careDashboardTitle => '教會關懷中央看版';

  @override
  String tabMemberActive(int count) {
    return '會友 ($count)';
  }

  @override
  String tabNewcomerActive(int count) {
    return '新朋友 ($count)';
  }

  @override
  String tabVisitedHistory(int count) {
    return '已探訪者 ($count)';
  }

  @override
  String get careSearchHint => '搜尋會友姓名 / 緣由 / 備註';

  @override
  String addNewCaseLabel(String label) {
    return '新增$label案件';
  }

  @override
  String get alertRedTitle => '需要立刻處理';

  @override
  String get alertYellowTitle => '即將需要安排';

  @override
  String get alertGreenTitle => '在追蹤中';

  @override
  String get historyNoResults => '沒有符合的人';

  @override
  String get historyEmpty => '暫無探訪歷史';

  @override
  String get historyEmptyHint => '在會友 / 新朋友 tab 開新案件並記錄探訪後,會出現喺度';

  @override
  String get searchNoCaseResults => '沒有符合的案件';

  @override
  String tabEmptyCaseState(String label) {
    return '目前沒有$label案件';
  }

  @override
  String addNewCaseButton(String label) {
    return '新增$label案件';
  }

  @override
  String get today => '今天';

  @override
  String daysNoVisit(int days) {
    return '🕐 $days 天沒探訪';
  }

  @override
  String caseRowSummary(String reason, String urgency) {
    return '$reason  ·  $urgency優先';
  }

  @override
  String caseRowLastVisitPrefix(String visitedBy, String date) {
    return '上次:$visitedBy $date ';
  }

  @override
  String get noVisitRecorded => '尚未探訪過';

  @override
  String get detailsButton => '詳情';

  @override
  String get logVisitButton => '記探訪';

  @override
  String get editCaseTooltip => '編輯案件';

  @override
  String get closeCaseTooltip => '結案';

  @override
  String get statusActiveBadge => '進行中';

  @override
  String historyRowLastVisit(String visitedBy, String method, String date) {
    return '上次:$visitedBy · $method · $date';
  }

  @override
  String get historyNoVisitRecorded => '尚未探訪過';

  @override
  String historyRowStats(int totalVisits, int caseCount) {
    return '共 $totalVisits 次探訪 · $caseCount 個案件';
  }

  @override
  String daysAgo(int days) {
    return '$days 天前';
  }

  @override
  String weeksAgo(int weeks) {
    return '$weeks 週前';
  }

  @override
  String monthsAgo(int months) {
    return '$months 個月前';
  }

  @override
  String yearsAgo(int years) {
    return '$years 年前';
  }

  @override
  String saveFailed(String error) {
    return '儲存失敗:$error';
  }

  @override
  String get deleteConfirmTitle => '確認刪除';

  @override
  String get deleteConfirmContent => '此會友嘅通訊錄資料會被永久刪除(相關探訪案件不會刪除)。';

  @override
  String editPersonTitle(String label) {
    return '編輯$label';
  }

  @override
  String addPersonTitle(String label) {
    return '新增$label';
  }

  @override
  String get fieldNameLabel => '姓名 *';

  @override
  String get fieldNameRequired => '請輸入姓名';

  @override
  String get fieldPhoneLabel => '電話(可空)';

  @override
  String get fieldBirthdayLabel => '生日';

  @override
  String get sectionChurchLife => '教會生命';

  @override
  String get fieldBaptismDateLabel => '洗禮日期';

  @override
  String get fieldJoinDateLabel => '轉會 / 加入日期';

  @override
  String get fieldAttendanceLabel => '出席崇拜';

  @override
  String get sectionParticipation => '參與';

  @override
  String get fieldSmallGroupLabel => '所屬小組 / 團契';

  @override
  String get fieldSmallGroupHint => '例:週三長者團、夫婦團契 B 組';

  @override
  String get fieldSundaySchoolLabel => '主日學參與';

  @override
  String get fieldSundaySchoolHint => '例:成人 B 班 - 學生、兒童老師';

  @override
  String get sectionOthers => '其他';

  @override
  String get fieldCreatedByLabel => '建立者(傳道人姓名)';

  @override
  String get fieldNotesLabel => '備註(可空)';

  @override
  String get commonSaving => '儲存中...';

  @override
  String get defaultNewcomerReason => '新朋友';

  @override
  String get deleteCaseConfirmContent => '此案件和所有相關探訪記錄都會被永久刪除。';

  @override
  String get editCaseTitle => '編輯案件';

  @override
  String get addNewCaseTitle => '新增關懷案件';

  @override
  String get fieldNewcomerNameLabel => '新朋友姓名 *';

  @override
  String get fieldMemberNameLabel => '會友姓名 *';

  @override
  String get fieldReasonLabel => '緣由 *(例:住院、喪父、新朋友追蹤)';

  @override
  String get fieldReasonRequired => '請輸入緣由';

  @override
  String get fieldIdentityLabel => '身分';

  @override
  String get fieldUrgencyLabel => '優先程度';

  @override
  String get urgencyLegend => '高 = 3 天紅燈 / 中 = 7 天紅燈 / 低 = 14 天紅燈';

  @override
  String get notSet => '未設定';

  @override
  String get clear => '清除';

  @override
  String get aiHighlight => 'AI 高亮';

  @override
  String get aiNotes => 'AI 注记';

  @override
  String get aiGuidedReading => 'AI 导读';

  @override
  String get aiMindMap => 'AI 思维导图';

  @override
  String get aiWordCard => 'AI 单词';

  @override
  String get close => '关闭';

  @override
  String get generateFailed => '生成失败，请稍后再试。';

  @override
  String get learningHub => '学习天地';

  @override
  String get learningHubSubtitle => '日文与英文学习工具';

  @override
  String get grammarAnalysis => '语法解析';

  @override
  String get inputSentenceHint => '请输入日文句子进行解析...';

  @override
  String get vocabAnalysis => '单词解析';

  @override
  String get inputWordHint => '请输入日文单词进行解析...';

  @override
  String get vocabAnalysisFailed => '单词解析失败，请稍后再试。';

  @override
  String get sentenceGeneration => '例句生成';

  @override
  String get aiSentence => 'AI 例句';

  @override
  String get inputSentenceWordHint => '请输入日文单词以生成例句...';

  @override
  String get sentenceGenerationFailed => '例句生成失败，请稍后再试。';

  @override
  String get stopSpeaking => '停止朗读';

  @override
  String get speakPronunciation => '语音朗读';

  @override
  String get japaneseLab => '日文学习';

  @override
  String get englishLab => '英文学习';

  @override
  String get enGrammarAnalysis => '英文语法解析';

  @override
  String get enInputSentenceHint => '请输入英文句子进行解析...';

  @override
  String get enVocabAnalysis => '英文单词解析';

  @override
  String get enInputWordHint => '请输入英文单词...';

  @override
  String get enVocabAnalysisFailed => '英文单词解析失败，请稍后再试。';

  @override
  String get enSentenceGeneration => '英文例句与测验';

  @override
  String get enAiSentence => 'AI 英文例句与测验';

  @override
  String get enInputSentenceWordHint => '请输入英文单词以生成例句与测验...';

  @override
  String get enSentenceGenerationFailed => '生成例句与测验失败，请稍后再试。';
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

  @override
  String get churchHubTitle => '會友管理';

  @override
  String get churchNoMembers => '目前尚無會友資料';

  @override
  String get churchAddMember => '新增會友';

  @override
  String get churchSearchHint => '搜尋姓名 / 電話';

  @override
  String get churchDirectoryTitle => '會友通訊錄';

  @override
  String get searchHint => '搜尋姓名 / 電話 / 小組 / 主日學 / 備註';

  @override
  String filterMemberCount(int count) {
    return '會友 ($count)';
  }

  @override
  String filterSeekerCount(int count) {
    return '非會友 ($count)';
  }

  @override
  String filterAllCount(int count) {
    return '全部 ($count)';
  }

  @override
  String filterMemberRegularCount(int count) {
    return '經常參加崇拜的會友 ($count)';
  }

  @override
  String filterSeekerRegularCount(int count) {
    return '經常參加崇拜的非會友 ($count)';
  }

  @override
  String filterMemberOccasionalCount(int count) {
    return '偶爾參加崇拜的會友 ($count)';
  }

  @override
  String filterSeekerOccasionalCount(int count) {
    return '偶爾參加崇拜的非會友 ($count)';
  }

  @override
  String filterMemberInactiveCount(int count) {
    return '久未參加崇拜的會友 ($count)';
  }

  @override
  String filterSeekerInactiveCount(int count) {
    return '久未參加崇拜的非會友 ($count)';
  }

  @override
  String get noSearchResults => '無符合搜尋條件嘅會友';

  @override
  String get emptyDirectory => '通訊錄空白';

  @override
  String get emptyDirectoryHint => '撳右下角加第一個會友';

  @override
  String personRowSmallGroup(String group) {
    return '小組:$group';
  }

  @override
  String personRowSundaySchool(String school) {
    return '主日學:$school';
  }

  @override
  String get historyTooltip => '歷史紀錄';

  @override
  String get closeCaseConfirmTitle => '結案';

  @override
  String closeCaseConfirmContent(String name) {
    return '將「$name」這個案件標記為已結案?';
  }

  @override
  String get closeCase => '結案';

  @override
  String get careDashboardTitle => '教會關懷中央看版';

  @override
  String tabMemberActive(int count) {
    return '會友 ($count)';
  }

  @override
  String tabNewcomerActive(int count) {
    return '新朋友 ($count)';
  }

  @override
  String tabVisitedHistory(int count) {
    return '已探訪者 ($count)';
  }

  @override
  String get careSearchHint => '搜尋會友姓名 / 緣由 / 備註';

  @override
  String addNewCaseLabel(String label) {
    return '新增$label案件';
  }

  @override
  String get alertRedTitle => '需要立刻處理';

  @override
  String get alertYellowTitle => '即將需要安排';

  @override
  String get alertGreenTitle => '在追蹤中';

  @override
  String get historyNoResults => '沒有符合的人';

  @override
  String get historyEmpty => '暫無探訪歷史';

  @override
  String get historyEmptyHint => '在會友 / 新朋友 tab 開新案件並記錄探訪後,會出現喺度';

  @override
  String get searchNoCaseResults => '沒有符合的案件';

  @override
  String tabEmptyCaseState(String label) {
    return '目前沒有$label案件';
  }

  @override
  String addNewCaseButton(String label) {
    return '新增$label案件';
  }

  @override
  String get today => '今天';

  @override
  String daysNoVisit(int days) {
    return '🕐 $days 天沒探訪';
  }

  @override
  String caseRowSummary(String reason, String urgency) {
    return '$reason  ·  $urgency優先';
  }

  @override
  String caseRowLastVisitPrefix(String visitedBy, String date) {
    return '上次:$visitedBy $date ';
  }

  @override
  String get noVisitRecorded => '尚未探訪過';

  @override
  String get detailsButton => '詳情';

  @override
  String get logVisitButton => '記探訪';

  @override
  String get editCaseTooltip => '編輯案件';

  @override
  String get closeCaseTooltip => '結案';

  @override
  String get statusActiveBadge => '進行中';

  @override
  String historyRowLastVisit(String visitedBy, String method, String date) {
    return '上次:$visitedBy · $method · $date';
  }

  @override
  String get historyNoVisitRecorded => '尚未探訪過';

  @override
  String historyRowStats(int totalVisits, int caseCount) {
    return '共 $totalVisits 次探訪 · $caseCount 個案件';
  }

  @override
  String daysAgo(int days) {
    return '$days 天前';
  }

  @override
  String weeksAgo(int weeks) {
    return '$weeks 週前';
  }

  @override
  String monthsAgo(int months) {
    return '$months 個月前';
  }

  @override
  String yearsAgo(int years) {
    return '$years 年前';
  }

  @override
  String saveFailed(String error) {
    return '儲存失敗:$error';
  }

  @override
  String get deleteConfirmTitle => '確認刪除';

  @override
  String get deleteConfirmContent => '此會友嘅通訊錄資料會被永久刪除(相關探訪案件不會刪除)。';

  @override
  String editPersonTitle(String label) {
    return '編輯$label';
  }

  @override
  String addPersonTitle(String label) {
    return '新增$label';
  }

  @override
  String get fieldNameLabel => '姓名 *';

  @override
  String get fieldNameRequired => '請輸入姓名';

  @override
  String get fieldPhoneLabel => '電話(可空)';

  @override
  String get fieldBirthdayLabel => '生日';

  @override
  String get sectionChurchLife => '教會生命';

  @override
  String get fieldBaptismDateLabel => '洗禮日期';

  @override
  String get fieldJoinDateLabel => '轉會 / 加入日期';

  @override
  String get fieldAttendanceLabel => '出席崇拜';

  @override
  String get sectionParticipation => '參與';

  @override
  String get fieldSmallGroupLabel => '所屬小組 / 團契';

  @override
  String get fieldSmallGroupHint => '例:週三長者團、夫婦團契 B 組';

  @override
  String get fieldSundaySchoolLabel => '主日學參與';

  @override
  String get fieldSundaySchoolHint => '例:成人 B 班 - 學生、兒童老師';

  @override
  String get sectionOthers => '其他';

  @override
  String get fieldCreatedByLabel => '建立者(傳道人姓名)';

  @override
  String get fieldNotesLabel => '備註(可空)';

  @override
  String get commonSaving => '儲存中...';

  @override
  String get defaultNewcomerReason => '新朋友';

  @override
  String get deleteCaseConfirmContent => '此案件和所有相關探訪記錄都會被永久刪除。';

  @override
  String get editCaseTitle => '編輯案件';

  @override
  String get addNewCaseTitle => '新增關懷案件';

  @override
  String get fieldNewcomerNameLabel => '新朋友姓名 *';

  @override
  String get fieldMemberNameLabel => '會友姓名 *';

  @override
  String get fieldReasonLabel => '緣由 *(例:住院、喪父、新朋友追蹤)';

  @override
  String get fieldReasonRequired => '請輸入緣由';

  @override
  String get fieldIdentityLabel => '身分';

  @override
  String get fieldUrgencyLabel => '優先程度';

  @override
  String get urgencyLegend => '高 = 3 天紅燈 / 中 = 7 天紅燈 / 低 = 14 天紅燈';

  @override
  String get notSet => '未設定';

  @override
  String get clear => '清除';

  @override
  String get aiHighlight => 'AI 高亮';

  @override
  String get aiNotes => 'AI 註記';

  @override
  String get aiGuidedReading => 'AI 導讀';

  @override
  String get aiMindMap => 'AI 思維導圖';

  @override
  String get aiWordCard => 'AI 單字';

  @override
  String get close => '關閉';

  @override
  String get generateFailed => '生成失敗，請稍後再試。';

  @override
  String get learningHub => '學習天地';

  @override
  String get learningHubSubtitle => '日文與英文學習工具';

  @override
  String get grammarAnalysis => '文法解析';

  @override
  String get inputSentenceHint => '請輸入日文句子進行解析...';

  @override
  String get vocabAnalysis => '單字解析';

  @override
  String get inputWordHint => '請輸入日文單字進行解析...';

  @override
  String get vocabAnalysisFailed => '單字解析失敗，請稍後再試。';

  @override
  String get sentenceGeneration => '例句生成';

  @override
  String get aiSentence => 'AI 例句';

  @override
  String get inputSentenceWordHint => '請輸入日文單字以生成例句...';

  @override
  String get sentenceGenerationFailed => '例句生成失敗，請稍後再試。';

  @override
  String get stopSpeaking => '停止朗讀';

  @override
  String get speakPronunciation => '語音朗讀';

  @override
  String get japaneseLab => '日文學習';

  @override
  String get englishLab => '英文學習';

  @override
  String get enGrammarAnalysis => '英文文法解析';

  @override
  String get enInputSentenceHint => '請輸入英文句子進行解析...';

  @override
  String get enVocabAnalysis => '英文單字解析';

  @override
  String get enInputWordHint => '請輸入英文單字...';

  @override
  String get enVocabAnalysisFailed => '英文單字解析失敗，請稍後再試。';

  @override
  String get enSentenceGeneration => '英文例句與測驗';

  @override
  String get enAiSentence => 'AI 英文例句與測驗';

  @override
  String get enInputSentenceWordHint => '請輸入英文單字以生成例句與測驗...';

  @override
  String get enSentenceGenerationFailed => '生成例句與測驗失敗，請稍後再試。';
}
