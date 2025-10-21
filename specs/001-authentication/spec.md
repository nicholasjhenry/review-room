# Feature Specification: User Authentication System

**Feature Branch**: `001-authentication`
**Created**: 2025-10-20
**Status**: Draft
**Input**: User description: "User authentication system with email/password - Use the phoenix dedicated phoenix generator for this feature"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - User Registration (Priority: P1)

New users can create an account with email and password to access the ReviewRoom application.

**Why this priority**: Registration is the foundational entry point for all users. Without the ability to create accounts, no other authentication features matter. This is the minimal viable authentication system.

**Independent Test**: Can be fully tested by navigating to registration page, submitting email/password, and verifying account creation in database and confirmation email sent to terminal logs.

**Acceptance Scenarios**:

1. **Given** I am on the registration page, **When** I enter a valid email and password (minimum 12 characters), **Then** I should see a success message and receive a confirmation email
2. **Given** I am on the registration page, **When** I enter an email that already exists, **Then** I should see an error message "Email has already been taken"
3. **Given** I am on the registration page, **When** I enter a password shorter than 12 characters, **Then** I should see an error message "Password must be at least 12 characters"
4. **Given** I am on the registration page, **When** I leave email or password blank, **Then** I should see validation errors for required fields
5. **Given** I registered but haven't confirmed, **When** I click the confirmation link from the email, **Then** my account should be confirmed and I should be logged in

---

### User Story 2 - User Login (Priority: P1)

Registered users can log in with their email and password to access the application.

**Why this priority**: Login is essential alongside registration. Users need to authenticate after account creation. Together with registration, this forms the MVP authentication system.

**Independent Test**: Can be fully tested by creating a confirmed user account, navigating to login page, submitting credentials, and verifying session establishment.

**Acceptance Scenarios**:

1. **Given** I am a confirmed user on the login page, **When** I enter correct email and password, **Then** I should be logged in and redirected to the home page
2. **Given** I am on the login page, **When** I enter an incorrect password, **Then** I should see an error message "Invalid email or password"
3. **Given** I am on the login page, **When** I enter an unregistered email, **Then** I should see an error message "Invalid email or password"
4. **Given** I am an unconfirmed user on the login page, **When** I enter correct credentials, **Then** I should be redirected to resend confirmation instructions
5. **Given** I am on the login page, **When** I check "Remember me", **Then** my session should persist for 60 days
6. **Given** I am on the login page, **When** I don't check "Remember me", **Then** my session should expire when browser closes

---

### User Story 3 - User Logout (Priority: P1)

Authenticated users can log out to end their session and secure their account.

**Why this priority**: Logout is a security essential. Users must be able to end sessions, especially on shared devices. This completes the MVP authentication triad (register, login, logout).

**Independent Test**: Can be fully tested by logging in as a user, clicking logout, and verifying session termination and inability to access protected pages.

**Acceptance Scenarios**:

1. **Given** I am logged in, **When** I click the logout button, **Then** I should be logged out and redirected to the home page
2. **Given** I just logged out, **When** I try to access a protected page, **Then** I should be redirected to the login page
3. **Given** I am logged in on multiple devices/tabs, **When** I click logout on one, **Then** I should be logged out on all devices/tabs

---

### User Story 4 - Password Reset (Priority: P2)

Users who forget their password can request a password reset link via email to regain access to their account.

**Why this priority**: Password reset is important for user retention (prevents account abandonment) but not required for MVP. The system can function without it while P1 stories are tested.

**Independent Test**: Can be fully tested by navigating to forgot password page, requesting reset for existing email, receiving reset link, and successfully changing password.

**Acceptance Scenarios**:

1. **Given** I am on the forgot password page, **When** I enter my registered email, **Then** I should receive a password reset email with a link
2. **Given** I received a reset link, **When** I click it and enter a new password, **Then** my password should be updated and I should be logged in
3. **Given** I am on the forgot password page, **When** I enter an unregistered email, **Then** I should still see a success message (to prevent email enumeration)
4. **Given** I have a reset token, **When** it expires (after 1 day), **Then** the reset link should be invalid
5. **Given** I successfully reset my password, **When** I try to use the same reset link again, **Then** it should be invalid (single-use tokens)

---

### User Story 5 - Email Change (Priority: P2)

Authenticated users can update their email address with confirmation to maintain account access.

**Why this priority**: Email change is a maintenance feature for account management but not critical for initial system launch. Users can function with their original email.

**Independent Test**: Can be fully tested by logging in, navigating to settings, requesting email change, confirming via link, and verifying new email is active.

**Acceptance Scenarios**:

1. **Given** I am logged in and on settings page, **When** I request to change my email to a new address, **Then** I should receive a confirmation email at the new address
2. **Given** I requested an email change, **When** I click the confirmation link, **Then** my email should be updated and I should remain logged in
3. **Given** I am on settings page, **When** I try to change to an email already in use, **Then** I should see an error message "Email has already been taken"
4. **Given** I requested an email change, **When** the confirmation expires (after 1 day), **Then** the link should be invalid and my email unchanged

---

### User Story 6 - Password Change (Priority: P2)

Authenticated users can change their password while logged in for security maintenance.

**Why this priority**: Password change is a security best practice and account maintenance feature but not critical for MVP launch. Users can use password reset if needed initially.

**Independent Test**: Can be fully tested by logging in, navigating to settings, entering current and new password, and verifying password is updated and old password no longer works.

**Acceptance Scenarios**:

1. **Given** I am logged in and on settings page, **When** I enter my current password and a new password, **Then** my password should be updated successfully
2. **Given** I am on the password change page, **When** I enter an incorrect current password, **Then** I should see an error message "Current password is invalid"
3. **Given** I am on the password change page, **When** I enter a new password shorter than 12 characters, **Then** I should see a validation error
4. **Given** I just changed my password, **When** I log out and log back in with the new password, **Then** I should be able to authenticate successfully

---

### User Story 7 - Session Management (Priority: P3)

Users can view and manage active sessions across different devices for security monitoring.

**Why this priority**: Session management is advanced security feature. While valuable, it's not essential for MVP. The core authentication system works without explicit session visibility.

**Independent Test**: Can be fully tested by logging in from multiple browsers/devices, viewing session list in settings, and revoking individual sessions.

**Acceptance Scenarios**:

1. **Given** I am logged in on multiple devices, **When** I view my settings page, **Then** I should see a list of all active sessions with device/location info
2. **Given** I see my session list, **When** I click "Log out all other sessions", **Then** all sessions except current should be terminated
3. **Given** I see my session list, **When** I click delete on a specific session, **Then** that session should be terminated
4. **Given** I am logged in, **When** my session token is older than 60 days (for remembered) or browser closes (for not remembered), **Then** my session should expire

---

### Edge Cases

- What happens when a user tries to register with a malformed email address?
  * System validates email format and shows error "Email must be a valid email address"

- What happens when a user tries to use a confirmation/reset token that has already been used?
  * System shows error "Token is invalid or has expired" and prompts to request new one

- What happens when multiple password reset requests are made in quick succession?
  * Each new token invalidates previous tokens for that user

- What happens when a user registers with an email that exists but is unconfirmed?
  * System allows re-registration and sends new confirmation email (replacing unconfirmed account)

- What happens during concurrent login attempts from different devices?
  * Both succeed; sessions are independent (unless same device/browser)

- What happens if user tries to access authenticated routes without being logged in?
  * System redirects to login page with flash message "You must log in to access this page"

- What happens if confirmation email is not received?
  * User can request resend from login page or registration confirmation page

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow users to register with unique email address and password
- **FR-002**: System MUST validate passwords are at least 12 characters long
- **FR-003**: System MUST hash passwords using bcrypt (Unix) or pbkdf2 (Windows) before storage
- **FR-004**: System MUST send confirmation email after registration
- **FR-005**: System MUST require email confirmation before allowing login
- **FR-006**: System MUST allow confirmed users to authenticate with email and password
- **FR-007**: System MUST create session tokens upon successful authentication
- **FR-008**: System MUST support "remember me" functionality with 60-day token expiration
- **FR-009**: System MUST allow users to log out and invalidate their session
- **FR-010**: System MUST allow users to request password reset via email
- **FR-011**: System MUST generate single-use password reset tokens valid for 1 day
- **FR-012**: System MUST allow authenticated users to change their email address with confirmation
- **FR-013**: System MUST allow authenticated users to change their password with current password verification
- **FR-014**: System MUST log all authentication emails to terminal during development (no actual email sending)
- **FR-015**: System MUST use LiveView for all authentication pages (--live flag)
- **FR-016**: System MUST implement :on_mount hooks for LiveView authentication
- **FR-017**: System MUST redirect unauthenticated users to login when accessing protected routes
- **FR-018**: System MUST store session tokens in database for revocation capability
- **FR-019**: System MUST use secure, cryptographically random tokens for all authentication operations
- **FR-020**: System MUST prevent email enumeration in password reset and login flows

### Key Entities

- **User**: Represents authenticated user with email, hashed password, confirmation status, and timestamps
  * Attributes: email (unique, required), hashed_password (required), confirmed_at (nullable datetime)
  * Validations: email format, email uniqueness, password length >= 12 characters

- **UserToken**: Represents authentication tokens for various purposes (session, confirmation, reset)
  * Attributes: user_id (foreign key), token (hashed, unique), context (string: session/email/reset), sent_to (email address for tracking), inserted_at (timestamp)
  * Relationships: belongs_to User
  * Token contexts: "session" (login sessions), "confirm" (email confirmation), "reset_password" (password reset)

- **Context Module (Accounts)**: Business logic container for user operations
  * Functions: register_user, get_user_by_email, verify_password, generate_tokens, confirm_user, reset_password, etc.
  * Handles: password hashing, token generation, email delivery (via Notifier)

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can complete registration and email confirmation workflow in under 3 minutes
- **SC-002**: Users can log in with valid credentials in under 10 seconds
- **SC-003**: Password reset workflow completes successfully in under 2 minutes
- **SC-004**: System handles 100 concurrent authentication requests without degradation
- **SC-005**: All authentication pages render using LiveView without full page reloads
- **SC-006**: Zero plain-text passwords stored in database (100% bcrypt/pbkdf2 hashed)
- **SC-007**: All authentication operations pass `mix precommit` quality gates (zero warnings, tests pass)
- **SC-008**: Test coverage for authentication module reaches 100% for all public functions
- **SC-009**: Users can navigate between authentication pages (login → register → reset) without full page reloads (LiveView benefit)
- **SC-010**: Session tokens automatically expire after defined periods (60 days for remembered, session close for non-remembered)
