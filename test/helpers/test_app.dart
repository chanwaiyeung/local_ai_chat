import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:local_ai_chat/l10n/app_localizations.dart';

/// Wraps a screen with the minimum MaterialApp configuration tests need.
/// Use this in widget tests instead of bare MaterialApp(home: ...).
class TestApp extends StatelessWidget {
  const TestApp({
    super.key,
    required this.child,
    this.locale = const Locale('zh', 'TW'),
    this.navigatorObservers = const [],
  });

  final Widget child;
  final Locale locale;
  final List<NavigatorObserver> navigatorObservers;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      navigatorObservers: navigatorObservers,
      home: child,
    );
  }
}
