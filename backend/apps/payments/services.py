import uuid
import logging
from abc import ABC, abstractmethod
from typing import Tuple
from django.db import transaction

from .models import PaymentTransaction, PaymentGateway, PaymentStatus

logger = logging.getLogger(__name__)

class BasePaymentGateway(ABC):
    """
    Abstract interface for all payment gateways.
    Enforces a strict contract for processing charges.
    """
    @abstractmethod
    def process_charge(self, transaction: PaymentTransaction) -> Tuple[bool, str, str]:
        """
        Processes the payment.
        Returns: (is_success: bool, gateway_transaction_id: str, error_message: str)
        """
        pass

class MockPaymentGateway(BasePaymentGateway):
    """
    Mock gateway for development and testing. 
    Always succeeds and generates a fake transaction ID.
    """
    def process_charge(self, transaction: PaymentTransaction) -> Tuple[bool, str, str]:
        fake_gateway_id = f"mock_txn_{uuid.uuid4().hex[:12]}"
        logger.info(f"MockGateway: Processed charge of {transaction.amount} {transaction.currency} for {transaction.user.email}")
        return True, fake_gateway_id, ""

class PaymentGatewayFactory:
    """
    Factory to instantiate the correct gateway based on input.
    Future gateways (Moyasar, HyperPay, Stripe) will be registered here.
    """
    @staticmethod
    def get_gateway(gateway_name: str) -> BasePaymentGateway:
        if gateway_name == PaymentGateway.MOCK:
            return MockPaymentGateway()
        
        raise NotImplementedError(f"Payment gateway '{gateway_name}' is not implemented yet.")

class PaymentService:
    """
    Central service for handling financial transactions across all app pillars.
    """
    @staticmethod
    @transaction.atomic
    def process_payment(user, amount, currency="SAR", gateway_name=PaymentGateway.MOCK) -> PaymentTransaction:
        # 1. Create Pending Transaction
        txn = PaymentTransaction.objects.create(
            user=user,
            amount=amount,
            currency=currency,
            gateway=gateway_name,
            status=PaymentStatus.PENDING
        )
        
        # 2. Execute Payment via Selected Gateway
        gateway_processor = PaymentGatewayFactory.get_gateway(gateway_name)
        is_success, gateway_id, error_msg = gateway_processor.process_charge(txn)
        
        # 3. Handle Result
        if is_success:
            txn.mark_as_success(gateway_id=gateway_id)
        else:
            txn.mark_as_failed(error_message=error_msg)
            raise ValueError(f"Payment failed: {error_msg}")
            
        return txn