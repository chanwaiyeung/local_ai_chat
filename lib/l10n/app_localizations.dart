import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('zh'),
    Locale('zh', 'CN'),
    Locale('zh', 'TW')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Library'**
  String get appTitle;

  /// No description provided for @tabRecords.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get tabRecords;

  /// No description provided for @tabAllocation.
  ///
  /// In en, this message translates to:
  /// **'Allocation'**
  String get tabAllocation;

  /// No description provided for @investmentFinance.
  ///
  /// In en, this message translates to:
  /// **'Investment'**
  String get investmentFinance;

  /// No description provided for @noInvestmentRecords.
  ///
  /// In en, this message translates to:
  /// **'No investment records yet'**
  String get noInvestmentRecords;

  /// No description provided for @aiFinancialAdvisor.
  ///
  /// In en, this message translates to:
  /// **'AI Financial Advisor'**
  String get aiFinancialAdvisor;

  /// No description provided for @totalAssets.
  ///
  /// In en, this message translates to:
  /// **'Net Worth'**
  String get totalAssets;

  /// No description provided for @currencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency:'**
  String get currencyLabel;

  /// No description provided for @moduleExpense.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get moduleExpense;

  /// No description provided for @moduleContacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get moduleContacts;

  /// No description provided for @moduleHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get moduleHealth;

  /// No description provided for @moduleWealth.
  ///
  /// In en, this message translates to:
  /// **'Investment'**
  String get moduleWealth;

  /// No description provided for @moduleDashboardSoon.
  ///
  /// In en, this message translates to:
  /// **'Full Dashboard'**
  String get moduleDashboardSoon;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @expenseCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No records yet} =1{1 record} other{{count} records}}'**
  String expenseCount(int count);

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageZhTw.
  ///
  /// In en, this message translates to:
  /// **'Traditional Chinese'**
  String get languageZhTw;

  /// No description provided for @languageZhCn.
  ///
  /// In en, this message translates to:
  /// **'Simplified Chinese'**
  String get languageZhCn;

  /// No description provided for @languageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @personalHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal Hub'**
  String get personalHubTitle;

  /// No description provided for @modules.
  ///
  /// In en, this message translates to:
  /// **'Modules'**
  String get modules;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard for {month}/{year}'**
  String dashboardTitle(int year, int month);

  /// No description provided for @totalExpensesThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Total Expenses This Month'**
  String get totalExpensesThisMonth;

  /// No description provided for @noExpensesThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No expenses this month'**
  String get noExpensesThisMonth;

  /// No description provided for @totalContacts.
  ///
  /// In en, this message translates to:
  /// **'Total Contacts'**
  String get totalContacts;

  /// No description provided for @healthRecords.
  ///
  /// In en, this message translates to:
  /// **'Health Records'**
  String get healthRecords;

  /// No description provided for @investmentNetWorth.
  ///
  /// In en, this message translates to:
  /// **'Net Worth'**
  String get investmentNetWorth;

  /// No description provided for @quickAiQuery.
  ///
  /// In en, this message translates to:
  /// **'Quick AI Query'**
  String get quickAiQuery;

  /// No description provided for @featureNotEnabled.
  ///
  /// In en, this message translates to:
  /// **'{feature}: Not enabled yet'**
  String featureNotEnabled(String feature);

  /// No description provided for @aiQueryFeatureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Cross-module AI query coming in Phase 6.3\'b'**
  String get aiQueryFeatureComingSoon;

  /// No description provided for @noRecordsYet.
  ///
  /// In en, this message translates to:
  /// **'No records yet'**
  String get noRecordsYet;

  /// No description provided for @noContactsYet.
  ///
  /// In en, this message translates to:
  /// **'No contacts yet'**
  String get noContactsYet;

  /// No description provided for @recordCountPlural.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No records yet} =1{1 record} other{{count} records}}'**
  String recordCountPlural(int count);

  /// No description provided for @contactCountPlural.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No contacts yet} =1{1 contact} other{{count} contacts}}'**
  String contactCountPlural(int count);

  /// No description provided for @wealth.
  ///
  /// In en, this message translates to:
  /// **'Investment & Finance'**
  String get wealth;

  /// No description provided for @assetAllocation.
  ///
  /// In en, this message translates to:
  /// **'Asset Allocation'**
  String get assetAllocation;

  /// No description provided for @addRecord.
  ///
  /// In en, this message translates to:
  /// **'Add Record'**
  String get addRecord;

  /// No description provided for @netWorth.
  ///
  /// In en, this message translates to:
  /// **'Net Worth'**
  String get netWorth;

  /// No description provided for @totalLiabilities.
  ///
  /// In en, this message translates to:
  /// **'Total Liabilities'**
  String get totalLiabilities;

  /// No description provided for @searchAssetHint.
  ///
  /// In en, this message translates to:
  /// **'Search asset / notes / tags...'**
  String get searchAssetHint;

  /// No description provided for @noDataToChart.
  ///
  /// In en, this message translates to:
  /// **'No investment data to chart'**
  String get noDataToChart;

  /// No description provided for @addFirstRecordHint.
  ///
  /// In en, this message translates to:
  /// **'Add your first record from the \'Records\' tab'**
  String get addFirstRecordHint;

  /// No description provided for @netWorthOverview.
  ///
  /// In en, this message translates to:
  /// **'Net Worth Overview'**
  String get netWorthOverview;

  /// No description provided for @assetCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} Assets'**
  String assetCountLabel(int count);

  /// No description provided for @valuationNote.
  ///
  /// In en, this message translates to:
  /// **'Based on latest valuation (no cross-currency conversion)'**
  String get valuationNote;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @netWorthTrend.
  ///
  /// In en, this message translates to:
  /// **'Net Worth Trend'**
  String get netWorthTrend;

  /// No description provided for @needTwoDatesForChart.
  ///
  /// In en, this message translates to:
  /// **'Need at least two different dates to chart trend'**
  String get needTwoDatesForChart;

  /// No description provided for @addInvestmentRecord.
  ///
  /// In en, this message translates to:
  /// **'Add Investment Record'**
  String get addInvestmentRecord;

  /// No description provided for @editInvestmentRecord.
  ///
  /// In en, this message translates to:
  /// **'Edit Investment Record'**
  String get editInvestmentRecord;

  /// No description provided for @valuationDate.
  ///
  /// In en, this message translates to:
  /// **'Valuation Date'**
  String get valuationDate;

  /// No description provided for @assetClass.
  ///
  /// In en, this message translates to:
  /// **'Asset Class'**
  String get assetClass;

  /// No description provided for @assetNameHint.
  ///
  /// In en, this message translates to:
  /// **'Asset Name (Optional, e.g., AAPL / 0050.TW)'**
  String get assetNameHint;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @invalidAmountError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get invalidAmountError;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @tagsCommaSeparated.
  ///
  /// In en, this message translates to:
  /// **'Tags (comma separated)'**
  String get tagsCommaSeparated;

  /// No description provided for @aiHealthAdvisor.
  ///
  /// In en, this message translates to:
  /// **'AI Health Advisor'**
  String get aiHealthAdvisor;

  /// No description provided for @searchHealthHint.
  ///
  /// In en, this message translates to:
  /// **'Search notes / tags...'**
  String get searchHealthHint;

  /// No description provided for @noHealthRecords.
  ///
  /// In en, this message translates to:
  /// **'No health records yet'**
  String get noHealthRecords;

  /// No description provided for @noRecordsLast30Days.
  ///
  /// In en, this message translates to:
  /// **'No records in the last 30 days'**
  String get noRecordsLast30Days;

  /// No description provided for @last30DaysOverview.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days overview'**
  String get last30DaysOverview;

  /// No description provided for @recordCountUnit.
  ///
  /// In en, this message translates to:
  /// **'{count} records'**
  String recordCountUnit(int count);

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @avgWeightStat.
  ///
  /// In en, this message translates to:
  /// **'Avg {val} kg ({count} times)'**
  String avgWeightStat(String val, int count);

  /// No description provided for @bloodPressure.
  ///
  /// In en, this message translates to:
  /// **'Blood Pressure'**
  String get bloodPressure;

  /// No description provided for @avgBpStat.
  ///
  /// In en, this message translates to:
  /// **'Avg {sys} / {dia} mmHg ({count} times)'**
  String avgBpStat(String sys, String dia, int count);

  /// No description provided for @heartRate.
  ///
  /// In en, this message translates to:
  /// **'Heart Rate'**
  String get heartRate;

  /// No description provided for @avgHeartRateStat.
  ///
  /// In en, this message translates to:
  /// **'Avg {val} bpm ({count} times)'**
  String avgHeartRateStat(String val, int count);

  /// No description provided for @steps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get steps;

  /// No description provided for @totalStepsStat.
  ///
  /// In en, this message translates to:
  /// **'Total {val} steps ({count} days)'**
  String totalStepsStat(String val, int count);

  /// No description provided for @sleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get sleep;

  /// No description provided for @avgSleepStat.
  ///
  /// In en, this message translates to:
  /// **'Avg {val} hours ({count} times)'**
  String avgSleepStat(String val, int count);

  /// No description provided for @noDataLabel.
  ///
  /// In en, this message translates to:
  /// **'(No data)'**
  String get noDataLabel;

  /// No description provided for @addHealthRecord.
  ///
  /// In en, this message translates to:
  /// **'Add Health Record'**
  String get addHealthRecord;

  /// No description provided for @editHealthRecord.
  ///
  /// In en, this message translates to:
  /// **'Edit Health Record'**
  String get editHealthRecord;

  /// No description provided for @measurementDate.
  ///
  /// In en, this message translates to:
  /// **'Measurement Date'**
  String get measurementDate;

  /// No description provided for @weightKg.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get weightKg;

  /// No description provided for @systolicMmHg.
  ///
  /// In en, this message translates to:
  /// **'Systolic (mmHg)'**
  String get systolicMmHg;

  /// No description provided for @diastolicMmHg.
  ///
  /// In en, this message translates to:
  /// **'Diastolic (mmHg)'**
  String get diastolicMmHg;

  /// No description provided for @heartRateBpm.
  ///
  /// In en, this message translates to:
  /// **'Heart Rate (bpm)'**
  String get heartRateBpm;

  /// No description provided for @sleepHours.
  ///
  /// In en, this message translates to:
  /// **'Sleep Hours (hours)'**
  String get sleepHours;

  /// No description provided for @fillAtLeastOneMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Please fill in at least one measurement or note'**
  String get fillAtLeastOneMeasurement;

  /// No description provided for @trendCharts.
  ///
  /// In en, this message translates to:
  /// **'Trend Charts'**
  String get trendCharts;

  /// No description provided for @weightTrend.
  ///
  /// In en, this message translates to:
  /// **'Weight Trend (kg)'**
  String get weightTrend;

  /// No description provided for @systolicTrend.
  ///
  /// In en, this message translates to:
  /// **'Systolic Trend (mmHg)'**
  String get systolicTrend;

  /// No description provided for @sleepHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Sleep Hours'**
  String get sleepHoursLabel;

  /// No description provided for @searchExpenseHint.
  ///
  /// In en, this message translates to:
  /// **'Search merchant / category / notes...'**
  String get searchExpenseHint;

  /// No description provided for @noMatchingExpenses.
  ///
  /// In en, this message translates to:
  /// **'No matching expenses'**
  String get noMatchingExpenses;

  /// No description provided for @previousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get nextMonth;

  /// No description provided for @yearMonthTitle.
  ///
  /// In en, this message translates to:
  /// **'{month} / {year}'**
  String yearMonthTitle(int year, int month);

  /// No description provided for @monthlyTotal.
  ///
  /// In en, this message translates to:
  /// **'Monthly total: {totalText}'**
  String monthlyTotal(String totalText);

  /// No description provided for @categoryAmountChip.
  ///
  /// In en, this message translates to:
  /// **'{label} · {amount}'**
  String categoryAmountChip(String label, String amount);

  /// No description provided for @noMerchant.
  ///
  /// In en, this message translates to:
  /// **'(No merchant)'**
  String get noMerchant;

  /// No description provided for @addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get addExpense;

  /// No description provided for @editExpense.
  ///
  /// In en, this message translates to:
  /// **'Edit Expense'**
  String get editExpense;

  /// No description provided for @merchant.
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get merchant;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @defaultCategoriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Default categories'**
  String get defaultCategoriesLabel;

  /// No description provided for @customCategoriesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} custom categories'**
  String customCategoriesCount(int count);

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get lightMode;

  /// No description provided for @systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get systemDefault;

  /// No description provided for @mySkills.
  ///
  /// In en, this message translates to:
  /// **'My Skills'**
  String get mySkills;

  /// No description provided for @embeddingSettings.
  ///
  /// In en, this message translates to:
  /// **'Embedding Settings'**
  String get embeddingSettings;

  /// No description provided for @enterEmbeddingModelName.
  ///
  /// In en, this message translates to:
  /// **'Please enter an embedding model name'**
  String get enterEmbeddingModelName;

  /// No description provided for @modelInstalled.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get modelInstalled;

  /// No description provided for @modelNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'Not installed, please pull this model using Ollama first'**
  String get modelNotInstalled;

  /// No description provided for @useCustomEmbeddingModel.
  ///
  /// In en, this message translates to:
  /// **'Use custom embedding model'**
  String get useCustomEmbeddingModel;

  /// No description provided for @customModelHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., mxbai-embed-large'**
  String get customModelHint;

  /// No description provided for @currentSelection.
  ///
  /// In en, this message translates to:
  /// **'Current selection: {model}'**
  String currentSelection(String model);

  /// No description provided for @changeModelWarning.
  ///
  /// In en, this message translates to:
  /// **'Note: Changing the embedding model will clear the current vector store. Please re-import your documents.'**
  String get changeModelWarning;

  /// No description provided for @retrievalMode.
  ///
  /// In en, this message translates to:
  /// **'Retrieval Mode'**
  String get retrievalMode;

  /// No description provided for @denseMode.
  ///
  /// In en, this message translates to:
  /// **'Dense: Vector Semantic Search'**
  String get denseMode;

  /// No description provided for @sparseMode.
  ///
  /// In en, this message translates to:
  /// **'Sparse: BM25 Keyword Search'**
  String get sparseMode;

  /// No description provided for @hybridMode.
  ///
  /// In en, this message translates to:
  /// **'Hybrid: Dense + BM25 + RRF'**
  String get hybridMode;

  /// No description provided for @applySettings.
  ///
  /// In en, this message translates to:
  /// **'Apply Settings'**
  String get applySettings;

  /// No description provided for @wealthExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get wealthExportCsv;

  /// No description provided for @wealthCsvCopied.
  ///
  /// In en, this message translates to:
  /// **'CSV copied to clipboard'**
  String get wealthCsvCopied;

  /// No description provided for @personalHubHealthRecords.
  ///
  /// In en, this message translates to:
  /// **'Health records'**
  String get personalHubHealthRecords;

  /// No description provided for @personalHubThisMonthExpense.
  ///
  /// In en, this message translates to:
  /// **'This month\'s expenses'**
  String get personalHubThisMonthExpense;

  /// No description provided for @wealthMonthlyReport.
  ///
  /// In en, this message translates to:
  /// **'Monthly Report'**
  String get wealthMonthlyReport;

  /// No description provided for @wealthThisMonthTotal.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get wealthThisMonthTotal;

  /// No description provided for @wealthLastMonthTotal.
  ///
  /// In en, this message translates to:
  /// **'Last month'**
  String get wealthLastMonthTotal;

  /// No description provided for @wealthChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get wealthChange;

  /// No description provided for @records.
  ///
  /// In en, this message translates to:
  /// **'records'**
  String get records;

  /// No description provided for @insightTitle.
  ///
  /// In en, this message translates to:
  /// **'One-tap Life Insight'**
  String get insightTitle;

  /// No description provided for @insightSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Combined Health & Wealth analysis, your personal life guide.'**
  String get insightSubtitle;

  /// No description provided for @personalQueryTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal Hub AI Query'**
  String get personalQueryTitle;

  /// No description provided for @personalQueryHint.
  ///
  /// In en, this message translates to:
  /// **'Ask your Personal Hub'**
  String get personalQueryHint;

  /// No description provided for @personalQueryHintSub.
  ///
  /// In en, this message translates to:
  /// **'Search across your expenses and contacts at once.'**
  String get personalQueryHintSub;

  /// No description provided for @skillsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search skills...'**
  String get skillsSearchHint;

  /// No description provided for @skillsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No skill cards yet'**
  String get skillsEmpty;

  /// No description provided for @skillsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'After an AI reply, tap \'⭐ Save as Skill\'\nor tap the cloud button at top right to generate'**
  String get skillsEmptyHint;

  /// No description provided for @skillSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved as skill!'**
  String get skillSaved;

  /// No description provided for @saveAsSkill.
  ///
  /// In en, this message translates to:
  /// **'Save as Skill'**
  String get saveAsSkill;

  /// No description provided for @querySample1.
  ///
  /// In en, this message translates to:
  /// **'How much did I spend dining with Manager Wang?'**
  String get querySample1;

  /// No description provided for @querySample2.
  ///
  /// In en, this message translates to:
  /// **'How much did I spend at 7-11 this month?'**
  String get querySample2;

  /// No description provided for @querySample3.
  ///
  /// In en, this message translates to:
  /// **'Who are the contacts at Acme Corp?'**
  String get querySample3;

  /// No description provided for @addManually.
  ///
  /// In en, this message translates to:
  /// **'Add Manually'**
  String get addManually;

  /// No description provided for @skillsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'AI Learning Library'**
  String get skillsSubtitle;

  /// No description provided for @settingsApiKeyRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter an API Key first'**
  String get settingsApiKeyRequired;

  /// No description provided for @settingsTestingConnection.
  ///
  /// In en, this message translates to:
  /// **'Testing connection...'**
  String get settingsTestingConnection;

  /// No description provided for @settingsCloudAiTitle.
  ///
  /// In en, this message translates to:
  /// **'Cloud AI Service (Gemini)'**
  String get settingsCloudAiTitle;

  /// No description provided for @settingsCloudAiDesc.
  ///
  /// In en, this message translates to:
  /// **'Set your API Key to enable cloud AI features and Wealth module photo scanning. This will be stored securely on your device.'**
  String get settingsCloudAiDesc;

  /// No description provided for @settingsTestConnection.
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get settingsTestConnection;

  /// No description provided for @settingsTelegramTitle.
  ///
  /// In en, this message translates to:
  /// **'Telegram Integration'**
  String get settingsTelegramTitle;

  /// No description provided for @settingsTelegramDesc.
  ///
  /// In en, this message translates to:
  /// **'Set your Telegram Bot Token to make Local AI your personal assistant. Get it from @BotFather.'**
  String get settingsTelegramDesc;

  /// No description provided for @changeCurrency.
  ///
  /// In en, this message translates to:
  /// **'Change currency'**
  String get changeCurrency;

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatTitle;

  /// No description provided for @libraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get libraryTitle;

  /// No description provided for @libraryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No items yet'**
  String get libraryEmpty;

  /// No description provided for @chatInputHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get chatInputHint;

  /// No description provided for @readingModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading Mode'**
  String get readingModeTitle;

  /// No description provided for @churchHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Church Members'**
  String get churchHubTitle;

  /// No description provided for @churchNoMembers.
  ///
  /// In en, this message translates to:
  /// **'No members yet'**
  String get churchNoMembers;

  /// No description provided for @churchAddMember.
  ///
  /// In en, this message translates to:
  /// **'Add Member'**
  String get churchAddMember;

  /// No description provided for @churchSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search name/phone'**
  String get churchSearchHint;

  /// No description provided for @churchDirectoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Church Directory'**
  String get churchDirectoryTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search name / phone / small group / Sunday school / notes'**
  String get searchHint;

  /// No description provided for @filterMemberCount.
  ///
  /// In en, this message translates to:
  /// **'Members ({count})'**
  String filterMemberCount(int count);

  /// No description provided for @filterSeekerCount.
  ///
  /// In en, this message translates to:
  /// **'Seekers ({count})'**
  String filterSeekerCount(int count);

  /// No description provided for @filterAllCount.
  ///
  /// In en, this message translates to:
  /// **'All ({count})'**
  String filterAllCount(int count);

  /// No description provided for @filterMemberRegularCount.
  ///
  /// In en, this message translates to:
  /// **'Regular Members ({count})'**
  String filterMemberRegularCount(int count);

  /// No description provided for @filterSeekerRegularCount.
  ///
  /// In en, this message translates to:
  /// **'Regular Seekers ({count})'**
  String filterSeekerRegularCount(int count);

  /// No description provided for @filterMemberOccasionalCount.
  ///
  /// In en, this message translates to:
  /// **'Occasional Members ({count})'**
  String filterMemberOccasionalCount(int count);

  /// No description provided for @filterSeekerOccasionalCount.
  ///
  /// In en, this message translates to:
  /// **'Occasional Seekers ({count})'**
  String filterSeekerOccasionalCount(int count);

  /// No description provided for @filterMemberInactiveCount.
  ///
  /// In en, this message translates to:
  /// **'Inactive Members ({count})'**
  String filterMemberInactiveCount(int count);

  /// No description provided for @filterSeekerInactiveCount.
  ///
  /// In en, this message translates to:
  /// **'Inactive Seekers ({count})'**
  String filterSeekerInactiveCount(int count);

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No members match search criteria'**
  String get noSearchResults;

  /// No description provided for @emptyDirectory.
  ///
  /// In en, this message translates to:
  /// **'Directory is empty'**
  String get emptyDirectory;

  /// No description provided for @emptyDirectoryHint.
  ///
  /// In en, this message translates to:
  /// **'Tap FAB to add the first member'**
  String get emptyDirectoryHint;

  /// No description provided for @personRowSmallGroup.
  ///
  /// In en, this message translates to:
  /// **'Group: {group}'**
  String personRowSmallGroup(String group);

  /// No description provided for @personRowSundaySchool.
  ///
  /// In en, this message translates to:
  /// **'Sunday School: {school}'**
  String personRowSundaySchool(String school);

  /// No description provided for @historyTooltip.
  ///
  /// In en, this message translates to:
  /// **'History Records'**
  String get historyTooltip;

  /// No description provided for @closeCaseConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Close Case'**
  String get closeCaseConfirmTitle;

  /// No description provided for @closeCaseConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'Mark case for \"{name}\" as closed?'**
  String closeCaseConfirmContent(String name);

  /// No description provided for @closeCase.
  ///
  /// In en, this message translates to:
  /// **'Close Case'**
  String get closeCase;

  /// No description provided for @careDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Care Dashboard'**
  String get careDashboardTitle;

  /// No description provided for @tabMemberActive.
  ///
  /// In en, this message translates to:
  /// **'Members ({count})'**
  String tabMemberActive(int count);

  /// No description provided for @tabNewcomerActive.
  ///
  /// In en, this message translates to:
  /// **'Newcomers ({count})'**
  String tabNewcomerActive(int count);

  /// No description provided for @tabVisitedHistory.
  ///
  /// In en, this message translates to:
  /// **'Visited ({count})'**
  String tabVisitedHistory(int count);

  /// No description provided for @careSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search member name / reason / notes'**
  String get careSearchHint;

  /// No description provided for @addNewCaseLabel.
  ///
  /// In en, this message translates to:
  /// **'Add {label} Case'**
  String addNewCaseLabel(String label);

  /// No description provided for @alertRedTitle.
  ///
  /// In en, this message translates to:
  /// **'Requires immediate attention'**
  String get alertRedTitle;

  /// No description provided for @alertYellowTitle.
  ///
  /// In en, this message translates to:
  /// **'Should schedule soon'**
  String get alertYellowTitle;

  /// No description provided for @alertGreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Under follow-up'**
  String get alertGreenTitle;

  /// No description provided for @historyNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matching persons'**
  String get historyNoResults;

  /// No description provided for @historyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No visit history yet'**
  String get historyEmpty;

  /// No description provided for @historyEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Open a new case and log a visit under Members/Newcomers to see it here'**
  String get historyEmptyHint;

  /// No description provided for @searchNoCaseResults.
  ///
  /// In en, this message translates to:
  /// **'No matching cases'**
  String get searchNoCaseResults;

  /// No description provided for @tabEmptyCaseState.
  ///
  /// In en, this message translates to:
  /// **'No {label} cases at present'**
  String tabEmptyCaseState(String label);

  /// No description provided for @addNewCaseButton.
  ///
  /// In en, this message translates to:
  /// **'Add {label} Case'**
  String addNewCaseButton(String label);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @daysNoVisit.
  ///
  /// In en, this message translates to:
  /// **'🕐 {days} days since last touch'**
  String daysNoVisit(int days);

  /// No description provided for @caseRowSummary.
  ///
  /// In en, this message translates to:
  /// **'{reason}  ·  {urgency} Priority'**
  String caseRowSummary(String reason, String urgency);

  /// No description provided for @caseRowLastVisitPrefix.
  ///
  /// In en, this message translates to:
  /// **'Last: {visitedBy} {date} '**
  String caseRowLastVisitPrefix(String visitedBy, String date);

  /// No description provided for @noVisitRecorded.
  ///
  /// In en, this message translates to:
  /// **'No visits logged yet'**
  String get noVisitRecorded;

  /// No description provided for @detailsButton.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get detailsButton;

  /// No description provided for @logVisitButton.
  ///
  /// In en, this message translates to:
  /// **'Log Visit'**
  String get logVisitButton;

  /// No description provided for @editCaseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit Case'**
  String get editCaseTooltip;

  /// No description provided for @closeCaseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Close Case'**
  String get closeCaseTooltip;

  /// No description provided for @statusActiveBadge.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActiveBadge;

  /// No description provided for @historyRowLastVisit.
  ///
  /// In en, this message translates to:
  /// **'Last: {visitedBy} · {method} · {date}'**
  String historyRowLastVisit(String visitedBy, String method, String date);

  /// No description provided for @historyNoVisitRecorded.
  ///
  /// In en, this message translates to:
  /// **'No visits logged yet'**
  String get historyNoVisitRecorded;

  /// No description provided for @historyRowStats.
  ///
  /// In en, this message translates to:
  /// **'Total {totalVisits} visits · {caseCount} cases'**
  String historyRowStats(int totalVisits, int caseCount);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String daysAgo(int days);

  /// No description provided for @weeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{weeks} weeks ago'**
  String weeksAgo(int weeks);

  /// No description provided for @monthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{months} months ago'**
  String monthsAgo(int months);

  /// No description provided for @yearsAgo.
  ///
  /// In en, this message translates to:
  /// **'{years} years ago'**
  String yearsAgo(int years);

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String saveFailed(String error);

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'This member\'s directory info will be permanently deleted (associated care cases will not be deleted).'**
  String get deleteConfirmContent;

  /// No description provided for @editPersonTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit {label}'**
  String editPersonTitle(String label);

  /// No description provided for @addPersonTitle.
  ///
  /// In en, this message translates to:
  /// **'Add {label}'**
  String addPersonTitle(String label);

  /// No description provided for @fieldNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name *'**
  String get fieldNameLabel;

  /// No description provided for @fieldNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter name'**
  String get fieldNameRequired;

  /// No description provided for @fieldPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get fieldPhoneLabel;

  /// No description provided for @fieldBirthdayLabel.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get fieldBirthdayLabel;

  /// No description provided for @sectionChurchLife.
  ///
  /// In en, this message translates to:
  /// **'Church Life'**
  String get sectionChurchLife;

  /// No description provided for @fieldBaptismDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Baptism Date'**
  String get fieldBaptismDateLabel;

  /// No description provided for @fieldJoinDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Transfer / Join Date'**
  String get fieldJoinDateLabel;

  /// No description provided for @fieldAttendanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Worship Attendance'**
  String get fieldAttendanceLabel;

  /// No description provided for @sectionParticipation.
  ///
  /// In en, this message translates to:
  /// **'Participation'**
  String get sectionParticipation;

  /// No description provided for @fieldSmallGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Small Group / Fellowship'**
  String get fieldSmallGroupLabel;

  /// No description provided for @fieldSmallGroupHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Wed Elderly Group, Couple Fellowship Group B'**
  String get fieldSmallGroupHint;

  /// No description provided for @fieldSundaySchoolLabel.
  ///
  /// In en, this message translates to:
  /// **'Sunday School'**
  String get fieldSundaySchoolLabel;

  /// No description provided for @fieldSundaySchoolHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Adult Class B - student, Children\'s teacher'**
  String get fieldSundaySchoolHint;

  /// No description provided for @sectionOthers.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get sectionOthers;

  /// No description provided for @fieldCreatedByLabel.
  ///
  /// In en, this message translates to:
  /// **'Created By (Pastor Name)'**
  String get fieldCreatedByLabel;

  /// No description provided for @fieldNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get fieldNotesLabel;

  /// No description provided for @commonSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get commonSaving;

  /// No description provided for @defaultNewcomerReason.
  ///
  /// In en, this message translates to:
  /// **'Newcomer'**
  String get defaultNewcomerReason;

  /// No description provided for @deleteCaseConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'This case and all associated visit logs will be permanently deleted.'**
  String get deleteCaseConfirmContent;

  /// No description provided for @editCaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Case'**
  String get editCaseTitle;

  /// No description provided for @addNewCaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Care Case'**
  String get addNewCaseTitle;

  /// No description provided for @fieldNewcomerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Newcomer Name *'**
  String get fieldNewcomerNameLabel;

  /// No description provided for @fieldMemberNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Member Name *'**
  String get fieldMemberNameLabel;

  /// No description provided for @fieldReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason * (e.g., hospitalized, father passed away, newcomer follow-up)'**
  String get fieldReasonLabel;

  /// No description provided for @fieldReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter reason'**
  String get fieldReasonRequired;

  /// No description provided for @fieldIdentityLabel.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get fieldIdentityLabel;

  /// No description provided for @fieldUrgencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Urgency'**
  String get fieldUrgencyLabel;

  /// No description provided for @urgencyLegend.
  ///
  /// In en, this message translates to:
  /// **'High = 3 days red / Med = 7 days red / Low = 14 days red'**
  String get urgencyLegend;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @aiHighlight.
  ///
  /// In en, this message translates to:
  /// **'AI Highlight'**
  String get aiHighlight;

  /// No description provided for @aiNotes.
  ///
  /// In en, this message translates to:
  /// **'AI Notes'**
  String get aiNotes;

  /// No description provided for @aiGuidedReading.
  ///
  /// In en, this message translates to:
  /// **'AI Guide'**
  String get aiGuidedReading;

  /// No description provided for @aiMindMap.
  ///
  /// In en, this message translates to:
  /// **'AI Mind Map'**
  String get aiMindMap;

  /// No description provided for @aiWordCard.
  ///
  /// In en, this message translates to:
  /// **'AI Vocab'**
  String get aiWordCard;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @generateFailed.
  ///
  /// In en, this message translates to:
  /// **'Generation failed. Please try again later.'**
  String get generateFailed;

  /// No description provided for @learningHub.
  ///
  /// In en, this message translates to:
  /// **'Learning Space'**
  String get learningHub;

  /// No description provided for @learningHubSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Japanese & English Learning Tools'**
  String get learningHubSubtitle;

  /// No description provided for @grammarAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Grammar Analysis'**
  String get grammarAnalysis;

  /// No description provided for @inputSentenceHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a Japanese sentence to analyze...'**
  String get inputSentenceHint;

  /// No description provided for @vocabAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary Analysis'**
  String get vocabAnalysis;

  /// No description provided for @inputWordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a Japanese word to analyze...'**
  String get inputWordHint;

  /// No description provided for @vocabAnalysisFailed.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary analysis failed. Please try again later.'**
  String get vocabAnalysisFailed;

  /// No description provided for @sentenceGeneration.
  ///
  /// In en, this message translates to:
  /// **'Sentence Generation'**
  String get sentenceGeneration;

  /// No description provided for @aiSentence.
  ///
  /// In en, this message translates to:
  /// **'AI Sentence'**
  String get aiSentence;

  /// No description provided for @inputSentenceWordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a Japanese word to generate sentences...'**
  String get inputSentenceWordHint;

  /// No description provided for @sentenceGenerationFailed.
  ///
  /// In en, this message translates to:
  /// **'Sentence generation failed. Please try again later.'**
  String get sentenceGenerationFailed;

  /// No description provided for @stopSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopSpeaking;

  /// No description provided for @speakPronunciation.
  ///
  /// In en, this message translates to:
  /// **'Read Aloud'**
  String get speakPronunciation;

  /// No description provided for @japaneseLab.
  ///
  /// In en, this message translates to:
  /// **'Japanese Lab'**
  String get japaneseLab;

  /// No description provided for @englishLab.
  ///
  /// In en, this message translates to:
  /// **'English Lab'**
  String get englishLab;

  /// No description provided for @enGrammarAnalysis.
  ///
  /// In en, this message translates to:
  /// **'English Grammar Analysis'**
  String get enGrammarAnalysis;

  /// No description provided for @enInputSentenceHint.
  ///
  /// In en, this message translates to:
  /// **'Enter an English sentence to analyze...'**
  String get enInputSentenceHint;

  /// No description provided for @enVocabAnalysis.
  ///
  /// In en, this message translates to:
  /// **'English Vocabulary Analysis'**
  String get enVocabAnalysis;

  /// No description provided for @enInputWordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter an English word...'**
  String get enInputWordHint;

  /// No description provided for @enVocabAnalysisFailed.
  ///
  /// In en, this message translates to:
  /// **'English vocabulary analysis failed. Please try again later.'**
  String get enVocabAnalysisFailed;

  /// No description provided for @enSentenceGeneration.
  ///
  /// In en, this message translates to:
  /// **'English Sentence & Quiz'**
  String get enSentenceGeneration;

  /// No description provided for @enAiSentence.
  ///
  /// In en, this message translates to:
  /// **'AI English Sentence & Quiz'**
  String get enAiSentence;

  /// No description provided for @enInputSentenceWordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter an English word to generate sentences and quiz...'**
  String get enInputSentenceWordHint;

  /// No description provided for @enSentenceGenerationFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate English sentences and quiz. Please try again later.'**
  String get enSentenceGenerationFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'CN':
            return AppLocalizationsZhCn();
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
