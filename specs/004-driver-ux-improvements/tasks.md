# Tasks: Driver UX Improvements

**Feature**: Driver UX Improvements
**Plan**: [plan.md](plan.md)
**Spec**: [spec.md](spec.md)

## Phase 1: Setup

- [ ] T001 [P] Create the `home/presentation/widgets` directory in `lib/features/home/presentation/widgets`
- [ ] T002 [P] Create the `home/presentation/pages` directory in `lib/features/home/presentation/pages`
- [ ] T003 Add placeholder strings for Logout and Profile in Arabic localization files (`.arb`)

## Phase 2: Foundational (State & Models)

- [ ] T004 [P] Implement `DrawerItem` UI model in `lib/features/home/domain/entities/drawer_item.dart`
- [ ] T005 [P] Create `driverStatusProvider` in `lib/features/home/presentation/providers/driver_status_provider.dart`
- [ ] T006 Define `DriverActivityStatus` enum in `lib/features/home/domain/entities/driver_activity_status.dart`

## Phase 3: User Story 1 - Secure Logout [US1]

**Goal**: Enable drivers to logout via the Navigation Drawer.

- [ ] T007 [P] [US1] Create the `GlobalDrawer` widget in `lib/features/home/presentation/widgets/global_drawer.dart`
- [ ] T008 [US1] Implement the Logout List Tile in `GlobalDrawer` using `LogoutUseCase`
- [ ] T009 [US1] Wrap `DutyDashboardPage` Scaffold with the new `GlobalDrawer` in `lib/features/coordinator/presentation/pages/duty_dashboard_page.dart`
- [ ] T010 [US1] Add the leading Hamburger Menu icon to the `DutyDashboardPage` AppBar

## Phase 4: User Story 2 - Navigation Drawer & Profile [US2]

**Goal**: Provide a central menu with profile info and a Profile page link.

- [ ] T011 [P] [US2] Create a basic `ProfilePage` in `lib/features/home/presentation/pages/profile_page.dart`
- [ ] T012 [US2] Implement the `DrawerHeader` in `GlobalDrawer` displaying Mock/Real Driver name and image
- [ ] T013 [US2] Add the "Profile" navigation link to the `GlobalDrawer` options

## Phase 5: User Story 3 - Dashboard Clarity [US3]

**Goal**: Improve messaging when no tasks are assigned.

- [ ] T014 [US3] Update `_EmptyDuty` widget in `lib/features/coordinator/presentation/pages/duty_dashboard_page.dart` to watch `driverStatusProvider`
- [ ] T015 [US3] Implement status-aware text (Off-Duty msg vs No-Trips msg) in `_EmptyDuty`

## Phase 6: Polish & Cross-Cutting

- [ ] T016 [P] Verify Right-to-Left (RTL) alignment of the Drawer
- [ ] T017 Final manual test of the end-to-end logout and navigation flow

## Dependencies

- [US1] must be completed before [US2] (Drawer structure needed).
- [US3] is independent but requires [Phase 2] status providers.

## Parallel Execution

- T001, T002, T004, T005, T006 can run in parallel (Foundational + Setup).
- T011 (Profile Page) can be built in parallel with T008 (Logout logic).

## Implementation Strategy

- **MVP**: Complete US1 (Logout) to resolve the immediate user pain point.
- **V2**: Complete US2 and US3 for full navigational clarity.
