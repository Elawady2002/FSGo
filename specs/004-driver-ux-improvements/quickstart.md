# Quickstart: Driver UX Improvements

## Feature Setup

1.  **Switch to Branch**: `git checkout 004-driver-ux-improvements`
2.  **Verify State Management**: Ensure `flutter_riverpod` is available in `pubspec.yaml`.
3.  **Localize**: Add the following keys to `lib/l10n/app_ar.arb`:
    - `logout`: "تسجيل الخروج"
    - `profile`: "المعرف الشخصي"
    - `no_trips_assigned`: "لا توجد رحلات معينة لك لهذا اليوم"
    - `off_duty`: "أنت حالياً خارج الخدمة"

## Core UI Components

- **GlobalDrawer**: `lib/features/home/presentation/widgets/global_drawer.dart`
- **Dashboard AppBar**: Update leading icon in `lib/features/coordinator/presentation/pages/duty_dashboard_page.dart`.

## Verification Scenarios

1.  **Logout Test**:
    - Open Drawer.
    - Tap "Logout".
    - Success: Redirects to Login screen.
2.  **Profile Access**:
    - Open Drawer.
    - Tap "Profile".
    - Success: Navigates to `ProfilePage`.
3.  **Empty State Test**:
    - Select a date with no trips.
    - Success: Dashboard shows status-aware message.
