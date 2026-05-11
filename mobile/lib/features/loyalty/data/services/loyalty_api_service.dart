import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import '../models/loyalty_models.dart';

class LoyaltyApiService {
  final Dio _dio;
  final Logger _logger = Logger('LoyaltyApiService');

  static const String _walletUrl = '/loyalty/wallet/';
  static const String _packagesUrl = '/loyalty/packages/';
  static const String _myMilestonesUrl = '/loyalty/my-milestones/';
  static const String _transactionsUrl = '/loyalty/transactions/';
  static const String _pointsHistoryUrl = '/loyalty/points-history/';
  static const String _claimRewardUrl = '/loyalty/milestones/claim/';
  static const String _consumeRewardUrl = '/loyalty/milestones/consume/';
  static const String _roadmapUrl = '/loyalty/milestones/';
  static const String _extendSubUrl = '/loyalty/extend-subscription/';
  static const String _bankAccountUrl = '/loyalty/bank-account/';
  static const String _withdrawUrl = '/loyalty/withdraw/';

  LoyaltyApiService({required Dio dio}) : _dio = dio;

  Future<WalletSummary> getWalletSummary() async {
    try {
      _logger.info('Fetching Wallet Summary from API: $_walletUrl');
      final response = await _dio.get(_walletUrl);

      if (response.statusCode == 200) {
        return WalletSummary.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception(
          'Failed to load wallet summary: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      _logger.severe('DioException in getWalletSummary: ${e.message}', e);
      throw Exception('Network error while fetching wallet summary.');
    } catch (e, stackTrace) {
      _logger.severe('Data parsing error in getWalletSummary', e, stackTrace);
      throw Exception('Failed to parse wallet data.');
    }
  }

  Future<List<LoyaltyPackage>> getPackages() async {
    try {
      _logger.info('Fetching Loyalty Packages from API: $_packagesUrl');
      final response = await _dio.get(_packagesUrl);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data
            .map(
              (json) => LoyaltyPackage.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw Exception('Failed to load packages: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.severe('DioException in getPackages: ${e.message}', e);
      throw Exception('Network error while fetching packages.');
    } catch (e, stackTrace) {
      _logger.severe('Data parsing error in getPackages', e, stackTrace);
      throw Exception('Failed to parse packages data.');
    }
  }

  Future<PaginatedUserMilestones> getMyMilestones({
    int? limit,
    int? page,
    String? status,
  }) async {
    try {
      _logger.info('Fetching My Milestones from API: $_myMilestonesUrl');

      final Map<String, dynamic> queryParams = {};
      if (limit != null) queryParams['limit'] = limit;
      if (page != null) queryParams['page'] = page;
      if (status != null && status != 'all') queryParams['status'] = status;

      final response = await _dio.get(
        _myMilestonesUrl,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return PaginatedUserMilestones.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw Exception(
          'Failed to load milestones history: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      _logger.severe('DioException in getMyMilestones: ${e.message}', e);
      throw Exception('Network error while fetching milestones history.');
    } catch (e, stackTrace) {
      _logger.severe('Data parsing error in getMyMilestones', e, stackTrace);
      throw Exception('Failed to parse milestones history.');
    }
  }

  Future<RewardsSummary> getRewardsSummary() async {
    try {
      _logger.info('Fetching Rewards Summary');
      final response = await _dio.get('$_myMilestonesUrl/summary/');

      if (response.statusCode == 200) {
        return RewardsSummary.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception(
          'Failed to load rewards summary: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      _logger.severe('DioException in getRewardsSummary: ${e.message}', e);
      throw Exception('Network error while fetching rewards summary.');
    } catch (e, stackTrace) {
      _logger.severe('Data parsing error in getRewardsSummary', e, stackTrace);
      throw Exception('Failed to parse rewards summary.');
    }
  }

  Future<PaginatedPointsTransactions> getPointsHistory({
    int? limit,
    int? page,
    String? type,
  }) async {
    try {
      _logger.info(
        'Fetching Points History with params: limit=$limit, page=$page, type=$type',
      );

      final Map<String, dynamic> queryParams = {};
      if (limit != null) queryParams['limit'] = limit;
      if (page != null) queryParams['page'] = page;
      if (type != null && type != 'all') queryParams['type'] = type;

      final response = await _dio.get(
        _pointsHistoryUrl,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return PaginatedPointsTransactions.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw Exception(
          'Failed to load points history: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      _logger.severe('DioException in getPointsHistory: ${e.message}', e);
      throw Exception('Network error while fetching points history.');
    } catch (e, stackTrace) {
      _logger.severe('Data parsing error in getPointsHistory', e, stackTrace);
      throw Exception('Failed to parse points history data.');
    }
  }

  Future<PointsSummary> getPointsSummary() async {
    try {
      _logger.info('Fetching Points Summary');
      final response = await _dio.get('$_pointsHistoryUrl/summary/');

      if (response.statusCode == 200) {
        return PointsSummary.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception(
          'Failed to load points summary: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      _logger.severe('DioException in getPointsSummary: ${e.message}', e);
      throw Exception('Network error while fetching points summary.');
    } catch (e, stackTrace) {
      _logger.severe('Data parsing error in getPointsSummary', e, stackTrace);
      throw Exception('Failed to parse points summary.');
    }
  }

  Future<PaginatedTransactions> getTransactions({
    int? limit,
    int? page,
    String?
    filter, // ARCHITECTURE FIX: Changed from 'type' to 'filter' to match backend
  }) async {
    try {
      _logger.info(
        'Fetching Transactions History with params: limit=$limit, page=$page, filter=$filter',
      );

      final Map<String, dynamic> queryParams = {};
      if (limit != null) queryParams['limit'] = limit;
      if (page != null) queryParams['page'] = page;
      // ARCHITECTURE FIX: Sending the parameter as 'filter'
      if (filter != null && filter != 'all') queryParams['filter'] = filter;

      final response = await _dio.get(
        _transactionsUrl,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return PaginatedTransactions.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw Exception('Failed to load transactions: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.severe('DioException in getTransactions: ${e.message}', e);
      throw Exception('Network error while fetching transactions.');
    } catch (e, stackTrace) {
      _logger.severe('Data parsing error in getTransactions', e, stackTrace);
      throw Exception('Failed to parse transactions data.');
    }
  }

  Future<TransactionSummary> getTransactionSummary() async {
    try {
      _logger.info('Fetching Transactions Summary');
      final response = await _dio.get('/loyalty/transactions/summary/');

      if (response.statusCode == 200) {
        return TransactionSummary.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw Exception(
          'Failed to load transaction summary: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      _logger.severe('DioException in getTransactionSummary: ${e.message}', e);
      throw Exception('Network error while fetching transaction summary.');
    } catch (e, stackTrace) {
      _logger.severe(
        'Data parsing error in getTransactionSummary',
        e,
        stackTrace,
      );
      throw Exception('Failed to parse transaction summary.');
    }
  }

  Future<ClaimRewardResponse> claimReward({
    required int userMilestoneId,
  }) async {
    try {
      _logger.info('Claiming reward for milestone ID: $userMilestoneId');
      final response = await _dio.post(
        _claimRewardUrl,
        data: {'user_milestone_id': userMilestoneId},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _logger.info('Reward claimed successfully.');
        return ClaimRewardResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw Exception('Failed to claim reward: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.severe('DioException in claimReward: ${e.message}', e);
      throw Exception('Network error while claiming reward.');
    }
  }

  Future<bool> extendSubscription({
    required int userMilestoneId,
    required int subscriptionId,
  }) async {
    try {
      _logger.info(
        'Extending subscription: $subscriptionId with milestone: $userMilestoneId',
      );
      final response = await _dio.post(
        _extendSubUrl,
        data: {
          'user_milestone_id': userMilestoneId,
          'subscription_id': subscriptionId,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _logger.info('Subscription extended successfully.');
        return true;
      } else {
        throw Exception(
          'Failed to extend subscription: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      _logger.severe('DioException in extendSubscription: ${e.message}', e);
      throw Exception('Network error while extending subscription.');
    }
  }

  Future<bool> consumeReward({
    required int userMilestoneId,
    required Map<String, dynamic> consumedDetails,
  }) async {
    try {
      _logger.info('Consuming reward for milestone ID: $userMilestoneId');
      final response = await _dio.post(
        _consumeRewardUrl,
        data: {
          'user_milestone_id': userMilestoneId,
          'consumed_details': consumedDetails,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _logger.info('Reward consumed successfully.');
        return true;
      } else {
        throw Exception('Failed to consume reward: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.severe('DioException in consumeReward: ${e.message}', e);
      throw Exception('Network error while consuming reward.');
    }
  }

  Future<LoyaltyRoadmapResponse> getUserRoadmap() async {
    try {
      _logger.info('Fetching User Specific Roadmap from API: $_roadmapUrl');
      final response = await _dio.get(_roadmapUrl);

      if (response.statusCode == 200) {
        return LoyaltyRoadmapResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw Exception('Failed to load user roadmap: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.severe('DioException in getUserRoadmap: ${e.message}', e);
      throw Exception('Network error while fetching roadmap.');
    } catch (e, stackTrace) {
      _logger.severe('Data parsing error in getUserRoadmap', e, stackTrace);
      throw Exception('Failed to parse roadmap data.');
    }
  }

  Future<bool> purchasePoints({
    required int packageId,
    required String gateway,
  }) async {
    try {
      _logger.info('Purchasing package ID: $packageId via gateway: $gateway');
      final response = await _dio.post(
        '/loyalty/purchase/',
        data: {'package_id': packageId, 'gateway': gateway},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _logger.info('Points purchased successfully.');
        return true;
      } else {
        throw Exception('Failed to purchase points: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.severe('DioException in purchasePoints: ${e.message}', e);
      throw Exception('Network error while purchasing points.');
    }
  }

  Future<bool> addOrUpdateBankAccount({
    required String bankName,
    required String accountNumber,
    required String iban,
    required String beneficiaryName,
  }) async {
    try {
      _logger.info('Submitting bank account details to API: $_bankAccountUrl');
      final response = await _dio.post(
        _bankAccountUrl,
        data: {
          'bank_name': bankName,
          'account_number': accountNumber,
          'iban': iban,
          'beneficiary_name': beneficiaryName,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _logger.info('Bank account saved successfully.');
        return true;
      } else {
        throw Exception('Failed to save bank account: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.severe('DioException in addOrUpdateBankAccount: ${e.message}', e);
      throw Exception('Network error while saving bank account.');
    }
  }

  Future<bool> requestWithdrawal({required double amount}) async {
    try {
      _logger.info('Submitting withdrawal request for amount: $amount');
      final response = await _dio.post(_withdrawUrl, data: {'amount': amount});

      if (response.statusCode == 200 || response.statusCode == 201) {
        _logger.info('Withdrawal request submitted successfully.');
        return true;
      } else {
        throw Exception('Failed to submit withdrawal: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _logger.severe('DioException in requestWithdrawal: ${e.message}', e);
      if (e.response?.statusCode == 400) {
        throw Exception(
          e.response?.data['detail'] ?? 'Invalid withdrawal request.',
        );
      }
      throw Exception('Network error while submitting withdrawal.');
    }
  }
}
