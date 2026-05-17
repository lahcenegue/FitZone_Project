import 'package:logging/logging.dart';

class RewardPayload {
  final String fulfillmentType;

  final String? couponCode;
  final String? expiresAt;
  final double? discountValue;
  final String? couponType;

  final int? visitsGranted;
  final String? qrCodeSignature;
  final String? qrId;

  final int? daysAdded;
  final String? status;

  final String? itemName;

  const RewardPayload({
    required this.fulfillmentType,
    this.couponCode,
    this.expiresAt,
    this.discountValue,
    this.couponType,
    this.visitsGranted,
    this.qrCodeSignature,
    this.qrId,
    this.daysAdded,
    this.status,
    this.itemName,
  });

  factory RewardPayload.fromJson(Map<String, dynamic> json) {
    final Logger logger = Logger('RewardPayloadModel');
    try {
      return RewardPayload(
        fulfillmentType: json['fulfillment_type']?.toString() ?? '',
        couponCode: json['coupon_code']?.toString(),
        expiresAt: json['expires_at']?.toString(),
        discountValue: double.tryParse(
          json['discount_value']?.toString() ?? '',
        ),
        couponType: json['coupon_type']?.toString(),
        visitsGranted: int.tryParse(json['visits_granted']?.toString() ?? ''),
        qrCodeSignature: json['qr_code_signature']?.toString(),
        qrId: json['qr_id']?.toString(),
        daysAdded: int.tryParse(json['days_added']?.toString() ?? ''),
        status: json['status']?.toString(),
        itemName: json['item_name']?.toString(),
      );
    } catch (e, stackTrace) {
      logger.severe('Error parsing RewardPayload', e, stackTrace);
      return const RewardPayload(fulfillmentType: 'unknown');
    }
  }
}

class UserMilestoneData {
  final String status;
  final int? userMilestoneId;

  const UserMilestoneData({required this.status, this.userMilestoneId});

  factory UserMilestoneData.fromJson(Map<String, dynamic> json) {
    return UserMilestoneData(
      status: json['status']?.toString() ?? 'locked',
      userMilestoneId: int.tryParse(
        json['user_milestone_id']?.toString() ?? '',
      ),
    );
  }
}

class LoyaltyReward {
  final int id;
  final String name;
  final String actionType;
  final double actionValue;
  final String fulfillmentType;
  final String? actionRoute;
  final String? couponType;
  final double? discountValue;
  final Map<String, dynamic> constraints;

  const LoyaltyReward({
    required this.id,
    required this.name,
    required this.actionType,
    required this.actionValue,
    required this.fulfillmentType,
    this.actionRoute,
    this.couponType,
    this.discountValue,
    required this.constraints,
  });

  factory LoyaltyReward.fromJson(Map<String, dynamic> json) {
    final Logger logger = Logger('LoyaltyRewardModel');
    try {
      return LoyaltyReward(
        id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
        name: json['name']?.toString() ?? '',
        actionType: json['action_type']?.toString() ?? '',
        actionValue:
            double.tryParse(json['action_value']?.toString() ?? '0.0') ?? 0.0,
        fulfillmentType: json['fulfillment_type']?.toString() ?? 'IMMEDIATE',
        actionRoute: json['action_route']?.toString(),
        couponType: json['coupon_type']?.toString(),
        discountValue: double.tryParse(
          json['discount_value']?.toString() ?? '',
        ),
        constraints: json['constraints'] as Map<String, dynamic>? ?? {},
      );
    } catch (e, stackTrace) {
      logger.severe('Error parsing LoyaltyReward', e, stackTrace);
      return const LoyaltyReward(
        id: 0,
        name: '',
        actionType: '',
        actionValue: 0.0,
        fulfillmentType: 'IMMEDIATE',
        constraints: {},
      );
    }
  }
}

class LoyaltyMilestone {
  final int id;
  final String title;
  final int requiredLifetimePoints;
  final LoyaltyReward? reward;
  final String description;
  final UserMilestoneData? userMilestoneData;

  const LoyaltyMilestone({
    required this.id,
    required this.title,
    required this.requiredLifetimePoints,
    this.reward,
    required this.description,
    this.userMilestoneData,
  });

  factory LoyaltyMilestone.fromJson(Map<String, dynamic> json) {
    final Logger logger = Logger('LoyaltyMilestoneModel');
    try {
      return LoyaltyMilestone(
        id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
        title: json['title']?.toString() ?? '',
        requiredLifetimePoints:
            int.tryParse(json['required_lifetime_points']?.toString() ?? '0') ??
            0,
        reward: json['reward'] != null
            ? LoyaltyReward.fromJson(json['reward'] as Map<String, dynamic>)
            : null,
        description: json['description']?.toString() ?? '',
        userMilestoneData: json['user_milestone_data'] != null
            ? UserMilestoneData.fromJson(
                json['user_milestone_data'] as Map<String, dynamic>,
              )
            : null,
      );
    } catch (e, stackTrace) {
      logger.severe('Error parsing LoyaltyMilestone', e, stackTrace);
      return const LoyaltyMilestone(
        id: 0,
        title: '',
        requiredLifetimePoints: 0,
        description: '',
      );
    }
  }
}

class UserMilestone {
  final int id;
  final LoyaltyMilestone milestone;
  final bool isClaimed;
  final String? claimedAt;
  final bool isConsumed;
  final String unlockedAt;
  final String? consumedAt;
  final RewardPayload? rewardPayload;

  const UserMilestone({
    required this.id,
    required this.milestone,
    required this.isClaimed,
    this.claimedAt,
    required this.isConsumed,
    required this.unlockedAt,
    this.consumedAt,
    this.rewardPayload,
  });

  factory UserMilestone.fromJson(Map<String, dynamic> json) {
    final Logger logger = Logger('UserMilestoneModel');
    try {
      return UserMilestone(
        id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
        milestone: LoyaltyMilestone.fromJson(
          json['milestone'] as Map<String, dynamic>,
        ),
        isClaimed: json['is_claimed'] as bool? ?? false,
        claimedAt: json['claimed_at']?.toString(),
        isConsumed: json['is_consumed'] as bool? ?? false,
        unlockedAt: json['unlocked_at']?.toString() ?? '',
        consumedAt: json['consumed_at']?.toString(),
        rewardPayload: json['reward_payload'] != null
            ? RewardPayload.fromJson(
                json['reward_payload'] as Map<String, dynamic>,
              )
            : null,
      );
    } catch (e, stackTrace) {
      logger.severe('Error parsing UserMilestone', e, stackTrace);
      throw Exception('Failed to parse UserMilestone JSON');
    }
  }
}

class PaginatedUserMilestones {
  final int count;
  final String? next;
  final String? previous;
  final List<UserMilestone> results;

  PaginatedUserMilestones({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory PaginatedUserMilestones.fromJson(Map<String, dynamic> json) {
    return PaginatedUserMilestones(
      count: json['count'] as int? ?? 0,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results:
          (json['results'] as List<dynamic>?)
              ?.map((e) => UserMilestone.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ClaimRewardResponse {
  final String message;
  final RewardPayload? rewardPayload;

  const ClaimRewardResponse({required this.message, this.rewardPayload});

  factory ClaimRewardResponse.fromJson(Map<String, dynamic> json) {
    return ClaimRewardResponse(
      message: json['message']?.toString() ?? '',
      rewardPayload: json['reward_payload'] != null
          ? RewardPayload.fromJson(
              json['reward_payload'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class LoyaltyPackage {
  final int id;
  final String name;
  final int points;
  final double price;
  final bool isBestSeller;

  const LoyaltyPackage({
    required this.id,
    required this.name,
    required this.points,
    required this.price,
    required this.isBestSeller,
  });

  factory LoyaltyPackage.fromJson(Map<String, dynamic> json) {
    final Logger logger = Logger('LoyaltyPackageModel');
    try {
      return LoyaltyPackage(
        id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
        name: json['name']?.toString() ?? '',
        points: int.tryParse(json['points']?.toString() ?? '0') ?? 0,
        price: double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0,
        // Map the new backend field correctly
        isBestSeller: json['is_best_seller'] as bool? ?? false,
      );
    } catch (e, stackTrace) {
      logger.severe('Error parsing LoyaltyPackage', e, stackTrace);
      return const LoyaltyPackage(
        id: 0,
        name: '',
        points: 0,
        price: 0.0,
        isBestSeller: false,
      );
    }
  }
}

class BankAccount {
  final String bankName;
  final String accountNumber;
  final String iban;
  final String beneficiaryName;

  const BankAccount({
    required this.bankName,
    required this.accountNumber,
    required this.iban,
    required this.beneficiaryName,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    final Logger logger = Logger('BankAccountModel');
    try {
      return BankAccount(
        bankName: json['bank_name']?.toString() ?? '',
        accountNumber: json['account_number']?.toString() ?? '',
        iban: json['iban']?.toString() ?? '',
        beneficiaryName: json['beneficiary_name']?.toString() ?? '',
      );
    } catch (e, stackTrace) {
      logger.severe('Error parsing BankAccount', e, stackTrace);
      return const BankAccount(
        bankName: '',
        accountNumber: '',
        iban: '',
        beneficiaryName: '',
      );
    }
  }
}

class RoadmapMetaProgress {
  final int lifetimePoints;
  final String currentMilestoneTitle;
  final String nextMilestoneTitle;
  final int pointsToNextMilestone;
  final double progressPct;

  const RoadmapMetaProgress({
    required this.lifetimePoints,
    required this.currentMilestoneTitle,
    required this.nextMilestoneTitle,
    required this.pointsToNextMilestone,
    required this.progressPct,
  });

  factory RoadmapMetaProgress.fromJson(Map<String, dynamic> json) {
    final Logger logger = Logger('RoadmapMetaProgressModel');
    try {
      return RoadmapMetaProgress(
        lifetimePoints:
            int.tryParse(json['lifetime_points']?.toString() ?? '0') ?? 0,
        currentMilestoneTitle:
            json['current_milestone_title']?.toString() ?? '',
        nextMilestoneTitle: json['next_milestone_title']?.toString() ?? '',
        pointsToNextMilestone:
            int.tryParse(json['points_to_next_milestone']?.toString() ?? '0') ??
            0,
        progressPct: (json['progress_pct'] as num?)?.toDouble() ?? 0.0,
      );
    } catch (e, stackTrace) {
      logger.severe('Error parsing RoadmapMetaProgress', e, stackTrace);
      return const RoadmapMetaProgress(
        lifetimePoints: 0,
        currentMilestoneTitle: '',
        nextMilestoneTitle: '',
        pointsToNextMilestone: 0,
        progressPct: 0.0,
      );
    }
  }
}

class LoyaltyRoadmapResponse {
  final RoadmapMetaProgress metaProgress;
  final List<LoyaltyMilestone> milestones;

  const LoyaltyRoadmapResponse({
    required this.metaProgress,
    required this.milestones,
  });

  factory LoyaltyRoadmapResponse.fromJson(Map<String, dynamic> json) {
    final Logger logger = Logger('LoyaltyRoadmapResponseModel');
    try {
      return LoyaltyRoadmapResponse(
        metaProgress: RoadmapMetaProgress.fromJson(
          json['meta_progress'] as Map<String, dynamic>,
        ),
        milestones:
            (json['milestones'] as List<dynamic>?)
                ?.map(
                  (e) => LoyaltyMilestone.fromJson(e as Map<String, dynamic>),
                )
                .toList() ??
            [],
      );
    } catch (e, stackTrace) {
      logger.severe('Error parsing LoyaltyRoadmapResponse', e, stackTrace);
      throw Exception('Failed to parse LoyaltyRoadmapResponse JSON');
    }
  }
}

class WalletSummary {
  final int spendablePoints;
  final int lifetimePoints;
  final double fiatBalance;
  final double pendingFiatBalance;
  final int unlockedRewardsCount;
  final BankAccount? bankAccount;

  const WalletSummary({
    required this.spendablePoints,
    required this.lifetimePoints,
    required this.fiatBalance,
    required this.pendingFiatBalance,
    required this.unlockedRewardsCount,
    this.bankAccount,
  });

  factory WalletSummary.fromJson(Map<String, dynamic> json) {
    final Logger logger = Logger('WalletSummaryModel');
    try {
      return WalletSummary(
        spendablePoints:
            int.tryParse(json['spendable_points']?.toString() ?? '0') ?? 0,
        lifetimePoints:
            int.tryParse(json['lifetime_points']?.toString() ?? '0') ?? 0,
        fiatBalance:
            double.tryParse(json['fiat_balance']?.toString() ?? '0.0') ?? 0.0,
        pendingFiatBalance:
            double.tryParse(
              json['pending_fiat_balance']?.toString() ?? '0.0',
            ) ??
            0.0,
        unlockedRewardsCount:
            int.tryParse(json['unlocked_rewards_count']?.toString() ?? '0') ??
            0,
        bankAccount: json['bank_account'] != null
            ? BankAccount.fromJson(json['bank_account'] as Map<String, dynamic>)
            : null,
      );
    } catch (e, stackTrace) {
      logger.severe('Error parsing WalletSummary', e, stackTrace);
      throw Exception('Failed to parse WalletSummary JSON');
    }
  }
}

class FinancialTransaction {
  final int id;
  final String title;
  final String amount;
  final String type;
  final String status;
  final String? statusLabel;
  final String createdAt;
  final String? expectedReleaseDate;
  final String impact;

  const FinancialTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.status,
    this.statusLabel,
    required this.createdAt,
    this.expectedReleaseDate,
    required this.impact,
  });

  factory FinancialTransaction.fromJson(Map<String, dynamic> json) {
    final Logger logger = Logger('FinancialTransactionModel');
    try {
      return FinancialTransaction(
        id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
        title: json['title']?.toString() ?? '',
        amount: json['amount']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        statusLabel: json['status_label']?.toString(),
        createdAt: json['created_at']?.toString() ?? '',
        expectedReleaseDate: json['expected_release_date']?.toString(),
        impact: json['impact']?.toString() ?? 'in',
      );
    } catch (e, stackTrace) {
      logger.severe('Error parsing FinancialTransaction', e, stackTrace);
      throw Exception('Failed to parse FinancialTransaction JSON');
    }
  }
}

class TransactionSummary {
  final double grossEarnings;
  final double availableFunds;
  final double pendingEscrow;
  final double totalConsumed;
  final double totalWithdrawn;

  TransactionSummary({
    required this.grossEarnings,
    required this.availableFunds,
    required this.pendingEscrow,
    required this.totalConsumed,
    required this.totalWithdrawn,
  });

  factory TransactionSummary.fromJson(Map<String, dynamic> json) {
    return TransactionSummary(
      grossEarnings: (json['gross_earnings'] as num?)?.toDouble() ?? 0.0,
      availableFunds: (json['available_funds'] as num?)?.toDouble() ?? 0.0,
      pendingEscrow: (json['pending_escrow'] as num?)?.toDouble() ?? 0.0,
      totalConsumed: (json['total_consumed'] as num?)?.toDouble() ?? 0.0,
      totalWithdrawn: (json['total_withdrawn'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PaginatedTransactions {
  final int count;
  final String? next;
  final String? previous;
  final List<FinancialTransaction> results;

  PaginatedTransactions({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory PaginatedTransactions.fromJson(Map<String, dynamic> json) {
    return PaginatedTransactions(
      count: json['count'] as int? ?? 0,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results:
          (json['results'] as List<dynamic>?)
              ?.map(
                (e) => FinancialTransaction.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}

class PointsTransaction {
  final int id;
  final String title;
  final int amount;
  final String type;
  final String createdAt;

  const PointsTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.createdAt,
  });

  factory PointsTransaction.fromJson(Map<String, dynamic> json) {
    final Logger logger = Logger('PointsTransactionModel');
    try {
      return PointsTransaction(
        id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
        title: json['title']?.toString() ?? '',
        amount: int.tryParse(json['amount']?.toString() ?? '0') ?? 0,
        type: json['type']?.toString() ?? '',
        createdAt: json['created_at']?.toString() ?? '',
      );
    } catch (e, stackTrace) {
      logger.severe('Error parsing PointsTransaction', e, stackTrace);
      throw Exception('Failed to parse PointsTransaction JSON');
    }
  }
}

class PaginatedPointsTransactions {
  final int count;
  final String? next;
  final String? previous;
  final List<PointsTransaction> results;

  PaginatedPointsTransactions({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  factory PaginatedPointsTransactions.fromJson(Map<String, dynamic> json) {
    return PaginatedPointsTransactions(
      count: json['count'] as int? ?? 0,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
      results:
          (json['results'] as List<dynamic>?)
              ?.map(
                (e) => PointsTransaction.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}

class PointsSummary {
  final int totalEarned;
  final int totalRedeemed;

  PointsSummary({required this.totalEarned, required this.totalRedeemed});

  factory PointsSummary.fromJson(Map<String, dynamic> json) {
    return PointsSummary(
      totalEarned: int.tryParse(json['total_earned']?.toString() ?? '0') ?? 0,
      totalRedeemed:
          int.tryParse(json['total_redeemed']?.toString() ?? '0') ?? 0,
    );
  }
}

class RewardsSummary {
  final int totalAvailable;
  final int totalConsumed;

  RewardsSummary({required this.totalAvailable, required this.totalConsumed});

  factory RewardsSummary.fromJson(Map<String, dynamic> json) {
    return RewardsSummary(
      totalAvailable:
          int.tryParse(json['total_available']?.toString() ?? '0') ?? 0,
      totalConsumed:
          int.tryParse(json['total_consumed']?.toString() ?? '0') ?? 0,
    );
  }
}
