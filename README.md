# SmartQ – Hospital Queue Management System

SmartQ is a Final Year project developed to modernize hospital queue management. The system reduces patient waiting time by providing a digital queue management solution with a Flutter mobile application for patients and a web-based administration dashboard for hospital staff.

## Project Overview

SmartQ enables hospitals to manage patient queues digitally while allowing patients to obtain queue tokens remotely through a mobile application.

The system consists of two major components:

- **SmartQ Admin** – Web-based administration system
- **SmartQ User** – Flutter mobile application for patients

---

## Project Structure

```
SmartQ
│
├── smartq-admin
│   ├── frontend (React.js)
│   └── backend (Node.js + Express + MongoDB)
│
└── smartq-user
    ├── Flutter Mobile Application
    └── Backend (Node.js + Express + MongoDB)
```

---

# Features

## Patient Mobile Application

- User Registration & Login
- Secure Authentication
- Hospital Selection
- Department Selection
- Queue Token Booking
- Live Queue Status
- Queue Position Tracking
- Estimated Waiting Time
- QR Code Token Verification
- Token Cancellation
- Push Notifications
- Queue History
- User Profile Management

---

## Admin Dashboard

### Super Administrator

- Manage Hospitals
- Manage Departments
- Manage Hospital Administrators
- Manage Department Administrators
- View System Statistics
- Hospital Performance Reports
- Manage Notifications
- Analytics Dashboard

### Hospital Administrator

- Manage Hospital Departments
- Manage Department Administrators
- Monitor Queue Sessions
- Online Appointment Scheduling
- View Reports
- Analytics Dashboard

### Department Administrator

- Create Queue Sessions
- Start Queue
- Close Queue
- Cancel Queue
- Call Next Patient
- Skip Tokens
- QR Code Token Verification
- Manage Current Queue
- View Reports
- Analytics Dashboard

---

# Technologies Used

## Mobile Application

- Flutter
- Dart
- Firebase Authentication
- Firebase Cloud Messaging (FCM)

## Admin Frontend

- React.js
- JavaScript
- Axios
- Socket.IO Client

## Backend

- Node.js
- Express.js
- MongoDB
- Mongoose
- JWT Authentication
- Socket.IO

---

# System Modules

- Authentication
- Hospital Management
- Department Management
- User Management
- Queue Session Management
- Token Management
- Notification Management
- Real-time Queue Updates

---

# Project Architecture

```
Flutter Mobile App
        │
        │ REST API
        ▼
 Node.js / Express Backend
        │
        ├──────── MongoDB
        │
        ├──────── Firebase
        │
        └──────── Socket.IO
                     ▲
                     │
             React Admin Dashboard
```

---

# Installation

## Clone Repository

```bash
git clone https://github.com/Pathumi0820/SmartQ.git
```

---

## Admin Frontend

```bash
cd smartq-admin/frontend
npm install
npm run dev
```

---

## Admin Backend

```bash
cd smartq-admin/backend
npm install
npm start
```

---

## Mobile Application

```bash
cd smartq-user
flutter pub get
flutter run
```

---

## Mobile Backend

```bash
cd smartq-user/backend
npm install
npm start
```

---

# Environment Variables

Create a `.env` file for each backend.

Example:

```env
PORT=5000
MONGODB_URI=YOUR_MONGODB_CONNECTION
JWT_SECRET=YOUR_SECRET_KEY
```

---

# Future Enhancements

- SMS Notifications
- Doctor Availability Tracking
- AI-based Waiting Time Prediction
- Multi-language Support

---

# License

Copyright © 2026 Pathumi Roshanee Kumarage.

This project, *SmartQ – Hospital Queue Management System*, was developed as a Final Year Project.
