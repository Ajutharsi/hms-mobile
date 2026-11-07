import 'package:flutter/foundation.dart';

/// What the hospital calls itself and what it charges in.
///
/// Currency is a per-hospital setting the web has always honoured — the
/// seeded default is LKR, not INR — while the app printed a rupee sign in
/// eighty places regardless. The server now sends it with the signed-in
/// user, and everything that shows money reads it from here.
///
/// A notifier rather than a provider: money appears in screens all over
/// the tree, including ones pushed above any provider the shells own.
final ValueNotifier<String> hospitalCurrency = ValueNotifier<String>('LKR');
final ValueNotifier<String?> hospitalName = ValueNotifier<String?>(null);

/// Codes worth a symbol. Anything else is shown as its code, which is
/// what a finance team would rather see than a wrong symbol.
const Map<String, String> _symbols = {
  'INR': '\u20B9',
  'LKR': 'Rs',
  'USD': '\u0024',
  'EUR': '\u20AC',
  'GBP': '\u00A3',
  'AED': 'AED',
  'PKR': 'Rs',
  'BDT': '\u09F3',
  'NPR': 'Rs',
};

/// Called when the server tells us who is signed in.
void rememberHospital({String? name, String? currency}) {
  if (currency != null && currency.trim().isNotEmpty) {
    hospitalCurrency.value = currency.trim().toUpperCase();
  }
  if (name != null && name.trim().isNotEmpty) hospitalName.value = name.trim();
}

/// The current currency's symbol, or its code when there is no symbol.
String get currencySymbol => _symbols[hospitalCurrency.value] ?? hospitalCurrency.value;

/// An amount with the hospital's currency in front of it.
///
/// [decimals] is 0 for the headline figures a dashboard shows and 2 where
/// the number has to reconcile — a cash count, a variance, an invoice line.
String money(num? amount, {int decimals = 0}) => '$currencySymbol${(amount ?? 0).toStringAsFixed(decimals)}';
