# `dashboard`

A local, self-contained progress tracker. `dashboard` never talks to the
network and never asks the candidate anything — it reads whatever
`.certicoach/` state already exists for the active certification, fills the
template at `references/dashboard-template.html`, and writes the result to
`.certicoach/dashboard.html` so the candidate can open one file
and see where they stand without running any other command.

`dashboard` is strictly read-only on every `.certicoach/` file except the
one it writes. It never recomputes a signal another command owns — it
restates what `gaps`, `readiness-engine`, `spaced-repetition-engine`, and
`progress` have already written to state, in one glanceable page. If a
number isn't in state yet, `dashboard` says so plainly; it never estimates,
interpolates, or guesses a figure to avoid an empty slot. `dashboard` is
certification-agnostic — it renders identically for any exam, any provider,
any number of domains, because every value it plots comes from the shared
state schema, never from exam-specific logic.

---

## Inputs

`dashboard` takes no candidate input. It reads `.certicoach/index.md` and
selects the certification named by the `current:` field.

- If `.certicoach/index.md` does not exist, or `current:` is empty, or
  `current:` does not match any row in the `## Certifications` table,
  `dashboard` does not render anything. It tells the candidate plainly that
  there is no active certification yet and to run `discover` first — an
  empty or placeholder dashboard is never produced just to have output.
- Otherwise, `current:`'s row supplies `<cert-slug>`, `Name`, `Provider`,
  `Target date`, and `Status`, which seed the header slots in Rendering
  below.

---

## Rendering

`dashboard` reads the current cert's state files under
`.certicoach/<cert-slug>/` — whichever of `exam-facts.md`, `gap-analysis.md`,
`spaced-repetition.md`, `mistake-ledger.md`, `plan.md`, `progress-log.md`,
and `readiness.md` exist — then loads `references/dashboard-template.html`
and replaces each of its twelve `{{...}}` slots (see that file's `SLOTS:`
comment) with values derived from those files. A file that doesn't exist yet
(the candidate hasn't reached that stage) produces a labelled "not yet"
state for its slot(s), never a fabricated number, a zero standing in for
"unknown," or a silently blank cell.

The per-slot mapping:

- **`{{CERT_NAME}}`** ← `index.md`'s `Name` for `current:`'s row.
- **`{{PROVIDER}}`** ← `index.md`'s `Provider` for the same row (falls back
  to `exam-facts.md`'s `## Identity` → `Provider:` line if the index row
  predates that field).
- **`{{EXAM_DATE}}`** ← `index.md`'s `Target date`. If the date has already
  passed, append " (past — re-scope with `plan`)" rather than silently
  showing a stale date as if it were still upcoming.
- **`{{STATUS_WORD}}`** ← `index.md`'s `Status` (`active`, `paused`,
  `passed`, or `abandoned`), title-cased for display.
- **`{{UPDATED_TS}}`** ← today's date (YYYY-MM-DD), the moment this render
  ran — this is when the dashboard was generated, not a field copied from
  any state file.
- **`{{READINESS_PCT}}`** and **`{{READINESS_LINE}}`** ← `readiness.md`'s
  "Current verdict" section if that file exists and has a verdict recorded:
  `{{READINESS_PCT}}` is the average score across the mocks backing that
  verdict (from the "Attempt history" table), and `{{READINESS_LINE}}` is
  the verdict string verbatim — one of **Not ready**, **Nearly ready**,
  **Exam ready**, **Ready with specific risks**, exactly as
  `references/engines/readiness-engine.md` defines them — followed by the
  first line of the "Rationale" section. `dashboard` never writes a verdict
  word that isn't one of those four, and never invents one when
  `readiness.md` doesn't exist or has no "Current verdict" yet. When
  `readiness.md` is absent or verdict-less, `{{READINESS_PCT}}` is instead
  the mean "Current level" across `gap-analysis.md`'s domain rows and
  `{{READINESS_LINE}}` reads "Baseline (pre-mock) — average domain
  standing; run `mock` for a readiness verdict." so the candidate can never
  mistake this baseline figure for an engine-produced verdict. If neither
  `readiness.md` nor `gap-analysis.md` exists, both slots read "Not yet
  available — run `diagnose` and `gaps` to establish a baseline."
- **`{{DOMAIN_BARS}}`** ← `gap-analysis.md`'s `## Domain readiness` table,
  one `.domain-row` per row (per the template comment's markup), sorted by
  the `Priority` column descending (highest-priority-to-fix first). Each
  row's `{name}` is the `Domain` column and `{pct}` is the `Current level`
  column. A row whose `Current level` is critical (below 50%) or otherwise
  flagged `low` in `gap-analysis.md`'s ranked priorities gets
  `class="needs-work"` on `.bar-fill` and `class="needs-work-text"` on
  `.domain-pct` — the label text itself still states the percentage, so the
  distinction is never color-only. If `gap-analysis.md` doesn't exist yet,
  this slot is a single line: "No domain analysis yet — run `diagnose` then
  `gaps`."
- **`{{DUE_STREAK}}`** ← three `.stat` blocks (per the template's `.strip`
  grid): (1) items due today + overdue, from `spaced-repetition.md`'s
  `## Due today` table (count rows whose `Due` is today or earlier); (2)
  current streak + last active, from `progress-log.md`'s `## Streak`
  section; (3) the active plan week, from `plan.md`'s most recent
  `### Week N` heading matched against today's date range. Any of the three
  source files missing renders that one `.stat` as "not yet — run
  `<command>`" (naming `review`, `progress`, or `plan` respectively) while
  still rendering the other two from whatever state does exist.
- **`{{LEDGER}}`** ← `mistake-ledger.md`'s open rows (the top-level table,
  not `## Resolved`) as `<tr>` rows: `Question`, `Correct` mapped to a
  `status-open` cell reading "Open", and `Next review`. Rows are sorted by
  `Next review` ascending so the soonest-due mistake appears first. The
  `## Resolved` count is summarized as a caption line via
  `.ledger-summary`-style trailing text appended after the closing
  `</tbody>` markup — e.g. "12 resolved". If `mistake-ledger.md` doesn't
  exist or has no open rows, `{{LEDGER}}` is a single `<tr>` with a
  colspan-3 cell reading "No open mistakes yet."
- **`{{NEXT_ACTION}}`** ← the same recommendation `SKILL.md`'s Session
  Protocol step 3 would produce right now, evaluated over the same state in
  the same order (no `diagnostic.md` → `diagnose`; diagnostic without
  `gap-analysis.md`/`plan.md` → `gaps` then `plan`; overdue `mock` →
  `mock`; `spaced-repetition.md`/`mistake-ledger.md` items past due →
  `review`; target date passed with no result → re-scope the plan;
  otherwise the next `plan.md` week item's command). `dashboard` does not
  invent a different prioritization — it restates the orchestrator's own
  next-best-action logic so the candidate sees the same recommendation here
  as they would get by starting a session.
- **`{{OTHER_CERTS}}`** ← `index.md`'s `## Certifications` table rows other
  than `current:`, rendered as "Also tracking: <Name> (<Status>), ...". If
  there are no other rows, this slot is empty (the footer's other-certs
  line simply doesn't print anything extra).

---

## Outputs

`dashboard` writes exactly one file:

- **`.certicoach/dashboard.html`** — the filled template from
  `references/dashboard-template.html`, all twelve slots replaced per the
  mapping above. This file is user-local output, not tracked state read by
  any other command — `dashboard` overwrites it in full on every run rather
  than merging into a prior version.

`dashboard` does not write, append, or otherwise modify any other file
under `.certicoach/` — `index.md`, `exam-facts.md`, `gap-analysis.md`,
`spaced-repetition.md`, `mistake-ledger.md`, `plan.md`, `progress-log.md`,
and `readiness.md` are read-only inputs to this command.

After writing the file, `dashboard` prints the path
(`.certicoach/dashboard.html`) and how to open it, e.g.
`open .certicoach/dashboard.html` — the candidate's data never
leaves their machine; there is no server, no upload, and no external
network reference in the rendered page.
