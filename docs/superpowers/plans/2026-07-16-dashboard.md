# CertiCoach `dashboard` (v0.2.0) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `dashboard` command that renders the current cert's `.certicoach/` state into a self-contained, offline, editorial-style local `dashboard.html`.

**Architecture:** Two new shipped files — `references/dashboard-template.html` (self-contained template with placeholder slots) and `references/commands/dashboard.md` (reads state → fills slots → writes `.certicoach/dashboard.html`). Wired into `SKILL.md` + `VERSIONS.md`. A new harness module proves the template is self-contained (no external URLs). Additive and read-only on user state.

**Tech Stack:** HTML/CSS/JS (inline, no external assets, no web fonts), markdown skill files, bash verification harness.

## Global Constraints

- The template `references/dashboard-template.html` must be **fully self-contained**: no `http://` or `https://` anywhere (no CDN scripts/styles/fonts/images). Inline all CSS/JS; embed any asset as a `data:` URI. This is what keeps the dashboard offline and non-exfiltrating; it is enforced by a harness check.
- Editorial/calm design per spec §5: system font stack only (refined serif headings, sans body, tabular numerals), neutral base + one accent, light+dark via `prefers-color-scheme` plus a `data-theme` override, generous whitespace, flat bars, responsive (body never scrolls horizontally; wide content scrolls in its own `overflow-x:auto` container), accessible contrast, never color-only.
- The command is **read-only on user state**: it reads `.certicoach/` and writes only `.certicoach/dashboard.html`. It must not modify any other `.certicoach/` file.
- Every rendered number traces to a state file; absent values render a labelled "not yet" state, never a fabricated number. Never shows a readiness verdict the readiness-engine didn't produce.
- No forbidden source-skill name (enforced via `verify/forbidden-encoded.txt`); no `TODO`/`TBD` literals in shipped files. Repo identity is Sachin Gupta <sachinkg12@gmail.com>; commit messages carry NO AI-attribution trailer; no `-c` overrides.
- `bash verify/verify.sh` must print `ALL CHECKS PASSED` (exit 0) at the end of every task.

---

## Task 1: Self-contained dashboard template + harness check

**Files:**
- Create: `references/dashboard-template.html`
- Create: `verify/self-contained-files.txt`
- Modify: `verify/verify.sh` (add the self-contained module), `verify/required-files.txt`, `verify/required-sections.tsv`, `verify/spec-coverage.tsv`

**Interfaces:**
- Produces: `references/dashboard-template.html` containing these exact placeholder slot tokens the command will replace: `{{CERT_NAME}}`, `{{PROVIDER}}`, `{{EXAM_DATE}}`, `{{STATUS_WORD}}`, `{{UPDATED_TS}}`, `{{READINESS_PCT}}`, `{{READINESS_LINE}}`, `{{DOMAIN_BARS}}`, `{{DUE_STREAK}}`, `{{LEDGER}}`, `{{NEXT_ACTION}}`, `{{OTHER_CERTS}}`. Later tasks rely on these token names.

- [ ] **Step 1: Load design skills.** Before writing any HTML, load `frontend-design` and `dataviz` and follow them (avoid generic AI aesthetics; accessible, theme-consistent visuals).

- [ ] **Step 2: Add the harness self-contained module.** In `verify/verify.sh`, add this block immediately before the final summary (`echo; if [ "$fail" -eq 0 ]...`):

```bash
echo "== self-contained files (no external URLs) =="
while IFS= read -r f; do
  [ -z "$f" ] && continue; case "$f" in \#*) continue;; esac
  if [ -f "$f" ] && grep -Eq 'https?://' "$f"; then
    bad "external URL in self-contained file: $f";
  else pass "self-contained: $f"; fi
done < verify/self-contained-files.txt
```

Create `verify/self-contained-files.txt`:
```
references/dashboard-template.html
```

- [ ] **Step 3: Add manifest rows (real TABs in .tsv).**
  - `verify/required-files.txt`: `references/dashboard-template.html`
  - `verify/required-sections.tsv`:
    - `references/dashboard-template.html	{{READINESS_PCT}}`
    - `references/dashboard-template.html	{{DOMAIN_BARS}}`
    - `references/dashboard-template.html	prefers-color-scheme`
  - `verify/spec-coverage.tsv`: `spec-dashboard-template	references/dashboard-template.html	self-contained editorial dashboard template`

- [ ] **Step 4: Run harness to verify it fails.**
Run: `bash verify/verify.sh`
Expected: FAIL — `references/dashboard-template.html` missing (required-files + required-sections), self-contained check skips the absent file.

- [ ] **Step 5: Author `references/dashboard-template.html`.** A single self-contained HTML file implementing the one-screen layout from spec §4 (header, readiness hero, domain bars, due & streak strip, mistake ledger, next action, footer) in the editorial/calm system (spec §5). Use the twelve `{{...}}` slot tokens above where dynamic content goes. Inline all CSS/JS; **no `http://`/`https://` anywhere**; system font stack only; light+dark via `prefers-color-scheme` + `:root[data-theme=...]` overrides; domain bars are labelled with name + % (not color-only); responsive with wide content in `overflow-x:auto`. Include a short `<!-- SLOTS: ... -->` comment listing the tokens for the command's reference. Seed the slots with neutral placeholder text so the raw template renders sensibly on its own.

- [ ] **Step 6: Run harness to verify it passes.**
Run: `bash verify/verify.sh`
Expected: `ALL CHECKS PASSED`, exit 0 (including `self-contained: references/dashboard-template.html`).

- [ ] **Step 7: Manually confirm no external refs.**
Run: `grep -nE 'https?://|@import|src=["'"'"']http|cdn' references/dashboard-template.html || echo "clean: fully self-contained"`
Expected: `clean: fully self-contained`.

- [ ] **Step 8: Commit.**
```bash
git add references/dashboard-template.html verify/
git commit -m "feat: add self-contained editorial dashboard template + harness self-contained check"
```

---

## Task 2: `dashboard` command + wiring

**Files:**
- Create: `references/commands/dashboard.md`
- Modify: `SKILL.md` (commands table + session protocol), `VERSIONS.md`
- Modify: `verify/required-files.txt`, `verify/required-sections.tsv`, `verify/crossref.tsv`, `verify/spec-coverage.tsv`

**Interfaces:**
- Consumes: `references/dashboard-template.html` (the twelve slot tokens from Task 1); the `.certicoach/` state schema.
- Produces: user-local `.certicoach/dashboard.html` (gitignored; not a tracked file).

- [ ] **Step 1: Add manifest rows (real TABs in .tsv).**
  - `verify/required-files.txt`: `references/commands/dashboard.md`
  - `verify/required-sections.tsv`:
    - `references/commands/dashboard.md	## Inputs`
    - `references/commands/dashboard.md	## Rendering`
    - `references/commands/dashboard.md	## Outputs`
    - `SKILL.md	dashboard`
    - `VERSIONS.md	## v0.2.0`
  - `verify/crossref.tsv`: `references/commands/dashboard.md	dashboard-template`
  - `verify/spec-coverage.tsv`: `spec-5-dashboard	references/commands/dashboard.md	dashboard command (local progress tracker)`

- [ ] **Step 2: Run harness to verify it fails.**
Run: `bash verify/verify.sh`
Expected: FAIL — `dashboard.md` missing; `SKILL.md` lacks `dashboard`; `VERSIONS.md` lacks `## v0.2.0`; crossref pending.

- [ ] **Step 3: Author `references/commands/dashboard.md`.** Sections:
  - `## Inputs`: read `.certicoach/index.md`; select the `current:` cert; if none, instruct the user to run `discover` first (do not render an empty dashboard).
  - `## Rendering`: read the current cert's available state files (`exam-facts.md`, `gap-analysis.md`, `spaced-repetition.md`, `mistake-ledger.md`, `plan.md`, `progress-log.md`, `readiness.md`); load `references/dashboard-template.html`; replace each `{{...}}` slot with values derived from those files. Spell out the mapping per slot (e.g. `{{DOMAIN_BARS}}` ← gap-analysis rows sorted by priority; `{{DUE_STREAK}}` ← spaced-repetition due dates + progress-log streak; `{{READINESS_PCT}}`/`{{READINESS_LINE}}` ← readiness.md verdict if present, else a labelled *baseline (pre-mock)* from gap-analysis; `{{NEXT_ACTION}}` ← session-protocol recommendation; `{{OTHER_CERTS}}` ← other index.md rows by name). Absent files → labelled "not yet" state, never a fabricated number. State explicitly it must NOT declare a readiness verdict the readiness-engine didn't produce.
  - `## Outputs`: write the filled HTML to `.certicoach/dashboard.html` (read-only on all other state); print the path and how to open it (e.g. `open .certicoach/dashboard.html`).
- [ ] **Step 4: Wire into `SKILL.md`.** Add a `dashboard` row to the `## Commands` table (purpose + `references/commands/dashboard.md`); add one line to `## Session Protocol` that the dashboard is regenerated at session end so it is current next time.
- [ ] **Step 5: Add `VERSIONS.md` entry** — a `## v0.2.0` section noting the new `dashboard` command (local, self-contained progress tracker).

- [ ] **Step 6: Run harness to verify it passes.**
Run: `bash verify/verify.sh`
Expected: `ALL CHECKS PASSED`, exit 0.

- [ ] **Step 7: Commit.**
```bash
git add references/commands/dashboard.md SKILL.md VERSIONS.md verify/
git commit -m "feat: add dashboard command (module) + wire into orchestrator, bump v0.2.0"
```

---

## Task 3: Fixture smoke test + live end-to-end verification

**Files:**
- Modify: `verify/spec-checklist.md`

- [ ] **Step 1: Add a dashboard smoke-test step to `verify/spec-checklist.md`.** A checkbox block: given a seeded `.certicoach/` for the golden fixture (AWS SAA-C03), running `dashboard` produces `.certicoach/dashboard.html` that (a) opens in a browser, (b) shows all panels (header, readiness hero, domain bars, due & streak, ledger, next action, footer) populated from the seeded numbers, (c) contains no `http(s)://` (self-contained), and (d) did not modify any other `.certicoach/` file.

- [ ] **Step 2: Run the full harness.**
Run: `bash verify/verify.sh`
Expected: `ALL CHECKS PASSED`, exit 0, with the `self-contained` and `spec-5-dashboard`/`spec-dashboard-template` rows passing.

- [ ] **Step 3: Live end-to-end smoke test (real state, not committed).** With the existing `.certicoach/google-generative-ai-leader/` state present, follow `dashboard.md` to generate `.certicoach/dashboard.html`; confirm it renders the four Gen AI Leader domains, the 3 due cards, the week-1 plan position, and contains no external URL (`grep -c 'https\?://' .certicoach/dashboard.html` → 0). This file is gitignored — do not commit it.

- [ ] **Step 4: Commit.**
```bash
git add verify/spec-checklist.md
git commit -m "test: add dashboard fixture smoke test to spec checklist"
```

---

## Self-Review (completed by plan author)

**1. Spec coverage:** §3 behavior → Task 2 (`## Inputs`/`## Rendering`/`## Outputs`); §4 one-screen panels → Task 1 (template) + Task 2 (slot mapping); §5 design system → Task 1 (constraints + skills); §6 files → Tasks 1–2; §7 anti-break safeguards → the self-contained harness module (Task 1), additive/read-only design (Task 2), fixture smoke test (Task 3); §8 build order → Tasks 1→2→3.

**2. Placeholder scan:** No TODO/TBD in shipped files (harness forbids them). The `{{...}}` slot tokens are intentional template markers, not placeholders-to-fill-in-the-plan; their names are fixed in Task 1's Interfaces and reused verbatim in Task 2.

**3. Type consistency:** The twelve slot tokens defined in Task 1 are the exact names Task 2 fills; `references/dashboard-template.html` and the `dashboard-template` crossref token match; `spec-5-dashboard` / `spec-dashboard-template` coverage ids are distinct and each map to a real file.
