# Quickstart – World-Class UI Redesign

1. **Review Design Tokens**
   - Open `assets/css/app.css` and confirm Tailwind `@import "tailwindcss"` directives remain intact.
   - Create/extend `assets/css/design-system.css` with new color, typography, spacing, and shadow tokens (match values captured in research).
   - Register DaisyUI custom theme in `app.css` using `@plugin` directives or CSS variables; avoid default DaisyUI palette.

2. **Plan Tests First**
   - For each LiveView (gallery, show, form), sketch new DOM IDs and states.
   - Add failing tests under `test/review_room_web/live/*.exs` asserting:
     - Presence of new layout sections and cards.
     - Accessibility via `assert_accessible/2` or equivalent helper.
     - Interaction feedback (hover classes, success toasts) using `render_hook`/`render_change`.

3. **Implement Shared Components**
   - Create `lib/review_room_web/components/design_system/` for tokens, navigation shell, cards, toasts, skeletons.
   - Reference components inside LiveViews; ensure templates remain wrapped with `<Layouts.app flash={@flash} current_scope={@current_scope}>`.

4. **Style Application**
   - Apply Tailwind + DaisyUI theme classes in HEEx templates, ensuring class lists use array syntax for conditional styling.
   - Introduce responsive layouts (grid/flex) matching spec breakpoints.
   - Add CSS transitions (180ms) and focus-visible states for keyboard navigation.

5. **Wire Micro-Interactions**
   - Add or update LiveView hooks in `assets/js/app.js` for clipboard success, filter panel toggles, and reduced-motion overrides.
   - Make sure hooks guard against duplicate DOM updates (`phx-update="ignore"` where appropriate).

6. **Gallery Visual Verification**
   - Use `ReviewRoomWeb.DesignSystemCase` helpers to snapshot `#gallery-hero`, `#gallery-filter-panel`, and `[data-role="gallery-card"]` so stats, overlay hooks, and metadata stay aligned with Spec 003.
   - Confirm `#gallery-layout-toggle` buttons flip `aria-pressed` states via the `"set_layout"` event and that `#gallery-stream` retains `phx-update="stream"` with responsive grid/list classes.
   - Manually toggle the filter panel (button `#gallery-filters-trigger`) to ensure the `FilterPanelToggle` hook honors the `data-open-classes` / `data-closed-classes` contract without DOM diff conflicts.

7. **Accessibility Verification**
   - Run tests to confirm color contrast tokens satisfy WCAG 2.1 AA (document ratios in tests or fixtures).
   - Validate reduced-motion preferences by toggling OS setting and confirming transitions disable gracefully.

8. **Finalize**
   - Run `mix precommit` to enforce constitution gates.
   - Capture screenshots or LazyHTML snapshots demonstrating redesigned states for review.
