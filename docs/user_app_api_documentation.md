# FitZone — User App API Documentation

> **Base URL:** `http://localhost:8000/api/v1/`
> **Target App:** User Application (Client App)

---

## Table of Contents

- [1. Discovery & Search](#1-discovery--search)
  - [1.1 Unified Discovery & Search (Map & List)](#11-unified-discovery--search-map--list)
  - [1.2 Get Gym Branch Details](#12-get-gym-branch-details)
- [2. Customer Authentication & Profile](#2-customer-authentication--profile)
  - [2.1 Quick Register (Step 1)](#21-quick-register-step-1)
  - [2.2 Verify Email](#22-verify-email)
  - [2.3 Resend Verification Email](#23-resend-verification-email)
  - [2.4 Login](#24-login)
  - [2.5 Complete Profile (Step 2)](#25-complete-profile-step-2--before-subscription)
  - [2.6 Request Password Reset OTP](#26-request-password-reset-otp)
  - [2.7 Confirm Password Reset](#27-confirm-password-reset)
  - [2.8 Change Password](#28-change-password)
  - [2.9 Update Avatar](#29-update-avatar)
  - [2.10 Update Profile (Partial)](#210-update-profile-partial)
  - [2.11 Delete Account](#211-delete-account)
  - [2.12 Token Refresh](#212-token-refresh)
  - [2.13 Logout](#213-logout)
- [3. App Initialization & Static Data](#3-app-initialization--static-data)
  - [3.1 App Initialization (Check Versions)](#31-app-initialization-check-versions)
  - [3.2 Get Service Types List](#32-get-service-types-list)
  - [3.3 Get Cities List](#33-get-cities-list)
  - [3.4 Get Sports List](#34-get-sports-list)
  - [3.5 Get Amenities List](#35-get-amenities-list)
- [4. Common Error Responses](#4-common-error-responses)

---

## 1. Discovery & Search

### 1.1 Unified Discovery & Search (Map & List)

The main endpoint powering both the **Map View** and the **List View**. Supports text search, geo-spatial filtering (bounding box for maps, radius for lists), dynamic filters (price, gender, sports, amenities), and pagination.

| Property | Value |
| :--- | :--- |
| **Endpoint** | `/providers/discover/` |
| **Method** | `GET` |
| **Auth Required** | No — Public endpoint |

#### Query Parameters

> All parameters are **optional**.

| Parameter | Type | Example | Description |
| :--- | :--- | :--- | :--- |
| `type` | String | `gym` | Service type: `gym`, `trainer`, `restaurant`, `equipment`. Defaults to `gym`. |
| `q` | String | `power` | Text search across name, address, and description. |
| `gender` | String | `men` | Filter by target audience: `men`, `women`, `mixed`. (Gym-specific) |
| `city_id` | String | `riyadh` | Exact match for city code. |
| `sports` | String | `1,4` | Comma-separated Sport IDs. (Gym-specific) |
| `amenities` | String | `2,3` | Comma-separated Amenity IDs. (Gym-specific) |
| `min_price` | Float | `150.0` | Minimum subscription plan price. |
| `max_price` | Float | `500.0` | Maximum subscription plan price. |
| `is_open` | Boolean | `true` | If `true`, returns only currently open branches (handles overnight shifts). |
| `min_lat`, `min_lng`, `max_lat`, `max_lng` | Float | `24.7110` | Bounding box coordinates — required for **Map View**. |
| `lat`, `lng` | Float | `24.7136` | User's current coordinates — required for distance calculation and sorting. |
| `radius_km` | Float | `10.5` | Search radius in kilometers. Requires `lat` and `lng`. |
| `sort_by` | String | `distance` | Sorting method: `distance` or `created_at`. Defaults to `created_at`. |
| `page` | Integer | `1` | Page number for pagination. Defaults to `1`. |

#### Example Request

```http
GET /api/v1/providers/discover/?type=gym&city_id=riyadh&gender=mixed&lat=24.7136&lng=46.6753&sort_by=distance&page=1
```

#### Responses

**`200 OK` — Success**

```json
{
  "results": [
    {
      "id": 7,
      "provider_id": 7,
      "provider_name": "Al-Rashid Fitness Center",
      "name": "ابو فهد جيم",
      "city": "riyadh",
      "address": "الكهف, الملك فهد, محافظة الرياض, منطقة الرياض",
      "gender": "mixed",
      "lat": 24.740771,
      "lng": 46.671236,
      "branch_logo": "http://localhost:8000/media/gyms/branches/logos/img.jpg",
      "is_active": true,
      "is_temporarily_closed": false,
      "distance_km": 5.2,
      "min_price": 200.00,
      "sports": ["Boxing", "football"],
      "amenities": ["ساونا"],
      "type": "gym",
      "rating": 4.5,
      "is_open_now": true,
      "crowd_level": "low"
    }
  ],
  "meta": {
    "total_items": 1,
    "total_pages": 1,
    "current_page": 1,
    "has_next": false,
    "has_previous": false
  }
}
```

**`400 Bad Request` — Unsupported service type**

```json
{
  "error": "Unsupported service type: unknown"
}
```

**`400 Bad Request` — min_price greater than max_price**

```json
{
  "detail": "Minimum price cannot be greater than maximum price."
}
```

---

### 1.2 Get Gym Branch Details

Retrieves full details of a specific gym branch, including the image gallery, amenities, and available subscription plans.

| Property | Value |
| :--- | :--- |
| **Endpoint** | `/gyms/branches/<int:branch_id>/` |
| **Method** | `GET` |
| **Auth Required** | No — Public endpoint |

#### Example Request

```http
GET /api/v1/gyms/branches/6/
```

#### Responses

**`200 OK` — Success**

```json
{
  "id": 6,
  "provider_name": "Al-Rashid Fitness Center",
  "name": "جيم جدة العروس",
  "description": "Best gym with modern equipment",
  "phone_number": "0560252325",
  "opening_time": "08:00:00",
  "closing_time": "20:00:00",
  "city": "jeddah",
  "address": "النعيم, جدة, السعودية",
  "lat": 21.619133,
  "lng": 39.147018,
  "branch_logo": "http://localhost:8000/media/gyms/branches/logos/logo.jpg",
  "images": [
    "http://localhost:8000/media/gyms/branches/gallery/img1.png"
  ],
  "sports": [
    {
      "id": 1,
      "name": "Boxing",
      "image": "http://localhost:8000/media/gyms/sports/images/boxing.png"
    }
  ],
  "amenities": [
    {
      "id": 1,
      "name": "ساونا",
      "icon_image": "http://localhost:8000/media/gyms/amenities/icons/sauna.png"
    }
  ],
  "plans": [
    {
      "id": 2,
      "name": "vip",
      "description": "استعمال كامل المعدات",
      "price": "500.00",
      "duration_days": 30,
      "features": [
        { "name": "vip" },
        { "name": "sunna" }
      ]
    }
  ]
}
```

**`404 Not Found` — Branch ID does not exist or is not active**

```json
{
  "detail": "Not found."
}
```

---

## 2. Customer Authentication & Profile

> **Base URL for this section:** `http://localhost:8000/api/v1/users/`

---

### 2.1 Quick Register (Step 1)

Registers a new customer. The account requires email verification before it can be used.

| Property | Value |
| :--- | :--- |
| **Endpoint** | `/register/` |
| **Method** | `POST` |
| **Auth Required** | No |

#### Request Body

```json
{
  "email": "customer@fitzone.sa",
  "password": "StrongPassword123!",
  "full_name": "سعد عبدالله",
  "gender": "male",
  "city": "Riyadh"
}
```

#### Request Fields

| Field | Type | Required | Description |
| :--- | :--- | :---: | :--- |
| `email` | String | ✅ | Valid email address |
| `password` | String | ✅ | Minimum 8 characters |
| `full_name` | String | ✅ | Cannot be blank |
| `gender` | String | ✅ | `male` or `female` |
| `city` | String | ✅ | City code (e.g., `Riyadh`, `Jeddah`) |

#### Responses

**`201 Created` — Success**

```json
{
  "message": "Registration successful. Please verify your email.",
  "user": {
    "id": 34,
    "email": "customer8@fitzone.sa",
    "full_name": "سعد عبدالله",
    "phone_number": "",
    "gender": "male",
    "avatar": null,
    "address": "",
    "city": "Jeddah",
    "lat": null,
    "lng": null,
    "is_active": true,
    "is_verified": false,
    "points_balance": 0,
    "profile_is_complete": false
  }
}
```

> **Note:** `profile_is_complete` will be `false` at this stage. `is_verified` will also be `false` until the user verifies their email.

**`400 Bad Request` — Email already registered**

```json
{
  "email": [
    "This email is already registered."
  ]
}
```

**`400 Bad Request` — Validation errors**

```json
{
  "email": [
    "Enter a valid email address."
  ],
  "password": [
    "Ensure this field has at least 8 characters."
  ],
  "full_name": [
    "This field may not be blank."
  ]
}
```

---

### 2.2 Verify Email

Verifies the customer's email using the 6-digit OTP sent to their inbox.

| Property | Value |
| :--- | :--- |
| **Endpoint** | `/verify-email/` |
| **Method** | `POST` |
| **Auth Required** | No |

#### Request Body

```json
{
  "otp": "123456"
}
```

#### Responses

**`200 OK` — Success**

```json
{
  "message": "Email verified successfully.",
  "user": {
    "id": 16,
    "email": "customer4@fitzone.sa",
    "full_name": "سعد عبدالله",
    "phone_number": "",
    "gender": "male",
    "avatar": null,
    "address": "",
    "city": "Jeddah",
    "lat": null,
    "lng": null,
    "is_active": true,
    "is_verified": true,
    "points_balance": 0,
    "profile_is_complete": false
  },
  "tokens": {
    "refresh": "eyJhbGciOiJIUzI1NiIsInR5...",
    "access": "eyJhbGciOiJIUzI1NiIsInR5..."
  }
}
```

> Returns the user object along with `access` and `refresh` tokens for auto-login after verification.

**`400 Bad Request` — OTP length is not 6 digits**

```json
{
  "otp": [
    "OTP must be exactly 6 digits."
  ]
}
```

**`400 Bad Request` — Invalid or expired OTP**

```json
{
  "detail": "Invalid or missing verification code."
}
```

**`400 Bad Request` — OTP field is blank**

```json
{
  "otp": [
    "This field may not be blank."
  ]
}
```

---

### 2.3 Resend Verification Email

Sends a new verification OTP to the customer's email address.

| Property | Value |
| :--- | :--- |
| **Endpoint** | `/resend-verification/` |
| **Method** | `POST` |
| **Auth Required** | No |

#### Request Body

```json
{
  "email": "customer@fitzone.sa"
}
```

#### Responses

**`200 OK` — Success**

```json
{
  "message": "If this email address is registered, a new link has been sent."
}
```

> Always returns a success message to prevent email enumeration.

**`400 Bad Request` — Email field is blank**

```json
{
  "email": [
    "This field may not be blank."
  ]
}
```

**`400 Bad Request` — Invalid email format**

```json
{
  "email": [
    "Enter a valid email address."
  ]
}
```

---

### 2.4 Login

Authenticates the customer and returns JWT tokens along with the user object.

| Property | Value |
| :--- | :--- |
| **Endpoint** | `/login/` |
| **Method** | `POST` |
| **Auth Required** | No |

#### Request Body

```json
{
  "email": "customer@fitzone.sa",
  "password": "StrongPassword123!"
}
```

#### Responses

**`200 OK` — Success**

```json
{
  "message": "Login successful.",
  "user": {
    "id": 18,
    "email": "customer6@fitzone.sa",
    "full_name": "سعد عبدالله",
    "phone_number": "0559988776",
    "gender": "male",
    "avatar": null,
    "address": "حي النرجس، الرياض",
    "city": "Jeddah",
    "lat": 24.7936,
    "lng": 46.6753,
    "is_active": true,
    "is_verified": true,
    "points_balance": 0,
    "profile_is_complete": true
  },
  "tokens": {
    "refresh": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "access": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**`401 Unauthorized` — Invalid credentials**

```json
{
  "detail": "Invalid email or password."
}
```

**`403 Forbidden` — Email not verified**

```json
{
  "detail": "Email is not verified.",
  "code": "EMAIL_NOT_VERIFIED",
  "email": "customer7@fitzone.sa"
}
```

> When `EMAIL_NOT_VERIFIED` is returned, the client must redirect the user to the OTP verification screen using the `email` value from the response.

---

### 2.5 Complete Profile (Step 2 — Before Subscription)

Updates the user profile with sensitive information required for gym subscriptions (ID card, face image, phone number).

| Property | Value |
| :--- | :--- |
| **Endpoint** | `/profile/complete/` |
| **Method** | `POST` |
| **Auth Required** | Yes — `Authorization: Bearer <access_token>` |
| **Content-Type** | `multipart/form-data` |

#### Request Body (Form-Data)

| Field | Type | Required | Description |
| :--- | :--- | :---: | :--- |
| `phone_number` | Text | ✅ | e.g., `0551234567` |
| `real_face_image` | File | ✅ | User face photo |
| `id_card_image` | File | ✅ | National ID card image |
| `address` | Text | ❌ | Optional address |
| `lat` | Float | ❌ | Optional latitude |
| `lng` | Float | ❌ | Optional longitude |

#### Responses

**`200 OK` — Success**

```json
{
  "message": "Profile completed successfully.",
  "user": {
    "id": 35,
    "email": "customer7@fitzone.sa",
    "full_name": "سعد عبدالله",
    "phone_number": "0559988776",
    "gender": "male",
    "avatar": null,
    "address": "حي النرجس، الرياض",
    "city": "Jeddah",
    "lat": 24.7936,
    "lng": 46.6753,
    "is_active": true,
    "is_verified": true,
    "points_balance": 0,
    "profile_is_complete": true
  }
}
```

**`400 Bad Request` — Missing required fields**

```json
{
  "phone_number": [
    "This field is required."
  ],
  "real_face_image": [
    "No file was submitted."
  ],
  "id_card_image": [
    "No file was submitted."
  ]
}
```

---

### 2.6 Request Password Reset OTP

Generates a 6-digit OTP and sends it to the user's email for password recovery.

| Property | Value |
| :--- | :--- |
| **Endpoint** | `/password-reset/request/` |
| **Method** | `POST` |
| **Auth Required** | No |

#### Request Body

```json
{
  "email": "customer@fitzone.sa"
}
```

#### Responses

**`200 OK` — Success**

```json
{
  "message": "If this email is registered, a password reset OTP has been sent."
}
```

> Always returns a success message to prevent email enumeration.

---

### 2.7 Confirm Password Reset

Validates the OTP and sets a new password for the user.

| Property | Value |
| :--- | :--- |
| **Endpoint** | `/password-reset/confirm/` |
| **Method** | `POST` |
| **Auth Required** | No |

#### Request Body

```json
{
  "email": "customer@fitzone.sa",
  "otp": "123456",
  "new_password": "NewStrongPassword123!"
}
```

#### Responses

**`200 OK` — Success**

```json
{
  "message": "Password has been reset successfully. You can now login."
}
```

**`400 Bad Request` — Invalid or expired OTP**

```json
{
  "detail": "Invalid or missing reset code."
}
```

> **Note:** Error responses for `new_password` shorter than 8 characters and for non-existent emails are not yet confirmed from the backend — to be added after testing.

---

### 2.8 Change Password

Allows an authenticated user to change their password by verifying the current one.

| Property | Value |
| :--- | :--- |
| **Endpoint** | `/profile/change-password/` |
| **Method** | `POST` |
| **Auth Required** | Yes — `Authorization: Bearer <access_token>` |

#### Request Body

```json
{
  "old_password": "StrongPassword2026!",
  "new_password": "NewStrongPassword2026!"
}
```

#### Responses

**`200 OK` — Success**

```json
{
  "message": "Password changed successfully."
}
```

**`400 Bad Request` — Current password is incorrect**

```json
{
  "detail": "Current password is incorrect."
}
```

**`400 Bad Request` — New password too short**

```json
{
  "new_password": [
    "Ensure this field has at least 8 characters."
  ]
}
```

---

### 2.9 Update Avatar

Updates only the user's profile picture.

| Property | Value |
| :--- | :--- |
| **Endpoint** | `/profile/avatar/` |
| **Method** | `POST` |
| **Auth Required** | Yes — `Authorization: Bearer <access_token>` |
| **Content-Type** | `multipart/form-data` |

#### Request Body (Form-Data)

| Field | Type | Required | Description |
| :--- | :--- | :---: | :--- |
| `avatar` | File | ✅ | The new profile image file |

#### Responses

**`200 OK` — Success**

```json
{
  "message": "Avatar updated successfully.",
  "avatar": "http://localhost:8000/media/avatars/logo.png"
}
```

**`400 Bad Request` — No file submitted**

```json
{
  "avatar": [
    "The submitted data was not a file. Check the encoding type on the form."
  ]
}
```

---

### 2.10 Update Profile (Partial)

Updates one or more profile fields. If the `email` field is modified, the user's `is_verified` status changes to `false` and a new verification OTP is sent automatically.

| Property | Value |
| :--- | :--- |
| **Endpoint** | `/profile/update/` |
| **Method** | `PATCH` |
| **Auth Required** | Yes — `Authorization: Bearer <access_token>` |
| **Content-Type** | `application/json` or `multipart/form-data` |

#### Request Body

> All fields are optional. Only provide the fields that need to be updated.

```json
{
  "full_name": "سعد عبدالله المعدل",
  "phone_number": "0555555555",
  "city": "Dammam"
}
```

#### Responses

**`200 OK` — Success**

> If `email_changed` is `true`, the client must redirect the user to the OTP verification screen.

```json
{
  "message": "Profile updated successfully.",
  "email_changed": false,
  "user": {
    "id": 28,
    "email": "customer7@fitzone.sa",
    "full_name": "سعد عبدالله المعدل",
    "phone_number": "0555555555",
    "gender": "male",
    "avatar": "http://localhost:8000/media/avatars/logo.png",
    "address": "حي النسيم, Jeddah",
    "city": "Dammam",
    "lat": 21.5202783,
    "lng": 39.2424917,
    "is_active": true,
    "is_verified": true,
    "points_balance": 0,
    "profile_is_complete": true
  }
}
```

**`400 Bad Request` — Email already registered to another account**

```json
{
  "detail": "This email is already registered with another account."
}
```

**`400 Bad Request` — Invalid phone number**

```json
{
  "phone_number": [
    "Phone number must be valid, between 9 and 15 digits, and can start with '+'."
  ]
}
```

---

### 2.11 Delete Account

Permanently deletes the user's account and all associated data. Requires password confirmation to prevent accidental deletion.

| Property | Value |
| :--- | :--- |
| **Endpoint** | `/profile/delete/` |
| **Method** | `DELETE` |
| **Auth Required** | Yes — `Authorization: Bearer <access_token>` |

#### Request Body

```json
{
  "password": "StrongPassword123!"
}
```

#### Responses

**`200 OK` — Success**

```json
{
  "message": "Account has been permanently deleted."
}
```

**`400 Bad Request` — Incorrect password**

```json
{
  "detail": "Incorrect password. Account deletion failed."
}
```

---

### 2.12 Token Refresh

Generates a new `access` token (and a rotated `refresh` token) using a valid refresh token. The app should call this endpoint automatically when any authenticated request returns `401 Unauthorized`.

| Property | Value |
| :--- | :--- |
| **Endpoint** | `/token/refresh/` |
| **Method** | `POST` |
| **Auth Required** | No |

#### Request Body

```json
{
  "refresh": "<refresh_token>"
}
```

#### Responses

**`200 OK` — Success**

```json
{
  "access": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

> Both a new `access` token and a rotated `refresh` token are returned. The app must save the new `refresh` token to replace the old one.

**`401 Unauthorized` — Token is blacklisted (already used after logout)**

```json
{
  "detail": "Token is blacklisted",
  "code": "token_not_valid"
}
```

**`401 Unauthorized` — Token is invalid or expired**

```json
{
  "detail": "Token is invalid or expired",
  "code": "token_not_valid"
}
```

---

### 2.13 Logout

Invalidates the user's refresh token by adding it to the blacklist. After logout, any attempt to use the same refresh token will be rejected.

| Property | Value |
| :--- | :--- |
| **Endpoint** | `/logout/` |
| **Method** | `POST` |
| **Auth Required** | Yes — `Authorization: Bearer <access_token>` |

#### Request Body

```json
{
  "refresh": "<refresh_token>"
}
```

#### Responses

**`200 OK` — Success**

```json
{
  "message": "Successfully logged out."
}
```

---

## 3. App Initialization & Static Data

These endpoints provide static data required for the app to function. The mobile app **must** call `/init/` on startup. If data versions have changed, the app should fetch and cache the updated lists.

> **Localization:** All static data endpoints support dynamic JSON translation. The app **must** send the `Accept-Language` header with every request to receive names in the user's current language.
>
> Examples: `Accept-Language: ar` or `Accept-Language: en`

---

### 3.1 App Initialization (Check Versions)

Retrieves current static data versions and app update requirements.

| Property | Value |
| :--- | :--- |
| **Endpoint** | `/init/` |
| **Method** | `GET` |
| **Auth Required** | No |

#### Response Fields

| Field | Type | Description |
| :--- | :--- | :--- |
| `sports_version` | Float | Current version of the sports list |
| `amenities_version` | Float | Current version of the amenities list |
| `cities_version` | Float | Current version of the cities list |
| `service_types_version` | Float | Current version of the service types list |
| `android_version` | String | Minimum required Android app version |
| `ios_version` | String | Minimum required iOS app version |
| `force_update` | Boolean | If `true`, the app must force the user to update before proceeding |
| `update_message` | String | Message to display to user when an update is required |

#### Responses

**`200 OK` — Success**

```json
{
  "sports_version": 1.0,
  "amenities_version": 1.0,
  "cities_version": 1.0,
  "service_types_version": 1.0,
  "android_version": "1.0.0",
  "ios_version": "1.0.0",
  "force_update": false,
  "update_message": ""
}
```

---

### 3.2 Get Service Types List

Retrieves the main categories of service providers available in the app. Automatically translated based on `Accept-Language`.

| Property | Value |
| :--- | :--- |
| **Endpoint** | `/service-types/` |
| **Method** | `GET` |
| **Auth Required** | No |
| **Header** | `Accept-Language: ar` (or `en`) |

#### Responses

**`200 OK` — Success**

```json
[
  { "id": "gym", "name": "صالة رياضية" },
  { "id": "trainer", "name": "مدرب شخصي" }
]
```

---

### 3.3 Get Cities List

Retrieves the list of active cities. Automatically translated based on `Accept-Language`.

| Property | Value |
| :--- | :--- |
| **Endpoint** | `/cities/` |
| **Method** | `GET` |
| **Auth Required** | No |
| **Header** | `Accept-Language: ar` (or `en`) |

#### Responses

**`200 OK` — Success**

```json
[
  { "id": "riyadh", "name": "الرياض" },
  { "id": "jeddah", "name": "جدة" }
]
```

---

### 3.4 Get Sports List

Retrieves the full list of available sports and their images for caching.

| Property | Value |
| :--- | :--- |
| **Endpoint** | `/gyms/sports/` |
| **Method** | `GET` |
| **Auth Required** | No |
| **Header** | `Accept-Language: ar` (or `en`) |

#### Responses

**`200 OK` — Success**

```json
[
  {
    "id": 1,
    "name": "ملاكمة",
    "image": "http://localhost:8000/media/gyms/sports/images/boxing.png"
  }
]
```

---

### 3.5 Get Amenities List

Retrieves the full list of available amenities and their icons for caching.

| Property | Value |
| :--- | :--- |
| **Endpoint** | `/gyms/amenities/` |
| **Method** | `GET` |
| **Auth Required** | No |
| **Header** | `Accept-Language: ar` (or `en`) |

#### Responses

**`200 OK` — Success**

```json
[
  {
    "id": 1,
    "name": "مسبح",
    "icon_image": "http://localhost:8000/media/gyms/amenities/icons/pool.png"
  }
]
```

---

## 4. Common Error Responses

These responses apply to **all endpoints that require authentication** (`Authorization: Bearer <access_token>`).

### `401 Unauthorized` — Missing or invalid token

```json
{
  "detail": "Authentication credentials were not provided."
}
```

### `401 Unauthorized` — Expired access token

```json
{
  "detail": "Given token not valid for any token type",
  "code": "token_not_valid"
}
```

> When this occurs, the app must call [2.12 Token Refresh](#212-token-refresh) to obtain a new access token. If the refresh token is also expired or blacklisted, the user must be redirected to the login screen.