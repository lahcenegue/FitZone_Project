import 'package:logging/logging.dart';

class CheckoutItemDetails {
  final String itemType;
  final String title;
  final String providerName;
  final double price;
  final double? originalPrice;
  final String? imageUrl;
  final int quantity;
  final String unit;

  const CheckoutItemDetails({
    required this.itemType,
    required this.title,
    required this.providerName,
    required this.price,
    this.originalPrice,
    this.imageUrl,
    required this.quantity,
    required this.unit,
  });

  factory CheckoutItemDetails.fromJson(Map<String, dynamic> json) {
    return CheckoutItemDetails(
      itemType: json['item_type']?.toString() ?? 'unknown',
      title: json['title']?.toString() ?? '',
      providerName: json['provider_name']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0,
      originalPrice: json['original_price'] != null
          ? double.tryParse(json['original_price'].toString())
          : null,
      imageUrl: json['image_url']?.toString(),
      quantity: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      unit: json['unit']?.toString() ?? '',
    );
  }
}

class CheckoutUserBalances {
  final double totalWalletBalance;
  final int totalRewardPoints;

  const CheckoutUserBalances({
    required this.totalWalletBalance,
    required this.totalRewardPoints,
  });

  factory CheckoutUserBalances.fromJson(Map<String, dynamic> json) {
    return CheckoutUserBalances(
      totalWalletBalance:
          double.tryParse(json['total_wallet_balance']?.toString() ?? '0.0') ??
          0.0,
      totalRewardPoints:
          int.tryParse(json['total_reward_points']?.toString() ?? '0') ?? 0,
    );
  }
}

class CheckoutInvoice {
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final int maxPointsAllowed;
  final double pointsValueApplied;
  final double walletBalanceApplied;
  final double remainingTotalToPay;
  final int expectedRewardPoints;
  final int actualPointsDeducted;
  final String currency;

  const CheckoutInvoice({
    required this.subtotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.maxPointsAllowed,
    required this.pointsValueApplied,
    required this.walletBalanceApplied,
    required this.remainingTotalToPay,
    required this.expectedRewardPoints,
    required this.actualPointsDeducted,
    required this.currency,
  });

  factory CheckoutInvoice.fromJson(Map<String, dynamic> json) {
    return CheckoutInvoice(
      subtotal: double.tryParse(json['subtotal']?.toString() ?? '0.0') ?? 0.0,
      taxAmount:
          double.tryParse(json['tax_amount']?.toString() ?? '0.0') ?? 0.0,
      discountAmount:
          double.tryParse(json['discount_amount']?.toString() ?? '0.0') ?? 0.0,
      maxPointsAllowed:
          int.tryParse(json['max_points_allowed']?.toString() ?? '0') ?? 0,
      pointsValueApplied:
          double.tryParse(json['points_value_applied']?.toString() ?? '0.0') ??
          0.0,
      walletBalanceApplied:
          double.tryParse(
            json['wallet_balance_applied']?.toString() ?? '0.0',
          ) ??
          0.0,
      remainingTotalToPay:
          double.tryParse(
            json['remaining_total_to_pay']?.toString() ?? '0.0',
          ) ??
          0.0,
      expectedRewardPoints:
          int.tryParse(json['expected_reward_points']?.toString() ?? '0') ?? 0,
      actualPointsDeducted:
          int.tryParse(json['actual_points_deducted']?.toString() ?? '0') ?? 0,
      currency: json['currency']?.toString() ?? 'SAR',
    );
  }
}

class CheckoutPreviewResponse {
  final CheckoutItemDetails itemDetails;
  final CheckoutUserBalances userBalances;
  final CheckoutInvoice invoice;

  const CheckoutPreviewResponse({
    required this.itemDetails,
    required this.userBalances,
    required this.invoice,
  });

  factory CheckoutPreviewResponse.fromJson(Map<String, dynamic> json) {
    final Logger logger = Logger('CheckoutPreviewModel');
    try {
      return CheckoutPreviewResponse(
        itemDetails: CheckoutItemDetails.fromJson(
          json['item_details'] as Map<String, dynamic>? ?? {},
        ),
        userBalances: CheckoutUserBalances.fromJson(
          json['user_balances'] as Map<String, dynamic>? ?? {},
        ),
        invoice: CheckoutInvoice.fromJson(
          json['invoice'] as Map<String, dynamic>? ?? {},
        ),
      );
    } catch (e, stackTrace) {
      logger.severe('Error parsing CheckoutPreviewResponse', e, stackTrace);
      throw Exception('Failed to parse checkout preview data');
    }
  }
}

class CheckoutProcessRequest {
  final String itemType;
  final int itemId;
  final String couponCode;
  final bool useWallet;
  final int pointsToRedeem;
  final String? paymentGateway;

  const CheckoutProcessRequest({
    required this.itemType,
    required this.itemId,
    this.couponCode = '',
    this.useWallet = false,
    this.pointsToRedeem = 0,
    this.paymentGateway,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'item_type': itemType,
      'item_id': itemId,
      'coupon_code': couponCode,
      'use_wallet': useWallet,
      'points_to_redeem': pointsToRedeem,
    };

    if (paymentGateway != null && paymentGateway!.isNotEmpty) {
      data['payment_gateway'] = paymentGateway;
    }

    return data;
  }
}

class CheckoutProcessResponse {
  final String status;
  final String transactionId;
  final String? redirectUrl;
  final String message;

  const CheckoutProcessResponse({
    required this.status,
    required this.transactionId,
    this.redirectUrl,
    required this.message,
  });

  factory CheckoutProcessResponse.fromJson(Map<String, dynamic> json) {
    return CheckoutProcessResponse(
      status: json['status']?.toString() ?? 'failed',
      transactionId: json['transaction_id']?.toString() ?? '',
      redirectUrl: json['redirect_url']?.toString(),
      message: json['message']?.toString() ?? '',
    );
  }
}
