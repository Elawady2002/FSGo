# Fielsekkia Driver

Flutter application for the **Driver & Coordinator** side of the Fielsekkia transport platform.

## Supported Roles

| Role | Description |
|------|-------------|
| Driver (`driver`) | Receives trip requests and reports live location |
| Office Owner (`office_owner`) | Manages a fleet of drivers from an office dashboard |
| Station Owner (`station_owner`) | Manages drivers assigned to a specific station |

## Getting Started

```bash
cd driver
flutter pub get
flutter run
```

## Architecture

Follows Clean Architecture with three layers:

- **Presentation** — Flutter Widgets + Riverpod providers
- **Domain** — Pure Dart entities and use cases
- **Data** — Supabase repositories and models

## Database Migration

Before running for the first time, apply the Supabase migration:

```
driver/scripts/migrations/002_driver_onboarding.sql
```

## Constitution

This app complies with the [Fielsekkia Constitution](../.specify/memory/constitution.md).
