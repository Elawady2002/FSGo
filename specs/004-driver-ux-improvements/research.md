# Research: Driver UX Improvements Implementation

## Unknowns Resolved

### Decision 1: Global Drawer Placement
- **Decision**: Implement the `GlobalDrawer` in the `Scaffold` of the `DutyDashboardPage` (as it acts as the home screen) and any subsequent top-level pages.
- **Rationale**: Since the app doesn't currently use a single `MainPage` wrapper, it's easier to inject the drawer into the existing scaffolds. If complexity grows, a `RootNavigator` or `ShellRoute` pattern may be considered.
- **Alternatives**: Using a separate "Settings" page without a drawer (rejected because it doesn't solve the "where is the logout" problem easily from every screen).

### Decision 2: Logout Flow Integration
- **Decision**: Directly reference the existing `authProvider` and `logoutUseCaseProvider`.
- **Rationale**: Reusing existing logic ensures consistency. The logout action will clear the state, which is already watched by the `MaterialApp` router to redirect to the Login page. 
- **Alternatives**: Manual redirection (rejected as it violates Riverpod-watched state patterns).

### Decision 3: "Empty State" UI Logic
- **Decision**: Add a `driverStatusProvider` to track whether the driver is "Active", "Off-Duty", or "Suspended".
- **Rationale**: This allows the `_EmptyDuty` widget to show context-sensitive text (e.g., "Switch to Online to see trips" vs "No trips assigned for today").
- **Alternatives**: Static text only (rejected by user as it creates confusion).

## Best Practices

- **Flutter Drawers**: Use `ThemeData` to style the drawer and ensure `Scaffold.appBar` has a custom `IconButton` if a default one doesn't appear.
- **Localization**: Use `AppLocalizations.of(context)` for all text in the drawer.
- **Testing**: Mock the `AuthProvider` to test that the drawer's logout button actually triggers the logout call.
