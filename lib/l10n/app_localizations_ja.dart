// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'AIライブラリ';

  @override
  String get tabRecords => '記録';

  @override
  String get tabAllocation => '配分';

  @override
  String get investmentFinance => '投資・財務';

  @override
  String get noInvestmentRecords => '投資記録がありません';

  @override
  String get aiFinancialAdvisor => 'AI財務アドバイザー';

  @override
  String get totalAssets => '総資産';

  @override
  String get currencyLabel => '通貨：';

  @override
  String get moduleExpense => '日常支出';

  @override
  String get moduleContacts => '名刺管理';

  @override
  String get moduleHealth => '健康記録';

  @override
  String get moduleWealth => '投資・財務';

  @override
  String get moduleDashboardSoon => 'ダッシュボード';

  @override
  String get comingSoon => '近日公開';

  @override
  String expenseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件',
      zero: '記録なし',
    );
    return '$_temp0';
  }

  @override
  String get saveButton => '保存';

  @override
  String get cancelButton => 'キャンセル';

  @override
  String get deleteButton => '削除';

  @override
  String get settings => '設定';

  @override
  String get language => '言語';

  @override
  String get languageZhTw => '繁体字中国語';

  @override
  String get languageZhCn => '簡体字中国語';

  @override
  String get languageEn => '英語';

  @override
  String get personalHubTitle => 'パーソナルハブ';

  @override
  String get modules => 'モジュール';

  @override
  String dashboardTitle(int year, int month) {
    return '$year年$month月 ダッシュボード';
  }

  @override
  String get totalExpensesThisMonth => '今月の総支出';

  @override
  String get noExpensesThisMonth => '今月の支出はありません';

  @override
  String get totalContacts => '名刺の総数';

  @override
  String get healthRecords => '健康記録';

  @override
  String get investmentNetWorth => '投資純資産';

  @override
  String get quickAiQuery => 'AI クイック検索';

  @override
  String featureNotEnabled(String feature) {
    return '$feature：まだ有効ではありません';
  }

  @override
  String get aiQueryFeatureComingSoon => 'クロスモジュールAIクエリは近日公開予定';

  @override
  String get noRecordsYet => 'まだ記録がありません';

  @override
  String get noContactsYet => 'まだ名刺がありません';

  @override
  String recordCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件',
      zero: '記録なし',
    );
    return '$_temp0';
  }

  @override
  String contactCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件',
      zero: '連絡先なし',
    );
    return '$_temp0';
  }

  @override
  String get wealth => '投資・財務';

  @override
  String get assetAllocation => '資産配分';

  @override
  String get addRecord => '記録を追加';

  @override
  String get netWorth => '純資産';

  @override
  String get totalLiabilities => '総負債';

  @override
  String get searchAssetHint => '資産・メモ・タグを検索...';

  @override
  String get noDataToChart => 'チャートに表示するデータがありません';

  @override
  String get addFirstRecordHint => '「記録」タブで最初のデータを追加しましょう';

  @override
  String get netWorthOverview => '純資産概要';

  @override
  String assetCountLabel(int count) {
    return '$count件の資産';
  }

  @override
  String get valuationNote => '最新評価額に基づく合計（通貨換算なし）';

  @override
  String get noData => 'データなし';

  @override
  String get netWorthTrend => '純資産の推移';

  @override
  String get needTwoDatesForChart => '推移グラフには少なくとも2つの異なる日付が必要です';

  @override
  String get addInvestmentRecord => '投資記録を追加';

  @override
  String get editInvestmentRecord => '投資記録を編集';

  @override
  String get valuationDate => '評価日';

  @override
  String get assetClass => '資産クラス';

  @override
  String get assetNameHint => '資産名（任意、例：AAPL / 0050.TW）';

  @override
  String get amount => '金額';

  @override
  String get invalidAmountError => '有効な金額を入力してください';

  @override
  String get currency => '通貨';

  @override
  String get notes => 'メモ';

  @override
  String get tagsCommaSeparated => 'タグ（カンマ区切り）';

  @override
  String get aiHealthAdvisor => 'AI健康アドバイザー';

  @override
  String get searchHealthHint => 'メモ・タグを検索...';

  @override
  String get noHealthRecords => '健康記録がありません';

  @override
  String get noRecordsLast30Days => '過去30日間の記録がありません';

  @override
  String get last30DaysOverview => '過去30日間の概要';

  @override
  String recordCountUnit(int count) {
    return '$count件';
  }

  @override
  String get weight => '体重';

  @override
  String avgWeightStat(String val, int count) {
    return '平均 $val kg（$count回）';
  }

  @override
  String get bloodPressure => '血圧';

  @override
  String avgBpStat(String sys, String dia, int count) {
    return '平均 $sys / $dia mmHg（$count回）';
  }

  @override
  String get heartRate => '心拍数';

  @override
  String avgHeartRateStat(String val, int count) {
    return '平均 $val bpm（$count回）';
  }

  @override
  String get steps => '歩数';

  @override
  String totalStepsStat(String val, int count) {
    return '合計 $val歩（$count日）';
  }

  @override
  String get sleep => '睡眠';

  @override
  String avgSleepStat(String val, int count) {
    return '平均 $val時間（$count回）';
  }

  @override
  String get noDataLabel => '（データなし）';

  @override
  String get addHealthRecord => '健康記録を追加';

  @override
  String get editHealthRecord => '健康記録を編集';

  @override
  String get measurementDate => '測定日';

  @override
  String get weightKg => '体重（kg）';

  @override
  String get systolicMmHg => '収縮期血圧（mmHg）';

  @override
  String get diastolicMmHg => '拡張期血圧（mmHg）';

  @override
  String get heartRateBpm => '心拍数（bpm）';

  @override
  String get sleepHours => '睡眠時間（時間）';

  @override
  String get fillAtLeastOneMeasurement => '少なくとも1つの測定値またはメモを入力してください';

  @override
  String get trendCharts => 'トレンドグラフ';

  @override
  String get weightTrend => '体重トレンド（kg）';

  @override
  String get systolicTrend => '収縮期血圧トレンド（mmHg）';

  @override
  String get sleepHoursLabel => '睡眠時間';

  @override
  String get searchExpenseHint => '店舗・カテゴリ・メモを検索...';

  @override
  String get noMatchingExpenses => '条件に合う支出がありません';

  @override
  String get previousMonth => '先月';

  @override
  String get nextMonth => '翌月';

  @override
  String yearMonthTitle(int year, int month) {
    return '$year年$month月';
  }

  @override
  String monthlyTotal(String totalText) {
    return '月合計：$totalText';
  }

  @override
  String categoryAmountChip(String label, String amount) {
    return '$label · $amount';
  }

  @override
  String get noMerchant => '（店舗未入力）';

  @override
  String get addExpense => '支出を追加';

  @override
  String get editExpense => '支出を編集';

  @override
  String get merchant => '店舗';

  @override
  String get category => 'カテゴリ';

  @override
  String get defaultCategoriesLabel => 'デフォルトカテゴリ';

  @override
  String customCategoriesCount(int count) {
    return 'カスタムカテゴリ $count件';
  }

  @override
  String get paymentMethod => '支払方法';

  @override
  String get date => '日付';

  @override
  String get appearance => '外観';

  @override
  String get theme => 'テーマ';

  @override
  String get darkMode => 'ダークモード';

  @override
  String get lightMode => 'ライトモード';

  @override
  String get systemDefault => 'システム設定に従う';

  @override
  String get mySkills => 'スキルライブラリ';

  @override
  String get embeddingSettings => '埋め込みモデル設定';

  @override
  String get enterEmbeddingModelName => '埋め込みモデル名を入力してください';

  @override
  String get modelInstalled => 'インストール済み';

  @override
  String get modelNotInstalled => '未インストール。Ollama で pull してください';

  @override
  String get useCustomEmbeddingModel => 'カスタム埋め込みモデルを使用';

  @override
  String get customModelHint => '例：mxbai-embed-large';

  @override
  String currentSelection(String model) {
    return '現在の選択：$model';
  }

  @override
  String get changeModelWarning =>
      '注意：埋め込みモデルを変更すると現在のベクターストアがクリアされます。ドキュメントを再インポートしてください。';

  @override
  String get retrievalMode => '検索モード';

  @override
  String get denseMode => 'Dense：ベクトル意味検索';

  @override
  String get sparseMode => 'Sparse：BM25キーワード検索';

  @override
  String get hybridMode => 'Hybrid：Dense + BM25 + RRF';

  @override
  String get applySettings => '設定を適用';

  @override
  String get wealthExportCsv => 'CSVエクスポート';

  @override
  String get wealthCsvCopied => 'CSVをクリップボードにコピーしました';

  @override
  String get personalHubHealthRecords => '健康記録';

  @override
  String get personalHubThisMonthExpense => '今月の支出';

  @override
  String get wealthMonthlyReport => '月次レポート';

  @override
  String get wealthThisMonthTotal => '今月合計';

  @override
  String get wealthLastMonthTotal => '先月合計';

  @override
  String get wealthChange => '変化';

  @override
  String get records => '件';

  @override
  String get insightTitle => 'ワンタップ生活インサイト';

  @override
  String get insightSubtitle => '健康と財務の統合分析で、あなた専用の生活ガイドを作成します。';

  @override
  String get personalQueryTitle => 'パーソナルハブ AI クエリ';

  @override
  String get personalQueryHint => 'パーソナルハブに質問する';

  @override
  String get personalQueryHintSub => '支出と名刺を一度に検索できます。';

  @override
  String get skillsSearchHint => 'スキルを検索...';

  @override
  String get skillsEmpty => 'スキルカードがありません';

  @override
  String get skillsEmptyHint => 'AI回答後に「⭐ スキルとして保存」をタップ\nまたは右上のクラウドボタンで生成';

  @override
  String get skillSaved => 'スキルとして保存しました！';

  @override
  String get saveAsSkill => 'スキルとして保存';

  @override
  String get querySample1 => '山田部長と食事にいくら使いましたか？';

  @override
  String get querySample2 => '今月コンビニにいくら使いましたか？';

  @override
  String get querySample3 => 'Acme Corpの連絡先は？';

  @override
  String get addManually => '手動で追加';

  @override
  String get skillsSubtitle => 'AIラーニングライブラリ';

  @override
  String get settingsApiKeyRequired => '先にAPIキーを入力してください';

  @override
  String get settingsTestingConnection => '接続テスト中...';

  @override
  String get settingsCloudAiTitle => 'クラウドAIサービス（Gemini）';

  @override
  String get settingsCloudAiDesc =>
      'APIキーを設定してクラウドAI機能と資産モジュールの写真スキャンを有効にします。本機に安全に保存されます。';

  @override
  String get settingsTestConnection => '接続テスト';

  @override
  String get settingsTelegramTitle => 'Telegram連携';

  @override
  String get settingsTelegramDesc =>
      'Telegram Bot Tokenを設定してローカルAIを個人アシスタントにしましょう。@BotFatherから取得できます。';

  @override
  String get changeCurrency => '通貨を変更';

  @override
  String get chatTitle => 'チャット';

  @override
  String get libraryTitle => 'ライブラリ';

  @override
  String get libraryEmpty => 'アイテムがありません';

  @override
  String get chatInputHint => 'メッセージを入力...';

  @override
  String get readingModeTitle => '読書モード';

  @override
  String get churchHubTitle => '教会員管理';

  @override
  String get churchNoMembers => '会員がいません';

  @override
  String get churchAddMember => '会員を追加';

  @override
  String get churchSearchHint => '名前・電話番号を検索';

  @override
  String get churchDirectoryTitle => '教会名簿';

  @override
  String get searchHint => '名前・電話・スモールグループ・日曜学校・メモを検索';

  @override
  String filterMemberCount(int count) {
    return '会員（$count）';
  }

  @override
  String filterSeekerCount(int count) {
    return '求道者（$count）';
  }

  @override
  String filterAllCount(int count) {
    return '全員（$count）';
  }

  @override
  String filterMemberRegularCount(int count) {
    return '定期出席会員（$count）';
  }

  @override
  String filterSeekerRegularCount(int count) {
    return '定期出席求道者（$count）';
  }

  @override
  String filterMemberOccasionalCount(int count) {
    return '時折出席会員（$count）';
  }

  @override
  String filterSeekerOccasionalCount(int count) {
    return '時折出席求道者（$count）';
  }

  @override
  String filterMemberInactiveCount(int count) {
    return '長期欠席会員（$count）';
  }

  @override
  String filterSeekerInactiveCount(int count) {
    return '長期欠席求道者（$count）';
  }

  @override
  String get noSearchResults => '検索条件に合う会員がいません';

  @override
  String get emptyDirectory => '名簿が空です';

  @override
  String get emptyDirectoryHint => '右下のボタンで最初の会員を追加';

  @override
  String personRowSmallGroup(String group) {
    return 'グループ：$group';
  }

  @override
  String personRowSundaySchool(String school) {
    return '日曜学校：$school';
  }

  @override
  String get historyTooltip => '履歴';

  @override
  String get closeCaseConfirmTitle => 'ケースを閉じる';

  @override
  String closeCaseConfirmContent(String name) {
    return '「$name」のケースを完了としてマークしますか？';
  }

  @override
  String get closeCase => '閉じる';

  @override
  String get careDashboardTitle => '教会ケアダッシュボード';

  @override
  String tabMemberActive(int count) {
    return '会員（$count）';
  }

  @override
  String tabNewcomerActive(int count) {
    return '新来者（$count）';
  }

  @override
  String tabVisitedHistory(int count) {
    return '訪問済み（$count）';
  }

  @override
  String get careSearchHint => '会員名・理由・メモを検索';

  @override
  String addNewCaseLabel(String label) {
    return '$labelケースを追加';
  }

  @override
  String get alertRedTitle => '即時対応が必要';

  @override
  String get alertYellowTitle => '近日中に予約';

  @override
  String get alertGreenTitle => 'フォローアップ中';

  @override
  String get historyNoResults => '該当する人がいません';

  @override
  String get historyEmpty => '訪問履歴がありません';

  @override
  String get historyEmptyHint => '会員・新来者タブでケースを作成し訪問を記録すると表示されます';

  @override
  String get searchNoCaseResults => '該当するケースがありません';

  @override
  String tabEmptyCaseState(String label) {
    return '現在$labelケースはありません';
  }

  @override
  String addNewCaseButton(String label) {
    return '$labelケースを追加';
  }

  @override
  String get today => '今日';

  @override
  String daysNoVisit(int days) {
    return '🕐 $days日未訪問';
  }

  @override
  String caseRowSummary(String reason, String urgency) {
    return '$reason  ·  優先度$urgency';
  }

  @override
  String caseRowLastVisitPrefix(String visitedBy, String date) {
    return '前回：$visitedBy $date ';
  }

  @override
  String get noVisitRecorded => 'まだ訪問記録がありません';

  @override
  String get detailsButton => '詳細';

  @override
  String get logVisitButton => '訪問を記録';

  @override
  String get editCaseTooltip => 'ケースを編集';

  @override
  String get closeCaseTooltip => 'ケースを閉じる';

  @override
  String get statusActiveBadge => '進行中';

  @override
  String historyRowLastVisit(String visitedBy, String method, String date) {
    return '前回：$visitedBy · $method · $date';
  }

  @override
  String get historyNoVisitRecorded => 'まだ訪問記録がありません';

  @override
  String historyRowStats(int totalVisits, int caseCount) {
    return '合計 $totalVisits回訪問 · $caseCount件';
  }

  @override
  String daysAgo(int days) {
    return '$days日前';
  }

  @override
  String weeksAgo(int weeks) {
    return '$weeks週前';
  }

  @override
  String monthsAgo(int months) {
    return '$monthsヶ月前';
  }

  @override
  String yearsAgo(int years) {
    return '$years年前';
  }

  @override
  String saveFailed(String error) {
    return '保存失敗：$error';
  }

  @override
  String get deleteConfirmTitle => '削除確認';

  @override
  String get deleteConfirmContent => 'この会員の連絡先情報が完全に削除されます（関連するケアケースは削除されません）。';

  @override
  String editPersonTitle(String label) {
    return '$labelを編集';
  }

  @override
  String addPersonTitle(String label) {
    return '$labelを追加';
  }

  @override
  String get fieldNameLabel => '名前 *';

  @override
  String get fieldNameRequired => '名前を入力してください';

  @override
  String get fieldPhoneLabel => '電話（任意）';

  @override
  String get fieldBirthdayLabel => '誕生日';

  @override
  String get sectionChurchLife => '教会生活';

  @override
  String get fieldBaptismDateLabel => '洗礼日';

  @override
  String get fieldJoinDateLabel => '転入・入会日';

  @override
  String get fieldAttendanceLabel => '礼拝出席';

  @override
  String get sectionParticipation => '参加状況';

  @override
  String get fieldSmallGroupLabel => 'スモールグループ・フェローシップ';

  @override
  String get fieldSmallGroupHint => '例：水曜シニアグループ、夫婦フェローシップBグループ';

  @override
  String get fieldSundaySchoolLabel => '日曜学校';

  @override
  String get fieldSundaySchoolHint => '例：成人Bクラス - 学生、子供教師';

  @override
  String get sectionOthers => 'その他';

  @override
  String get fieldCreatedByLabel => '作成者（牧師名）';

  @override
  String get fieldNotesLabel => 'メモ（任意）';

  @override
  String get commonSaving => '保存中...';

  @override
  String get defaultNewcomerReason => '新来者';

  @override
  String get deleteCaseConfirmContent => 'このケースと関連するすべての訪問記録が完全に削除されます。';

  @override
  String get editCaseTitle => 'ケースを編集';

  @override
  String get addNewCaseTitle => 'ケアケースを追加';

  @override
  String get fieldNewcomerNameLabel => '新来者名 *';

  @override
  String get fieldMemberNameLabel => '会員名 *';

  @override
  String get fieldReasonLabel => '理由 *（例：入院、父逝去、新来者フォローアップ）';

  @override
  String get fieldReasonRequired => '理由を入力してください';

  @override
  String get fieldIdentityLabel => '身分';

  @override
  String get fieldUrgencyLabel => '緊急度';

  @override
  String get urgencyLegend => '高 = 3日で赤信号 / 中 = 7日で赤信号 / 低 = 14日で赤信号';

  @override
  String get notSet => '未設定';

  @override
  String get clear => 'クリア';

  @override
  String get aiHighlight => 'AI Highlight';

  @override
  String get aiNotes => 'AI Notes';

  @override
  String get aiGuidedReading => 'AI Guide';

  @override
  String get aiMindMap => 'AI Mind Map';

  @override
  String get aiWordCard => 'AI Vocab';

  @override
  String get close => 'Close';

  @override
  String get generateFailed => 'Generation failed. Please try again later.';

  @override
  String get learningHub => 'Learning Space';

  @override
  String get learningHubSubtitle => 'Japanese & English Learning Tools';

  @override
  String get grammarAnalysis => 'Grammar Analysis';

  @override
  String get inputSentenceHint => 'Enter a Japanese sentence to analyze...';

  @override
  String get vocabAnalysis => 'Vocabulary Analysis';

  @override
  String get inputWordHint => 'Enter a Japanese word to analyze...';

  @override
  String get vocabAnalysisFailed =>
      'Vocabulary analysis failed. Please try again later.';

  @override
  String get sentenceGeneration => 'Sentence Generation';

  @override
  String get aiSentence => 'AI Sentence';

  @override
  String get inputSentenceWordHint =>
      'Enter a Japanese word to generate sentences...';

  @override
  String get sentenceGenerationFailed =>
      'Sentence generation failed. Please try again later.';

  @override
  String get stopSpeaking => 'Stop';

  @override
  String get speakPronunciation => 'Read Aloud';

  @override
  String get japaneseLab => 'Japanese Lab';

  @override
  String get englishLab => 'English Lab';

  @override
  String get enGrammarAnalysis => 'English Grammar Analysis';

  @override
  String get enInputSentenceHint => 'Enter an English sentence to analyze...';

  @override
  String get enVocabAnalysis => 'English Vocabulary Analysis';

  @override
  String get enInputWordHint => 'Enter an English word...';

  @override
  String get enVocabAnalysisFailed =>
      'English vocabulary analysis failed. Please try again later.';

  @override
  String get enSentenceGeneration => 'English Sentence & Quiz';

  @override
  String get enAiSentence => 'AI English Sentence & Quiz';

  @override
  String get enInputSentenceWordHint =>
      'Enter an English word to generate sentences and quiz...';

  @override
  String get enSentenceGenerationFailed =>
      'Failed to generate English sentences and quiz. Please try again later.';
}
