// lib/services/currency_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global default currency. Each record still keeps its own currency field;
/// this only governs the *initial value* shown in forms / fallback display.
class CurrencyService extends ChangeNotifier {
  CurrencyService._();
  static final CurrencyService instance = CurrencyService._();

  static const _key = 'default_currency';

  static const List<String> supported = [
    'USD', 'EUR', 'GBP', 'HKD', 'TWD', 'CAD', 'JPY', 'CNY', 'AUD',
  ];

  static const Map<String, String> symbols = {
    'USD': r'$',
    'EUR': '€',
    'GBP': '£',
    'HKD': r'HK$',
    'TWD': r'NT$',
    'CAD': r'CA$',
    'JPY': '¥',
    'CNY': '¥',
    'AUD': r'A$',
  };

  static const Map<String, String> names = {
    'USD': 'US Dollar',
    'EUR': 'Euro',
    'GBP': 'British Pound',
    'HKD': 'Hong Kong Dollar',
    'TWD': 'New Taiwan Dollar',
    'CAD': 'Canadian Dollar',
    'JPY': 'Japanese Yen',
    'CNY': 'Chinese Yuan',
    'AUD': 'Australian Dollar',
  };

  String _code = 'USD';
  String get code => _code;
  String get symbol => symbols[_code] ?? _code;
  String get name => names[_code] ?? _code;

  /// Detect from system locale, e.g. "en_GB" -> GBP, "de_DE" -> EUR.
  /// Eurozone region codes map to EUR. Falls back to USD.
  static String detectFromLocale() {
    try {
      final locale = Platform.localeName;
      final parts = locale.split(RegExp(r'[_\.\-]'));
      final region = parts.length > 1 ? parts[1].toUpperCase() : '';
      switch (region) {
        // Eurozone members
        case 'DE': case 'FR': case 'ES': case 'IT': case 'NL':
        case 'PT': case 'IE': case 'FI': case 'AT': case 'BE':
        case 'GR': case 'LU': case 'MT': case 'CY': case 'EE':
        case 'LV': case 'LT': case 'SK': case 'SI': case 'HR':
          return 'EUR';
        case 'GB': return 'GBP';
        case 'AU': return 'AUD';
        case 'TW': return 'TWD';
        case 'HK': return 'HKD';
        case 'CN': return 'CNY';
        case 'CA': return 'CAD';
        case 'JP': return 'JPY';
        case 'US': return 'USD';
        default:   return 'USD';
      }
    } catch (_) {
      return 'USD';
    }
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _code = prefs.getString(_key) ?? detectFromLocale();
    notifyListeners();
  }

  Future<void> setCode(String code) async {
    if (!supported.contains(code) || code == _code) return;
    _code = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
    notifyListeners();
  }

  String format(num amount) {
    if (_code == 'JPY') return '$symbol${amount.toStringAsFixed(0)}';
    return '$symbol${amount.toStringAsFixed(2)}';
  }
}


