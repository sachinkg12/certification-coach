# `learn`

Module 8: the adaptive teaching session itself — where a candidate actually
studies a domain, question by question, until the objectives on today's
`plan.md` item are either demonstrated or flagged for remediation. `learn`
runs against a specific week's objectives (`plan.md`'s `## Weeks` entry for
the current date), pulling material context from `resources.md` and writing
results back into `plan.md` and `mistake-ledger.md` as it goes, so a
candidate can stop mid-session and resume later without losing progress.

`learn` never runs its own teach-and-branch logic. Every question-answer
cycle in this command executes `adaptive-engine`'s `advance(session-state)`
loop start to finish — this file does not restate that state machine, its
six-step loop, or its remediation-branch triggers and exit condition; see
`references/engines/adaptive-engine.md` for the authoritative loop `learn`
runs underneath. `learn` is certification-agnostic: it drives the same loop
whether the current objective is a cloud IAM policy or a project-management
risk-register technique — nothing about the session flow is hardcoded to a
specific provider's syllabus.

---

## Teaching loop

`learn` opens a session by identifying the current objective(s) — the
active `plan.md` week's `Objectives covered` field for today's date, or the
specific objective the candidate names if they ask to work a topic outside
today's plan item. It then hands control to `adaptive-engine`'s
`advance(session-state)` loop and stays there, question after question,
until one of the loop's own stopping conditions is reached: the week's exit
criteria are met, the candidate stops the session, or an unresolved
misconception is carried over per the remediation branch's 5-cycle limit.
`learn` supplies the loop's inputs (objective, candidate answer, confidence
rating, `I guessed` flag, explanation) and displays the loop's outputs
(explanation, micro-lesson, next question) to the candidate — it does not
independently decide when to advance, when to branch into remediation, or
when a misconception has cleared, since all three of those decisions belong
to `adaptive-engine` alone.

**Auto-invoking `analogy-engine`.** Whenever the loop's step 3 (naming the
underlying misconception) or step 4 (the remedial micro-lesson) identifies
that a misconception is rooted in confused or abstract terminology — the
candidate is conflating two exam terms, or the concept itself is
non-concrete enough that a plain restatement is unlikely to land — `learn`
automatically calls `analogy-engine`'s `analogize(concept, exam_terms)`
before delivering that step's micro-lesson, rather than waiting for the
candidate to ask for one via `explain`. The returned three-part structure
(everyday-operations analogy, precise technical restatement, "where this
breaks down" caveat) is folded directly into the micro-lesson the loop
already produces — `learn` never skips the caveat or delivers the analogy's
first two parts without the third. This auto-invocation is silent to the
loop's own control flow: it changes what a micro-lesson contains, not
whether the loop advances or branches, which stays entirely governed by
`adaptive-engine`'s rules. Misconceptions that are not terminology-rooted
(e.g. `cannot apply` gaps with no confused term at their center) get the
loop's ordinary micro-lesson with no analogy attached — an analogy forced
onto a gap that has nothing to do with confused wording only adds an
unnecessary layer between the candidate and the missing skill.

Confidence rating and the `I guessed` flag are elicited from the candidate
on every answer, before the answer is passed to the loop, exactly as
`assessment-engine`'s `classify(answer)` requires — `learn` does not infer
confidence from response time or phrasing, and never skips asking because
the candidate answered quickly or looked certain.

---

## Outputs

`learn` does not write a template of its own — every write this command
produces happens as a side effect of the loop's step 6, per
`adaptive-engine.md`, into two existing files:

- **`.certicoach/<cert-slug>/mistake-ledger.md`** — a new row for every
  answer classified `has a misconception` or `cannot apply`, per the
  `mistake-ledger.md` template in `references/state-schema.md`: the
  question tagged `[GENERATED PRACTICE]`, the candidate's answer, the
  correct answer, the root cause named by the loop's step 3 (or "gap — no
  specific misconception" when nothing nameable applies), the exam
  objective, and `Next review` left for `spaced-repetition-engine`. When a
  carried-over or actively-tracked misconception later clears under a
  fresh scenario, `learn` records the resolution in the ledger's
  `## Resolved` table exactly as the remediation branch's exit condition
  specifies.
- **`.certicoach/<cert-slug>/plan.md`** — the active week's objective
  progresses toward its exit criteria whenever the loop's step 6 says so
  (a `knows` or `partially understands` answer on the current plan item's
  objective), and any remediation branch entered, exited, or carried over
  is logged in `## Plan change log` with the concrete reason the loop
  supplies (e.g. "remediation: auth-vs-authz misconception seen 3x
  consecutive," "remediation resolved: auth-vs-authz, 4 cycles, cleared on
  fresh scenario"). `learn` never hand-edits a week's fields directly —
  every change flows through the loop's own write rules.

Every question `learn` serves also produces the row `question-generator`
requires in `question-attempts.md` at serve time (per
`references/engines/question-generator.md`'s "record on serve" step) — this
is the question-generator's own output contract, not a separate write
`learn` performs, but it is what keeps a `learn` session's questions
correctly deduplicated against everything the candidate has already seen
across `quiz`, `mock`, and prior `learn` sessions.
