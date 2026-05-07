import 'package:logging/logging.dart';

// ARCHITECTURE FIX: Added Reward Payload to handle polymorphic fulfillment types
class RewardPayload {
  final String fulfillmentType;

  // Coupon Payload
  final String? couponCode;
  final String? expiresAt;
  final double? discountValue;
  final String? couponType;

  // Roaming Pass Payload
  final int? visitsGranted;
  final String? qrCodeSignature;
  final String? qrId;

  // Subscription Extension Payload
  final int? daysAdded;
  final String? status;

  // Manual/Physical Payload
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
  // ARCHITECTURE FIX: Added fields from the updated backend JSON
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
  final UserMilestoneData? userMilestoneData; // Added for Gamified Track

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

  const LoyaltyPackage({
    required this.id,
    required this.name,
    required this.points,
    required this.price,
  });

  factory LoyaltyPackage.fromJson(Map<String, dynamic> json) {
    final Logger logger = Logger('LoyaltyPackageModel');
    try {
      return LoyaltyPackage(
        id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
        name: json['name']?.toString() ?? '',
        points: int.tryParse(json['points']?.toString() ?? '0') ?? 0,
        price: double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0,
      );
    } catch (e, stackTrace) {
      logger.severe('Error parsing LoyaltyPackage', e, stackTrace);
      return const LoyaltyPackage(id: 0, name: '', points: 0, price: 0.0);
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

class NextMilestone {
  final String title;
  final int requiredPoints;
  final int pointsToNextMilestone; // ARCHITECTURE FIX: Added mapping
  final double progressPct;

  const NextMilestone({
    required this.title,
    required this.requiredPoints,
    required this.pointsToNextMilestone,
    required this.progressPct,
  });

  factory NextMilestone.fromJson(Map<String, dynamic> json) {
    final Logger logger = Logger('NextMilestoneModel');
    try {
      return NextMilestone(
        title: json['title']?.toString() ?? '',
        requiredPoints: int.tryParse(json['required']?.toString() ?? '0') ?? 0,
        pointsToNextMilestone:
            int.tryParse(json['points_to_next_milestone']?.toString() ?? '0') ??
            0,
        // Ensure we handle percentages coming as 72 or 72.5
        progressPct: (json['progress_pct'] as num?)?.toDouble() ?? 0.0,
      );
    } catch (e, stackTrace) {
      logger.severe('Error parsing NextMilestone', e, stackTrace);
      return const NextMilestone(
        title: '',
        requiredPoints: 0,
        pointsToNextMilestone: 0,
        progressPct: 0.0,
      );
    }
  }
}

class WalletSummary {
  final String currentMilestoneTitle; // ARCHITECTURE FIX: Added mapping
  final int spendablePoints;
  final int lifetimePoints;
  final double fiatBalance;
  final int unlockedRewardsCount;
  final NextMilestone? nextMilestone;
  final BankAccount? bankAccount;

  const WalletSummary({
    required this.currentMilestoneTitle,
    required this.spendablePoints,
    required this.lifetimePoints,
    required this.fiatBalance,
    required this.unlockedRewardsCount,
    this.nextMilestone,
    this.bankAccount,
  });

  factory WalletSummary.fromJson(Map<String, dynamic> json) {
    final Logger logger = Logger('WalletSummaryModel');
    try {
      return WalletSummary(
        currentMilestoneTitle:
            json['current_milestone_title']?.toString() ?? '',
        spendablePoints:
            int.tryParse(json['spendable_points']?.toString() ?? '0') ?? 0,
        lifetimePoints:
            int.tryParse(json['lifetime_points']?.toString() ?? '0') ?? 0,
        fiatBalance:
            double.tryParse(json['fiat_balance']?.toString() ?? '0.0') ?? 0.0,
        unlockedRewardsCount:
            int.tryParse(json['unlocked_rewards_count']?.toString() ?? '0') ??
            0,
        nextMilestone: json['next_milestone'] != null
            ? NextMilestone.fromJson(
                json['next_milestone'] as Map<String, dynamic>,
              )
            : null,
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
  final String createdAt;

  const FinancialTransaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.status,
    required this.createdAt,
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
        createdAt: json['created_at']?.toString() ?? '',
      );
    } catch (e, stackTrace) {
      logger.severe('Error parsing FinancialTransaction', e, stackTrace);
      throw Exception('Failed to parse FinancialTransaction JSON');
    }
  }
}

class TransactionSummary {
  final double totalEarned;
  final double totalSpent;
  final double pendingWithdrawals;
  final double completedWithdrawals;

  TransactionSummary({
    required this.totalEarned,
    required this.totalSpent,
    required this.pendingWithdrawals,
    required this.completedWithdrawals,
  });

  factory TransactionSummary.fromJson(Map<String, dynamic> json) {
    return TransactionSummary(
      totalEarned: (json['total_earned'] as num?)?.toDouble() ?? 0.0,
      totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0.0,
      pendingWithdrawals:
          (json['pending_withdrawals'] as num?)?.toDouble() ?? 0.0,
      completedWithdrawals:
          (json['completed_withdrawals'] as num?)?.toDouble() ?? 0.0,
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
