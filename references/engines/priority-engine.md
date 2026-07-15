# Priority Engine

Ranks every exam domain by how urgently it deserves study time right now.
A raw weak-area list is not enough — a domain the candidate is weak in but
that barely appears on the exam should not out-rank a domain the candidate
is weak in that the exam weights heavily, and a domain the candidate once
knew but has not touched in weeks needs a nudge even if their last
recorded score there was high. This engine exists to fold exam weighting,
current mastery, and memory decay into one comparable number so `gaps` can
produce a ranked list instead of three separate tables the candidate has
to reconcile by eye.

Produces the operation `priority(domain)`. Consumed by `gaps` (Task 10) to
populate the `Knowledge gap`, `Forgetting risk`, and `Priority` columns and
the `Ranked priorities` list in `gap-analysis.md`. No command computes a
domain ranking by any other formula — every priority number written to
state routes through this engine.

---

## Formula

```
Priority = ExamWeight × KnowledgeGap × ForgettingRisk
```

All three factors are normalized to the `0-1` range, so `Priority` itself
falls in `0-1` (an ExamWeight of `1.0` — a domain worth 100% of the exam,
which never happens in practice — combined with total ignorance and
maximum decay is the only way to reach `1.0`). Multiplying rather than
adding is deliberate: a domain scores high priority only when it is
*both* heavily examined *and* poorly known (or fading), not when either
factor alone is large. A domain the candidate has fully mastered
(`KnowledgeGap = 0`) contributes `0` priority regardless of exam weight,
because further review time there is wasted. A domain barely covered on
the exam (`ExamWeight` near `0`) stays near-`0` priority even at total
ignorance, because time spent mastering it returns little exam-day value.

### ExamWeight

The domain's exam weighting as published in `exam-facts.md`'s "Syllabus /
domains" table, normalized from a percentage to `0-1` (a domain weighted
`25%` of the exam is `ExamWeight = 0.25`). This value only ever comes from
an `[OFFICIAL — source + date]`-tagged fact per `provenance-engine`; if a
domain's weight is not yet known (unpublished or ungraded by the
provider), the engine does not guess a share — it flags the domain as
`ExamWeight: unweighted` and `gaps` reports it separately rather than
computing a numeric priority that looks precise but isn't.

### KnowledgeGap

```
KnowledgeGap = 1 - CurrentMastery
```

`CurrentMastery` (`0-1`) is derived from the most recent per-domain
signals recorded in `diagnostic.md` (and any later quiz/mock results for
that domain), using `assessment-engine`'s six-way classification as the
input rather than raw correctness — a domain scored entirely "guessed
correctly" and a domain scored entirely "knows" can share the same raw
accuracy but must not share the same mastery estimate. Map each answered
item's `Signal` to a per-item mastery value, then average across the
domain's answered items:

| Signal | Per-item mastery |
|---|---|
| knows | 1.0 |
| partially understands | 0.6 |
| memorized terminology | 0.4 |
| guessed correctly | 0.2 |
| has a misconception | 0.1 |
| cannot apply | 0.0 |

`memorized terminology` sits below `partially understands` even though
both come from a correct answer, because it is the state most likely to
fail on the real exam's rephrased or applied variants — treating it as
near-mastery would understate risk. `has a misconception` sits below
`guessed correctly` even though both are incorrect, because a specific
wrong mental model actively misleads the candidate on related questions,
where a guess at least leaves the door open. A domain with no answered
items yet has no `CurrentMastery` signal to average — treat it as
`CurrentMastery = 0` (`KnowledgeGap = 1`, maximum gap), since an
un-diagnosed domain must never be assumed known.

### ForgettingRisk

`0-1`, computed by the decay model below from the domain's most recent
successful-review date. Rises the longer a domain goes untouched, and is
never treated as `0` for a domain that has never been reviewed at all.

---

## Forgetting-risk model

`ForgettingRisk` is driven by elapsed time since the domain's most recent
*successful* review — a correct answer on a `spaced-repetition.md` item, a
resolved row in `mistake-ledger.md`'s "Resolved" table, or a correct
diagnostic/quiz answer for that domain, whichever is most recent. A wrong
answer never counts as a successful review even if it happened yesterday.

Compute `DaysSinceReview` as today's date minus that most-recent
successful-review date, then map it to a `0-1` risk band:

| DaysSinceReview | ForgettingRisk |
|---|---|
| 0-2 days | 0.1 |
| 3-6 days | 0.3 |
| 7-13 days | 0.5 |
| 14-29 days | 0.7 |
| 30+ days | 0.9 |
| never reviewed | 1.0 |

The bands track the same 1/3/7/14-day cadence `spaced-repetition-engine`
already uses to schedule reviews, so a domain that has just fallen off
that schedule (e.g. a 7-day item now 9 days overdue) reads as
meaningfully riskier without needing a separate decay curve to maintain.
`never reviewed` is capped at `1.0` rather than left unset — a domain the
candidate has touched zero times is the highest-risk case the model can
express, not a missing data point to skip.

Two domain states drive the highest `ForgettingRisk` in practice, and
both are worth naming explicitly since they are what `gaps` surfaces as
"ranked priorities" reasons:

- **Long-unreviewed weak areas** — a domain already low on
  `CurrentMastery` that has also drifted past its `spaced-repetition.md`
  due date or has open rows in `mistake-ledger.md`'s active table with no
  recent correct review. `ForgettingRisk` and `KnowledgeGap` compound
  here, pushing `Priority` sharply upward.
- **Never-reviewed weak areas** — a domain with diagnostic signals below
  mastery that has no entry in `spaced-repetition.md` or
  `mistake-ledger.md` yet at all (e.g. it was diagnosed once and never
  revisited). `ForgettingRisk = 1.0` applies by the `never reviewed` row
  above, since there is no successful review to decay from.

A domain the candidate scored well on *and* reviewed within the last two
days sits at low `ForgettingRisk` (`0.1`) even though it was once a weak
area, which is the intended effect: recent, successful review is what
pulls a domain back down the priority list, not the passage of time
alone.

---

## Worked example

Three domains from a hypothetical exam, computed by hand:

**Domain A — Security** (`ExamWeight = 0.30`, i.e. 30% of the exam):
Diagnostic signals average to `CurrentMastery = 0.3` (mostly "cannot
apply" and "has a misconception"), so `KnowledgeGap = 1 - 0.3 = 0.7`. Last
successful review was 20 days ago -> `14-29 days` band -> `ForgettingRisk
= 0.7`.

```
Priority(A) = 0.30 × 0.7 × 0.7 = 0.147
```

**Domain B — Networking** (`ExamWeight = 0.10`, 10% of the exam):
`CurrentMastery = 0.2` (mostly "guessed correctly"), so `KnowledgeGap =
0.8`. Never reviewed since the diagnostic -> `ForgettingRisk = 1.0`.

```
Priority(B) = 0.10 × 0.8 × 1.0 = 0.08
```

**Domain C — Storage** (`ExamWeight = 0.25`, 25% of the exam):
`CurrentMastery = 0.9` (mostly "knows"), so `KnowledgeGap = 0.1`. Reviewed
yesterday -> `ForgettingRisk = 0.1`.

```
Priority(C) = 0.25 × 0.1 × 0.1 = 0.0025
```

Ranked: **A (0.147) > B (0.08) > C (0.0025)**. Domain A out-ranks Domain B
even though Domain B has a slightly worse `KnowledgeGap` and a strictly
worse `ForgettingRisk`, because Domain A carries three times the exam
weight — this is the "weak-but-heavy beats weak-but-light" behavior the
formula is designed to produce. Domain C, despite being a real weak spot
historically, is now both well-known and freshly reviewed, so it correctly
falls to the bottom of the study queue for now.
