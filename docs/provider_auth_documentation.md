# FitZone Provider Auth — API Documentation

> **Base URL:** `http://localhost:8000/api/v1/providers/`

---

## Table of Contents

- [1. Register a New Provider](#1-register-a-new-provider)
- [2. Verify Email (Auto-Login)](#2-verify-email-auto-login)
- [3. Login](#3-login)
- [4. Resend Verification Email](#4-resend-verification-email)
- [5. Logout](#5-logout)
- [6. Check Registration Status](#6-check-registration-status)

---

## 1. Register a New Provider

Creates a new provider account and sends a verification email.

| Property | Value |
| :--- | :--- |
| **Endpoint** | `/register/` |
| **Method** | `POST` |
| **Auth Required** | No |

#### Request Body

```json
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
```

#### Responses

**`201 Created` — Success**

```json
{
  "message": "Registration successful. A verification email has been sent.",
  "provider": {
    "id": 1,
    "provider_type": "gym",
    "status": "pending",
    "email_verified": false
  }
}
```

---

## 2. Verify Email (Auto-Login)

Verifies the token from the deep-link and returns JWT tokens for auto-login.

| Property | Value |
| :--- | :--- |
| **Endpoint** | `/verify-email/` |
| **Method** | `POST` |
| **Auth Required** | No |

#### Request Body

```json
{
  "token": "d19c3b74ee90324e74cbd4b081b..."
}
```

#### Responses

**`200 OK` — Success**

```json
{
  "message": "Email verified successfully. Your account is under review.",
  "provider": {
    "email_verified": true,
    "status": "pending"
  },
  "tokens": {
    "refresh": "eyJhbGciOi...",
    "access": "eyJhbGciOi..."
  }
}
```

---

## 3. Login

Authenticates the provider and returns JWT tokens.

| Property | Value |
| :--- | :--- |
| **Endpoint** | `/login/` |
| **Method** | `POST` |
| **Auth Required** | No |

#### Request Body

```json
{
  "email": "test@fitzone.sa",
  "password": "StrongPassword123!"
}
```

#### Responses

**`200 OK` — Success**

Returns the provider object and tokens.

**`401 Unauthorized` — Wrong credentials**

```json
{
  "detail": "Invalid email or password."
}
```

**`403 Forbidden` — Email not verified**

> **Note for App Developer:** Use this response to redirect the user to the "Resend Verification" screen.

```json
{
  "detail": "Email is not verified.",
  "code": "EMAIL_NOT_VERIFIED",
  "email": "test@fitzone.sa"
}
```

---

## 4. Resend Verification Email

Generates a new token and sends a new verification email. Used when the user attempts to log in but their email is not yet verified.

| Property | Value |
| :--- | :--- |
| **Endpoint** | `/resend-verification/` |
| **Method** | `POST` |
| **Auth Required** | No |

#### Request Body

```json
{
  "email": "test@fitzone.sa"
}
```

#### Responses

**`200 OK` — Success**

```json
{
  "message": "If this email address is registered and pending verification, a new link has been sent."
}
```

---

## 5. Logout

Blacklists the refresh token to end the session securely.

| Property | Value |
| :--- | :--- |
| **Endpoint** | `/logout/` |
| **Method** | `POST` |
| **Auth Required** | Yes — `Authorization: Bearer <access_token>` |

#### Request Body

```json
{
  "refresh": "eyJhbGciOi..."
}
```

#### Responses

**`205 Reset Content` — Success**

```json
{
  "message": "Successfully logged out."
}
```

---

## 6. Check Registration Status

Fetches the current status of the authenticated provider. Possible values for `status` are: `pending`, `approved`, `active`, `suspended`.

| Property | Value |
| :--- | :--- |
| **Endpoint** | `/registration-status/` |
| **Method** | `GET` |
| **Auth Required** | Yes — `Authorization: Bearer <access_token>` |

#### Responses

**`200 OK` — Success**

```json
{
  "provider": {
    "provider_type": "gym",
    "status": "pending",
    "email_verified": true,
    "can_access_dashboard": false
  }
}
```