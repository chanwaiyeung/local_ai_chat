// lib/widgets/currency_picker_button.dart
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/currency_service.dart';

/// Compact picker. Renders as a small icon-row that opens a popup menu
/// listing all supported currencies. Tapping persists the choice and
/// notifies all listeners (cards rebuild instantly).
class CurrencyPickerButton extends StatelessWidget {
  const CurrencyPickerButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CurrencyService.instance,
      builder: (context, _) {
        final current = CurrencyService.instance.code;
        return PopupMenuButton<String>(
          tooltip: AppLocalizations.of(context).changeCurrency,
          padding: EdgeInsets.zero,
          icon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.currency_exchange, size: 18),
              const SizedBox(width: 4),
              Text(current, style: const TextStyle(fontSize: 13)),
              const Icon(Icons.arrow_drop_down, size: 18),
            ],
          ),
          onSelected: (code) => CurrencyService.instance.setCode(code),
          itemBuilder: (_) => CurrencyService.supported.map((code) {
            final sym = CurrencyService.symbols[code] ?? code;
            final isCurrent = code == current;
            return PopupMenuItem<String>(
              value: code,
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      sym,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(code),
                  const Spacer(),
                  if (isCurrent) const Icon(Icons.check, size: 18),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}


