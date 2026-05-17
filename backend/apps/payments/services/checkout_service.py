# apps/payments/services/checkout_service.py

import logging
from decimal import Decimal, ROUND_HALF_UP
from django.core.exceptions import ValidationError
from django.db import transaction
from django.core.signals import request_finished  # generic safe metadata import if needed
from django.utils import timezone
from datetime import timedelta

# Absolute imports to prevent any path resolution issues
from apps.gyms.models import SubscriptionPlan, GymBranch, GymSubscription, RoamingPass
from apps.resale.models import (
    SubscriptionResaleListing, ResaleListingStatus, ResaleGlobalSetting, 
    ResaleTransaction, ResaleTransactionStatus
)
from apps.loyalty.models import (
    PointPackage, LoyaltyGlobalSetting, CustomerWallet, 
    WalletTransaction, TransactionType, TransactionStatus
)
from apps.coupons.models import UserCoupon, CouponDefinition
from apps.coupons.services import CouponValidationService
from apps.payments.services.payment_gateway_service import PaymentService
from apps.payments.models import PaymentTransaction, PaymentGlobalSetting

logger = logging.getLogger(__name__)

class CheckoutService:
    """
    Centralized service for handling all financial calculations, payment routing, 
    and product fulfillment in a single unified atomic transaction.
    """

    @staticmethod
    def _get_absolute_image_url(request, image_field) -> str | None:
        """
        Helper method to convert an ImageField to a full absolute URL.
        Applies DRY principle for all image URL generations.
        """
        if image_field and hasattr(image_field, 'url'):
            return request.build_absolute_uri(image_field.url)
        return None

    @staticmethod
    def validate_package_discounts(item_type: str, coupon_code: str, points_to_redeem: int) -> None:
        """
        Validates and rejects any coupon code or points redemption attempts 
        whenever a user is purchasing a points package. 
        Protects the platform's economic integrity against system loops.
        """
        if item_type == "points_package":
            if coupon_code and coupon_code.strip() != "":
                logger.warning("Attempted to apply a coupon discount on a points package purchase.")
                raise ValidationError(
                    message="Coupons cannot be applied when purchasing points packages.",
                    code="package_coupon_prohibited"
                )
            if points_to_redeem > 0:
                logger.warning("Attempted to redeem loyalty points to purchase a points package.")
                raise ValidationError(
                    message="Loyalty points cannot be used to purchase points packages.",
                    code="package_points_prohibited"
                )

    @staticmethod
    def _fetch_item_details(request, item_type: str, item_id: int, loyalty_settings: LoyaltyGlobalSetting) -> dict:
        """
        Validates the requested item and extracts its details securely from the database.
        Returns a dictionary with raw data to allow flexible frontend localization.
        """
        try:
            if item_type == "gym_plan":
                item = SubscriptionPlan.objects.select_related('provider').get(id=item_id, is_active=True)
                image_url = CheckoutService._get_absolute_image_url(request, item.provider.logo)
                return {
                    "item_type": "gym_plan",
                    "price": item.price,
                    "original_price": None,
                    "max_discount_pct": loyalty_settings.max_discount_gym_plan,
                    "earn_rate": loyalty_settings.gym_earn_rate,
                    "title": item.name,
                    "provider_name": item.provider.business_name,
                    "image_url": image_url,
                    "quantity": item.duration_days,
                    "unit": "days"
                }
                
            elif item_type == "resale_item":
                item = SubscriptionResaleListing.objects.select_related('subscription__plan__provider').get(id=item_id, status=ResaleListingStatus.ACTIVE)
                
                
                from apps.resale.services import ResaleMarketService
                decayed_pricing = ResaleMarketService.calculate_current_fair_price(item)
                current_decayed_asking_price = decayed_pricing["current_asking_price"]

                plan = item.subscription.plan
                provider = plan.provider
                image_url = CheckoutService._get_absolute_image_url(request, provider.logo)
                return {
                    "item_type": "resale_item",
                    "price": current_decayed_asking_price, 
                    "original_price": plan.price,
                    "max_discount_pct": loyalty_settings.max_discount_resale,
                    "earn_rate": Decimal("0.00"),
                    "title": plan.name,
                    "provider_name": provider.business_name,
                    "image_url": image_url,
                    "quantity": plan.duration_days,
                    "unit": "days"
                }
                
            elif item_type == "roaming_pass":
                item = GymBranch.objects.select_related('provider').get(id=item_id, is_active=True, is_roaming_enabled=True)
                
                if hasattr(item, 'branch_logo') and item.branch_logo:
                    image_url = CheckoutService._get_absolute_image_url(request, item.branch_logo)
                else:
                    image_url = CheckoutService._get_absolute_image_url(request, item.provider.logo)
                    
                return {
                    "item_type": "roaming_pass",
                    "price": item.roaming_visit_price,
                    "original_price": None,
                    "max_discount_pct": loyalty_settings.max_discount_roaming,
                    "earn_rate": loyalty_settings.gym_earn_rate,
                    "title": "Roaming Visit",
                    "provider_name": f"{item.provider.business_name} - {item.name}",
                    "image_url": image_url,
                    "quantity": 1,
                    "unit": "visit"
                }
                
            elif item_type == "points_package":
                item = PointPackage.objects.get(id=item_id, is_active=True)
                return {
                    "item_type": "points_package",
                    "price": item.price,
                    "original_price": None,
                    "max_discount_pct": loyalty_settings.max_discount_packages,
                    "earn_rate": Decimal("0.00"),
                    "title": item.name,
                    "provider_name": "FitZone",
                    "image_url": None,
                    "quantity": item.points,
                    "unit": "points"
                }
            else:
                raise ValidationError(message="Invalid item_type provided.", code="invalid_item_type")
                
        except Exception as e:
            logger.error(f"Item validation failed during checkout for type {item_type} ID {item_id}: {e}")
            raise ValidationError(message="The requested item does not exist or is currently unavailable.", code="item_unavailable")

    @staticmethod
    def _calculate_coupon_discount(user, coupon_code: str, subtotal: Decimal) -> Decimal:
        """
        Validates and calculates the fiat discount amount from a coupon code.
        Catches inner validation errors and attaches custom error codes for the frontend.
        """
        if not coupon_code:
            return Decimal("0.00")
            
        try:
            validation_result = CouponValidationService.validate_and_calculate_discount(
                user=user, 
                coupon_code=coupon_code, 
                subtotal=subtotal
            )
            return validation_result.get("discount_amount", Decimal("0.00"))
        except ValidationError as e:
            error_msg = e.message if hasattr(e, 'message') else (e.messages[0] if hasattr(e, 'messages') else str(e))
            
            error_code = "invalid_coupon"
            msg_lower = error_msg.lower()
            
            if "paused" in msg_lower or "active" in msg_lower:
                error_code = "campaign_paused"
            elif "expire" in msg_lower or "expiration" in msg_lower:
                error_code = "coupon_expired"
            elif "limit" in msg_lower or "used" in msg_lower or "redeem" in msg_lower:
                error_code = "coupon_exhausted"
                
            raise ValidationError(message=error_msg, code=error_code)

    @staticmethod
    def preview_checkout(request, payload: dict) -> dict:
        """
        Generates a secure, immutable invoice preview for the requested items.
        Includes VAT, structured item metrics, user balances, and coupon integration.
        """
        user = request.user
        item_type = payload.get("item_type")
        item_id = payload.get("item_id")
        coupon_code = payload.get("coupon_code", "").strip()
        use_wallet = bool(payload.get("use_wallet", False))
        points_to_redeem = int(payload.get("points_to_redeem", 0))

        if points_to_redeem < 0:
            raise ValidationError(message="Points to redeem cannot be negative.", code="invalid_points")

        # Strict Security Business Validation Step
        CheckoutService.validate_package_discounts(item_type, coupon_code, points_to_redeem)

        loyalty_settings = LoyaltyGlobalSetting.load()
        payment_settings = PaymentGlobalSetting.load()
        wallet, _ = CustomerWallet.objects.get_or_create(user=user)

        # 1. Base Price & Item Details
        item_details = CheckoutService._fetch_item_details(request, item_type, item_id, loyalty_settings)
        subtotal = item_details["price"]
        
        # 2. Coupon Discount
        coupon_discount = CheckoutService._calculate_coupon_discount(user, coupon_code, subtotal)
        price_after_coupon = max(Decimal("0.00"), subtotal - coupon_discount)

        # 3. VAT Calculation
        tax_amount = (price_after_coupon * payment_settings.vat_percentage) / Decimal("100.00")
        grand_total = price_after_coupon + tax_amount

        # 4. Points Economy Resolution
        max_fiat_discount_allowed = (grand_total * item_details["max_discount_pct"]) / Decimal("100.00")
        max_points_allowed_by_rules = int(max_fiat_discount_allowed * loyalty_settings.point_to_fiat_rate)
        
        opacity_max_points_allowed = min(max_points_allowed_by_rules, wallet.points_balance)
        final_points_redeemed = min(points_to_redeem, opacity_max_points_allowed)
        
        points_fiat_value = Decimal(final_points_redeemed) / loyalty_settings.point_to_fiat_rate
        price_after_points = max(Decimal("0.00"), grand_total - points_fiat_value)

        # 5. Wallet Fiat Resolution
        wallet_fiat_applied = Decimal("0.00")
        if use_wallet and price_after_points > 0:
            wallet_fiat_applied = min(wallet.fiat_balance, price_after_points)
        
        # 6. Final Gateway Total
        remaining_total_to_pay = price_after_points - wallet_fiat_applied

        # 7. Expected Reward Projection
        expected_reward_points = 0
        earn_rate = item_details["earn_rate"]
        if earn_rate > 0:
            fiat_paid = wallet_fiat_applied + remaining_total_to_pay
            expected_reward_points = int(fiat_paid / earn_rate)

        original_price_formatted = None
        if item_details["original_price"] is not None:
            original_price_formatted = float(item_details["original_price"].quantize(Decimal("0.01"), rounding=ROUND_HALF_UP))

        return {
            "item_details": {
                "item_type": str(item_details["item_type"]),
                "title": str(item_details["title"]),
                "provider_name": str(item_details["provider_name"]),
                "price": float(subtotal.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)),
                "original_price": original_price_formatted,
                "image_url": item_details["image_url"],
                "quantity": int(item_details["quantity"]),
                "unit": str(item_details["unit"])
            },
            "user_balances": {
                "total_wallet_balance": float(wallet.fiat_balance.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)),
                "total_reward_points": wallet.points_balance
            },
            "invoice": {
                "subtotal": float(subtotal.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)),
                "tax_amount": float(tax_amount.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)),
                "discount_amount": float(coupon_discount.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)),
                "max_points_allowed": opacity_max_points_allowed,
                "points_value_applied": float(points_fiat_value.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)),
                "wallet_balance_applied": float(wallet_fiat_applied.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)),
                "remaining_total_to_pay": float(remaining_total_to_pay.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)),
                "expected_reward_points": expected_reward_points,
                "actual_points_deducted": final_points_redeemed,
                "currency": "SAR"
            }
        }

    @staticmethod
    @transaction.atomic
    def process_checkout(request, payload: dict) -> dict:
        """
        Executes the checkout process securely based on the preview engine.
        Applies deductions, processes payments, and fulfills the requested item.
        """
        user = request.user
        item_type = payload.get("item_type")
        coupon_code = payload.get("coupon_code", "").strip()
        points_to_redeem = int(payload.get("points_to_redeem", 0))

        # Strict Runtime Core Integrity Validation Step
        CheckoutService.validate_package_discounts(item_type, coupon_code, points_to_redeem)

        preview_data = CheckoutService.preview_checkout(request, payload)
        invoice = preview_data["invoice"]
        
        item_id = payload.get("item_id")
        gateway_name = payload.get("payment_gateway", "mock")
        
        points_to_deduct = invoice["actual_points_deducted"]
        wallet_fiat_to_deduct = Decimal(str(invoice["wallet_balance_applied"]))
        remaining_fiat = Decimal(str(invoice["remaining_total_to_pay"]))
        expected_rewards = invoice["expected_reward_points"]
        
        wallet = CustomerWallet.objects.select_for_update().get(user=user)

        # Financial Execution: Deduct internal balances
        if points_to_deduct > 0:
            WalletTransaction.execute_transaction(
                wallet=wallet, t_type=TransactionType.SPEND_DISCOUNT,
                points=-points_to_deduct,
                description=f"Redeemed points for {item_type} #{item_id}"
            )
        
        if wallet_fiat_to_deduct > 0:
            WalletTransaction.execute_transaction(
                wallet=wallet, t_type=TransactionType.SPEND_DISCOUNT,
                fiat=-wallet_fiat_to_deduct,
                description=f"Used wallet balance for {item_type} #{item_id}"
            )
            
        # Financial Execution: External Gateway Payment
        payment_txn = None
        if remaining_fiat > 0:
            payment_txn = PaymentService.process_payment(
                user=user, amount=remaining_fiat, currency="SAR", gateway_name=gateway_name
            )
        else:
            payment_txn = PaymentService.process_payment(
                user=user, amount=Decimal("0.00"), currency="SAR", gateway_name="mock"
            )

        # Item Fulfillment Strategy
        if item_type == "gym_plan":
            plan = SubscriptionPlan.objects.get(id=item_id)
            start_date = timezone.now().date()
            end_date = start_date + timedelta(days=plan.duration_days)
            GymSubscription.objects.create(
                user=user, plan=plan, payment=payment_txn,
                start_date=start_date, end_date=end_date, status="active"
            )

        elif item_type == "resale_item":
            listing = SubscriptionResaleListing.objects.select_for_update().get(id=item_id, status=ResaleListingStatus.ACTIVE)
            resale_settings = ResaleGlobalSetting.load()
            
            app_commission = (listing.asking_price * resale_settings.app_commission_percentage) / Decimal("100.00")
            seller_earnings = listing.asking_price - app_commission

            subscription = listing.subscription
            subscription.user = user
            subscription.is_resold = True
            subscription.save()

            listing.status = ResaleListingStatus.SOLD
            listing.save()
            
            ResaleTransaction.objects.create(
                listing=listing, buyer=user, payment=payment_txn,
                sale_price=listing.asking_price, app_commission=app_commission,
                seller_earnings=seller_earnings, status=ResaleTransactionStatus.ESCROW
            )

        elif item_type == "roaming_pass":
            branch = GymBranch.objects.get(id=item_id)
            RoamingPass.objects.create(
                user=user, branch=branch, payment=payment_txn,
                points_used=points_to_deduct, 
                fiat_paid=wallet_fiat_to_deduct + remaining_fiat
            )

        elif item_type == "points_package":
            package = PointPackage.objects.get(id=item_id)
            WalletTransaction.execute_transaction(
                wallet=wallet, t_type=TransactionType.BUY_POINTS,
                points=package.points, fiat=Decimal("0.00"),
                description=f"Purchased Point Package: {package.name}"
            )

        # Coupon Mark as Used
        if coupon_code and invoice["discount_amount"] > 0:
            actual_discount_saved = Decimal(str(invoice["discount_amount"]))
            code_clean = coupon_code.strip().upper()
            
            loyalty_coupon = UserCoupon.objects.filter(code=code_clean, user=user, is_used=False).first()
            if loyalty_coupon:
                loyalty_coupon.mark_as_used(discount_amount=actual_discount_saved)
            else:
                definition = CouponDefinition.objects.get(code__iexact=code_clean)
                UserCoupon.objects.create(
                    user=user,
                    definition=definition,
                    code=code_clean,
                    is_used=True,
                    used_at=timezone.now(),
                    fiat_discount_applied=actual_discount_saved
                )

        # Issue Cashback / Rewards
        if expected_rewards > 0:
            WalletTransaction.execute_transaction(
                wallet=wallet, t_type=TransactionType.EARN_PURCHASE,
                points=expected_rewards,
                description=f"Cashback reward for purchasing {item_type} #{item_id}"
            )

        return {
            "status": "success",
            "transaction_id": payment_txn.gateway_transaction_id if payment_txn else "WALLET_ONLY",
            "redirect_url": None,
            "message": "Purchase completed successfully."
        }