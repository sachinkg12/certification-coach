# `gaps`

Module 4: the domain-level readiness report. `gaps` turns the raw signals
sitting in `exam-facts.md` (what the exam weighs) and `diagnostic.md` (what
the candidate currently knows, and how long ago they last proved it) into
one ranked answer to "what should I study next, and why." Nothing else in
CertiCoach produces a domain ranking — `plan` sizes its weeks against this
report, `review` reads its ranked list to decide what the weak-area queue
surfaces first, and `progress` explains plan changes by pointing back at how
this report shifted since it was last computed.

`gaps` never invents its own way of scoring a domain. Every `Priority`
number in `gap-analysis.md` is produced by calling `priority-engine`'s
`priority(domain)` operation — `gaps` supplies the per-domain inputs
(`ExamWeight` from `exam-facts.md`, the diagnostic/quiz/mock history that
`KnowledgeGap` is derived from, the most-recent-successful-review date that
`ForgettingRisk` is derived from) and reports back exactly what the engine
returns. `gaps` is certification-agnostic: it runs identically over three
exam domains or twelve, and over a candidate who is uniformly weak or
uniformly strong — nothing about the table shape or the ranking logic is
hardcoded to a specific provider or exam.

`gaps` is recomputed, not just computed once: any command that changes a
domain's standing — a new `diagnose` attempt, a `quiz` or `mock` result, a
resolved row in `mistake-ledger.md`, a review logged in
`spaced-repetition.md` — makes the existing `gap-analysis.md` stale, and the
next time `gaps` runs it recomputes the full table from current state rather
than patching individual rows by hand.

---

## Readiness table

`gaps` builds one row per domain listed in `exam-facts.md`'s "Syllabus /
domains" table — every domain the exam covers, never a subset chosen
because it looks more urgent; a domain the candidate has fully mastered
still gets a row, since a readiness report that omits solved domains can't
be trusted to have checked them. For each domain, `gaps` reports:

- **Exam weight** — the domain's published weighting from `exam-facts.md`,
  as a percentage. If `exam-facts.md` has no weight for a domain (the
  provider hasn't published one), `gaps` records `unweighted` in this
  column rather than guessing a share, matching `priority-engine`'s
  `ExamWeight: unweighted` flag for that domain.
- **Current level** — a `0-100` score derived from the domain's most recent
  signals in `diagnostic.md` (and any later `quiz`/`mock` results for that
  domain), read as `CurrentMastery × 100` using the same per-item mastery
  mapping `priority-engine` uses for `KnowledgeGap` — this keeps "current
  level" and "knowledge gap" two views of the same underlying number rather
  than two independently-eyeballed estimates that could disagree. A domain
  with no answered items yet (never diagnosed) is reported as `0`, per
  `priority-engine`'s rule that an un-diagnosed domain is never assumed
  known.
- **Priority** — the domain's `priority(domain)` value from
  `priority-engine`, computed as described in `## Priority computation`
  below.

This is the spec's headline view: a single table a candidate can scan —
`Domain | Exam weight | Current level | Priority` — to see at a glance
which domains carry real exam weight, which ones the candidate has actually
demonstrated mastery on (not just self-rated highly in `profile.md`), and
which ones the priority score says deserve the next study session. `gaps`
never reorders this table by priority on its own — the table stays in
`exam-facts.md`'s domain order so it can be scanned against the syllabus
directly; ranking is what the `Ranked priorities` output section is for.

---

## Priority computation

For every domain, `gaps` calls `priority-engine`'s `priority(domain)`
operation with that domain's three inputs and records exactly the value
returned — `gaps` does not re-derive `Priority = ExamWeight × KnowledgeGap
× ForgettingRisk` itself, does not round or adjust the engine's output, and
never substitutes a domain's `Current level` score for its `Priority`
directly (the two differ by design: `ForgettingRisk` can push a
recently-strong domain back up, and `ExamWeight` can pull a weak-but-minor
domain back down). See `priority-engine.md` for the formula, the
`ExamWeight` / `KnowledgeGap` / `ForgettingRisk` definitions, the
forgetting-risk decay bands, and the worked example this section relies on
rather than restates.

The result is that `Priority` reflects **both** weakness and exam weight at
once, never either alone. A domain the candidate is weak in but that the
exam barely tests stays low-priority, because time spent mastering it
returns little exam-day value; a domain the candidate is weak in *and* the
exam weights heavily out-ranks every other weak domain, even one with a
worse raw score, because that is where study time returns the most exam-day
value per hour spent. `gaps` surfaces this explicitly in `## Notes` and
`## Ranked priorities` rather than leaving the candidate to infer it from
three separate numbers — e.g. "Security ranks above Networking despite a
similar knowledge gap because Security is worth three times the exam
weight," echoing `priority-engine`'s own worked example.

Domains `priority-engine` flags `ExamWeight: unweighted` are reported
separately from the ranked list rather than given a numeric `Priority` that
would look precise but isn't — `gaps` lists them in `## Notes` as domains
whose priority cannot be computed until the provider publishes a weighting,
so the candidate knows to keep studying them by `Current level` alone in
the meantime rather than assuming a missing rank means "safe to skip."

---

## Outputs

`gaps` writes exactly one thing, conforming byte-for-byte to the
`gap-analysis.md` template in `state-schema.md`:

**`.certicoach/<cert-slug>/gap-analysis.md`** — fully recomputed (not
appended to) each time `gaps` runs, since the report is a snapshot of
current standing rather than a history:

- **Headline** — `Computed: YYYY-MM-DD`, today's date.
- **`## Domain readiness`** table — one row per domain, columns `Domain`,
  `Exam weight`, `Current level`, `Knowledge gap`, `Forgetting risk`,
  `Priority`, `Last reviewed`, matching the `## Readiness table` contents
  above plus the two `priority-engine` intermediate values
  (`KnowledgeGap`, `ForgettingRisk`) and the most-recent-successful-review
  date that `ForgettingRisk` was derived from, so the row is
  self-explanatory without cross-referencing `diagnostic.md` by hand.
- **`## Ranked priorities`** — every domain with a computed (non-unweighted)
  `Priority`, ordered highest to lowest, each line naming the domain and a
  concrete reason drawn from its `ExamWeight`, `KnowledgeGap`, and
  `ForgettingRisk` values (e.g. "Security — 30% of the exam, mostly 'cannot
  apply' signals, last reviewed 20 days ago") rather than the number alone.
- **`## Notes`** — the explainability narrative for how priorities shifted
  since the previous `gap-analysis.md` (a domain that dropped after a
  strong `quiz` result, one that rose because it drifted past its
  `spaced-repetition.md` due date), plus any `unweighted` domains excluded
  from the ranked list per `## Priority computation` above.
