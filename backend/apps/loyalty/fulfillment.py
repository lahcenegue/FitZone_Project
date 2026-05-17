"""
Fulfillment Strategy Pattern for Loyalty Rewards.
"""

import uuid
import logging
from typing import Dict, Any
from django.core.signing import Signer
from django.core.exceptions import ValidationError
from django.utils.translation import gettext as _
from apps.loyalty.models import RewardActionType

logger = logging.getLogger(__name__)

class BaseFulfillmentStrategy:
    def execute_fulfillment(self, user, reward, extra_details: Dict[str, Any] = None) -> Dict[str, Any]:
        raise NotImplementedError("Subclasses must implement execute_fulfillment.")


class CouponFulfillmentStrategy(BaseFulfillmentStrategy):
    def execute_fulfillment(self, user, reward, extra_details: Dict[str, Any] = None) -> Dict[str, Any]:
        # Generate a unique, unguessable coupon code specifically for this loyal user
        unique_id = str(uuid.uuid4())[:8].upper()
        unique_code = f"FZ-LYL-{unique_id}"
        
        logger.info(f"Loyalty Coupon {unique_code} generated for user {user.id}")
        
        return {
            "fulfillment_type": "coupon",
            "coupon_code": unique_code,
            "discount_value": float(reward.action_value),
            "coupon_type": reward.discount_type,
            "status": "ready_to_use"
        }


class RoamingFulfillmentStrategy(BaseFulfillmentStrategy):
    def execute_fulfillment(self, user, reward, extra_details: Dict[str, Any] = None) -> Dict[str, Any]:
        unique_id = str(uuid.uuid4())
        signer = Signer(salt="fitzone_roaming_qr_auth")
        qr_signature = signer.sign(f"FZ-ROAM-{unique_id}")
        
        logger.info(f"Roaming QR generated for user {user.id}")
        return {
            "fulfillment_type": "roaming_pass",
            "visits_granted": float(reward.action_value),
            "qr_code_signature": qr_signature,
            "qr_id": unique_id
        }


class ExtensionFulfillmentStrategy(BaseFulfillmentStrategy):
    def execute_fulfillment(self, user, reward, extra_details: Dict[str, Any] = None) -> Dict[str, Any]:
        return {
            "fulfillment_type": "subscription_extension",
            "days_added": float(reward.action_value),
            "status": "pending_application"
        }


class ManualFulfillmentStrategy(BaseFulfillmentStrategy):
    def execute_fulfillment(self, user, reward, extra_details: Dict[str, Any] = None) -> Dict[str, Any]:
        """Generates a secure QR code for physical gifts to be scanned by staff."""
        unique_id = str(uuid.uuid4())
        signer = Signer(salt="fitzone_gift_qr_auth")
        qr_signature = signer.sign(f"FZ-GIFT-{unique_id}")
        
        logger.info(f"Manual Gift QR generated for user {user.id}")
        return {
            "fulfillment_type": "manual_gift",
            "item_name": reward.name,
            "qr_code_signature": qr_signature,
            "qr_id": unique_id,
            "status": "ready_for_pickup"
        }


class FulfillmentFactory:
    @staticmethod
    def resolve_strategy(action_type: str) -> BaseFulfillmentStrategy:
        strategies = {
            RewardActionType.GENERATE_COUPON: CouponFulfillmentStrategy(),
            RewardActionType.SYSTEM_ROAMING: RoamingFulfillmentStrategy(),
            RewardActionType.SYSTEM_EXTENSION: ExtensionFulfillmentStrategy(),
            RewardActionType.MANUAL_FULFILLMENT: ManualFulfillmentStrategy(),
        }
        strategy = strategies.get(action_type)
        if not strategy:
            raise ValidationError(_("A valid fulfillment strategy was not found."))
        return strategy