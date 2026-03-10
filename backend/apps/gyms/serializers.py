"""
Serializers for the Gyms app API.
Handles input validation for gym operations.
"""

from rest_framework import serializers


class QRScanSerializer(serializers.Serializer):
    """Input validation for POST /api/v1/gyms/scan-qr/."""
    
    qr_code_id = serializers.UUIDField(
        error_messages={
            "invalid": "Must be a valid UUID format."
        }
    )
    branch_id = serializers.IntegerField(min_value=1)