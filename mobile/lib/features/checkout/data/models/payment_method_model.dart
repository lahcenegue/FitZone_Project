import 'package:flutter/material.dart';

/// Defines a payment gateway configuration.
class PaymentMethodModel {
  final String
  id; // The value sent to the API (e.g., 'stripe', 'apple_pay', 'mock')
  final String
  translationKey; // Used to fetch the localized name (e.g., l10n.creditCard)
  final IconData icon;

  const PaymentMethodModel({
    required this.id,
    required this.translationKey,
    required this.icon,
  });
}
