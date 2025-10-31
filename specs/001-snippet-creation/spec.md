# Feature Specification: Developer Code Snippet Creation

**Feature Branch**: `001-snippet-creation`  
**Created**: 2025-10-31  
**Status**: Draft  
**Input**: User description: "Create the new snippet for a developer - Add the syntax highlighting language to a snippet - Add the tags to a snippet - Set the visibility/privacy for a snippet - Add the title and description to a snippet"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Create Basic Snippet (Priority: P1)

A developer wants to save a code snippet with syntax highlighting so they can reference it later or share it with their team.

**Why this priority**: This is the core functionality that delivers immediate value - allowing developers to capture and store code snippets. Without this, no other features are possible.

**Independent Test**: Can be fully tested by creating a new snippet with code content and a selected language, then verifying the snippet is stored and displays with proper syntax highlighting.

**Acceptance Scenarios**:

1. **Given** a developer is on the snippet creation page, **When** they enter code content and select a syntax highlighting language, **Then** the snippet is saved with the selected language
2. **Given** a developer has created a snippet with a specific language, **When** they view the snippet, **Then** the code is displayed with appropriate syntax highlighting for that language
3. **Given** a developer is creating a snippet, **When** they do not select a language, **Then** the snippet is saved with plain text formatting

---

### User Story 2 - Add Metadata (Title & Description) (Priority: P2)

A developer wants to add a title and description to their snippet so they can quickly identify its purpose and provide context for others.

**Why this priority**: Titles and descriptions significantly improve snippet discoverability and usability, but the snippet can function without them. This enables better organization as the snippet library grows.

**Independent Test**: Can be fully tested by creating a snippet with a title and description, then verifying both display correctly when viewing the snippet and in any snippet listing.

**Acceptance Scenarios**:

1. **Given** a developer is creating a snippet, **When** they enter a title and description, **Then** both are saved with the snippet
2. **Given** a developer views a snippet with title and description, **When** the snippet loads, **Then** the title is prominently displayed and the description provides context
3. **Given** a developer creates a snippet without a title, **When** the snippet is saved, **Then** a default identifier is used (such as timestamp or auto-generated name)

---

### User Story 3 - Organize with Tags (Priority: P3)

A developer wants to add tags to their snippets so they can categorize and filter them by topic, technology, or use case.

**Why this priority**: Tags enable powerful organization and filtering capabilities but are not essential for the core snippet creation and storage functionality. Developers can still create and use snippets effectively without tags.

**Independent Test**: Can be fully tested by creating snippets with various tags, then verifying tags display with the snippet and can be used to filter or search snippets.

**Acceptance Scenarios**:

1. **Given** a developer is creating a snippet, **When** they add multiple tags, **Then** all tags are associated with the snippet
2. **Given** a developer has created snippets with different tags, **When** they filter by a specific tag, **Then** only snippets with that tag are displayed
3. **Given** a developer is adding tags, **When** they enter a tag that already exists, **Then** the existing tag is reused (consistent tagging)
4. **Given** a developer creates a snippet without tags, **When** the snippet is saved, **Then** it is still accessible and usable

---

### User Story 4 - Control Visibility/Privacy (Priority: P2)

A developer wants to control who can view their snippet so they can keep sensitive code private or share useful snippets publicly.

**Why this priority**: Privacy controls are important for real-world usage where developers may handle proprietary or sensitive code. This is higher priority than tags because it directly impacts security and usability in professional settings.

**Independent Test**: Can be fully tested by creating snippets with different visibility settings (private, team-only, public), then verifying access permissions are correctly enforced for different users.

**Acceptance Scenarios**:

1. **Given** a developer is creating a snippet, **When** they set visibility to private, **Then** only they can view the snippet
2. **Given** a developer is creating a snippet, **When** they set visibility to team-only, **Then** only team members can view the snippet
3. **Given** a developer is creating a snippet, **When** they set visibility to public, **Then** anyone with access to the platform can view the snippet
4. **Given** a developer has not specified visibility, **When** the snippet is saved, **Then** it defaults to private for security
5. **Given** a developer tries to access another developer's private snippet, **When** they attempt to view it, **Then** access is denied

---

### Edge Cases

- What happens when a developer enters extremely long code content (e.g., thousands of lines)?
- How does the system handle unsupported or invalid syntax highlighting languages?
- What happens when a developer enters special characters or code that could be interpreted as HTML/scripts in the title or description?
- How does the system handle a very large number of tags on a single snippet?
- What happens when a developer tries to create a snippet without any code content?
- How does the system handle concurrent edits if a snippet is modified while being created?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow developers to create a new code snippet with text content
- **FR-002**: System MUST provide a selection of syntax highlighting languages for snippets
- **FR-003**: System MUST apply syntax highlighting based on the selected language when displaying snippets
- **FR-004**: System MUST allow developers to add a title to their snippet
- **FR-005**: System MUST allow developers to add a description to their snippet
- **FR-006**: System MUST allow developers to add one or more tags to categorize their snippet
- **FR-007**: System MUST allow developers to set visibility/privacy level for their snippet (private, team-only, public)
- **FR-008**: System MUST default snippet visibility to private if no visibility is specified
- **FR-009**: System MUST enforce privacy settings by preventing unauthorized access to private snippets
- **FR-010**: System MUST store all snippet data persistently
- **FR-011**: System MUST validate that code content is present before saving a snippet
- **FR-012**: System MUST sanitize user input in titles and descriptions to prevent XSS attacks
- **FR-013**: System MUST associate each snippet with the creating developer's account
- **FR-014**: System MUST support common programming language syntax highlighting including JavaScript, Python, Java, Go, Ruby, PHP, C, C++, C#, TypeScript, SQL, HTML, CSS, Shell/Bash, and Markdown at minimum

### Explicit Dependencies & Configuration *(mandatory)*

- **Dependency**: Syntax Highlighting Library - Purpose: Provides syntax highlighting for various programming languages. Configuration source: Application dependencies (e.g., npm/hex package). Validation strategy: Verify library loads and supports required languages at application startup. Tests that will fail without it: Any test attempting to render a snippet with syntax highlighting, language selection tests.
- **Dependency**: Authentication System - Purpose: Identifies the current developer to associate snippets with accounts and enforce privacy. Configuration source: Existing authentication system (`phx.gen.auth`). Validation strategy: Verify `current_scope` is available in LiveView/Controller. Tests that will fail without it: Snippet creation tests (no user to associate with), privacy enforcement tests.
- **Configuration**: Maximum Snippet Size - Default: 1MB of text content. Validation behaviour: Reject snippets exceeding size limit with user-friendly error message. How failures surface: Form validation error before submission, preventing data loss.
- **Configuration**: Maximum Tags Per Snippet - Default: 10 tags. Validation behaviour: Prevent adding more than maximum number of tags with informative message. How failures surface: UI prevents adding additional tags once limit reached.
- **Configuration**: Supported Languages List - Default: Common languages as specified in FR-014. Validation behaviour: Language dropdown only shows supported languages. How failures surface: Unsupported languages cannot be selected; if somehow submitted, validation error occurs.

### Key Entities

- **Snippet**: Represents a code snippet created by a developer. Key attributes include code content (text), syntax highlighting language, title (optional), description (optional), visibility/privacy level, creation timestamp, and last modified timestamp. Associated with a developer (creator).
- **Tag**: Represents a categorization label that can be applied to snippets. Key attributes include tag name. Relationship: Many-to-many with Snippets (a snippet can have multiple tags, a tag can be on multiple snippets).
- **Developer/User**: The creator and owner of snippets. Relationship: One-to-many with Snippets (a developer can create many snippets).

## Test Plan *(mandatory before implementation)*

### Unit Tests *(write these first)*

- Test snippet changeset validation with valid data (code content, language, title, description, tags, visibility)
- Test snippet changeset validation with missing required code content (should fail)
- Test snippet changeset validation with invalid language selection
- Test snippet changeset validation with visibility defaulting to private when not specified
- Test snippet changeset with XSS attempts in title/description (should be sanitized)
- Test snippet changeset with code content exceeding maximum size (should fail)
- Test snippet changeset with too many tags (should fail)
- Test tag creation and association with snippets
- Test snippet authorization logic for private snippets (owner can access, others cannot)
- Test snippet authorization logic for team-only snippets (team members can access, others cannot)
- Test snippet authorization logic for public snippets (anyone can access)

### Integration Tests *(required for each cross-boundary interaction)*

- LiveView test: Create a new snippet with all fields populated, verify it's saved to database
- LiveView test: Create a snippet with only required fields (code and language), verify defaults are applied
- LiveView test: Attempt to create a snippet without code content, verify validation error displays
- LiveView test: Create a snippet with multiple tags, verify all tags are saved
- LiveView test: Create a private snippet, verify another user cannot access it
- LiveView test: Create a public snippet, verify it's accessible to other users
- LiveView test: View a snippet with syntax highlighting, verify correct CSS classes are applied
- Database test: Verify snippet is correctly associated with creating user
- Database test: Verify many-to-many relationship between snippets and tags works correctly
- Form submission test: Submit snippet creation form with valid data, verify success response
- Form submission test: Submit snippet creation form with invalid data, verify error response and error messages display

## Failure Modes & Observability *(mandatory)*

- **Database connection failure during snippet creation**: User sees error message "Unable to save snippet at this time. Please try again." Event is logged with error level including user ID, timestamp, and database error details. Alert triggered if failure rate exceeds 1% over 5 minutes.
- **Syntax highlighting library fails to load**: Snippets display as plain text without highlighting. Warning logged on application startup. User sees notice that syntax highlighting is temporarily unavailable. Alert triggered on startup failure.
- **Invalid language selection submitted**: Validation prevents save and displays error "Selected language is not supported." Logged as warning with submitted language value and user ID.
- **Snippet content exceeds size limit**: Validation prevents save and displays error "Snippet content is too large. Maximum size is 1MB." Logged as info with user ID and attempted size.
- **XSS attempt in title/description**: Content is sanitized automatically. Security event logged with warning level including user ID, timestamp, and sanitized content for audit purposes. Alert triggered if multiple attempts from same user within short timeframe.
- **Privacy check failure (missing user context)**: Snippet creation/viewing fails with error "Authentication required." Logged as error with session details. Circuit breaker: If authentication system fails repeatedly, redirect to login page and display maintenance message.
- **Tag association failure**: Snippet is saved without tags and user sees warning "Snippet saved but some tags could not be applied." Logged as warning with snippet ID and failed tag details. User can retry adding tags later.

### Logging Strategy

- All snippet creation events logged at info level with user ID, snippet ID, language, visibility, and tag count
- Failed validation logged at warning level with validation errors and user ID
- Security events (XSS attempts, unauthorized access) logged at warning/error level with full audit trail
- Database errors logged at error level with full stack trace and context

### Trace Context

- Each snippet creation request assigned unique trace ID propagated through all operations
- Trace includes user ID, session ID, timestamp, and operation type
- Traces retained for 30 days for debugging and audit purposes

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Developers can create a basic code snippet (code + language) in under 30 seconds
- **SC-002**: Developers can create a fully detailed snippet (code, language, title, description, tags, visibility) in under 2 minutes
- **SC-003**: 95% of snippet creations succeed on first attempt without validation errors
- **SC-004**: Syntax highlighting renders correctly for all supported languages with visual distinction immediately visible to developers
- **SC-005**: Privacy settings are enforced with 100% accuracy (no unauthorized access to private snippets)
- **SC-006**: Zero XSS vulnerabilities in snippet titles, descriptions, or content
- **SC-007**: System handles snippets up to 1MB in size without performance degradation
- **SC-008**: 90% of developers successfully categorize their snippets using tags within their first 5 snippets created
