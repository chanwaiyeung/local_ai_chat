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
}
