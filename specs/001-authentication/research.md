# Research: User Authentication System

**Feature**: 001-authentication
**Date**: 2025-10-20
**Phase**: 0 (Research & Technical Decisions)

## Overview

Research findings for implementing user authentication using Phoenix's `phx.gen.auth` generator. This document resolves all technical unknowns and establishes the foundation for implementation.

## Key Decisions

### Decision 1: Use Phoenix phx.gen.auth Generator with LiveView

**What was chosen**: Phoenix's built-in `mix phx.gen.auth Accounts User users --live` generator

**Rationale**:
- Official Phoenix solution designed specifically for authentication
- Generates production-ready, security-audited code
- Includes comprehensive test coverage out of the box
- Follows Phoenix 1.8+ best practices automatically
- LiveView support via `--live` flag for modern UX
- Maintained by Phoenix core team with security updates

**Alternatives considered**:
1. **Guardian + Custom Implementation**: Rejected - More complex, requires manual security implementation, higher maintenance burden
2. **Pow Library**: Rejected - Third-party dependency, less community support than official generator
3. **Auth0/OAuth Only**: Rejected - Requires external service, adds complexity for simple email/password auth
4. **Custom from scratch**: Rejected - Reinventing the wheel, security risks, no test coverage

**Implementation command**:
```bash
mix phx.gen.auth Accounts User users --live
```

### Decision 2: Password Hashing Library

**What was chosen**: Bcrypt for Unix systems (default), Pbkdf2 for Windows (default)

**Rationale**:
- Bcrypt is industry standard with proven security track record
- Adaptive hashing resists brute-force attacks
- Phoenix generator defaults are security-audited
- Pbkdf2 fallback for Windows compatibility
- No need to specify `--hashing-lib` flag (uses smart defaults)

**Alternatives considered**:
1. **Argon2**: Rejected - More complex setup, bcrypt sufficient for our needs
2. **Pbkdf2 only**: Rejected - Bcrypt is more secure on Unix systems
3. **Custom hashing**: Rejected - Never implement your own crypto

**Decision**: Use generator defaults (bcrypt on Unix, pbkdf2 on Windows)

### Decision 3: Email Delivery in Development

**What was chosen**: Terminal logging via Swoosh notifier (generator default)

**Rationale**:
- Swoosh already configured in Phoenix project (see mix.exs)
- Development mailbox available at `/dev/mailbox` route
- No external email service needed for development/testing
- Fast iteration without email service delays
- Can upgrade to real email service later (SendGrid, Mailgun, etc.)

**Alternatives considered**:
1. **Real email service in dev**: Rejected - Slow, requires API keys, unnecessary complexity
2. **Bamboo library**: Rejected - Swoosh is Phoenix default and more modern
3. **No emails at all**: Rejected - Breaks confirmation/reset workflows

**Implementation**: Generator creates `UserNotifier` module that uses Swoosh, logs to terminal by default

### Decision 4: Token Storage Strategy

**What was chosen**: Database-backed session tokens (generator default)

**Rationale**:
- Enables token revocation (logout, "log out all devices")
- Provides audit trail of active sessions
- Required for session management feature (P3)
- No additional configuration needed (handled by generator)
- UserToken schema automatically created

**Alternatives considered**:
1. **Cookie-only sessions**: Rejected - Cannot revoke sessions, no visibility
2. **Redis tokens**: Rejected - Adds infrastructure complexity, PostgreSQL sufficient
3. **JWT tokens**: Rejected - Cannot revoke, security concerns for session management

**Implementation**: Generator creates `users_tokens` table and UserToken schema

### Decision 5: Session Expiration Policy

**What was chosen**: 60 days for "remember me", session-based for regular login

**Rationale**:
- Balances security with user convenience
- Industry standard duration (many sites use 30-90 days)
- Generator provides built-in support for "remember me" checkbox
- Session-based for non-remembered logins improves security

**Alternatives considered**:
1. **No expiration**: Rejected - Security risk
2. **7 days only**: Rejected - Poor UX, forces frequent re-login
3. **Forever tokens**: Rejected - Major security vulnerability

**Implementation**: Generator handles token expiration logic automatically, configurable in generated code

### Decision 6: Confirmation Requirement

**What was chosen**: Email confirmation required before first login

**Rationale**:
- Verifies email ownership
- Prevents spam accounts
- Industry standard practice
- Generator includes complete confirmation workflow
- Can be bypassed in tests

**Alternatives considered**:
1. **No confirmation**: Rejected - Spam risk, no email verification
2. **Optional confirmation**: Rejected - Defeats purpose
3. **Confirmed by default**: Rejected - Cannot verify email ownership

**Implementation**: Generator creates confirmation token system and LiveViews

## Technical Integration Points

### Database Schema

**Generated Tables**:
1. `users` table:
   - `id` (uuid, primary key)
   - `email` (string, unique, not null)
   - `hashed_password` (string, not null)
   - `confirmed_at` (datetime, nullable)
   - `inserted_at`, `updated_at` (timestamps)

2. `users_tokens` table:
   - `id` (uuid, primary key)
   - `user_id` (uuid, foreign key to users)
   - `token` (binary, hashed)
   - `context` (string: "session", "confirm", "reset_password")
   - `sent_to` (string, email address)
   - `inserted_at` (timestamp)

**Indexes**: Automatic indexes on `users.email`, `users_tokens.user_id`, `users_tokens.token`, `users_tokens.context`

### Router Integration

**Generated Routes** (all LiveView with `--live` flag):
- `GET /users/register` - UserRegistrationLive
- `POST /users/register` - UserRegistrationLive (form submit)
- `GET /users/log_in` - UserLoginLive
- `POST /users/log_in` - UserLoginLive (form submit)
- `DELETE /users/log_out` - UserSessionController.delete
- `GET /users/reset_password` - UserResetPasswordLive
- `GET /users/reset_password/:token` - UserResetPasswordLive (with token)
- `GET /users/settings` - UserSettingsLive (requires auth)
- `GET /users/confirm` - UserConfirmationLive
- `GET /users/confirm/:token` - UserConfirmationLive (with token)

**LiveSession Configuration**:
Generator adds `:on_mount` hooks for authentication:
- `{ReviewRoomWeb.UserAuth, :mount_current_user}` - Loads current user
- `{ReviewRoomWeb.UserAuth, :ensure_authenticated}` - Redirects if not logged in
- `{ReviewRoomWeb.UserAuth, :redirect_if_user_is_authenticated}` - Redirects if logged in

### Testing Strategy

**Generated Test Coverage**:
1. **Context tests** (`test/review_room/accounts_test.exs`):
   - User registration with valid/invalid data
   - Email uniqueness validation
   - Password hashing verification
   - Login with correct/incorrect credentials
   - Token generation and validation
   - Password reset workflows
   - Email change workflows

2. **LiveView tests** (`test/review_room_web/live/user_*_live_test.exs`):
   - Registration form rendering and submission
   - Login form with remember me checkbox
   - Password reset request and completion
   - Email confirmation flow
   - Settings page for authenticated users

3. **Fixtures** (`test/support/fixtures/accounts_fixtures.ex`):
   - `user_fixture/1` - Create test users
   - `confirmed_user_fixture/1` - Create confirmed users
   - `extract_user_token/1` - Extract tokens from emails

**Test Coverage Target**: Generator provides ~95% coverage for authentication code

## Performance Considerations

### Expected Metrics
- Password hashing: ~100-300ms per hash (bcrypt work factor 12)
- Database queries: <10ms for user lookup by email (indexed)
- Session token validation: <5ms (indexed token lookup)
- LiveView navigation: <100ms (no full page reload)

### Optimization Opportunities
1. **Database connection pooling**: Already configured in Phoenix (10 connections default)
2. **Query optimization**: Generator uses `Repo.get_by` with indexes
3. **Caching**: Not needed initially, can add `:current_user` caching later
4. **Password hashing**: Work factor already optimized (bcrypt default)

## Security Considerations

### Built-in Security Features
1. **CSRF protection**: Automatic via Phoenix form helpers
2. **Timing attack prevention**: Generator uses `Bcrypt.verify_pass/2` with constant-time comparison
3. **Password requirements**: Minimum 12 characters (configurable)
4. **Token single-use**: Reset tokens deleted after use
5. **Token expiration**: Confirmation/reset tokens expire after 1 day
6. **Email enumeration prevention**: Generic messages for password reset

### Additional Security Notes
- Session tokens are hashed before storage
- Passwords never logged or displayed
- All forms use Phoenix token authentication
- HTTPS recommended for production (not enforced in dev)

## Dependency Analysis

### Required Dependencies (Already in mix.exs)
- ✅ `phoenix` ~> 1.8.1
- ✅ `phoenix_ecto` ~> 4.5
- ✅ `ecto_sql` ~> 3.13
- ✅ `postgrex` >= 0.0.0
- ✅ `phoenix_live_view` ~> 1.1.0
- ✅ `swoosh` ~> 1.16

### Additional Dependencies (Added by generator)
- `bcrypt_elixir` ~> 3.0 (Unix systems)
- OR `pbkdf2_elixir` ~> 2.0 (Windows systems)

**Installation**: Generator automatically adds appropriate dependency to mix.exs

## Migration Path

### Generator Execution Steps
1. Run `mix phx.gen.auth Accounts User users --live`
2. Review generated files (contexts, schemas, LiveViews, tests)
3. Inspect migration file for schema
4. **RUN TESTS FIRST** (verify they fail - Constitution Principle I)
5. Run `mix deps.get` (installs bcrypt/pbkdf2)
6. Run `mix ecto.migrate`
7. Run `mix test` (verify all tests pass)
8. Run `mix precommit` (quality gate)

### Post-Generation Customization
**Minimal changes needed**:
- Update navigation in `layouts.ex` (generator provides template)
- Add user menu with login/logout links
- Customize email templates in `user_notifier.ex` (optional)
- Adjust password requirements if needed (change from 12 chars)

## Open Questions & Risks

### Resolved Questions
- ✅ Which generator to use? → `phx.gen.auth` with `--live`
- ✅ Password hashing library? → Bcrypt (generator default)
- ✅ Email in development? → Swoosh terminal logging
- ✅ Session storage? → Database-backed tokens
- ✅ LiveView or Controllers? → LiveView via `--live` flag

### No Outstanding Questions
All technical decisions resolved. Ready for Phase 1 (Design).

### Risk Assessment
**LOW RISK**: Using official Phoenix generator significantly reduces implementation risk. Generator code is:
- Security-audited by Phoenix core team
- Battle-tested in production by thousands of applications
- Actively maintained with security updates
- Comprehensive test coverage included
- Well-documented with upgrade paths

**Mitigation**: Follow generator recommendations, run `mix precommit` quality gate, verify all tests pass.

## References

- Phoenix phx.gen.auth documentation: https://hexdocs.pm/phoenix/mix_phx_gen_auth.html
- Phoenix Authentication Guide: https://hexdocs.pm/phoenix/authentication.html
- Bcrypt best practices: https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html
- Phoenix LiveView Authentication: https://hexdocs.pm/phoenix_live_view/security-model.html

## Next Steps

Proceed to **Phase 1: Design & Contracts**
- Generate data-model.md (User and UserToken schemas)
- Document authentication flows in contracts/
- Create quickstart.md for running authentication locally
- Update agent context with authentication patterns
