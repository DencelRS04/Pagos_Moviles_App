# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run on Android emulator
flutter run

# Run on specific device
flutter run -d <device_id>

# List connected devices
flutter devices

# Build APK (debug)
flutter build apk --debug

# Build APK (release)
flutter build apk --release

# Analyze / lint
flutter analyze

# Run tests
flutter test

# Run a single test file
flutter test test/path/to/test_file.dart

# Get dependencies
flutter pub get

# Clean build artifacts
flutter clean
```

## Architecture

This is a Flutter mobile banking app ("CUC Pagos Móviles") that connects to a local backend API (running at `10.0.2.2` — the Android emulator loopback for `localhost`). SSL certificate validation is intentionally bypassed for development via `badCertificateCallback`.

### Dual-layer structure

The codebase has **two parallel implementations** that coexist:

1. **Active implementation** (`lib/screens/`, `lib/services/`, `lib/widgets/`, `lib/models/`): This is what `main.dart` actually uses. It uses plain Flutter `StatefulWidget` with `http` for networking and `FlutterSecureStorage` for session management.

2. **Scaffolded feature architecture** (`lib/features/`, `lib/core/`, `lib/shared/`): A more structured layer with data/domain/presentation separation (datasources, repositories, controllers). Most files here are empty stubs (1-line files). This is intended for future development.

The active screens registered in `main.dart`:
- `/login` → `LoginScreen` (`lib/screens/login_screen.dart`)
- `/home` → `AuthGuard` wrapping `MainLayout` (`lib/screens/main_layout.dart`)

### Navigation

`MainLayout` uses a `BottomNavigationBar` with 5 tabs (index-based, no named routes beyond `/login` and `/home`):
- 0: `HomePage` — dashboard with welcome card and linked accounts
- 1: Placeholder — "Inscribir / Desinscribir" (not yet implemented)
- 2: Placeholder — "Saldo Actual" (not yet implemented)
- 3: Placeholder — "Historial de Movimientos" (not yet implemented)
- 4: `TransferPage` — money transfer form

`HomePage` can trigger navigation to tab 4 via the `onTransferir` callback passed down from `MainLayout`.

### Auth flow

- Login validates that email ends with `@cuc.cr` before making any API call
- On success, `AuthService` stores: `access_token`, `refresh_token`, `expires_in`, `usuarioID`, `nombre_completo` in `FlutterSecureStorage`
- `remembered_email` is stored separately and survives logout
- `AuthGuard` in `main.dart` checks for `access_token` presence to allow access to `/home`

### API endpoints

- Auth: `https://10.0.2.2:7143/auth/login`
- Transfer: `https://10.0.2.2:7000/gateway/admin/transactions/route`
- All requests use `Bearer` token from secure storage for authenticated calls

### Shared utilities

- `UIUtils` (`lib/widgets/ui_utils.dart`): `showMsg()` for snackbars (green/red), `showConfirmDialog()` for confirmation dialogs — used across all screens

### Upcoming features (stub directories exist)

The `lib/features/` directory has stubs for: `balance`, `movements`, `subscription` (register/unregister wallet), `profile`, `splash`, and `transfer` (confirm page). When implementing these, follow the data/domain/presentation pattern already scaffolded there.
