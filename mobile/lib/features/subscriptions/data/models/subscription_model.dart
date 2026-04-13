import 'package:equatable/equatable.dart';

/// Core model representing a user's subscription with branch details.
class SubscriptionModel extends Equatable {
  final int id;
  final String? serviceType;
  final String planName;
  final String providerName;
  final int? branchId;
  final String? branchLogo;
  final String? address;
  final double? lat;
  final double? lng;
  final String status;
  final String qrCodeSignature;
  final String startDate;
  final String endDate;
  final double? price;
  final String? purchasedAt;
  final bool? isResold;

  const SubscriptionModel({
    required this.id,
    this.serviceType,
    required this.planName,
    required this.providerName,
    this.branchId,
    this.branchLogo,
    this.address,
    this.lat,
    this.lng,
    required this.status,
    required this.qrCodeSignature,
    required this.startDate,
    required this.endDate,
    this.price,
    this.purchasedAt,
    this.isResold,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      serviceType: json['service_type']?.toString(),
      planName: json['plan_name']?.toString() ?? '',
      providerName: json['provider_name']?.toString() ?? '',
      branchId: int.tryParse(json['branch_id']?.toString() ?? '0'),
      branchLogo: json['branch_logo']?.toString(),
      address: json['address']?.toString(),
      lat: double.tryParse(json['lat']?.toString() ?? ''),
      lng: double.tryParse(json['lng']?.toString() ?? ''),
      status: json['status']?.toString() ?? 'unknown',
      qrCodeSignature: json['qr_code_signature']?.toString() ?? '',
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      price: double.tryParse(json['price']?.toString() ?? ''),
      purchasedAt: json['purchased_at']?.toString(),
      isResold: json['is_resold'] as bool?,
    );
  }

  @override
  List<Object?> get props => [
    id,
    serviceType,
    planName,
    providerName,
    branchId,
    branchLogo,
    address,
    lat,
    lng,
    status,
    qrCodeSignature,
    startDate,
    endDate,
    price,
    purchasedAt,
    isResold,
  ];
}
