# Implementation Plan: Driver UX Improvements

**Branch**: `004-driver-ux-improvements` | **Date**: 2026-04-06 | **Spec**: [/specs/004-driver-ux-improvements/spec.md](spec.md)
**Input**: Feature specification from `/specs/004-driver-ux-improvements/spec.md`

## Summary

The primary goal is to improve the Driver app's usability by introducing a consistent navigation structure (Navigation Drawer) accessible from any screen, allowing drivers to view their Profile info and Logout securely. Additionally, the feature will enhance the "No Tasks" dashboard state with status-aware messaging (Online/Offline/No Trips). 

We will adopt a **Global Drawer** approach implemented at the root of the Home feature, ensuring the menu is accessible without duplicating logic across multiple dashboard pages.

## Technical Context

**Language/Version**: Dart (Sound Null Safety) | Flutter (Latest Stable)
**Primary Dependencies**: `flutter_riverpod`, `google_fonts`, `cupertino_icons`
**Storage**: Secure Storage (for auth state)
**Testing**: `flutter_test` (Unit & Widget tests)
**Target Platform**: iOS 15+, Android 12+
**Project Type**: Mobile Application
**Performance Goals**: Drawer access and navigation transitions < 200ms
**Constraints**: Must maintain consistent branding and dark-themed UI
**Scale/Scope**: Impacts 1-2 core screens but establishes a new global navigation pattern

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Flutter-First**: Compliant. Uses standard Flutter Widgets.
- **Clean Architecture**: Compliant. Logic stays in Use Cases/Providers.
- **Shared Logic**: Compliant. Drawer logic will be placed in a shared UI directory within the `home` feature.
- **Localization**: Compliant. All strings will be added to `.arb` files.

## Project Structure

### Documentation (this feature)

```text
specs/004-driver-ux-improvements/
├── plan.md              # This file
├── research.md          # Implementation research
├── data-model.md        # UI models and state definitions
├── quickstart.md        # Feature setup guide
└── tasks.md             # Implementation tasks
```

### Source Code (repository root)

```text
lib/
├── features/
│   ├── home/
│   │   ├── presentation/
│   │   │   ├── widgets/
│   │   │   │   └── global_drawer.dart  # [NEW] Common drawer widget
│   │   │   └── pages/
│   │   │       └── profile_page.dart # [NEW] Basic profile view
│   ├── auth/
│   │   └── presentation/
│   │       └── providers/
│   │           └── auth_provider.dart # Referenced for Logout
│   └── coordinator/
│       └── presentation/
│           └── pages/
│               └── duty_dashboard_page.dart # [MODIFY] Add hamburger icon
```

**Structure Decision**: Option 1 (Single Project) using Feature-First organization. The Drawer will be part of the `home/widgets` directory to be reusable across the domain.

## Complexity Tracking

*No violations identified.*
