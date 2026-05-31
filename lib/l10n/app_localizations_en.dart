// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AI Library';

  @override
  String get tabRecords => 'Records';

  @override
  String get tabAllocation => 'Allocation';

  @override
  String get investmentFinance => 'Investment';

  @override
  String get noInvestmentRecords => 'No investment records yet';

  @override
  String get aiFinancialAdvisor => 'AI Financial Advisor';

  @override
  String get totalAssets => 'Net Worth';

  @override
  String get currencyLabel => 'Currency:';

  @override
  String get moduleExpense => 'Expenses';

  @override
  String get moduleContacts => 'Contacts';

  @override
  String get moduleHealth => 'Health';

  @override
  String get moduleWealth => 'Investment';

  @override
  String get moduleDashboardSoon => 'Full Dashboard';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String expenseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count records',
      one: '1 record',
      zero: 'No records yet',
    );
    return '$_temp0';
  }

  @override
  String get saveButton => 'Save';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get deleteButton => 'Delete';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get languageZhTw => 'Traditional Chinese';

  @override
  String get languageZhCn => 'Simplified Chinese';

  @override
  String get languageEn => 'English';

  @override
  String get personalHubTitle => 'Personal Hub';

  @override
  String get modules => 'Modules';

  @override
  String dashboardTitle(int year, int month) {
    return 'Dashboard for $month/$year';
  }

  @override
  String get totalExpensesThisMonth => 'Total Expenses This Month';

  @override
  String get noExpensesThisMonth => 'No expenses this month';

  @override
  String get totalContacts => 'Total Contacts';

  @override
  String get healthRecords => 'Health Records';

  @override
  String get investmentNetWorth => 'Net Worth';

  @override
  String get quickAiQuery => 'Quick AI Query';

  @override
  String featureNotEnabled(String feature) {
    return '$feature: Not enabled yet';
  }

  @override
  String get aiQueryFeatureComingSoon =>
      'Cross-module AI query coming in Phase 6.3\'b';

  @override
  String get noRecordsYet => 'No records yet';

  @override
  String get noContactsYet => 'No contacts yet';

  @override
  String recordCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count records',
      one: '1 record',
      zero: 'No records yet',
    );
    return '$_temp0';
  }

  @override
  String contactCountPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count contacts',
      one: '1 contact',
      zero: 'No contacts yet',
    );
    return '$_temp0';
  }

  @override
  String get wealth => 'Investment & Finance';

  @override
  String get assetAllocation => 'Asset Allocation';

  @override
  String get addRecord => 'Add Record';

  @override
  String get netWorth => 'Net Worth';

  @override
  String get totalLiabilities => 'Total Liabilities';

  @override
  String get searchAssetHint => 'Search asset / notes / tags...';

  @override
  String get noDataToChart => 'No investment data to chart';

  @override
  String get addFirstRecordHint =>
      'Add your first record from the \'Records\' tab';

  @override
  String get netWorthOverview => 'Net Worth Overview';

  @override
  String assetCountLabel(int count) {
    return '$count Assets';
  }

  @override
  String get valuationNote =>
      'Based on latest valuation (no cross-currency conversion)';

  @override
  String get noData => 'No data';

  @override
  String get netWorthTrend => 'Net Worth Trend';

  @override
  String get needTwoDatesForChart =>
      'Need at least two different dates to chart trend';

  @override
  String get addInvestmentRecord => 'Add Investment Record';

  @override
  String get editInvestmentRecord => 'Edit Investment Record';

  @override
  String get valuationDate => 'Valuation Date';

  @override
  String get assetClass => 'Asset Class';

  @override
  String get assetNameHint => 'Asset Name (Optional, e.g., AAPL / 0050.TW)';

  @override
  String get amount => 'Amount';

  @override
  String get invalidAmountError => 'Please enter a valid amount';

  @override
  String get currency => 'Currency';

  @override
  String get notes => 'Notes';

  @override
  String get tagsCommaSeparated => 'Tags (comma separated)';

  @override
  String get aiHealthAdvisor => 'AI Health Advisor';

  @override
  String get searchHealthHint => 'Search notes / tags...';

  @override
  String get noHealthRecords => 'No health records yet';

  @override
  String get noRecordsLast30Days => 'No records in the last 30 days';

  @override
  String get last30DaysOverview => 'Last 30 days overview';

  @override
  String recordCountUnit(int count) {
    return '$count records';
  }

  @override
  String get weight => 'Weight';

  @override
  String avgWeightStat(String val, int count) {
    return 'Avg $val kg ($count times)';
  }

  @override
  String get bloodPressure => 'Blood Pressure';

  @override
  String avgBpStat(String sys, String dia, int count) {
    return 'Avg $sys / $dia mmHg ($count times)';
  }

  @override
  String get heartRate => 'Heart Rate';

  @override
  String avgHeartRateStat(String val, int count) {
    return 'Avg $val bpm ($count times)';
  }

  @override
  String get steps => 'Steps';

  @override
  String totalStepsStat(String val, int count) {
    return 'Total $val steps ($count days)';
  }

  @override
  String get sleep => 'Sleep';

  @override
  String avgSleepStat(String val, int count) {
    return 'Avg $val hours ($count times)';
  }

  @override
  String get noDataLabel => '(No data)';

  @override
  String get addHealthRecord => 'Add Health Record';

  @override
  String get editHealthRecord => 'Edit Health Record';

  @override
  String get measurementDate => 'Measurement Date';

  @override
  String get weightKg => 'Weight (kg)';

  @override
  String get systolicMmHg => 'Systolic (mmHg)';

  @override
  String get diastolicMmHg => 'Diastolic (mmHg)';

  @override
  String get heartRateBpm => 'Heart Rate (bpm)';

  @override
  String get sleepHours => 'Sleep Hours (hours)';

  @override
  String get fillAtLeastOneMeasurement =>
      'Please fill in at least one measurement or note';

  @override
  String get trendCharts => 'Trend Charts';

  @override
  String get weightTrend => 'Weight Trend (kg)';

  @override
  String get systolicTrend => 'Systolic Trend (mmHg)';

  @override
  String get sleepHoursLabel => 'Sleep Hours';

  @override
  String get searchExpenseHint => 'Search merchant / category / notes...';

  @override
  String get noMatchingExpenses => 'No matching expenses';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String yearMonthTitle(int year, int month) {
    return '$month / $year';
  }

  @override
  String monthlyTotal(String totalText) {
    return 'Monthly total: $totalText';
  }

  @override
  String categoryAmountChip(String label, String amount) {
    return '$label · $amount';
  }

  @override
  String get noMerchant => '(No merchant)';

  @override
  String get addExpense => 'Add Expense';

  @override
  String get editExpense => 'Edit Expense';

  @override
  String get merchant => 'Merchant';

  @override
  String get category => 'Category';

  @override
  String get defaultCategoriesLabel => 'Default categories';

  @override
  String customCategoriesCount(int count) {
    return '$count custom categories';
  }

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get date => 'Date';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get systemDefault => 'System Default';

  @override
  String get mySkills => 'My Skills';

  @override
  String get embeddingSettings => 'Embedding Settings';

  @override
  String get enterEmbeddingModelName => 'Please enter an embedding model name';

  @override
  String get modelInstalled => 'Installed';

  @override
  String get modelNotInstalled =>
      'Not installed, please pull this model using Ollama first';

  @override
  String get useCustomEmbeddingModel => 'Use custom embedding model';

  @override
  String get customModelHint => 'e.g., mxbai-embed-large';

  @override
  String currentSelection(String model) {
    return 'Current selection: $model';
  }

  @override
  String get changeModelWarning =>
      'Note: Changing the embedding model will clear the current vector store. Please re-import your documents.';

  @override
  String get retrievalMode => 'Retrieval Mode';

  @override
  String get denseMode => 'Dense: Vector Semantic Search';

  @override
  String get sparseMode => 'Sparse: BM25 Keyword Search';

  @override
  String get hybridMode => 'Hybrid: Dense + BM25 + RRF';

  @override
  String get applySettings => 'Apply Settings';

  @override
  String get wealthExportCsv => 'Export CSV';

  @override
  String get wealthCsvCopied => 'CSV copied to clipboard';

  @override
  String get personalHubHealthRecords => 'Health records';

  @override
  String get personalHubThisMonthExpense => 'This month\'s expenses';

  @override
  String get wealthMonthlyReport => 'Monthly Report';

  @override
  String get wealthThisMonthTotal => 'This month';

  @override
  String get wealthLastMonthTotal => 'Last month';

  @override
  String get wealthChange => 'Change';

  @override
  String get records => 'records';

  @override
  String get insightTitle => 'One-tap Life Insight';

  @override
  String get insightSubtitle =>
      'Combined Health & Wealth analysis, your personal life guide.';

  @override
  String get personalQueryTitle => 'Personal Hub AI Query';

  @override
  String get personalQueryHint => 'Ask your Personal Hub';

  @override
  String get personalQueryHintSub =>
      'Search across your expenses and contacts at once.';

  @override
  String get skillsSearchHint => 'Search skills...';

  @override
  String get skillsEmpty => 'No skill cards yet';

  @override
  String get skillsEmptyHint =>
      'After an AI reply, tap \'⭐ Save as Skill\'\nor tap the cloud button at top right to generate';

  @override
  String get skillSaved => 'Saved as skill!';

  @override
  String get saveAsSkill => 'Save as Skill';

  @override
  String get querySample1 => 'How much did I spend dining with Manager Wang?';

  @override
  String get querySample2 => 'How much did I spend at 7-11 this month?';

  @override
  String get querySample3 => 'Who are the contacts at Acme Corp?';

  @override
  String get addManually => 'Add Manually';

  @override
  String get skillsSubtitle => 'AI Learning Library';

  @override
  String get settingsApiKeyRequired => 'Please enter an API Key first';

  @override
  String get settingsTestingConnection => 'Testing connection...';

  @override
  String get settingsCloudAiTitle => 'Cloud AI Service (Gemini)';

  @override
  String get settingsCloudAiDesc =>
      'Set your API Key to enable cloud AI features and Wealth module photo scanning. This will be stored securely on your device.';

  @override
  String get settingsTestConnection => 'Test Connection';

  @override
  String get settingsTelegramTitle => 'Telegram Integration';

  @override
  String get settingsTelegramDesc =>
      'Set your Telegram Bot Token to make Local AI your personal assistant. Get it from @BotFather.';

  @override
  String get changeCurrency => 'Change currency';

  @override
  String get chatTitle => 'Chat';

  @override
  String get libraryTitle => 'Library';

  @override
  String get libraryEmpty => 'No items yet';

  @override
  String get chatInputHint => 'Type a message...';

  @override
  String get readingModeTitle => 'Reading Mode';

  @override
  String get churchHubTitle => 'Church Members';

  @override
  String get churchNoMembers => 'No members yet';

  @override
  String get churchAddMember => 'Add Member';

  @override
  String get churchSearchHint => 'Search name/phone';

  @override
  String get churchDirectoryTitle => 'Church Directory';

  @override
  String get searchHint =>
      'Search name / phone / small group / Sunday school / notes';

  @override
  String filterMemberCount(int count) {
    return 'Members ($count)';
  }

  @override
  String filterSeekerCount(int count) {
    return 'Seekers ($count)';
  }

  @override
  String filterAllCount(int count) {
    return 'All ($count)';
  }

  @override
  String filterMemberRegularCount(int count) {
    return 'Regular Members ($count)';
  }

  @override
  String filterSeekerRegularCount(int count) {
    return 'Regular Seekers ($count)';
  }

  @override
  String filterMemberOccasionalCount(int count) {
    return 'Occasional Members ($count)';
  }

  @override
  String filterSeekerOccasionalCount(int count) {
    return 'Occasional Seekers ($count)';
  }

  @override
  String filterMemberInactiveCount(int count) {
    return 'Inactive Members ($count)';
  }

  @override
  String filterSeekerInactiveCount(int count) {
    return 'Inactive Seekers ($count)';
  }

  @override
  String get noSearchResults => 'No members match search criteria';

  @override
  String get emptyDirectory => 'Directory is empty';

  @override
  String get emptyDirectoryHint => 'Tap FAB to add the first member';

  @override
  String personRowSmallGroup(String group) {
    return 'Group: $group';
  }

  @override
  String personRowSundaySchool(String school) {
    return 'Sunday School: $school';
  }

  @override
  String get historyTooltip => 'History Records';

  @override
  String get closeCaseConfirmTitle => 'Close Case';

  @override
  String closeCaseConfirmContent(String name) {
    return 'Mark case for \"$name\" as closed?';
  }

  @override
  String get closeCase => 'Close Case';

  @override
  String get careDashboardTitle => 'Care Dashboard';

  @override
  String tabMemberActive(int count) {
    return 'Members ($count)';
  }

  @override
  String tabNewcomerActive(int count) {
    return 'Newcomers ($count)';
  }

  @override
  String tabVisitedHistory(int count) {
    return 'Visited ($count)';
  }

  @override
  String get careSearchHint => 'Search member name / reason / notes';

  @override
  String addNewCaseLabel(String label) {
    return 'Add $label Case';
  }

  @override
  String get alertRedTitle => 'Requires immediate attention';

  @override
  String get alertYellowTitle => 'Should schedule soon';

  @override
  String get alertGreenTitle => 'Under follow-up';

  @override
  String get historyNoResults => 'No matching persons';

  @override
  String get historyEmpty => 'No visit history yet';

  @override
  String get historyEmptyHint =>
      'Open a new case and log a visit under Members/Newcomers to see it here';

  @override
  String get searchNoCaseResults => 'No matching cases';

  @override
  String tabEmptyCaseState(String label) {
    return 'No $label cases at present';
  }

  @override
  String addNewCaseButton(String label) {
    return 'Add $label Case';
  }

  @override
  String get today => 'Today';

  @override
  String daysNoVisit(int days) {
    return '🕐 $days days since last touch';
  }

  @override
  String caseRowSummary(String reason, String urgency) {
    return '$reason  ·  $urgency Priority';
  }

  @override
  String caseRowLastVisitPrefix(String visitedBy, String date) {
    return 'Last: $visitedBy $date ';
  }

  @override
  String get noVisitRecorded => 'No visits logged yet';

  @override
  String get detailsButton => 'Details';

  @override
  String get logVisitButton => 'Log Visit';

  @override
  String get editCaseTooltip => 'Edit Case';

  @override
  String get closeCaseTooltip => 'Close Case';

  @override
  String get statusActiveBadge => 'Active';

  @override
  String historyRowLastVisit(String visitedBy, String method, String date) {
    return 'Last: $visitedBy · $method · $date';
  }

  @override
  String get historyNoVisitRecorded => 'No visits logged yet';

  @override
  String historyRowStats(int totalVisits, int caseCount) {
    return 'Total $totalVisits visits · $caseCount cases';
  }

  @override
  String daysAgo(int days) {
    return '$days days ago';
  }

  @override
  String weeksAgo(int weeks) {
    return '$weeks weeks ago';
  }

  @override
  String monthsAgo(int months) {
    return '$months months ago';
  }

  @override
  String yearsAgo(int years) {
    return '$years years ago';
  }

  @override
  String saveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String get deleteConfirmTitle => 'Confirm Delete';

  @override
  String get deleteConfirmContent =>
      'This member\'s directory info will be permanently deleted (associated care cases will not be deleted).';

  @override
  String editPersonTitle(String label) {
    return 'Edit $label';
  }

  @override
  String addPersonTitle(String label) {
    return 'Add $label';
  }

  @override
  String get fieldNameLabel => 'Name *';

  @override
  String get fieldNameRequired => 'Please enter name';

  @override
  String get fieldPhoneLabel => 'Phone (optional)';

  @override
  String get fieldBirthdayLabel => 'Birthday';

  @override
  String get sectionChurchLife => 'Church Life';

  @override
  String get fieldBaptismDateLabel => 'Baptism Date';

  @override
  String get fieldJoinDateLabel => 'Transfer / Join Date';

  @override
  String get fieldAttendanceLabel => 'Worship Attendance';

  @override
  String get sectionParticipation => 'Participation';

  @override
  String get fieldSmallGroupLabel => 'Small Group / Fellowship';

  @override
  String get fieldSmallGroupHint =>
      'e.g., Wed Elderly Group, Couple Fellowship Group B';

  @override
  String get fieldSundaySchoolLabel => 'Sunday School';

  @override
  String get fieldSundaySchoolHint =>
      'e.g., Adult Class B - student, Children\'s teacher';

  @override
  String get sectionOthers => 'Others';

  @override
  String get fieldCreatedByLabel => 'Created By (Pastor Name)';

  @override
  String get fieldNotesLabel => 'Notes (optional)';

  @override
  String get commonSaving => 'Saving...';

  @override
  String get defaultNewcomerReason => 'Newcomer';

  @override
  String get deleteCaseConfirmContent =>
      'This case and all associated visit logs will be permanently deleted.';

  @override
  String get editCaseTitle => 'Edit Case';

  @override
  String get addNewCaseTitle => 'Add Care Case';

  @override
  String get fieldNewcomerNameLabel => 'Newcomer Name *';

  @override
  String get fieldMemberNameLabel => 'Member Name *';

  @override
  String get fieldReasonLabel =>
      'Reason * (e.g., hospitalized, father passed away, newcomer follow-up)';

  @override
  String get fieldReasonRequired => 'Please enter reason';

  @override
  String get fieldIdentityLabel => 'Identity';

  @override
  String get fieldUrgencyLabel => 'Urgency';

  @override
  String get urgencyLegend =>
      'High = 3 days red / Med = 7 days red / Low = 14 days red';

  @override
  String get notSet => 'Not set';

  @override
  String get clear => 'Clear';

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
