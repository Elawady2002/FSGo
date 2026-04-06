# Feature Specification: Driver UX Improvements

**Feature Branch**: `004-driver-ux-improvements`  
**Created**: 2026-04-06  
**Status**: Draft  
**Input**: User description: "Improve driver UX including logout, navigation menu (Drawer), and dashboard clarity"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Secure Logout (Priority: P1)

As a driver, I want to be able to logout of my account easily at the end of my shift so that my session is closed and my account remains secure.

**Why this priority**: Core security requirement. Users currently feel trapped in the app with no clear way to exit.

**Independent Test**: Can be fully tested by opening the Navigation Drawer, tapping "Logout", and confirming the user is redirected to the Login screen.

**Acceptance Scenarios**:

1. **Given** the driver is on the Duty Dashboard, **When** they tap the menu icon (hamburger), **Then** a Navigation Drawer should appear.
2. **Given** the Navigation Drawer is open, **When** they tap "تسجيل الخروج" (Logout), **Then** the app should clear the session and show the Login page.

---

### User Story 2 - Navigation Drawer & Profile Access (Priority: P1)

As a driver, I want a central menu (Drawer) where I can see my profile information and navigate to different sections of the app.

**Why this priority**: Essential for app structure and scalability. Provides a consistent place for secondary actions.

**Independent Test**: Can be tested by opening the drawer and seeing the Driver's name, phone number, and a "Profile" navigation item.

**Acceptance Scenarios**:

1. **Given** the app is open, **When** the driver swipes from the left or taps the menu icon, **Then** the Drawer should open containing a header with Profile info (Name/Image).
2. **Given** the Drawer is open, **When** the driver taps "الملف الشخصي" (Profile), **Then** they should be navigated to a dedicated Profile page.

---

### User Story 3 - Dashboard Clarity & Status (Priority: P2)

As a driver, I want to clearly understand my current work status and why the task list might be empty, so I am not confused about whether the app is working correctly.

**Why this priority**: Reduces user anxiety and support requests. Improves perceived reliability.

**Independent Test**: Can be tested by viewing the dashboard in different states (No tasks assigned vs Off-duty).

**Acceptance Scenarios**:

1. **Given** no journeys are assigned for the selected date, **When** the dashboard is viewed, **Then** the text should explicitly say "No journeys assigned to you for this day" instead of just "No tasks".
2. **Given** the driver is "Offline" or not in an active shift, **When** the dashboard is viewed, **Then** a status indicator should clearly show "خارج الخدمة" (Off-duty).

---

### Edge Cases

- **No Internet**: What happens when the driver tries to logout while offline? (System should attempt to clear local session even if remote logout fails).
- **Session Expired**: How does the drawer handle the profile info if the token expires? (Should redirect to login if background refresh fails).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST implement a `NavigationDrawer` widget accessible from the `DutyDashboardPage`.
- **FR-002**: Navigation Drawer MUST contain a `DrawerHeader` displaying the driver's name and profile picture (if available).
- **FR-003**: System MUST provide a "Logout" list tile in the drawer that triggers the `LogoutUseCase`.
- **FR-004**: System MUST provide a "Profile" list tile navigating to the profile feature.
- **FR-005**: `DutyDashboardPage` MUST update its AppBar to include a leading hamburger menu icon.
- **FR-006**: The `EmptyDuty` state MUST be updated with more descriptive Arabic text and a visual indicator of the driver's current online/offline status.

### Key Entities

- **DriverProfile**: Represents the logged-in driver. Attributes: id, name, phone, avatarUrl, currentStatus (Online/Offline).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of tested drivers can find the logout button within 5 seconds of opening the app.
- **SC-002**: Navigating to the Profile page requires no more than 2 taps from the home screen.
- **SC-003**: Empty state confusion (as measured by user feedback) is reduced by providing status-aware messaging.

## Assumptions

- The existing `LogoutUseCase` and `AuthProvider` are functional and can be triggered from the UI.
- The `Profile` feature already exists or has a basic implementation that can be linked to.
- The `AppTheme` supports the dark-themed Drawer consistent with the rest of the app.
