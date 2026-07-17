# `readiness`

Module 12: the verdict on whether a candidate is ready to sit the exam.

`readiness` runs `readiness-engine`'s `verdict(history)` over the candidate's
full `readiness.md` attempt history — including all prior mock and quiz
attempts, the supporting signals recorded in each row (per-domain minimums,
unseen-question accuracy, time discipline, confidence calibration), and the
open misconceptions currently tracked in `mistake-ledger.md` — and reports
the single verdict that engine computes: one of four fixed strings, never a
judgment off a single mock attempt or a single metric.

`readiness` defers all verdict logic to `readiness-engine` and restates none
of its rules here. Every signal that informs the verdict (`average score
across mocks`, `score stability across days`, `per-domain minimums`,
`accuracy on unseen questions`, `confidence calibration`, `time per question`,
`hands-on performance`, `unresolved misconceptions`) is fully documented in
`references/engines/readiness-engine.md`'s "Signals" section, and every rule
that produces the four verdicts is documented there as well. This command's
job is to surface that verdict to the candidate and explain which signals
drove it, never to restate or recompute readiness logic.

---

## Behavior

**Sourcing the verdict.** `readiness` reads the candidate's `readiness.md`
file in full — every row in the "Attempt history" table — along with the
corresponding signals in `mistake-ledger.md` and `gap-analysis.md`, and
passes this history to `readiness-engine`'s `verdict(history)` function.
That engine evaluates all eight signals simultaneously (see
`readiness-engine.md` for the full signal set and the decision order), never
a single metric or attempt in isolation, and returns exactly one of four
fixed verdict strings.

**Verdicts.** The four possible verdicts are these exactly, verbatim:
- **Not ready** — The candidate does not yet meet the primary score/stability/domain bar. The core gates (number of passing mocks, average score, per-domain minimums, unseen-question accuracy, timing) have not been satisfied, or scores are still unstable. This is the default verdict whenever the primary criteria are genuinely unmet, regardless of strength in other dimensions.
- **Nearly ready** — The primary bar is close but not yet met, with no **Not ready** disqualifier: for example, 1-2 passing mocks trending upward, exactly one domain marginally below 70%, or unseen-question accuracy in the mid-70s rather than at 80%. The gap is specific and closeable.
- **Exam ready** — All five verdict rules are satisfied with no residual risk: 3+ passing mocks, all domains at or above 70%, unseen-question accuracy at or above 80%, all mocks within the time limit, and no critical misconception repeated across the last two assessments. This verdict requires multiple passing attempts, never springs from a single sitting.
- **Ready with specific risks** — Rules 1-4 are satisfied (score, domain floors, unseen accuracy, timing), but a named, bounded risk remains: a single domain below the candidate's others, persistent overconfidence in one area, or one misconception that resurfaced once but needs one more clean confirmation to close. This verdict names the residual risk explicitly so the candidate knows what to double-check before exam day, rather than silently dropping known gaps or overstating readiness.

**Transparency.** `readiness` reports not just the verdict but a signal-by-signal justification written to the "Rationale" section of `readiness.md`'s "Current verdict" block. Each signal that contributed to the decision is listed with concrete values (e.g., "3 passing mocks in last 10 days; average 82%; Domain X at 64%, below 70% minimum"), so the candidate understands exactly which facts drove the judgment. For **Ready with specific risks**, the "Risks" section lists each bounded residual threat by name and concrete observation (e.g., "Security domain: 71% vs. other domains' average 85%", "Overconfidence delta in Configuration Management: +0.8 vs. target ≤ 0.3").

---

## Outputs

`readiness` writes to one existing per-cert file — it does not introduce a
template of its own:

- **`.certicoach/<cert-slug>/readiness.md`** — `readiness` updates the
  "Current verdict" section (see `references/state-schema.md`'s
  `### readiness.md` template for the exact format):
  - `Verdict:` field is set to exactly one of the four fixed strings above.
  - `As of:` field is set to today's date (YYYY-MM-DD).
  - `Rationale:` section contains a bulleted list, one line per signal that
    informed the verdict, with concrete values drawn from the attempt history
    and mistake-ledger (e.g., "3 passing mocks, average score 81%", "All
    domains at or above 70% (lowest: Network Design at 73%)", "Unseen-question
    accuracy: 82% across 47 unique items").
  - `Risks:` section (present only if verdict is "Ready with specific risks")
    lists each residual threat: domain name + score vs. median, overconfidence
    delta in area X, or misconception name + count of open instances, enough
    to tell the candidate what to review before exam day.

`readiness` never modifies the "Attempt history" table or any prior rows —
the history is written by `mock` and `quiz` on attempt submission. Every call
to `readiness` recomputes the verdict over the same history; the "Current
verdict" section is the only part of `readiness.md` that changes on each run.
