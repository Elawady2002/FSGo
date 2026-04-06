# Data Model: Driver UX Improvements

## Entities

### `DrawerItem`
- Represents a clickable item in the Navigation Drawer.
- **Attributes**:
  - `label`: String (Localized name)
  - `icon`: IconData (Cupertino icon)
  - `route`: String (Target route path)
  - `onTap`: Function (Custom action label, e.g., "logout")

### `DriverActivityStatus`
- Represents the real-time availability of the driver.
- **Values**:
  - `online`: Driver is active and looking for trips.
  - `offline`: Driver is off-duty.
  - `busy`: Driver is currently in a trip.

## State Definitions

### `driverStatusProvider` (StateProvider)
- Tracks `DriverActivityStatus`.
- Used to inform the `_EmptyDuty` widget.

### `drawerOpenProvider` (StateProvider)
- Tracks whether the Drawer is currently open (**Internal UI State**).

## Validations

- **Logout Confirmation**: A Dialog must be shown before confirming a logout action to prevent accidental sign-outs.
- **Language Direction**: Ensure the Drawer opens from the `end` (right-side) as the app is in Arabic (RTL).
