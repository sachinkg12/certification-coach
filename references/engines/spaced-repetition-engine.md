# Spaced Repetition Engine

Schedules when a missed item or a weak area comes back for review, and
decides — on each review — whether that item earns a longer interval or
falls back to the start. A mistake corrected once in a session is not the
same as a mistake the candidate will still get right two weeks later
without the original context in front of them; this engine is what turns
"corrected once" into "verified durable," on a fixed cadence the candidate
can trust rather than an ad hoc "study more" instruction.

This engine does not decide *what* to teach or *how* to explain it — it
only decides *when* an already-identified item (a `mistake-ledger.md` row)
or an already-identified weak area (a domain or concept below mastery)
comes back up for review, and tracks whether it has survived enough
reviews to be considered durable. It does not classify answers itself;
whatever served the review question routes the candidate's answer through
`assessment-engine`'s `classify(answer)` first, and this engine only
consumes the resulting correct/incorrect verdict to decide the next
interval.

Produces two operations: `schedule(item, verdict)`, which advances or
resets an item's interval based on the outcome of its most recent review,
and `enqueue_weak_area(domain-or-concept)` / `dequeue_weak_area(...)`,
which manage membership in the weak-area queue. Both operations write to
`spaced-repetition.md` per `references/state-schema.md`'s template, and
`schedule(...)` also updates the `Next review` date on the corresponding
`mistake-ledger.md` row. Consumed by `review` as its due-today source of
truth, by `learn`/`quiz`/`mock` whenever they log a fresh miss to
`mistake-ledger.md` (a new row always enters this engine's schedule, never
a review cadence a command invents itself), and by `priority-engine`,
which reads the most-recent-successful-review dates this engine maintains
to compute `ForgettingRisk`. No command sets or advances a review date by
any logic other than what is described below.

---

## Schedule

### Cadence

Every scheduled item — a mistake-ledger row or a weak-area entry pulled
into active review — moves through four fixed intervals, in order:

| Step | Interval | Meaning |
|---|---|---|
| 1 | 1 day | First review after the miss (or after re-entering the schedule on a reset) |
| 2 | 3 days | Second review, only reached after a correct 1-day review |
| 3 | 7 days | Third review, only reached after a correct 3-day review |
| 4 | 14 days | Fourth review, only reached after a correct 7-day review |

An item's `Interval` and `Due` columns in `spaced-repetition.md`'s "Due
today" / "Upcoming" tables always reflect where it currently sits in this
sequence, and `Streak` counts consecutive correct reviews since the last
reset (0-4).

### Entering the schedule

An item enters the schedule the moment it is written to `mistake-ledger.md`
by `learn`, `quiz`, `mock`, or `review` itself: `schedule(item, verdict)`
runs immediately with `Interval = 1 day`, `Due = today + 1 day`, and
`Streak = 0`, and a matching row is added to `spaced-repetition.md`'s "Due
today" or "Upcoming" table (whichever the due date lands in) with `Type:
mistake`. The `mistake-ledger.md` row's `Next review` column is set to the
same date in the same write — the two files never disagree about when an
item is next due, because this engine is the only writer of both fields.

### Advancing on a correct review

When `review` (or any command surfacing a scheduled item) serves the
question and the candidate's answer classifies as correct (`knows`,
`partially understands`, or `guessed correctly` count as a correct
*review* outcome here, since the review's purpose is confirming the
answer lands, not re-running the full six-way diagnostic; `memorized
terminology` and worse do not count as correct and are handled under
"Resetting" below):

- `Streak` increments by 1.
- The item advances to the next step in the cadence table above (1d -> 3d
  -> 7d -> 14d). An item already at the 14-day step that passes its 14-day
  review has completed the full cadence — see "Exiting the schedule"
  below rather than looping back to 1 day.
- `Due` is recomputed as today + the new interval, and both
  `spaced-repetition.md`'s row and the corresponding `mistake-ledger.md`
  row's `Next review` column are updated to the new date in the same
  write.
- This review date also becomes the domain's new most-recent-successful-
  review date that `priority-engine`'s `ForgettingRisk` model reads —
  advancing an item's interval is itself the signal that pulls
  `ForgettingRisk` back down for that domain.

### Resetting on a miss

When a scheduled review comes back incorrect, or classifies as
`memorized terminology` (a correct answer that does not demonstrate
understanding is treated as a review failure here, the same way
`priority-engine`'s mastery mapping scores it below a true "knows"):

- `Streak` resets to 0.
- The item resets to `Interval = 1 day`, `Due = today + 1 day` — back to
  the start of the cadence, not the step before the one just missed. A
  miss at any point means the correction did not hold, so the schedule
  re-verifies from the beginning rather than assuming partial credit for
  the steps already passed.
- `spaced-repetition.md` and the `mistake-ledger.md` row's `Next review`
  are updated together, as above.
- The root cause on the `mistake-ledger.md` row is left as-is unless the
  review surfaces a different or more specific misconception than the one
  originally recorded, in which case the row is updated to reflect the
  sharper description — the schedule tracks the same underlying gap
  across resets, it does not spawn a duplicate row per reset.

### Exiting the schedule

An item exits active scheduling — and is eligible to move from
`mistake-ledger.md`'s open table to its `## Resolved` table — only after
it passes **four consecutive correct reviews**, one at each cadence step
in order (1d, then 3d, then 7d, then 14d), with no reset in between. This
is the `<n>` in the `## Resolved` table's `Confirmed by` field: `n = 4`,
always phrased as "4 consecutive correct reviews (1/3/7/14-day cadence)"
so a later reader can see exactly what was verified without recomputing
it. An item that resets at any step (say, it fails its 7-day review after
passing 1-day and 3-day) does not carry partial credit forward — its
streak returns to 0 and it must pass all four steps consecutively again
before it qualifies for resolution. When an item exits the schedule this
way, its row is removed from `spaced-repetition.md`'s active tables and
the matching `mistake-ledger.md` row moves to `## Resolved` with
`Resolved on` set to the date of the passing 14-day review.

---

## Weak-area queue

`spaced-repetition.md`'s "Weak-area queue" section is a second, coarser
review mechanism that runs alongside the per-item cadence above. Where the
cadence tracks individual missed *questions*, the weak-area queue tracks
*domains or concepts* the candidate has not yet demonstrated durable
mastery of — and unlike a scheduled item, a weak-area entry is reviewed on
every session `review` runs, regardless of interval, because the whole
point of flagging it is that it should not be allowed to go quiet on a
fixed schedule while still shaky.

### Entering the queue

A domain or concept enters the weak-area queue when either signal holds:

- **Repeated root cause.** Two or more open `mistake-ledger.md` rows share
  the same or closely related root cause (the same named misconception, or
  the same objective with a pattern of `cannot apply` misses) — a single
  miss is handled by the per-item cadence above, but a repeated pattern
  means the per-item cadence alone is not surfacing the concept often
  enough.
- **Elevated gap-analysis signal.** `gap-analysis.md` reports the domain
  at `Knowledge gap >= 0.5` (per `priority-engine`'s `KnowledgeGap`
  computation) combined with `Forgetting risk >= 0.5` — a domain both
  poorly known and fading, per `priority-engine`'s bands, is added
  regardless of whether any individual mistake-ledger row exists yet for
  it (this is how a domain that was diagnosed once and never revisited
  gets pulled back into rotation instead of silently aging out).

`enqueue_weak_area(...)` appends one line to `spaced-repetition.md`'s
"Weak-area queue" list naming the domain or concept and the reason it
qualified, so a later read explains why it's there without re-deriving
the signal.

### Leaving the queue

A domain or concept is removed from the weak-area queue (`dequeue_weak_area
(...)`) only when both hold:

- `gap-analysis.md`'s most recent computation shows `Knowledge gap < 0.5`
  for that domain, and
- every `mistake-ledger.md` row that contributed to the entry (the
  repeated-root-cause rows, if that was the trigger) has moved to
  `## Resolved` under the four-consecutive-correct-review rule above.

A domain does not leave the queue on a single good session — it leaves
once the underlying mastery signal and the per-item schedule both agree
the concept holds up, which is deliberately the same bar the per-item
cadence uses, applied at the domain level instead of the single-question
level.

---

## Provisional clearing vs. confirmed resolution

`adaptive-engine`'s remediation branch and this engine's schedule both
touch the same `mistake-ledger.md` rows, and they mean different things by
"cleared" — this is worth stating explicitly so the two never read as
contradictory.

- **Provisional clearing (in-session, `adaptive-engine`'s job).** When a
  candidate's remediation loop in `learn` produces a correct answer under
  a fresh scenario, `adaptive-engine` ends the remediation branch and logs
  the recovery in `plan.md`'s change log immediately. This is a real,
  useful signal — it means the correction landed in the moment — but it is
  a single data point taken under session conditions (the concept was just
  freshly re-taught minutes earlier). It does **not** by itself move the
  `mistake-ledger.md` row to `## Resolved`. Instead, the row it was
  originally logged against stays open, and its `Next review` date is
  whatever this engine already has scheduled (or, if the row was logged
  during this same session, it enters the schedule fresh at `Interval = 1
  day` per "Entering the schedule" above).
- **Confirmed resolution (long-term, this engine's job).** A
  `mistake-ledger.md` row only moves to `## Resolved` — with `Confirmed
  by` reading "4 consecutive correct reviews (1/3/7/14-day cadence)" —
  after it survives the full scheduled cadence described above, with no
  reset. Passing a 1-day review the day after remediation is one of the
  four required checkpoints, not the whole confirmation; a concept that
  looked cleared in-session but resets at the 7-day or 14-day mark was not
  actually durable, and the row correctly stays open until it passes the
  cadence again from the start.

In short: `adaptive-engine` decides when the *session* can stop dwelling on
a misconception; this engine decides when the *candidate's state* can
stop tracking it as a risk at all. The former is necessary to keep `learn`
moving — a session cannot productively remediate the same point forever —
but only the latter is sufficient to certify the gap closed, which is why
`priority-engine`'s `ForgettingRisk` and `gaps`' ranked priorities key off
this engine's review history and `## Resolved` table, never off
`adaptive-engine`'s in-session exit condition alone.
