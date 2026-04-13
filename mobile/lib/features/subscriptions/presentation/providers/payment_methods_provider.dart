import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/payment_method_model.dart';

part 'payment_methods_provider.g.dart';

/// Provides the list of available payment methods.
/// Currently hardcoded, but structured to easily fetch from an API later.
@riverpod
List<PaymentMethodModel> paymentMethods(Ref ref) {
  return const [
    PaymentMethodModel(
      id: 'mock_apple', // In the future, change to 'apple_pay'
      translationKey: 'applePay',
      icon: Icons.apple_rounded,
    ),
    PaymentMethodModel(
      id: 'mock', // In the future, change to 'stripe' or 'paymob'
      translationKey: 'creditCard',
      icon: Icons.credit_card_rounded,
    ),
  ];
}
