# FitZone Loyalty & Wallet API Documentation

## 1. Data Synchronization Lifecycle (Important for Mobile Dev)
To optimize server requests and improve app speed, the mobile application MUST implement a local caching mechanism (e.g., SQLite, Room, CoreData) for static data like the Loyalty Milestones Roadmap.

**The Sync Algorithm:**
1. On app launch, call `GET /api/v1/init/`.
2. Compare the received `loyalty_roadmap_version` with the version stored locally on the device.
    * **If matches:** Do NOT call the `/milestones/` API. Load the roadmap from the local database.
    * **If different (or first launch):** Call `GET /api/v1/loyalty/milestones/`, save the new list to the local database, and update the locally stored `loyalty_roadmap_version`.

---

## 2. API Endpoints Dictionary

### [1] App Initialization & Version Check
The entry point of the app. Used to check if updates are required.

* **URL**: `/api/v1/init/`
* **Method**: `GET`
* **Authentication**: None (Public)
* **Response Example**:
```json
{
  "sports_version": 1.0,
  "amenities_version": 1.0,
  "cities_version": 3.0,
  "service_types_version": 1.0,
  "loyalty_roadmap_version": 3,
  "android_version": "1.0.0",
  "ios_version": "1.0.0",
  "force_update": false,
  "update_message": ""
}
```

### [2] Point Packages List
Fetches the active packages available for the user to purchase.

* **URL**: `/api/v1/loyalty/packages/`
* **Method**: `GET`
* **Authentication**: None (Public)
* **Response Example**:
```json
[
  {
    "id": 1,
    "name": "basic",
    "points": 100,
    "price": "10.00"
  },
  {
    "id": 2,
    "name": "Premium",
    "points": 1000,
    "price": "112.50"
  }
]
```

### [3] Milestone Roadmap
Fetches the entire progression map. **Note:** Only call this if `loyalty_roadmap_version` has changed.

* **URL**: `/api/v1/loyalty/milestones/`
* **Method**: `GET`
* **Authentication**: None (Public)
* **Response Example**:
```json
[
  {
    "id": 1,
    "title": "1K",
    "required_lifetime_points": 1000,
    "reward": {
      "id": 1,
      "name": "1 Free Roaming Visit",
      "action_type": "sys_roaming",
      "action_value": 1
    },
    "description": "زيارة تجوال مجانية"
  },
  {
    "id": 2,
    "title": "10K",
    "required_lifetime_points": 10000,
    "reward": {
      "id": 2,
      "name": "Extend subscription for 7 days",
      "action_type": "sys_extension",
      "action_value": 7
    },
    "description": "ترقية الاشتراك الخاص بك لمدة اسبوع"
  }
]
```

### [4] Purchase Points (Payment Checkout)
Processes the payment for a selected point package.

* **URL**: `/api/v1/loyalty/purchase/`
* **Method**: `POST`
* **Authentication**: Required (Bearer Token)
* **Request Body**:
```json
{
    "package_id": 2,
    "gateway": "mock"
}
```
* **Response Example (200 OK)**:
```json
{
  "message": "Points purchased successfully."
}
```

### [5] Wallet Summary
Retrieves the user's current point balance and their progress towards the next milestone.

* **URL**: `/api/v1/loyalty/wallet/`
* **Method**: `GET`
* **Authentication**: Required (Bearer Token)
* **Concepts**:
    * `spendable_points`: Points the user can use for purchases/discounts.
    * `lifetime_points`: Total points ever earned. Used ONLY for calculating milestone progress.
* **Response Example**:
```json
{
  "spendable_points": 2051,
  "lifetime_points": 2151,
  "fiat_balance": 0.0,
  "unlocked_rewards_count": 1,
  "next_milestone": {
    "title": "10K",
    "required": 10000,
    "progress_pct": 21
  }
}
```

### [6] User's Unlocked Milestones
Fetches the specific milestones the authenticated user has unlocked.

* **URL**: `/api/v1/loyalty/my-milestones/`
* **Method**: `GET`
* **Authentication**: Required (Bearer Token)
* **Response Example**:
```json
[
  {
    "id": 1,
    "milestone": {
      "id": 1,
      "title": "1K",
      "required_lifetime_points": 1000,
      "reward": {
        "id": 1,
        "name": "1 Free Roaming Visit",
        "action_type": "sys_roaming",
        "action_value": 1
      },
      "description": "زيارة تجوال مجانية"
    },
    "is_consumed": true,
    "unlocked_at": "2026-04-27T11:32:25.262963+03:00",
    "consumed_at": "2026-04-27T11:35:54.137248+03:00"
  }
]
```

### [7] Consume Milestone Reward
Triggers the consumption of a specific reward.

* **URL**: `/api/v1/loyalty/milestones/consume/`
* **Method**: `POST`
* **Authentication**: Required (Bearer Token)
* **Request Body**:
```json
{
    "user_milestone_id": 1
}
```
* **Response Example (200 OK)**:
```json
{
  "message": "Milestone reward consumed successfully."
}
```