# CertiCoach `dashboard` — Design Spec (v0.2.0)

**Date:** 2026-07-16
**Status:** Approved for implementation planning
**Type:** New command added to the existing CertiCoach skill

## 1. Summary

Add a `dashboard` command that renders the user's *current* certification progress
into a self-contained, offline, local `dashboard.html` file the user opens in a
browser. It is a **snapshot view** of the `.certicoach/` state files — not a store
of record and not a live app. Regenerating it re-reads the state files, so nothing
is ever lost by regenerating.

Visual direction: **editorial / calm** — a big calm readiness number, strong
typographic hierarchy, generous whitespace, one restrained accent color, light +
dark. "Fancy but readable and simple."

Built by loading `frontend-design` (anti-generic, production-grade UI), `dataviz`
(accessible progress visuals, consistent light/dark), and `artifact-design`.

## 2. Goals & non-goals

**Goals**
- One-screen, scannable snapshot of readiness, what's due, streak, plan position, and the mistake ledger.
- Fully local and private: reads only `.certicoach/`, writes only `.certicoach/dashboard.html`; no data leaves the machine; no external network requests.
- Works offline in any modern browser; theme-aware; responsive.
- Every number traces to a state file; absent values are shown as absent, never faked.
- Additive and read-only on user state — cannot corrupt learning data.

**Non-goals**
- No live / auto-updating UI (a browser `file://` page can't live-read sibling files; that needs a companion server — deferred).
- No hosted/claude.ai artifact (would upload snapshot data — conflicts with privacy).
- No full multi-cert analytics view in v0.2.0 (render the current cert; list others by name only).
- No new persistent state files (the dashboard is disposable output).

## 3. Behavior

`dashboard` command:
1. Reads `.certicoach/index.md` to find the `current:` cert (if none, tells the user to run `discover` first).
2. Reads that cert's available state files: `exam-facts.md`, `gap-analysis.md`,
   `spaced-repetition.md`, `mistake-ledger.md`, `plan.md`, `progress-log.md`,
   `readiness.md` (any that exist).
3. Loads the shipped `references/dashboard-template.html`, injects the parsed values
   into its data slots, and writes the result to `.certicoach/dashboard.html`.
4. Tells the user the path and how to open it (e.g. `open .certicoach/dashboard.html`).
- Also auto-regenerated at session end (session-protocol addition) so it is current when the user next looks.
- On a cert with missing files (e.g. no `readiness.md` yet), the corresponding panel
  renders a labelled "not yet" state rather than a fabricated value.

## 4. The one screen (top → bottom)

1. **Header** — cert name · provider · exam date · one status word (readiness verdict if present, else "in progress") · "updated &lt;timestamp&gt;".
2. **Readiness hero** — the large calm number + a one-line summary. Before any mock, labelled *baseline (pre-mock)*, derived from diagnostic/gap levels; never shows "Exam ready" without the readiness-engine verdict.
3. **Domain bars** — the exam's domains, weighted, current level, sorted by priority; one accent + a restrained "needs-work" tone for critical domains. Never color-only — always labelled with name + %.
4. **Due & streak strip** — cards due/overdue today (count + short list) · study streak · week X of N.
5. **Mistake ledger** — open cards (with next-review dates) vs. resolved count.
6. **Next action** — the session-protocol recommendation.
7. **Footer** — "Generated from your local `.certicoach/` files · re-run `dashboard` to refresh · your data never leaves this machine."

## 5. Design system

- **Fonts:** system stack only, no web fonts (offline): refined serif for the big
  number/headings (`ui-serif, Georgia, …`), sans for body (`system-ui, …`),
  **tabular numerals** for figures.
- **Color:** neutral paper/ink base + ONE accent; state tones (critical / on-track)
  used sparingly and never as the only signal. Muted, low-saturation.
- **Theme:** light + dark via `prefers-color-scheme`, plus a `data-theme` override
  hook so a viewer toggle can win in both directions.
- **Layout:** generous whitespace, clear hierarchy, hairline dividers, flat simple
  bars (no decorative gradients/3D). Responsive; the page body never scrolls
  horizontally — any wide content scrolls inside its own `overflow-x:auto` container.
- **Accessibility:** sufficient contrast in both themes; information never conveyed
  by color alone.

## 6. Files

**Shipped (tracked):**
- `references/commands/dashboard.md` — the command (read state → fill template → write html).
- `references/dashboard-template.html` — the self-contained template with data slots.
- Modify `SKILL.md` — add `dashboard` to the `## Commands` table (now 17 commands) and a line in `## Session Protocol` for end-of-session regeneration.
- Modify `VERSIONS.md` — `## v0.2.0` entry.

**Not shipped (user-local, gitignored):** `.certicoach/dashboard.html` (regenerated output).

## 7. Anti-break safeguards (verification)

- **The existing harness is the gate.** Every change re-runs `verify/verify.sh`
  (required files/sections, cross-references, spec-coverage, forbidden strings).
- **New harness checks (this is how the dashboard specifically can't break the skill or go online):**
  - `references/dashboard-template.html` is **self-contained** — a check greps it for
    any external reference (`http://`, `https://`, `src=`, `href=`, `@import`,
    `cdn`) and fails on any match, guaranteeing offline/no-exfiltration behavior.
  - the template is present and non-empty; `dashboard.md` states it writes only under `.certicoach/`.
- **Additive + read-only on user state:** the command reads `.certicoach/` and writes
  only `dashboard.html`; it touches none of the 16 existing commands, 8 engines, or
  the state schema. Worst-case failure is a cosmetic dashboard, never data loss.
- **Fixture smoke test:** `verify/spec-checklist.md` gains a step — generate a
  dashboard against the golden fixture (a seeded `.certicoach/` for AWS SAA-C03) and
  confirm it opens and shows all panels with the seeded numbers, no external
  requests.
- **Same review discipline:** brainstorm → spec → plan → subagent implementation with
  two-stage per-task review + a final whole-branch review, shipped as `v0.2.0`.

## 8. Build order

1. `dashboard-template.html` (the design-heavy piece — built with `frontend-design` + `dataviz`) + the self-contained harness check.
2. `dashboard.md` command (state → template → output) + wiring into `SKILL.md` and `VERSIONS.md` + spec-coverage.
3. Fixture smoke test in `spec-checklist.md` + final verification.
