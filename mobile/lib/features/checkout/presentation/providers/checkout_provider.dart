import 'dart:async';

import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/config/app_constants.dart';
import '../../../../core/network/api_provider.dart';
import '../../data/models/checkout_models.dart';
import '../../data/services/checkout_api_service.dart';

part 'checkout_provider.g.dart';

@riverpod
CheckoutApiService checkoutApiService(Ref ref) {
  final dio = ref.watch(dioClientProvider);
  return CheckoutApiService(dio);
}

class CheckoutState {
  final CheckoutProcessRequest request;
  final CheckoutPreviewResponse? invoiceData;
  final bool isInitialLoading;
  final bool isUpdatingInvoice;
  final bool isApplyingCoupon;
  final bool isProcessingPayment;
  final Object? couponError;
  final Object? generalError;

  CheckoutState({
    required this.request,
    this.invoiceData,
    this.isInitialLoading = true,
    this.isUpdatingInvoice = false,
    this.isApplyingCoupon = false,
    this.isProcessingPayment = false,
    this.couponError,
    this.generalError,
  });

  CheckoutState copyWith({
    CheckoutProcessRequest? request,
    CheckoutPreviewResponse? invoiceData,
    bool? isInitialLoading,
    bool? isUpdatingInvoice,
    bool? isApplyingCoupon,
    bool? isProcessingPayment,
    Object? couponError,
    bool clearCouponError = false,
    Object? generalError,
  }) {
    return CheckoutState(
      request: request ?? this.request,
      invoiceData: invoiceData ?? this.invoiceData,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isUpdatingInvoice: isUpdatingInvoice ?? this.isUpdatingInvoice,
      isApplyingCoupon: isApplyingCoupon ?? this.isApplyingCoupon,
      isProcessingPayment: isProcessingPayment ?? this.isProcessingPayment,
      couponError: clearCouponError ? null : (couponError ?? this.couponError),
      generalError: generalError ?? this.generalError,
    );
  }
}

@riverpod
class CheckoutController extends _$CheckoutController {
  final Logger _logger = Logger('CheckoutController');
  Timer? _debounceTimer;

  @override
  CheckoutState build(String itemType, int itemId) {
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });

    final initialRequest = CheckoutProcessRequest(
      itemType: itemType,
      itemId: itemId,
      useWallet: true,
      pointsToRedeem: 0,
      couponCode: '',
    );

    _fetchPreview(initialRequest, isInitial: true);

    return CheckoutState(request: initialRequest);
  }

  void toggleWallet(bool useWallet) {
    final newRequest = CheckoutProcessRequest(
      itemType: state.request.itemType,
      itemId: state.request.itemId,
      useWallet: useWallet,
      pointsToRedeem: state.request.pointsToRedeem,
      couponCode: state.request.couponCode,
    );
    state = state.copyWith(
      request: newRequest,
      isUpdatingInvoice: true,
      clearCouponError: true,
    );
    _fetchPreview(newRequest);
  }

  void updatePoints(int points) {
    final newRequest = CheckoutProcessRequest(
      itemType: state.request.itemType,
      itemId: state.request.itemId,
      useWallet: state.request.useWallet,
      pointsToRedeem: points,
      couponCode: state.request.couponCode,
    );
    state = state.copyWith(
      request: newRequest,
      isUpdatingInvoice: true,
      clearCouponError: true,
    );
    _debouncedFetchPreview(newRequest);
  }

  void applyCoupon(String code) {
    final newRequest = CheckoutProcessRequest(
      itemType: state.request.itemType,
      itemId: state.request.itemId,
      useWallet: state.request.useWallet,
      pointsToRedeem: state.request.pointsToRedeem,
      couponCode: code,
    );
    state = state.copyWith(
      request: newRequest,
      isApplyingCoupon: true,
      clearCouponError: true,
    );
    _fetchPreview(newRequest, isCoupon: true);
  }

  void _debouncedFetchPreview(CheckoutProcessRequest request) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    // ARCHITECTURE FIX: Unified debounce delay from constants
    _debounceTimer = Timer(
      const Duration(milliseconds: AppConstants.debounceMilliseconds),
      () {
        _fetchPreview(request);
      },
    );
  }

  Future<void> _fetchPreview(
    CheckoutProcessRequest request, {
    bool isInitial = false,
    bool isCoupon = false,
  }) async {
    try {
      final apiService = ref.read(checkoutApiServiceProvider);
      final response = await apiService.getCheckoutPreview(request);

      if (state.request == request) {
        state = state.copyWith(
          invoiceData: response,
          isInitialLoading: false,
          isUpdatingInvoice: false,
          isApplyingCoupon: false,
          clearCouponError: true,
        );
      }
    } catch (e, stackTrace) {
      _logger.severe('Failed to fetch checkout preview', e, stackTrace);
      if (state.request == request) {
        if (isInitial) {
          state = state.copyWith(isInitialLoading: false, generalError: e);
        } else {
          state = state.copyWith(
            isUpdatingInvoice: false,
            isApplyingCoupon: false,
            couponError: isCoupon ? e : null,
          );
        }
      }
    }
  }

  Future<CheckoutProcessResponse> processPayment(String? gateway) async {
    state = state.copyWith(isProcessingPayment: true);
    try {
      final apiService = ref.read(checkoutApiServiceProvider);
      final finalRequest = CheckoutProcessRequest(
        itemType: state.request.itemType,
        itemId: state.request.itemId,
        useWallet: state.request.useWallet,
        pointsToRedeem: state.request.pointsToRedeem,
        couponCode: state.request.couponCode,
        paymentGateway: gateway,
      );

      final response = await apiService.processCheckout(finalRequest);
      state = state.copyWith(isProcessingPayment: false);
      return response;
    } catch (e, stackTrace) {
      _logger.severe('Payment processing failed', e, stackTrace);
      state = state.copyWith(isProcessingPayment: false);
      rethrow;
    }
  }
}
