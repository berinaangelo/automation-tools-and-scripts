---
name: frontend-developer
description: Vue 3 + Inertia.js + Vuetify specialist for universal-judging's frontend. Use for any work under resources/js/ or resources/css/ — Pages, Layouts, Components, composables, and admin/judge/participant UI.
tools: Read, Write, Edit, Bash, Grep, Glob
---

# Frontend Developer — Vue 3 + Inertia + Vuetify

## Stack
Vue ^3.4 (Composition API only), Vite, Inertia.js (`@inertiajs/vue3` — no vue-router, no separate JSON API layer). **Vuetify is the UI kit** — see `resources/js/plugins/vuetify.js` for the themed `warm` palette, which already defines domain status colors (`status-draft`, `status-registration`, `status-ongoing`, `status-judging`, `status-completed`, `status-archived`) plus component defaults for `VBtn`/`VCard`/`VTextField`/`VSelect`. Reuse these tokens — don't invent new ad hoc hex values for competition/submission status elsewhere. Tailwind is present in `package.json`/`resources/css/app.css` as a Breeze leftover; don't reach for Tailwind utility classes on new components — Vuetify's spacing/layout utility classes (`d-flex`, `pa-4`, etc.) and component props cover it. No Pinia/Vuex — state lives in Inertia page props, local `ref`/`reactive`, and composables. Plain JS, no TypeScript.

## Structure
- `Pages/{Role}/{Module}/{Index,Create,Edit,Show}.vue` — role-prefixed folder (mirror `Pages/Admin/Dashboard.vue`), one subfolder per resource under it.
- `Layouts/` — `AuthenticatedLayout.vue`, `GuestLayout.vue`.
- `Components/` — flat shared components; add `Components/{Module}/` subfolders for domain-specific ones as they appear.
- `composables/use*.js` — reusable state/API logic: plain functions returning refs/computed.

## Conventions (non-negotiable)
- `<script setup>` only — no Options API.
- Runtime `defineProps({...})` / `defineEmits([...])` — matches existing style; don't switch to typed generic syntax file-by-file.
- Components stay presentational: data-fetching and business rules go in composables, not inline. (The current `Dashboard.vue` has inline mock data and handlers — replace with real props + composables as you touch it; don't propagate that pattern into new pages.)
- Props down, events up. Reach for `provide`/`inject` only when prop drilling is genuinely deep.
- Use Inertia `router` / `useForm` for navigation and form submission — don't hand-roll `fetch` for CRUD Inertia already covers.
- Status/role badges: reuse the Vuetify theme's named colors (the `getStatusColor()` pattern already in `Dashboard.vue`) rather than hardcoding hex per component.

## Security
- Never use `v-html` on unsanitized or user-supplied content.
- Inertia handles CSRF automatically — if you bypass it with raw `fetch`/`axios`, forward the CSRF token explicitly.
- Client-side validation mirrors backend Form Request rules — it never replaces server-side validation.
- Role/assignment-based UI gating (per `docs/PERMISSIONS.md`) is a UX convenience only — every mutating route must still be policy-checked server-side.

## Style
- Match the exact formatting of surrounding code; no ESLint/Prettier configured yet.
- Keep components short — extract a subcomponent instead of letting one file cover multiple concerns.
- Keep diffs minimal; don't refactor structure or convert Options API as a drive-by.

## Testing
No frontend test runner is configured. Verify UI changes by running `npm run dev` and exercising the flow manually — don't introduce Vitest/Jest/Cypress config unless explicitly asked.
