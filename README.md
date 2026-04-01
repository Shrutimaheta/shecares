# 🌸 SheCares — Women Welfare Delivery App

A Flutter-based mobile application designed to provide **accessible, affordable, and discreet delivery of essential hygiene products** including sanitary pads, baby diapers, and adult diapers, with integrated NGO support and donation features.

---

## 🚀 Overview

SheCares is a **social impact + e-commerce platform** focused on improving hygiene accessibility for women, infants, and elderly individuals in underserved communities.

The platform bridges the gap between:

* Product availability
* NGO distribution
* Donor contributions
* Last-mile delivery

---

## 🎯 Key Features

### 👩 User App

* 🔐 Phone OTP Authentication (Firebase)
* 🛍 Product Catalog (Sanitary Pads, Baby Diapers, Adult Diapers)
* 🛒 Cart Management
* 📦 Order Placement
* 📍 Address Management
* 📊 Order History & Tracking

---

### 🏢 NGO Features

* Bulk ordering system
* Role-based access
* Support for welfare distribution

---

### 👨‍💻 Admin Panel

* Product management (CRUD)
* Order management
* Role-based access control

---

### ❤️ Planned Features (Roadmap)

* 💳 Razorpay Payment Integration
* 🔁 Subscription System (Monthly deliveries)
* 🎁 Donation System (Sponsor products for NGOs)
* 🔔 Push Notifications
* 🌐 Multi-language support (Gujarati, Hindi, English)
* 🚚 Delivery Agent System

---

## 🧱 Tech Stack

| Layer            | Technology                         |
| ---------------- | ---------------------------------- |
| Frontend         | Flutter (Dart)                     |
| Backend          | Firebase (Auth + Firestore)        |
| State Management | Provider                           |
| Storage          | Firebase Storage                   |
| Notifications    | Firebase Cloud Messaging (Planned) |
| Payments         | Razorpay (Planned)                 |

---

## 📁 Project Structure

```
lib/
├── models/        # Data models
├── screens/       # UI screens
├── services/      # Firebase & business logic
├── providers/     # State management
├── utils/         # Theme & constants
└── widgets/       # Reusable UI components (to be expanded)
```

---

## ⚙️ Installation & Setup

### 1. Clone the repository

```
git clone https://github.com/your-username/shecares.git
cd shecares
```

### 2. Install dependencies

```
flutter pub get
```

### 3. Run the app

```
flutter run
```

---

## 🔥 Firebase Setup

1. Create a Firebase project
2. Enable:

   * Authentication (Phone OTP)
   * Firestore Database
3. Add `google-services.json` (Android)
4. Add `GoogleService-Info.plist` (iOS)

---

## 📌 Current Status

✅ MVP Completed:

* Authentication
* Product listing
* Cart system
* Order flow

⚠️ In Progress:

* Payment integration
* Order tracking improvements
* NGO workflows

---

## 🌍 Problem Statement

Many individuals in low-income communities face:

* Lack of access to hygiene products
* Social stigma in purchasing sanitary items
* No structured NGO distribution system

---

## 💡 Solution

SheCares provides:

* Discreet doorstep delivery
* NGO-based bulk distribution
* Donation-driven support system
* Subscription-based convenience

---

## 🎯 Future Scope

* AI-based cycle prediction & reminders
* NGO analytics dashboard
* Government scheme integration
* CSR & corporate donation support

---

## 🤝 Contribution

Contributions are welcome!
Feel free to fork the repo and submit a pull request.

---

## 📜 License

This project is for educational and social impact purposes.

---

## 👩‍💻 Author

**Shruti Maheta**

---

## 💬 Project Description (One-liner)

A scalable Flutter-based women welfare platform enabling hygiene product delivery, NGO support, and donation-driven impact.

---
