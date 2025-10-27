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

8. **Form Confidence Checklist**
   - Execute `mix test test/review_room_web/live/snippet_form_live_test.exs` to ensure the hero, helper text, aria-describedby chaining, and toast hook assertions pass.
   - Validate the LiveView manually: open `/snippets/new`, confirm `#snippet-form` references `aria-labelledby="snippet-form-hero-title"` and that `[data-role="field-helper"]` strings match the spec copy.
   - Trigger a flash message (e.g., `put_flash(:info, "Snippet saved with new design system styles.")`) and observe `#snippet-form-toast`: the `FormFeedbackToast` hook should auto-dismiss after ~4.2s unless reduced motion is enabled. In reduced-motion mode the toast should stay steady (no translateY) while still clearing via button or hook.
   - Verify clipboard interactions under `#snippet-share-toolbar`: success states surface emerald accents and errors use rose accents. Contrast ratios (text on backgrounds) stay ≥4.5:1 (e.g., `text-slate-900` on `bg-white` ≈ 12.6:1, `text-emerald-900` on `bg-emerald-50` ≈ 7.8:1).

9. **Finalize**
   - Run `mix precommit` to enforce constitution gates.
   - Capture screenshots or LazyHTML snapshots demonstrating redesigned states for review.

10. **Navigation Confidence Checklist**
    - Load `/s/:id` and verify `#app-navigation` highlights the `workspace` item with `aria-current="page"`.
    - Toggle reduced-motion preferences and confirm the workspace shell transitions respect `data-state` and `motion-safe` fallbacks.
    - Collapse empty timeline states by inspecting `#workspace-activity-empty[data-role="empty-state"]` and ensure it only displays when no activity entries exist.
    - Visit `/users/settings` and `/snippets/my` to confirm the new chrome renders the correct breadcrumbs, active nav state, and polished dashboard cards.
