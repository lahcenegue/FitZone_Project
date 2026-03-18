# FitZone User App — API Documentation

> **Base URL:** `http://localhost:8000/api/v1/`  
> **Target App:** User Application (Client App)

---

## Table of Contents

- [1. Discovery & Map](#1-discovery--map)
  - [1.1 Get Providers on Map](#11-get-providers-on-map-unified-map-discovery)
  - [1.2 Get Gym Branch Details](#12-get-gym-branch-details)
- [2. Customer Authentication & Profile](#2-customer-authentication--profile)
  - [2.1 Quick Register (Step 1)](#21-quick-register-step-1)
  - [2.2 Verify Email](#22-verify-email)
  - [2.3 Resend Verification Email](#23-resend-verification-email)
  - [2.4 Login](#24-login)
  - [2.5 Complete Profile (Step 2)](#25-complete-profile-step-2---before-subscription)

---

## 1. Discovery & Map

### 1.1 Get Providers on Map (Unified Map Discovery)

Retrieves all active providers (Gyms, and later Trainers, Restaurants, Stores) within the user's current map viewport (Bounding Box). This endpoint is lightweight and uses PostGIS for fast spatial queries.

| Property | Value |
| :--- | :--- |
| **Endpoint** | `/providers/map/discover/` |
| **Method** | `GET` |
| **Auth Required** | No — Public endpoint for guests and users |

#### Query Parameters

> All four parameters are **required**. The app must send the bounding box coordinates of the visible map screen.

| Parameter | Type | Description | Example |
| :--- | :--- | :--- | :--- |
| `min_lat` | Float | Bottom edge latitude of the screen | `24.7110` |
| `min_lng` | Float | Left edge longitude of the screen | `46.6710` |
| `max_lat` | Float | Top edge latitude of the screen | `24.7210` |
| `max_lng` | Float | Right edge longitude of the screen | `46.6810` |

#### Example Request

```http
GET /api/v1/providers/map/discover/?min_lat=24.7110&min_lng=46.6710&max_lat=24.7210&max_lng=46.6810
```

#### Responses

**`200 OK` — Success**

Returns a unified list of markers to be drawn on the map.

```json
{
  "count": 2,
  "results": [
    {
      "id": 1,
      "provider_id": 5,
      "type": "gym",
      "name": "FitZone Main Branch",
      "description": "Best equipment in town",
      "lat": 24.7136,
      "lng": 46.6753,
      "image_url": "http://localhost:8000/media/gyms/branches/logos/logo.png",
      "sports": ["Boxing", "CrossFit", "Bodybuilding"],
      "is_active": true
    },
    {
      "id": 2,
      "provider_id": 8,
      "type": "gym",
      "name": "PowerHouse Gym",
      "description": "CrossFit and Weightlifting",
      "lat": 24.7180,
      "lng": 46.6800,
      "image_url": null,
      "sports": ["Weightlifting", "Yoga"],
      "is_active": true
    }
  ]
}
```

**`400 Bad Request` — Missing or invalid coordinates**

```json
{
  "detail": "Invalid or missing bounding box parameters. Require: min_lat, min_lng, max_lat, max_lng."
}
```

---

### 1.2 Get Gym Branch Details

Retrieves full details of a specific gym branch, including its image gallery, amenities, and available subscription plans.

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
  "lat": 21.619132999999998,
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
    },
    { 
      "id": 2, 
      "name": "Football", 
      "image": "http://localhost:8000/media/gyms/sports/images/football.png" 
    }
  ],
  "amenities": [
    { 
      "id": 1, 
      "name": "ساونا", 
      "icon_image": "http://localhost:8000/media/gyms/amenities/icons/sauna.png" 
    },
    { 
      "id": 2, 
      "name": "مسبح", 
      "icon_image": "http://localhost:8000/media/gyms/amenities/icons/pool.png" 
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

Registers a new customer. The account will require email verification before it can be used.

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

#### Responses

**`201 Created` — Success**

Returns the user object.

> **Note:** `profile_is_complete` will be `false` at this stage.

---

### 2.2 Verify Email

Verifies the customer's email using the token sent to their inbox.

| Property | Value |
| :--- | :--- |
| **Endpoint** | `/verify-email/` |
| **Method** | `POST` |
| **Auth Required** | No |

#### Request Body

```json
{
  "token": "uuid-token-string"
}
```

#### Responses

**`200 OK` — Success**

Returns the user object along with `access` and `refresh` tokens for auto-login.

---

### 2.3 Resend Verification Email

Sends a new verification token to the customer's email address.

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

---

### 2.4 Login

Authenticates the customer and returns JWT tokens.

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

Returns JWT `access` and `refresh` tokens.

**`403 Forbidden` — Email not verified**

```json
{
  "detail": "Email is not verified.",
  "code": "EMAIL_NOT_VERIFIED",
  "email": "customer@fitzone.sa"
}
```

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

Returns the updated user object where `profile_is_complete` is now `true`.