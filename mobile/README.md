# Home School Logs - Mobile App

Flutter mobile application for tracking homeschool hours and activities. Works **completely offline** by default - no account required!

## Quick Start

```bash
# Install dependencies
flutter pub get

# Generate Freezed models
dart run build_runner build --delete-conflicting-outputs

# Run the app (local development, offline-only)
flutter run
```

---

## 🎯 Server Targeting

The app uses compile-time configuration via Dart's `--dart-define` flag. By default, the app runs in **offline-only mode** and doesn't require any server.

### API Base URL Configuration

| Environment | Command |
|-------------|---------|
| **Offline-only** (default) | `flutter run` |
| **Local backend** | `flutter run --dart-define=API_URL=http://localhost:8080/api/v1` |
| **Local via IP** (for physical device) | `flutter run --dart-define=API_URL=http://192.168.1.xxx:8080/api/v1` |
| **Preview server** | `flutter run --dart-define=API_URL=https://preview.hmslogs.com/api/v1` |
| **Production** | `flutter run --dart-define=API_URL=https://hmslogs.com/api/v1` |

### Building for Release

```bash
# Debug APK (no signing required)
flutter build apk --debug --dart-define=API_URL=https://hmslogs.com/api/v1

# Release APK (requires signing configuration)
flutter build apk --release --dart-define=API_URL=https://hmslogs.com/api/v1
```

### Running on Physical Android Device

When testing on a physical device, `localhost` won't work. Use your computer's local IP:

```bash
# Find your IP (Windows)
ipconfig

# Run with your IP
flutter run --dart-define=API_URL=http://192.168.1.100:8080/api/v1
```

---

## 🖥️ Backend Development Setup

### Prerequisites

- Go 1.25.5+
- Node.js 18+ and npm
- MongoDB 8.2 (local or remote)

### Option 1: Local MongoDB (Docker)

```bash
# From project root
docker-compose up -d mongo

# Start backend (from backend/ folder)
cd backend
go run .

# Start frontend dev server (from backend/frontend/ folder)
cd backend/frontend
npm install
npm run dev
```

### Option 2: Remote MongoDB via SSH Tunnel

If using the remote Dokploy MongoDB:

```powershell
# 1. Start SSH tunnel (Windows PowerShell)
.\scripts\ssh-mongo-start.ps1

# This creates a tunnel: localhost:27027 → remote MongoDB
# Keep this terminal open!

# 2. In a new terminal, start backend with remote DB connection
cd backend
$env:MONGO_URI="mongodb://user:pass@localhost:27027/hmslogs?authSource=admin"
go run .

# 3. In another terminal, start frontend
cd backend/frontend
npm run dev
```

### All-in-One Dev Script

```powershell
# Starts MongoDB, backend, and frontend together
.\scripts\dev.ps1
```

### Default URLs

| Service | URL |
|---------|-----|
| Backend API | http://localhost:8080 |
| Frontend (dev) | http://localhost:5173 |
| MongoDB (local) | mongodb://localhost:27017 |
| MongoDB (tunnel) | mongodb://localhost:27027 |

---

## 📱 Architecture: Offline-First

This app is designed to work **completely offline** as the primary mode. Cloud sync is optional.

### Data Flow

```
┌─────────────────────────────────────────────────┐
│                    App                          │
├─────────────────────────────────────────────────┤
│  Riverpod Providers                             │
│         ↓                                       │
│  HiveLocalRepository (primary, always used)     │
│         ↓                      ↓                │
│    Hive Boxes             SyncService           │
│  (local storage)      (optional, if account)    │
└─────────────────────────────────────────────────┘
```

### Modes of Operation

| Mode | Description |
|------|-------------|
| **Offline-only** | All data in Hive. Works forever without internet. |
| **Synced** | User created account. Hive is primary, syncs to cloud. |
| **Offline + account** | Has account but offline. Queues changes, syncs when back. |

### Export/Import

Users can export their data anytime for:
- Submitting to state education department
- Transferring to new phone
- Backup purposes

Supported formats:
- JSON (full data, reimportable)
- CSV (spreadsheet-friendly for state submission)

### Dead Man's Switch

The app periodically saves a backup export to the Android file system. If the app crashes or becomes unresponsive, users can recover their data from:

```
/storage/emulated/0/Documents/hmslogs/backup_YYYY-MM-DD.json
```

---

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/widget_test.dart
```

---

## 📁 Project Structure

```
lib/
├── main.dart              # App entry point
├── core/
│   ├── api/               # API client (optional, for sync)
│   ├── database/          # Hive setup and boxes
│   ├── constants.dart     # Configuration
│   └── theme.dart         # App theming
├── features/
│   ├── auth/              # Optional account/sync
│   ├── dashboard/         # Home screen
│   ├── logs/              # Log entries
│   ├── students/          # Student management
│   ├── subjects/          # Subject management
│   ├── export/            # Export/import functionality
│   └── settings/          # App settings
├── models/                # Freezed data models
├── providers/             # Riverpod state management
└── repositories/          # Data access (Hive + optional API sync)
```

---

## 🔧 Development Tips

### Code Generation (Freezed/Riverpod)

After changing model files:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Or watch mode:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

### Linting

```bash
flutter analyze
```

### Formatting

```bash
dart format lib/ test/
```

---

## 📚 Related Documentation

- [Project Overview](../docs/01-project-overview.md)
- [Data Models](../docs/04-data-models.md)
- [API Contracts](../docs/14-api-contracts.md)
- [Implementation Plan](../HMS_LOGS_IMP.md)
