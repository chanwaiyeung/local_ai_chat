import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
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
    Locale('zh'),
    Locale('zh', 'CN'),
    Locale('zh', 'TW')
  ];

  /// App title shown in OS task switcher
  ///
  /// In zh_TW, this message translates to:
  /// **'智讀館'**
  String get appTitle;

  /// No description provided for @tabRecords.
  ///
  /// In zh_TW, this message translates to:
  /// **'紀錄'**
  String get tabRecords;

  /// No description provided for @tabAllocation.
  ///
  /// In zh_TW, this message translates to:
  /// **'配置'**
  String get tabAllocation;

  /// No description provided for @investmentFinance.
  ///
  /// In zh_TW, this message translates to:
  /// **'投資理財'**
  String get investmentFinance;

  /// No description provided for @noInvestmentRecords.
  ///
  /// In zh_TW, this message translates to:
  /// **'尚無投資紀錄'**
  String get noInvestmentRecords;

  /// No description provided for @aiFinancialAdvisor.
  ///
  /// In zh_TW, this message translates to:
  /// **'AI 理財顧問'**
  String get aiFinancialAdvisor;

  /// No description provided for @totalAssets.
  ///
  /// In zh_TW, this message translates to:
  /// **'總資產'**
  String get totalAssets;

  /// No description provided for @currencyLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'幣別：'**
  String get currencyLabel;

  /// No description provided for @moduleExpense.
  ///
  /// In zh_TW, this message translates to:
  /// **'日常開支'**
  String get moduleExpense;

  /// No description provided for @moduleContacts.
  ///
  /// In zh_TW, this message translates to:
  /// **'名片管理'**
  String get moduleContacts;

  /// No description provided for @moduleHealth.
  ///
  /// In zh_TW, this message translates to:
  /// **'健康紀錄'**
  String get moduleHealth;

  /// No description provided for @moduleWealth.
  ///
  /// In zh_TW, this message translates to:
  /// **'投資理財'**
  String get moduleWealth;

  /// No description provided for @moduleDashboardSoon.
  ///
  /// In zh_TW, this message translates to:
  /// **'完整儀表板'**
  String get moduleDashboardSoon;

  /// No description provided for @comingSoon.
  ///
  /// In zh_TW, this message translates to:
  /// **'即將推出'**
  String get comingSoon;

  /// No description provided for @expenseCount.
  ///
  /// In zh_TW, this message translates to:
  /// **'{count, plural, =0{尚未加入紀錄} other{{count} 筆紀錄}}'**
  String expenseCount(int count);

  /// No description provided for @saveButton.
  ///
  /// In zh_TW, this message translates to:
  /// **'儲存'**
  String get saveButton;

  /// No description provided for @cancelButton.
  ///
  /// In zh_TW, this message translates to:
  /// **'取消'**
  String get cancelButton;

  /// No description provided for @deleteButton.
  ///
  /// In zh_TW, this message translates to:
  /// **'刪除'**
  String get deleteButton;

  /// No description provided for @settings.
  ///
  /// In zh_TW, this message translates to:
  /// **'設定'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In zh_TW, this message translates to:
  /// **'語言'**
  String get language;

  /// No description provided for @languageZhTw.
  ///
  /// In zh_TW, this message translates to:
  /// **'繁體中文'**
  String get languageZhTw;

  /// No description provided for @languageZhCn.
  ///
  /// In zh_TW, this message translates to:
  /// **'簡體中文'**
  String get languageZhCn;

  /// No description provided for @languageEn.
  ///
  /// In zh_TW, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @personalHubTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'Personal Hub'**
  String get personalHubTitle;

  /// No description provided for @modules.
  ///
  /// In zh_TW, this message translates to:
  /// **'模組'**
  String get modules;

  /// No description provided for @dashboardTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'{year} 年 {month} 月總覽'**
  String dashboardTitle(int year, int month);

  /// No description provided for @totalExpensesThisMonth.
  ///
  /// In zh_TW, this message translates to:
  /// **'本月總開支'**
  String get totalExpensesThisMonth;

  /// No description provided for @noExpensesThisMonth.
  ///
  /// In zh_TW, this message translates to:
  /// **'本月暫無開支'**
  String get noExpensesThisMonth;

  /// No description provided for @totalContacts.
  ///
  /// In zh_TW, this message translates to:
  /// **'名片總數'**
  String get totalContacts;

  /// No description provided for @healthRecords.
  ///
  /// In zh_TW, this message translates to:
  /// **'健康紀錄'**
  String get healthRecords;

  /// No description provided for @investmentNetWorth.
  ///
  /// In zh_TW, this message translates to:
  /// **'投資淨值'**
  String get investmentNetWorth;

  /// No description provided for @quickAiQuery.
  ///
  /// In zh_TW, this message translates to:
  /// **'快速 AI 查詢'**
  String get quickAiQuery;

  /// No description provided for @featureNotEnabled.
  ///
  /// In zh_TW, this message translates to:
  /// **'{feature}：尚未啟用，請等待後續 Phase'**
  String featureNotEnabled(String feature);

  /// No description provided for @aiQueryFeatureComingSoon.
  ///
  /// In zh_TW, this message translates to:
  /// **'AI 跨模組查詢將於 Phase 6.3\'b 推出'**
  String get aiQueryFeatureComingSoon;

  /// No description provided for @noRecordsYet.
  ///
  /// In zh_TW, this message translates to:
  /// **'尚未加入紀錄'**
  String get noRecordsYet;

  /// No description provided for @noContactsYet.
  ///
  /// In zh_TW, this message translates to:
  /// **'尚未加入名片'**
  String get noContactsYet;

  /// No description provided for @recordCountPlural.
  ///
  /// In zh_TW, this message translates to:
  /// **'{count, plural, =0{尚未加入紀錄} other{{count} 筆紀錄}}'**
  String recordCountPlural(int count);

  /// No description provided for @contactCountPlural.
  ///
  /// In zh_TW, this message translates to:
  /// **'{count, plural, =0{尚未加入名片} other{{count} 張名片}}'**
  String contactCountPlural(int count);

  /// No description provided for @wealth.
  ///
  /// In zh_TW, this message translates to:
  /// **'投資理財'**
  String get wealth;

  /// No description provided for @assetAllocation.
  ///
  /// In zh_TW, this message translates to:
  /// **'資產配置'**
  String get assetAllocation;

  /// No description provided for @addRecord.
  ///
  /// In zh_TW, this message translates to:
  /// **'新增紀錄'**
  String get addRecord;

  /// No description provided for @netWorth.
  ///
  /// In zh_TW, this message translates to:
  /// **'投資淨值'**
  String get netWorth;

  /// No description provided for @totalLiabilities.
  ///
  /// In zh_TW, this message translates to:
  /// **'總負債'**
  String get totalLiabilities;

  /// No description provided for @searchAssetHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'搜尋資產 / 備註 / 標籤...'**
  String get searchAssetHint;

  /// No description provided for @noDataToChart.
  ///
  /// In zh_TW, this message translates to:
  /// **'沒有可繪製的投資資料'**
  String get noDataToChart;

  /// No description provided for @addFirstRecordHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'從「紀錄」分頁加入第一筆吧'**
  String get addFirstRecordHint;

  /// No description provided for @netWorthOverview.
  ///
  /// In zh_TW, this message translates to:
  /// **'淨值總覽'**
  String get netWorthOverview;

  /// No description provided for @assetCountLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'{count} 項資產'**
  String assetCountLabel(int count);

  /// No description provided for @valuationNote.
  ///
  /// In zh_TW, this message translates to:
  /// **'依最新一筆估值合計（不跨幣別換算）'**
  String get valuationNote;

  /// No description provided for @noData.
  ///
  /// In zh_TW, this message translates to:
  /// **'暫無資料'**
  String get noData;

  /// No description provided for @netWorthTrend.
  ///
  /// In zh_TW, this message translates to:
  /// **'淨值趨勢'**
  String get netWorthTrend;

  /// No description provided for @needTwoDatesForChart.
  ///
  /// In zh_TW, this message translates to:
  /// **'需要至少兩個不同日期才能繪製趨勢'**
  String get needTwoDatesForChart;

  /// No description provided for @addInvestmentRecord.
  ///
  /// In zh_TW, this message translates to:
  /// **'新增投資紀錄'**
  String get addInvestmentRecord;

  /// No description provided for @editInvestmentRecord.
  ///
  /// In zh_TW, this message translates to:
  /// **'編輯投資紀錄'**
  String get editInvestmentRecord;

  /// No description provided for @valuationDate.
  ///
  /// In zh_TW, this message translates to:
  /// **'估值日期'**
  String get valuationDate;

  /// No description provided for @assetClass.
  ///
  /// In zh_TW, this message translates to:
  /// **'資產類別'**
  String get assetClass;

  /// No description provided for @assetNameHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'資產名稱（選填，例如 AAPL / 0050.TW）'**
  String get assetNameHint;

  /// No description provided for @amount.
  ///
  /// In zh_TW, this message translates to:
  /// **'金額'**
  String get amount;

  /// No description provided for @invalidAmountError.
  ///
  /// In zh_TW, this message translates to:
  /// **'請輸入有效金額'**
  String get invalidAmountError;

  /// No description provided for @currency.
  ///
  /// In zh_TW, this message translates to:
  /// **'幣別'**
  String get currency;

  /// No description provided for @notes.
  ///
  /// In zh_TW, this message translates to:
  /// **'備註'**
  String get notes;

  /// No description provided for @tagsCommaSeparated.
  ///
  /// In zh_TW, this message translates to:
  /// **'標籤（逗號分隔）'**
  String get tagsCommaSeparated;

  /// No description provided for @aiHealthAdvisor.
  ///
  /// In zh_TW, this message translates to:
  /// **'AI 健康顧問'**
  String get aiHealthAdvisor;

  /// No description provided for @searchHealthHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'搜尋備註 / 標籤...'**
  String get searchHealthHint;

  /// No description provided for @noHealthRecords.
  ///
  /// In zh_TW, this message translates to:
  /// **'尚無健康紀錄'**
  String get noHealthRecords;

  /// No description provided for @noRecordsLast30Days.
  ///
  /// In zh_TW, this message translates to:
  /// **'最近 30 天暫無紀錄'**
  String get noRecordsLast30Days;

  /// No description provided for @last30DaysOverview.
  ///
  /// In zh_TW, this message translates to:
  /// **'最近 30 天概況'**
  String get last30DaysOverview;

  /// No description provided for @recordCountUnit.
  ///
  /// In zh_TW, this message translates to:
  /// **'{count} 筆'**
  String recordCountUnit(int count);

  /// No description provided for @weight.
  ///
  /// In zh_TW, this message translates to:
  /// **'體重'**
  String get weight;

  /// No description provided for @avgWeightStat.
  ///
  /// In zh_TW, this message translates to:
  /// **'平均 {val} kg ({count} 次)'**
  String avgWeightStat(String val, int count);

  /// No description provided for @bloodPressure.
  ///
  /// In zh_TW, this message translates to:
  /// **'血壓'**
  String get bloodPressure;

  /// No description provided for @avgBpStat.
  ///
  /// In zh_TW, this message translates to:
  /// **'平均 {sys} / {dia} mmHg ({count} 次)'**
  String avgBpStat(String sys, String dia, int count);

  /// No description provided for @heartRate.
  ///
  /// In zh_TW, this message translates to:
  /// **'心率'**
  String get heartRate;

  /// No description provided for @avgHeartRateStat.
  ///
  /// In zh_TW, this message translates to:
  /// **'平均 {val} bpm ({count} 次)'**
  String avgHeartRateStat(String val, int count);

  /// No description provided for @steps.
  ///
  /// In zh_TW, this message translates to:
  /// **'步數'**
  String get steps;

  /// No description provided for @totalStepsStat.
  ///
  /// In zh_TW, this message translates to:
  /// **'總計 {val} 步 ({count} 天)'**
  String totalStepsStat(String val, int count);

  /// No description provided for @sleep.
  ///
  /// In zh_TW, this message translates to:
  /// **'睡眠'**
  String get sleep;

  /// No description provided for @avgSleepStat.
  ///
  /// In zh_TW, this message translates to:
  /// **'平均 {val} 小時 ({count} 次)'**
  String avgSleepStat(String val, int count);

  /// No description provided for @noDataLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'(無資料)'**
  String get noDataLabel;

  /// No description provided for @addHealthRecord.
  ///
  /// In zh_TW, this message translates to:
  /// **'新增健康紀錄'**
  String get addHealthRecord;

  /// No description provided for @editHealthRecord.
  ///
  /// In zh_TW, this message translates to:
  /// **'編輯健康紀錄'**
  String get editHealthRecord;

  /// No description provided for @measurementDate.
  ///
  /// In zh_TW, this message translates to:
  /// **'測量日期'**
  String get measurementDate;

  /// No description provided for @weightKg.
  ///
  /// In zh_TW, this message translates to:
  /// **'體重 (kg)'**
  String get weightKg;

  /// No description provided for @systolicMmHg.
  ///
  /// In zh_TW, this message translates to:
  /// **'收縮壓 (mmHg)'**
  String get systolicMmHg;

  /// No description provided for @diastolicMmHg.
  ///
  /// In zh_TW, this message translates to:
  /// **'舒張壓 (mmHg)'**
  String get diastolicMmHg;

  /// No description provided for @heartRateBpm.
  ///
  /// In zh_TW, this message translates to:
  /// **'心率 (bpm)'**
  String get heartRateBpm;

  /// No description provided for @sleepHours.
  ///
  /// In zh_TW, this message translates to:
  /// **'睡眠時數 (小時)'**
  String get sleepHours;

  /// No description provided for @fillAtLeastOneMeasurement.
  ///
  /// In zh_TW, this message translates to:
  /// **'請至少填寫一項測量值或備註'**
  String get fillAtLeastOneMeasurement;

  /// No description provided for @trendCharts.
  ///
  /// In zh_TW, this message translates to:
  /// **'趨勢圖表'**
  String get trendCharts;

  /// No description provided for @weightTrend.
  ///
  /// In zh_TW, this message translates to:
  /// **'體重趨勢 (kg)'**
  String get weightTrend;

  /// No description provided for @systolicTrend.
  ///
  /// In zh_TW, this message translates to:
  /// **'收縮壓趨勢 (mmHg)'**
  String get systolicTrend;

  /// No description provided for @sleepHoursLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'睡眠時數'**
  String get sleepHoursLabel;

  /// No description provided for @searchExpenseHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'搜尋商家 / 分類 / 備註...'**
  String get searchExpenseHint;

  /// No description provided for @noMatchingExpenses.
  ///
  /// In zh_TW, this message translates to:
  /// **'沒有符合條件的開支'**
  String get noMatchingExpenses;

  /// No description provided for @previousMonth.
  ///
  /// In zh_TW, this message translates to:
  /// **'上個月'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In zh_TW, this message translates to:
  /// **'下個月'**
  String get nextMonth;

  /// No description provided for @yearMonthTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'{year} 年 {month} 月'**
  String yearMonthTitle(int year, int month);

  /// No description provided for @monthlyTotal.
  ///
  /// In zh_TW, this message translates to:
  /// **'本月合計：{totalText}'**
  String monthlyTotal(String totalText);

  /// No description provided for @categoryAmountChip.
  ///
  /// In zh_TW, this message translates to:
  /// **'{label} · {amount}'**
  String categoryAmountChip(String label, String amount);

  /// No description provided for @noMerchant.
  ///
  /// In zh_TW, this message translates to:
  /// **'(未填商家)'**
  String get noMerchant;

  /// No description provided for @addExpense.
  ///
  /// In zh_TW, this message translates to:
  /// **'新增開支'**
  String get addExpense;

  /// No description provided for @editExpense.
  ///
  /// In zh_TW, this message translates to:
  /// **'編輯開支'**
  String get editExpense;

  /// No description provided for @merchant.
  ///
  /// In zh_TW, this message translates to:
  /// **'商家'**
  String get merchant;

  /// No description provided for @category.
  ///
  /// In zh_TW, this message translates to:
  /// **'分類'**
  String get category;

  /// No description provided for @defaultCategoriesLabel.
  ///
  /// In zh_TW, this message translates to:
  /// **'預設類別'**
  String get defaultCategoriesLabel;

  /// No description provided for @customCategoriesCount.
  ///
  /// In zh_TW, this message translates to:
  /// **'已有 {count} 個自訂類別'**
  String customCategoriesCount(int count);

  /// No description provided for @paymentMethod.
  ///
  /// In zh_TW, this message translates to:
  /// **'付款方式'**
  String get paymentMethod;

  /// No description provided for @date.
  ///
  /// In zh_TW, this message translates to:
  /// **'日期'**
  String get date;

  /// No description provided for @appearance.
  ///
  /// In zh_TW, this message translates to:
  /// **'外觀'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In zh_TW, this message translates to:
  /// **'主題'**
  String get theme;

  /// No description provided for @darkMode.
  ///
  /// In zh_TW, this message translates to:
  /// **'深色模式'**
  String get darkMode;

  /// No description provided for @lightMode.
  ///
  /// In zh_TW, this message translates to:
  /// **'淺色模式'**
  String get lightMode;

  /// No description provided for @systemDefault.
  ///
  /// In zh_TW, this message translates to:
  /// **'跟隨系統'**
  String get systemDefault;

  /// No description provided for @mySkills.
  ///
  /// In zh_TW, this message translates to:
  /// **'我的技能庫'**
  String get mySkills;

  /// No description provided for @embeddingSettings.
  ///
  /// In zh_TW, this message translates to:
  /// **'Embedding 設定'**
  String get embeddingSettings;

  /// No description provided for @enterEmbeddingModelName.
  ///
  /// In zh_TW, this message translates to:
  /// **'請輸入 embedding model 名稱'**
  String get enterEmbeddingModelName;

  /// No description provided for @modelInstalled.
  ///
  /// In zh_TW, this message translates to:
  /// **'已安裝'**
  String get modelInstalled;

  /// No description provided for @modelNotInstalled.
  ///
  /// In zh_TW, this message translates to:
  /// **'未安裝，請先用 Ollama pull 此 model'**
  String get modelNotInstalled;

  /// No description provided for @useCustomEmbeddingModel.
  ///
  /// In zh_TW, this message translates to:
  /// **'使用自訂 embedding model'**
  String get useCustomEmbeddingModel;

  /// No description provided for @customModelHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'例如：mxbai-embed-large'**
  String get customModelHint;

  /// No description provided for @currentSelection.
  ///
  /// In zh_TW, this message translates to:
  /// **'目前選擇：{model}'**
  String currentSelection(String model);

  /// No description provided for @changeModelWarning.
  ///
  /// In zh_TW, this message translates to:
  /// **'注意：更換 embedding model 會清空目前 vector store，請重新匯入文件。'**
  String get changeModelWarning;

  /// No description provided for @retrievalMode.
  ///
  /// In zh_TW, this message translates to:
  /// **'檢索模式'**
  String get retrievalMode;

  /// No description provided for @denseMode.
  ///
  /// In zh_TW, this message translates to:
  /// **'Dense：向量語意搜尋'**
  String get denseMode;

  /// No description provided for @sparseMode.
  ///
  /// In zh_TW, this message translates to:
  /// **'Sparse：BM25 關鍵字搜尋'**
  String get sparseMode;

  /// No description provided for @hybridMode.
  ///
  /// In zh_TW, this message translates to:
  /// **'Hybrid：Dense + BM25 + RRF'**
  String get hybridMode;

  /// No description provided for @applySettings.
  ///
  /// In zh_TW, this message translates to:
  /// **'套用設定'**
  String get applySettings;

  /// No description provided for @wealthExportCsv.
  ///
  /// In zh_TW, this message translates to:
  /// **'匯出 CSV'**
  String get wealthExportCsv;

  /// No description provided for @wealthCsvCopied.
  ///
  /// In zh_TW, this message translates to:
  /// **'CSV 已複製到剪貼簿'**
  String get wealthCsvCopied;

  /// No description provided for @personalHubHealthRecords.
  ///
  /// In zh_TW, this message translates to:
  /// **'健康紀錄'**
  String get personalHubHealthRecords;

  /// No description provided for @personalHubThisMonthExpense.
  ///
  /// In zh_TW, this message translates to:
  /// **'本月開支'**
  String get personalHubThisMonthExpense;

  /// No description provided for @wealthMonthlyReport.
  ///
  /// In zh_TW, this message translates to:
  /// **'本月報告'**
  String get wealthMonthlyReport;

  /// No description provided for @wealthThisMonthTotal.
  ///
  /// In zh_TW, this message translates to:
  /// **'本月總值'**
  String get wealthThisMonthTotal;

  /// No description provided for @wealthLastMonthTotal.
  ///
  /// In zh_TW, this message translates to:
  /// **'上月總值'**
  String get wealthLastMonthTotal;

  /// No description provided for @wealthChange.
  ///
  /// In zh_TW, this message translates to:
  /// **'變化'**
  String get wealthChange;

  /// No description provided for @records.
  ///
  /// In zh_TW, this message translates to:
  /// **'筆紀錄'**
  String get records;

  /// No description provided for @insightTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'一鍵生活洞察'**
  String get insightTitle;

  /// No description provided for @insightSubtitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'結合 Health 與 Wealth 雙核分析，打造您的專屬生活指南。'**
  String get insightSubtitle;

  /// No description provided for @personalQueryTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'Personal Hub AI 查詢'**
  String get personalQueryTitle;

  /// No description provided for @personalQueryHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'問問你的 Personal Hub'**
  String get personalQueryHint;

  /// No description provided for @personalQueryHintSub.
  ///
  /// In zh_TW, this message translates to:
  /// **'可以同時搜尋你的開支與名片紀錄。'**
  String get personalQueryHintSub;

  /// No description provided for @skillsSearchHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'搜尋技能...'**
  String get skillsSearchHint;

  /// No description provided for @skillsEmpty.
  ///
  /// In zh_TW, this message translates to:
  /// **'尚無技能卡'**
  String get skillsEmpty;

  /// No description provided for @skillsEmptyHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'使用 AI 回答後點擊「⭐ 儲存為技能」\n或點擊右上角雲端按鈕來生成'**
  String get skillsEmptyHint;

  /// No description provided for @skillSaved.
  ///
  /// In zh_TW, this message translates to:
  /// **'已手動儲存為技能！'**
  String get skillSaved;

  /// No description provided for @saveAsSkill.
  ///
  /// In zh_TW, this message translates to:
  /// **'儲存為技能'**
  String get saveAsSkill;

  /// No description provided for @querySample1.
  ///
  /// In zh_TW, this message translates to:
  /// **'上次跟王經理吃飯花了多少？'**
  String get querySample1;

  /// No description provided for @querySample2.
  ///
  /// In zh_TW, this message translates to:
  /// **'我這個月在 7-11 花了多少？'**
  String get querySample2;

  /// No description provided for @querySample3.
  ///
  /// In zh_TW, this message translates to:
  /// **'Acme Corp 有哪些聯絡人？'**
  String get querySample3;

  /// No description provided for @addManually.
  ///
  /// In zh_TW, this message translates to:
  /// **'手動新增'**
  String get addManually;

  /// No description provided for @skillsSubtitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'AI 學習記憶庫'**
  String get skillsSubtitle;

  /// No description provided for @settingsApiKeyRequired.
  ///
  /// In zh_TW, this message translates to:
  /// **'請先輸入 API Key'**
  String get settingsApiKeyRequired;

  /// No description provided for @settingsTestingConnection.
  ///
  /// In zh_TW, this message translates to:
  /// **'測試連線中...'**
  String get settingsTestingConnection;

  /// No description provided for @settingsCloudAiTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'Cloud AI 服務 (Gemini)'**
  String get settingsCloudAiTitle;

  /// No description provided for @settingsCloudAiDesc.
  ///
  /// In zh_TW, this message translates to:
  /// **'設定您的 API Key 以啟用「雲端大模型教導本地小模型」與「Wealth 模組的照片掃描」功能。這將被妥善保存在本機。'**
  String get settingsCloudAiDesc;

  /// No description provided for @settingsTestConnection.
  ///
  /// In zh_TW, this message translates to:
  /// **'測試連線'**
  String get settingsTestConnection;

  /// No description provided for @settingsTelegramTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'Telegram 整合'**
  String get settingsTelegramTitle;

  /// No description provided for @settingsTelegramDesc.
  ///
  /// In zh_TW, this message translates to:
  /// **'設定您的 Telegram Bot Token，讓 Local AI 成為您的隨身助理。可從 @BotFather 取得。'**
  String get settingsTelegramDesc;

  /// No description provided for @changeCurrency.
  ///
  /// In zh_TW, this message translates to:
  /// **'切換幣別'**
  String get changeCurrency;

  /// No description provided for @chatTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'對話'**
  String get chatTitle;

  /// No description provided for @libraryTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'圖書館'**
  String get libraryTitle;

  /// No description provided for @libraryEmpty.
  ///
  /// In zh_TW, this message translates to:
  /// **'尚無項目'**
  String get libraryEmpty;

  /// No description provided for @chatInputHint.
  ///
  /// In zh_TW, this message translates to:
  /// **'輸入訊息...'**
  String get chatInputHint;

  /// No description provided for @readingModeTitle.
  ///
  /// In zh_TW, this message translates to:
  /// **'閱讀模式'**
  String get readingModeTitle;
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
      <String>['en', 'zh'].contains(locale.languageCode);

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
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
