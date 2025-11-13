# Feature Specification: Snippet Creation

**Feature Branch**: `001-snippet-creation`  
**Created**: 2025-11-13  
**Status**: Draft  
**Input**: User description: "Creating a Snippet

1. Create the new snippet for a developer
2. Add the syntax highlighting language to a snippet
3. Add the tags to a snippet
4. Set the visibility/privacy for a snippet
5. Add the title and description to a snippet"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Create Basic Snippet (Priority: P1)

A developer wants to save a code snippet for personal reference or sharing. They create a new snippet, paste their code, and save it to their collection.

**Why this priority**: This is the core functionality - without the ability to create a snippet, no other features can be used. This represents the MVP.

**Independent Test**: Can be fully tested by creating a new snippet with code content and verifying it is saved and retrievable, delivering immediate value for personal code storage.

**Acceptance Scenarios**:

1. **Given** a logged-in developer is on the snippet creation page, **When** they enter code content and click "Save", **Then** the snippet is created and they are redirected to view the snippet
2. **Given** a developer has created a snippet, **When** they navigate to their snippets list, **Then** the newly created snippet appears in the list
3. **Given** a developer tries to save a snippet without code content, **When** they click "Save", **Then** they see a validation error message

---

### User Story 2 - Add Syntax Highlighting (Priority: P2)

A developer wants their code snippet to be displayed with proper syntax highlighting for readability. They select the programming language from a dropdown when creating or editing a snippet.

**Why this priority**: Syntax highlighting significantly improves code readability and is a standard feature users expect, but snippets can still be useful without it.

**Independent Test**: Can be tested by creating a snippet, selecting a language (e.g., "Elixir"), saving it, and verifying the code displays with appropriate syntax highlighting when viewed.

**Acceptance Scenarios**:

1. **Given** a developer is creating a snippet, **When** they select a language from the syntax highlighting dropdown, **Then** the preview shows the code with appropriate syntax highlighting
2. **Given** a developer creates a snippet with a selected language, **When** they view the snippet later, **Then** the code displays with the correct syntax highlighting for that language
3. **Given** a developer doesn't select a language, **When** they save the snippet, **Then** the code is displayed without syntax highlighting (plain text)

---

### User Story 3 - Organize with Tags (Priority: P3)

A developer wants to organize their snippets by topics for easy retrieval. They add one or more tags (e.g., "authentication", "database", "testing") to a snippet during creation or editing.

**Why this priority**: Tags enable organization and discovery, but are not essential for basic snippet storage and retrieval.

**Independent Test**: Can be tested by creating a snippet, adding multiple tags, saving it, and verifying the snippet can be found by filtering or searching by those tags.

**Acceptance Scenarios**:

1. **Given** a developer is creating a snippet, **When** they add tags in the tags field (comma-separated or tag interface), **Then** the tags are associated with the snippet
2. **Given** a developer has created snippets with different tags, **When** they filter or search by a specific tag, **Then** only snippets with that tag are displayed
3. **Given** a developer views a snippet, **When** they click on a tag, **Then** they see all snippets with that tag

---

### User Story 4 - Set Snippet Visibility (Priority: P2)

A developer wants to control who can see their snippet. They choose from visibility options (e.g., "Private", "Public", "Unlisted") when creating or editing a snippet.

**Why this priority**: Privacy control is important for security-sensitive code and professional use, but less critical than basic creation functionality.

**Independent Test**: Can be tested by creating a snippet with "Private" visibility, attempting to access it from an incognito session or different account, and verifying access is denied.

**Acceptance Scenarios**:

1. **Given** a developer sets a snippet to "Private", **When** another user tries to access the snippet URL, **Then** they see an access denied message
2. **Given** a developer sets a snippet to "Public", **When** any user (logged in or not) accesses the snippet URL, **Then** they can view the snippet
3. **Given** a developer sets a snippet to "Unlisted", **When** someone has the direct URL, **Then** they can view the snippet, but it doesn't appear in public listings
4. **Given** a developer creates a snippet without explicitly setting visibility, **Then** it defaults to "Private"

---

### User Story 5 - Add Title and Description (Priority: P1)

A developer wants to give their snippet a descriptive title and optional description to make it easier to identify and understand its purpose. They enter these fields when creating or editing a snippet.

**Why this priority**: Title is essential for snippet identification and organization, making this a core P1 feature alongside basic creation.

**Independent Test**: Can be tested by creating a snippet with a title and description, saving it, and verifying both are displayed when viewing the snippet and in the snippets list.

**Acceptance Scenarios**:

1. **Given** a developer is creating a snippet, **When** they enter a title and description, **Then** both are saved with the snippet
2. **Given** a developer creates a snippet without a title, **When** they try to save, **Then** they see a validation error requiring a title
3. **Given** a developer creates a snippet without a description, **When** they save, **Then** the snippet is saved successfully (description is optional)
4. **Given** a developer views a snippet, **When** the page loads, **Then** the title appears as a heading and the description is displayed below it

---

### Edge Cases

- What happens when a developer tries to add an extremely long title (e.g., 1000+ characters)?
- How does the system handle snippets with very large code content (e.g., 1MB+ of code)?
- What happens when a developer enters special characters or HTML in the title or description?
- How does the system handle invalid or unsupported language selections?
- What happens when a developer tries to add duplicate tags to the same snippet?
- How does the system handle concurrent edits to the same snippet by the same user in different browser tabs?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST allow authenticated developers to create new code snippets
- **FR-002**: System MUST require a title for every snippet (minimum 1 character, maximum 200 characters)
- **FR-003**: System MUST allow developers to add optional description text to snippets (maximum 2000 characters)
- **FR-004**: System MUST require code content for every snippet (minimum 1 character, maximum 500KB)
- **FR-005**: System MUST provide a selection of programming languages for syntax highlighting
- **FR-006**: System MUST apply syntax highlighting to snippets based on selected language
- **FR-007**: System MUST allow snippets to be saved without a language selection (displayed as plain text)
- **FR-008**: System MUST allow developers to add multiple tags to a snippet
- **FR-009**: System MUST support tag-based filtering and searching of snippets
- **FR-010**: System MUST provide visibility options: Private (default), Public, and Unlisted
- **FR-011**: System MUST enforce visibility permissions when snippets are accessed
- **FR-012**: System MUST associate each snippet with the developer who created it
- **FR-013**: System MUST persist all snippet data (title, description, code, language, tags, visibility)
- **FR-014**: System MUST validate all input fields and provide clear error messages
- **FR-015**: System MUST sanitize user input to prevent XSS attacks in titles and descriptions
- **FR-016**: System MUST prevent unauthorized access to private snippets

### Explicit Dependencies & Configuration *(mandatory)*

- **Dependency**: Syntax Highlighting Library - Used to render code with appropriate syntax highlighting for multiple languages. Configuration includes the list of supported languages. Tests will fail without this dependency when attempting to view snippets with language selections. Validation: Verify library is loaded and language list is available on page load.

- **Configuration**: Maximum Snippet Size - Default: 500KB. Validation behavior: Reject snippets exceeding size limit with clear error message. Failures surface as validation errors on the creation form. No retries or circuit breakers needed as this is synchronous validation.

- **Configuration**: Supported Languages List - Default: Common programming languages (Elixir, JavaScript, Python, Ruby, Go, Rust, SQL, HTML, CSS, JSON, YAML, Markdown, etc.). Validation: Ensure list is loaded and available in language selector. Failures surface as empty dropdown or error message on page load.

### Key Entities

- **Snippet**: Represents a code snippet created by a developer. Key attributes: title (string, required, 1-200 chars), description (text, optional, max 2000 chars), code content (text, required, max 500KB), language (string, optional, from supported list), tags (list of strings), visibility (enum: private/public/unlisted, defaults to private), creator (reference to user), timestamps (created_at, updated_at).

- **Tag**: Represents a label for organizing snippets. Key attributes: name (string, unique). Relationships: Many-to-many with Snippets (a tag can be on many snippets, a snippet can have many tags).

## Test Plan *(mandatory before implementation)*

### Unit Tests *(write these first)*

- Test snippet creation with all required fields succeeds
- Test snippet creation without title fails with validation error
- Test snippet creation without code content fails with validation error
- Test snippet title length validation (max 200 characters)
- Test snippet description length validation (max 2000 characters)
- Test snippet code content size validation (max 500KB)
- Test default visibility is set to "Private" when not specified
- Test visibility can be set to "Public", "Private", or "Unlisted"
- Test tag association with snippets
- Test multiple tags can be added to a snippet
- Test language selection is persisted correctly
- Test snippet without language selection stores null/none value
- Test XSS sanitization in title field
- Test XSS sanitization in description field
- Test snippet ownership is set to authenticated user on creation

### Integration Tests *(required for each cross-boundary interaction)*

- Test complete snippet creation flow from form submission to database persistence
- Test snippet retrieval displays correct syntax highlighting based on language
- Test snippet visibility enforcement (private snippets not accessible to other users)
- Test public snippets are accessible to unauthenticated users
- Test unlisted snippets are accessible via direct URL only
- Test tag filtering returns correct snippets
- Test LiveView real-time validation feedback on form fields
- Test syntax highlighting library integration renders code correctly
- Test snippet list view displays all user snippets with correct metadata

## Failure Modes & Observability *(mandatory)*

- **Validation Failures**: When input validation fails (missing title, oversized content, etc.), log the validation error with user_id and field name. Display user-friendly error messages on the form. No retries needed as these are user input errors.

- **Database Persistence Failures**: When snippet save fails due to database issues, log error with full context (user_id, snippet data size, error message). Display generic error to user ("Unable to save snippet, please try again"). Implement timeout of 5 seconds for save operations.

- **Syntax Highlighting Library Load Failures**: When syntax highlighting library fails to load, log error with library version and load time. Degrade gracefully to plain text display with notice to user. Circuit breaker: After 3 consecutive failures, stop attempting to load library for 5 minutes.

- **Unauthorized Access Attempts**: When user attempts to access private snippet they don't own, log security event with user_id, snippet_id, and IP address. Return 404 (not 403) to avoid revealing snippet existence.

- **Oversized Content**: When user attempts to paste extremely large code (>500KB), provide real-time feedback before save attempt. Log attempts over 1MB as potential abuse with user_id and content size.

- **Observability**: All snippet creation events include trace context with user_id, snippet_id, visibility, language, tag count, and content size. Alert on: save failure rate >5% over 5 minutes, unauthorized access attempts >10 per user per hour, oversized content attempts >20 per hour system-wide.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Developers can create a basic snippet (code + title) in under 30 seconds
- **SC-002**: 95% of snippet creation attempts succeed on first try (excluding validation errors)
- **SC-003**: Syntax highlighting displays correctly for all supported languages within 1 second of page load
- **SC-004**: Private snippets are never accessible to unauthorized users (0% unauthorized access success rate)
- **SC-005**: Tag-based filtering returns results in under 2 seconds for collections up to 1000 snippets
- **SC-006**: 90% of developers successfully add tags to at least one snippet within their first 5 snippets created
- **SC-007**: System handles 100 concurrent snippet creation requests without degradation
- **SC-008**: Zero XSS vulnerabilities in title and description fields
