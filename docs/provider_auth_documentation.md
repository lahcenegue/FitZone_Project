FitZone Provider Auth API Documentation
Base URL: http://localhost:8000/api/v1/providers/

1. Register a New Provider
Creates a new provider account and sends a verification email.

Endpoint: /register/

Method: POST

Auth Required: No

Body (JSON):

JSON
{
  "email": "test@fitzone.sa",
  "password": "StrongPassword123!",
  "password_confirm": "StrongPassword123!",
  "full_name": "Ahmed Ali",
  "phone_number": "0501234567",
  "provider_type": "gym",
  "business_name": "Power Gym",
  "business_phone": "0112345678",
  "city": "Riyadh"
}
Success Response (201 Created):

JSON
{
  "message": "Registration successful. A verification email has been sent.",
  "provider": { "id": 1, "provider_type": "gym", "status": "pending", ... }
}
2. Verify Email (Auto-Login)
Verifies the token from the deep-link and returns JWT tokens for auto-login.

Endpoint: /verify-email/

Method: POST

Auth Required: No

Body (JSON):

JSON
{
  "token": "d19c3b74ee90324e74cbd4b081b..."
}
Success Response (200 OK):

JSON
{
  "message": "Email verified successfully. Your account is under review.",
  "provider": { ... },
  "tokens": {
    "refresh": "eyJhbGciOi...",
    "access": "eyJhbGciOi..."
  }
}
3. Login
Authenticates the provider and returns JWT tokens.

Endpoint: /login/

Method: POST

Auth Required: No

Body (JSON):

JSON
{
  "email": "test@fitzone.sa",
  "password": "StrongPassword123!"
}
Success Response (200 OK): Returns provider object and tokens.

Error Response (401 Unauthorized): {"detail": "Invalid email or password."}

4. Logout
Blacklists the refresh token to end the session securely.

Endpoint: /logout/

Method: POST

Auth Required: Yes (Authorization: Bearer <access_token>)

Body (JSON):

JSON
{
  "refresh": "eyJhbGciOi..." 
}
Success Response (205 Reset Content): {"message": "Successfully logged out."}

5. Check Registration Status
Fetches the current status (pending, approved, active, suspended) of the authenticated provider.

Endpoint: /registration-status/

Method: GET

Auth Required: Yes (Authorization: Bearer <access_token>)

Success Response (200 OK):

JSON
{
  "provider": {
    "provider_type": "gym",
    "status": "pending",
    "email_verified": true,
    "can_access_dashboard": false
  }
}
6. Resend Verification Email
Generates a new token and sends a new verification email.

Endpoint: /resend-verification/

Method: POST

Auth Required: No

Body (JSON):

JSON
{
  "email": "test@fitzone.sa"
}
Success Response (200 OK): {"message": "If this email address is registered..."}