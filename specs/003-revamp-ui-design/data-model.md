# Data Model – World-Class UI Redesign

## Visual Design System

- **Purpose**: Centralize color palette, typography scale, spacing, elevation, and motion guidelines consumed by LiveView components.
- **Attributes**:
  - `color.primary`, `color.accent`, `color.surface`, `color.background`, `color.danger`, `color.success` (WCAG 2.1 AA compliant).
  - `typography.display`, `typography.headline`, `typography.body`, `typography.label`, `typography.code` (font family, size, weight, line-height).
  - `spacing.scale` (4px increments, derived 8px rhythm), `radius.scale`, `shadow.elevation`.
  - `motion.fast`, `motion.standard`, `motion.emphasis` (timing + easing curves).
- **Relationships**: Referenced by UI Component Library tokens and Tailwind/DaisyUI theme extensions.

## UI Component Library

- **Purpose**: Shared presentational primitives for navigation, cards, forms, alerts, loaders, and skeletons.
- **Components**:
  - `Shell.Navbar` (slots: brand, primary actions, user menu).
  - `Shell.Sidebar` (sections: navigation groups, active state indicator).
  - `Gallery.Card` (fields: snippet title, language, visibility badge, owner, updated_at, interaction CTA).
  - `Form.Field` (fields: label, helper_text, control, validation_state).
  - `Feedback.Toast` / `Feedback.Alert` (variants: success, info, warning, danger).
  - `Skeleton.Loader` (variants for cards, text blocks, forms).
- **Relationships**: Components consume Visual Design System tokens; LiveViews compose components to render scenarios.

## User-Facing LiveViews

- **SnippetGalleryLive**:
  - Streams snippet summaries.
  - Consumes `Gallery.Card`, `Skeleton.Loader`, global filters panel.
  - State flags: `filters_open?`, `loading?`, `layout_view` (grid/list).
- **SnippetFormLive**:
  - Manages create/edit flows with `Form.Field` components.
  - Tracks `changeset`, `submitting?`, `show_visibility_modal?`.
- **SnippetShowLive**:
  - Displays real-time snippet with presence indicators, action bar.
  - Integrates `Feedback.Toast` for clipboard status.

## Accessibility Metadata

- **Purpose**: Ensure color and motion choices meet accessibility goals.
- **Attributes**:
  - `contrast_ratios` mapping (foreground/background pairs with numeric ratios).
  - `reduced_motion_overrides` toggling transition durations to 0 for users preferring reduced motion.
- **Relationships**: Applied via CSS custom properties and LiveView assigns to conditionally update classes.
