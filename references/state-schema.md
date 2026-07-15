# State Schema

Canonical file formats for `.certicoach/`, the per-user runtime state
directory written to the **user's working directory** (never inside the
installed skill). Every command that reads or writes state must conform to
these templates. Fields are additive across sessions — a command appends or
updates fields, never discards prior history unless a template explicitly
says "current only."

Content in these files must respect the three provenance tiers wherever a
line asserts a fact or presents practice content:

- `[OFFICIAL — source + date]`
- `[COMMUNITY — source]`
- `[GENERATED PRACTICE]`

Directory shape:

```
.certicoach/
  index.md
  <cert-slug>/
    exam-facts.md
    profile.md
    diagnostic.md
    gap-analysis.md
    plan.md
    resources.md
    mistake-ledger.md
    spaced-repetition.md
    question-attempts.md
    readiness.md
    progress-log.md
```

`<cert-slug>` is a lowercase, hyphenated identifier derived from the exam
name and provider (e.g. `google-generative-ai-leader`), unique within
`.certicoach/`. All per-cert files below live under one `<cert-slug>/`
directory per certification the user is preparing for.

---

### index.md

Registry of every certification the user has started preparing for, and
which one is active. Machine-parseable: the `current:` field and the table
rows are read by the orchestrator on every session load to select context
and to route the "next best action" recommendation.

```markdown
# CertiCoach Index

current: <cert-slug>

## Certifications

| Slug | Name | Provider | Target date | Status | Last session |
|---|---|---|---|---|---|
| <cert-slug> | <exam name> | <provider> | YYYY-MM-DD | active \| paused \| passed \| abandoned | YYYY-MM-DD |

## Notes

- <free-text notes about switching certs, retakes, or scheduling conflicts>
```

Field rules:

- `current:` must match exactly one `Slug` value in the table (or be empty
  if no cert has been discovered yet).
- `Status` is one of `active`, `paused`, `passed`, `abandoned` — set to
  `passed` by `postexam` on a confirmed pass, never inferred.
- `Last session` is updated by every command that writes state, not just
  session boundaries.

---

### exam-facts.md

Written by `discover`. Every factual line about the exam itself must end
with a provenance tag; unsourced facts are never persisted. The exam
version is tracked separately so version-awareness alerts can fire.

```markdown
# Exam Facts — <exam name> (<exam code>)

Exam version: <version identifier or syllabus revision, e.g. "v3 (2025-11)">
Last verified: YYYY-MM-DD

## Identity

- Exam code: <code> — [OFFICIAL — <url> — retrieved YYYY-MM-DD]
- Provider: <provider> — [OFFICIAL — <url> — retrieved YYYY-MM-DD]
- Status: active | retiring on YYYY-MM-DD | retired — [OFFICIAL — <url> — retrieved YYYY-MM-DD]

## Format

- Duration: <minutes> — [OFFICIAL — <url> — retrieved YYYY-MM-DD]
- Question count: <n> — [OFFICIAL — <url> — retrieved YYYY-MM-DD]
- Question types: <multiple choice, multi-select, performance-based, ...> — [OFFICIAL — <url> — retrieved YYYY-MM-DD]
- Delivery: online proctored | test center | both — [OFFICIAL — <url> — retrieved YYYY-MM-DD]

## Passing policy

- Passing score / policy: <scaled score, percentage, or scoring model> — [OFFICIAL — <url> — retrieved YYYY-MM-DD]

## Cost & logistics

- Cost: <amount + currency> — [OFFICIAL — <url> — retrieved YYYY-MM-DD]
- Renewal: <interval / recert requirement> — [OFFICIAL — <url> — retrieved YYYY-MM-DD]
- Prerequisites: <none | required certs/experience> — [OFFICIAL — <url> — retrieved YYYY-MM-DD]

## Syllabus / domains

| Domain | Weight | Objectives |
|---|---|---|
| <domain name> | <%> | <objective list> — [OFFICIAL — <url> — retrieved YYYY-MM-DD] |

## Recent changes

- <change description> — [OFFICIAL — <url> — retrieved YYYY-MM-DD]

## Community notes

- <clarifying detail not on the official page> — [COMMUNITY — <source>]
```

If web access is unavailable, `discover` (via `provenance-engine`) does not
write placeholder facts here — it asks the user to paste the official page
instead of leaving this file partially populated with guesses.

---

### profile.md

Written by `profile`. Captures the candidate relative to *this specific
certification*, not a generic resume.

```markdown
# Candidate Profile — <cert-slug>

Captured: YYYY-MM-DD

## Experience

- Experience with this platform/product: <none | months/years + context>
- Current role: <title / function>
- Recent hands-on tech used: <list>
- Prior certifications: <list, or none>

## Per-domain familiarity (self-reported, pre-diagnostic)

| Domain | Self-rated familiarity (1-5) | Notes |
|---|---|---|

## Constraints & preferences

- Hours available per week: <n>
- Learning style: <visual | reading | hands-on | mixed>
- Target exam date: YYYY-MM-DD
- Budget for materials: <amount + currency, or "none">
- Labs / cloud sandbox access: <yes/no + details>
- Goal: pass | master | interview-prep

## Notes

- <free-text context relevant to personalization>
```

---

### diagnostic.md

Written by `diagnose`, one entry per baseline attempt. Every answer records
a confidence rating and an explicit "I guessed" flag so `assessment-engine`
can compute the 6-way classification and confidence calibration later.

```markdown
# Diagnostic — <cert-slug>

## Attempt: YYYY-MM-DD

Domains covered: <list>

### Answers

| # | Domain | Question type | Confidence (1-5) | I guessed | Correct | Signal |
|---|---|---|---|---|---|---|
| 1 | <domain> | conceptual \| scenario \| hands-on | <1-5> | yes \| no | yes \| no | knows \| partially understands \| memorized terminology \| guessed correctly \| has a misconception \| cannot apply |

### Per-domain baseline

| Domain | Score | Signal summary |
|---|---|---|

### Notes

- <misconceptions surfaced, patterns worth flagging to gap-analysis>
```

The `Signal` column values are exactly the 6-way classification from
`assessment-engine`: knows, partially understands, memorized terminology,
guessed correctly, has a misconception, cannot apply. Confidence and
correctness together (not correctness alone) determine which signal
applies — e.g. correct + `I guessed: yes` maps to "guessed correctly," not
"knows."

---

### gap-analysis.md

Written by `gaps`, recomputed whenever diagnostic, quiz, or mock results
change a domain's standing. Priority is computed by `priority-engine`.

```markdown
# Gap Analysis — <cert-slug>

Computed: YYYY-MM-DD

## Domain readiness

| Domain | Exam weight | Current level | Knowledge gap | Forgetting risk | Priority | Last reviewed |
|---|---|---|---|---|---|---|
| <domain> | <%> | <0-100> | <0-1> | <0-1> | <ExamWeight x KnowledgeGap x ForgettingRisk> | YYYY-MM-DD |

## Ranked priorities

1. <domain> — <reason in concrete terms>
2. <domain> — <reason in concrete terms>

## Notes

- <explainability narrative for why priorities shifted since last computation>
```

---

### plan.md

Written by `plan`. Records the chosen path archetype and the current
week-by-week plan. Every week item is concrete — never a vague "study X for
3 days" line.

```markdown
# Study Plan — <cert-slug>

Archetype: fast-track | balanced | deep-mastery | weekend-only | experienced-professional | beginner
Chosen: YYYY-MM-DD
Target exam date: YYYY-MM-DD

## Weeks

### Week 1 (YYYY-MM-DD to YYYY-MM-DD)

- Objectives covered: <list mapped to exam-facts.md domains>
- What: <specific topics/tasks>
- Why: <link to gap-analysis priority>
- Material: <specific resource reference from resources.md>
- Hands-on: <specific lab/exercise>
- Revision: <specific spaced-repetition items due>
- Practice target: <n questions, target accuracy>
- Exit criteria: <measurable condition to advance>

## Plan change log

| Date | Change | Reason |
|---|---|---|
| YYYY-MM-DD | <what changed> | <concrete explainability narrative> |
```

---

### resources.md

Written by `resources`. A minimum-sufficient, version-matched set — not an
exhaustive list. Tags provenance on every entry (official vs. community vs.
generated where applicable).

```markdown
# Resources — <cert-slug>

Curated: YYYY-MM-DD
Exam version matched: <version identifier, must match exam-facts.md>

## Curated set

| Category | Title | Version match | Cost | Est. time | Difficulty | Domain coverage | Last updated | Role |
|---|---|---|---|---|---|---|---|---|
| official guide \| official docs \| official training \| books \| video \| labs \| community notes \| practice exams \| cheat sheets | <title> — [OFFICIAL — <url> — retrieved YYYY-MM-DD] or [COMMUNITY — <source>] | yes \| no \| unknown | <amount/free> | <hours> | beginner \| intermediate \| advanced | <domains> | YYYY-MM-DD | primary \| supplementary |

## Excluded / superseded

- <resource> — <reason excluded, e.g. version mismatch, overlaps primary pick>
```

---

### mistake-ledger.md

Written by `learn`, `quiz`, `mock`, and `review`. One row per missed or
flagged question. Columns are fixed: Question, User answer, Correct, Root
cause, Objective, Next review.

```markdown
# Mistake Ledger — <cert-slug>

| Question | User answer | Correct | Root cause | Objective | Next review (YYYY-MM-DD) |
|---|---|---|---|---|---|
| <question text or ref, [GENERATED PRACTICE] if applicable> | <what the user answered> | <the correct answer> | <misconception / gap named plainly> | <exam objective from exam-facts.md> | YYYY-MM-DD |
```

`Next review` is set by `spaced-repetition-engine` and updated every time
the item is reviewed (1/3/7/14-day schedule). A row is never deleted on
review — mark it resolved instead:

```markdown
## Resolved

| Question | Root cause | Resolved on | Confirmed by |
|---|---|---|---|
| <question text or ref> | <original root cause> | YYYY-MM-DD | <n> consecutive correct reviews |
```

---

### spaced-repetition.md

Written by `spaced-repetition-engine`, read by `review`. Tracks the review
queue independent of the mistake-ledger's per-item history so `review` can
answer "what's due today" in one pass.

```markdown
# Spaced Repetition Queue — <cert-slug>

Updated: YYYY-MM-DD

## Due today (YYYY-MM-DD)

| Item | Type | Domain | Interval | Due | Streak |
|---|---|---|---|---|---|
| <mistake-ledger ref or concept> | mistake \| weak-area \| flashcard | <domain> | 1d \| 3d \| 7d \| 14d | YYYY-MM-DD | <consecutive correct count> |

## Upcoming

| Item | Type | Domain | Due |
|---|---|---|---|

## Weak-area queue

- <domain/concept still below threshold, reviewed on every session regardless of interval>
```

---

### question-attempts.md

Written by every command that serves a question (`learn`, `quiz`, `mock`,
`lab`). Log of every question served, used for dedup and unseen-question
tracking (readiness-engine's accuracy-on-unseen-questions signal depends on
this file being complete).

```markdown
# Question Attempts — <cert-slug>

| Question ID | Domain | Type | Served in | Date | Label | Correct | Time taken (s) |
|---|---|---|---|---|---|---|---|
| <stable hash or slug> | <domain> | conceptual \| scenario \| hands-on | learn \| quiz \| mock \| lab | YYYY-MM-DD | [GENERATED PRACTICE] | yes \| no | <n> |
```

`Question ID` must be stable and unique so `question-generator` can dedupe
against this file before serving a new question. Every row's `Label` is
`[GENERATED PRACTICE]` — no other tier is valid here, since this file only
ever logs originally generated practice content, never real exam material.

---

### readiness.md

Written by `readiness-engine`, read by `readiness`. One row per mock/graded
attempt so the multi-signal verdict can be computed over a history, never
off a single score.

```markdown
# Readiness — <cert-slug>

## Attempt history

| Date | Type | Score | Unseen-question accuracy | Time vs. limit | Confidence calibration | Domain minimums met | Verdict |
|---|---|---|---|---|---|---|---|
| YYYY-MM-DD | mock \| quiz | <%> | <%> | <actual>/<limit> min | <calibration score, e.g. over/under-confident delta> | yes \| no | Not ready \| Nearly ready \| Exam ready \| Ready with specific risks |

## Current verdict

Verdict: Not ready | Nearly ready | Exam ready | Ready with specific risks
As of: YYYY-MM-DD

Rationale:
- <signal-by-signal justification, e.g. "3 passing mocks, but security domain at 64% (<70% minimum)">

## Risks (if "Ready with specific risks")

- <specific domain or misconception still unresolved>
```

---

### progress-log.md

Written after every session. Tracks continuity, streaks, and recovery from
missed plan items — this is what lets the orchestrator explain "why" the
plan changed and what happened since last time.

```markdown
# Progress Log — <cert-slug>

## Sessions

| Date | Commands run | Time spent (min) | Milestone | Notes |
|---|---|---|---|---|
| YYYY-MM-DD | <list> | <n> | <e.g. "Week 2 exit criteria met"> | <free text> |

## Streak

Current streak: <n> days
Longest streak: <n> days
Last active: YYYY-MM-DD

## Missed-plan recovery

| Missed item | Originally due | Recovery action | Recovered on |
|---|---|---|---|
| <plan.md week item> | YYYY-MM-DD | <what changed to compensate> | YYYY-MM-DD or in progress |
```
