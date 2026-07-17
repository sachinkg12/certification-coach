# `review`

Module 9: on-demand, spaced-repetition-driven recall of previously missed
items and weak areas. Where `learn` teaches new material and `quiz` assesses
standing under exam-like conditions, `review` asks a simpler question: *can the
candidate still answer this when time has passed?* Every item a candidate
reviews has been missed once already — `learn` logged it, `quiz` or another
session surfaced it — and `review` verifies the correction has durability,
on a fixed cadence the candidate can trust. A candidate who misses an item in
`learn` does not jump directly to mastery; they move from "just caught" to
"scheduled for verification," and `review` is the command that runs those
verifications in order.

`review` never schedules its own items and never scores its own answers. Item
scheduling is the sole job of `spaced-repetition-engine`, which tracks the
1/3/7/14-day cadence and decides when an item re-enters the candidate's
session (see `references/engines/spaced-repetition-engine.md` for the
authoritative schedule logic). Every question `review` serves comes from
`question-generator`'s generation, and every answer is classified by
`assessment-engine`'s `classify(answer)` — this file does not restate either
engine's rules; see `references/engines/question-generator.md` and
`references/engines/assessment-engine.md`. `review` is certification-agnostic:
the same review modes below run identically whether the candidate is reviewing
a security item or a project-scheduling item — nothing about mode selection,
question sourcing, or scheduling is hardcoded to a specific provider's
syllabus.

---

## Review modes

`review` supports five distinct modes for bringing scheduled items back into
active practice:

- **Spaced repetition (default)** — items due today, drawn from
  `spaced-repetition.md`'s "Due today" table, in the order the engine
  schedules them. The candidate sees each item's current interval (1/3/7/14
  days) and streak count so they understand where they stand in the cadence.
  This is the mode `review` runs when invoked without arguments or when
  recommended by the orchestrator based on `plan.md` and `gap-analysis.md`.
  Items answered correctly advance to the next interval; incorrect answers
  reset to 1 day. Scheduling is deferred entirely to `spaced-repetition-engine`
  — `review` does not restate schedule logic and does not apply its own cadence
  outside what the engine prescribes.

- **Flashcards** — a self-directed, low-friction mode optimized for recall
  drills on terminology and definitions. Every scheduled item appears as a
  concept-first flashcard (prompt on the front, answer on the back), with no
  scenario wrapper or extended reasoning required. The candidate sees the
  question, attempts recall, reveals the answer, and rates their confidence
  (1-5 scale). Correct answers per `assessment-engine`'s classification
  advance the interval; misses reset. This mode is useful when a scheduled
  item covers a concept the candidate needs to build fluency on without
  deeper scenario work.

- **Daily-five quick revision** — a rapid, fixed-size session on exactly five
  items pulled from the "Due today" or "Upcoming" queues, including weak-area
  entries if present. No scenario depth, fast pacing, light cognitive load —
  designed to fit into a candidate's active session even when time is short.
  Correctness and intervals follow the same rules as other modes, but this
  mode is low-friction by design, prioritizing consistency over depth.

- **Mistake-ledger review by due date** — browse open `mistake-ledger.md`
  rows filtered by their scheduled `Next review` date (due today, overdue,
  upcoming). The candidate can see the original miss, their prior reasoning,
  the correct answer, and the misconception or gap that was flagged. They
  re-answer the same question or a related one from
  `question-generator`, and correctness updates the scheduling and clears or
  extends the next review date. This mode surfaces the full context of what
  went wrong the first time, useful when a candidate wants to review the
  *narrative* of the mistake rather than just re-drill the concept.

- **Weak-area queue review** — items pulled from `spaced-repetition.md`'s
  "Weak-area queue" section, regardless of the 1/3/7/14-day interval. A domain
  or concept enters this queue when repeated misconceptions or elevated
  `gap-analysis` signals show it is still below mastery. Unlike the scheduled
  cadence, weak-area items come back *on every review session*, not on a fixed
  interval — the whole point is that it should not be allowed to go quiet
  while still shaky. Correctness on weak-area items does not automatically
  remove them from the queue; a domain leaves the queue only when both
  `gap-analysis` shows knowledge gap < 0.5 *and* every contributing
  mistake-ledger row has moved to `## Resolved` under the four-consecutive-
  correct rule, per `spaced-repetition-engine`'s contract.

---

## Outputs

`review` writes to two existing per-cert files — it does not introduce a
template of its own:

- **`.certicoach/<cert-slug>/spaced-repetition.md`** — every scheduled item
  reviewed updates its `Interval`, `Due`, and `Streak` columns per
  `spaced-repetition-engine`'s `schedule(item, verdict)` operation:
  - Correct review: `Streak` increments, `Interval` advances to the next step
    in the cadence (1d → 3d → 7d → 14d), and `Due` is recomputed as
    today + new interval. An item at the 14-day step that passes its review
    completes the cadence and exits active scheduling.
  - Incorrect review or `memorized terminology` classification: `Streak` resets
    to 0, `Interval` returns to 1 day, `Due` resets to today + 1 day.
  - Item removed from "Due today" / "Upcoming" tables only when it completes
    the full cadence (4 consecutive correct reviews at 1/3/7/14 days with no
    reset). Weak-area entries remain in the queue independently of this logic,
    subject to their own dequeue rules per `spaced-repetition-engine`.

- **`.certicoach/<cert-slug>/mistake-ledger.md`** — the `Next review` column
  is updated on every review by the same write that updates
  `spaced-repetition.md`, per `spaced-repetition-engine`'s contract. A row
  stays open (in the main table) for as long as it is scheduled for review,
  and moves to `## Resolved` table only after it passes four consecutive
  correct reviews (one at each cadence step: 1/3/7/14 days) with no reset in
  between. When a row resolves, it is removed from the main table, logged to
  `## Resolved` with the date of the passing 14-day review and the text
  "4 consecutive correct reviews (1/3/7/14-day cadence)" in the `Confirmed by`
  field, and `spaced-repetition-engine` is the sole arbiter of when that
  transition happens — `review` does not resolve items on a single pass or any
  logic other than what the engine prescribes.

`review` does not maintain a separate results file per session. Session-level
signals (accuracy per mode, time taken, confidence calibration) are reported
back to the candidate at session end for their own awareness, but are not
logged to a persistent results store — `gap-analysis.md` recomputes domain
standing from `question-attempts.md`, `mistake-ledger.md`, and `spaced-
repetition.md` the next time `gaps` runs if the candidate is concerned about
tracking domain-level progress across review sessions.
