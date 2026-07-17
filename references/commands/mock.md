# `mock`

Module 11: the realistic full exam simulation — the command a candidate
reaches for when the question is no longer "do I know this domain" but
"can I sit down and pass the actual exam, under the actual exam's
conditions, right now?" Where `quiz`'s timed mini-test proportions a short
set of questions from the exam's per-question budget and `lab` isolates
hands-on competency, `mock` reproduces the whole exam experience end to
end — the same question count, the same duration, the same domain mix,
the same difficulty curve, the same review mechanics — in one sitting.
`mock` is the closest thing to exam day CertiCoach can offer, and it is
built to be trusted precisely because it never cuts a corner the real
exam doesn't cut.

`mock` never drafts its own questions and never invents its own exam
structure. Every question served comes from `question-generator`'s
`generate(objective, form)`, and every structural parameter — question
count, duration, domain weighting, question types — is read from the
active certification's `exam-facts.md`, not hardcoded here. This file
does not restate either source's rules; see
`references/engines/question-generator.md` for the question-sourcing
contract `mock` runs underneath and `references/state-schema.md`'s
`exam-facts.md` template for where the structural parameters come from.
`mock` is certification-agnostic: the same simulation mechanics below
produce a 65-question, 130-minute cloud-architecture mock and a
40-question, 90-minute project-management mock without a single line of
provider-specific logic — everything that varies between exams varies
because `exam-facts.md` varies, not because `mock` branches on which
certification is active.

---

## Simulation fidelity

`mock` reproduces every dimension of the real exam that `exam-facts.md`
documents. Nothing below is a fixed default — each bullet is read from the
active certification's `exam-facts.md` at the start of every attempt, so a
mock reflects whatever the candidate's actual exam looks like, not a
generic template:

- **Question count** — exactly the `Question count` figure from
  `exam-facts.md`'s "Format" section. `mock` never serves a shorter
  "sample" set and calls it a full simulation; a partial-length session
  belongs to `quiz`'s timed mini-test mode, not here.
- **Duration** — a visible clock counting down from `exam-facts.md`'s
  `Duration`, running for the whole attempt, not reset or paused between
  questions. The candidate answers, flags, or times out against this one
  continuous clock exactly as the real exam enforces it.
- **Domain distribution** — questions are drawn in the proportions given
  by `exam-facts.md`'s "Syllabus / domains" table `Weight` column, not
  evenly split and not weighted toward the candidate's weak areas the way
  `quiz`'s mixed-domain mode deliberately is. A domain weighted 30% of the
  real exam gets ~30% of this mock's questions — `mock`'s job is to
  reproduce exam-day question mix, not to optimize the candidate's
  learning, which is what makes its results a trustworthy proxy for the
  real thing.
- **Difficulty progression** — item difficulty is composed by
  `question-generator`'s difficulty-aware generation to approximate the
  real exam's typical spread (a mix of straightforward and harder items
  distributed across the attempt, not a steady ramp or a front-loaded easy
  section) rather than clustering every hard item at the candidate's
  current weak point the way a targeted `quiz` session would.
- **Flag-for-review** — the candidate can flag any question and return to
  it before submitting, exactly as the real exam's review screen allows.
  Flagged questions remain answerable (or changeable) until the attempt is
  submitted or the clock expires, and `mock` shows a review summary
  (answered / flagged / unanswered) before final submission, matching the
  real exam's pre-submit review step.
- **Negatively-worded questions** — a realistic share of items use
  negative framing ("which of the following is NOT...", "all of the
  following are true EXCEPT...") when the certification's real exam uses
  this pattern, per `exam-facts.md`'s "Question types" and "Community
  notes." `question-generator` composes these as first-class items, not
  a reworded positive question, since a candidate who misreads "NOT" under
  time pressure is a specific, real failure mode `mock` is built to
  surface before exam day does.
- **Scenario length** — scenario-based items are sized to match the real
  exam's typical scenario length (a short paragraph of setup vs. a dense
  multi-paragraph incident writeup), per whatever `exam-facts.md`'s
  "Question types" and "Community notes" document about the real exam's
  item style. A mock that only ever serves one-line scenarios understates
  the reading-and-parsing load the real exam imposes.
- **Time pressure** — the per-question time budget implied by dividing
  `exam-facts.md`'s `Duration` by `Question count` is never shown to the
  candidate as a per-item countdown (the real exam doesn't do this
  either) — only the single overall clock is visible, so the candidate
  experiences the same pacing pressure and the same self-management
  problem (spend too long early, run out of time late) the real exam
  creates.
- **Break rules** — for certifications whose `exam-facts.md` documents a
  scheduled break (e.g., a fixed break point in a long-duration exam),
  `mock` reproduces it: the clock pauses (or keeps running, matching
  whichever the real exam does) at the documented point, and the
  candidate cannot return to questions answered before the break, exactly
  as the real proctoring rules specify. For certifications with no
  documented break, `mock` runs as one uninterrupted sitting — this
  bullet is never simulated where `exam-facts.md` doesn't document it.
- **Multiple-choice + multiple-response formats** — item formats are
  drawn in the mix `exam-facts.md`'s `Question types` documents (e.g.
  "multiple choice, multi-select"), with multiple-response items
  explicitly marked "select all that apply" exactly as
  `question-generator`'s Form-appropriate rule requires, so a candidate
  who only ever practices single-answer picks in other modes still meets
  the real exam's format mix here.

If any of the above is missing or unverified in the active certification's
`exam-facts.md` (e.g. no documented break policy, no `Question types`
line), `mock` does not invent a plausible-sounding default — it tells the
candidate which structural fact is missing and that this dimension of the
simulation cannot be reproduced with confidence until `discover` (or a
manual edit to `exam-facts.md`) fills it in, per `provenance-engine`'s
persistence rule that unsourced facts are never used as if they were
verified.

---

## Behavior

**Sourcing.** Every question in a `mock` attempt comes from
`question-generator`'s `generate(objective, form)`, mapped to the specific
objective and domain the exam-facts.md weighting assigned it, and is
labeled `[GENERATED PRACTICE]` at presentation exactly as that engine's
Labeling section requires — a `mock` attempt never presents a question as
if it were drawn from the real exam bank, even while everything about its
structure mirrors the real exam. Before serving, `mock` relies on the
engine's own dedup pass (`is_duplicate(candidate, question-attempts)`)
against `question-attempts.md`, so a `mock` attempt never re-serves a
question the candidate has already seen from `learn`, `quiz`, `mock`, or
`lab` — every mock is built from originally-composed items, which is what
keeps the "accuracy on unseen questions" signal `readiness-engine` reads
meaningful across repeated mock attempts, not just the first one.

**Decision-making under uncertainty.** A real exam is not just a
knowledge test — it is a decision-making test under a clock, and `mock`
is deliberately built to exercise that, not just correctness. On every
question, the candidate has the same set of real options a real exam
presents, and `mock` never collapses them into a single "answer or skip"
choice:

- **Answer now** — commit to a choice and move to the next question.
- **Flag and return** — mark the question as uncertain and move on,
  coming back before submission per the flag-for-review mechanic above.
- **Eliminate two choices** — narrow the option set before committing,
  a distinct behavior from guessing blind that `mock` records separately
  (it changes how a wrong answer is later classified — an eliminated-down
  wrong guess and a blind wrong guess are different signals for
  `assessment-engine` to read from the candidate's stated reasoning).
- **Spend more time** — deliberately linger on a question past the
  implied per-question budget, trading pace for confidence. `mock` never
  penalizes this in the moment (no per-item countdown, per Simulation
  fidelity above) but does record the time cost against the overall
  clock, exactly as the real exam would.
- **Make an educated guess** — commit to a choice while explicitly
  flagging low confidence, distinct from a confident answer. `mock`
  collects a confidence rating (1-5) and an explicit "I guessed" flag on
  every question, the same four inputs (answer, confidence, guess flag,
  reasoning) `assessment-engine`'s `classify(answer)` requires, so a mock
  attempt produces a fully classifiable signal for every item, not just a
  correct/incorrect count.

**Time tracking.** `mock` records time spent per question against the
single overall clock (never a fabricated per-question limit, since the
real exam doesn't impose one), plus the aggregate time used against
`exam-facts.md`'s `Duration`. This is what lets `readiness-engine`'s "Time
per question / time vs. limit" signal distinguish a candidate who passes
comfortably inside the time limit from one who only clears the score bar
by using every available minute — both attempts can produce the same
score and a materially different readiness picture.

**Scoring.** Once the attempt is submitted (by the candidate or by the
clock expiring), every answer is passed to `assessment-engine`'s
`classify(answer)` for the six-way signal (knows, partially understands,
memorized terminology, guessed correctly, has a misconception, cannot
apply), and `calibration(history)` is run over the full attempt before
results are written, exactly as `quiz` runs it over a session and
`diagnose` runs it over a baseline attempt. A `mock` attempt is scored in
full only after submission — `mock` does not reveal correctness
question-by-question the way an untimed drill might, since knowing an
answer was wrong mid-attempt would let the candidate recalibrate their
pacing in a way the real exam never allows.

**No self-declared readiness.** A `mock` attempt reports its own score,
but `mock` never tells the candidate they are "ready" or "not ready" off
that one attempt — that verdict belongs solely to `readiness-engine`'s
`verdict(history)`, which reads the full `readiness.md` attempt history
(stability across days, per-domain minimums, unseen-question accuracy,
calibration, timing, and unresolved misconceptions together), never a
single row in isolation. `mock` writes this attempt's row and hands off;
it does not compute or print a readiness judgment of its own. See
`references/engines/readiness-engine.md` for the full multi-signal rule
set that turns a history of `mock` (and `quiz`) attempts into one of the
four fixed verdicts.

---

## Outputs

`mock` writes to three existing per-cert files — it does not introduce a
template of its own:

- **`.certicoach/<cert-slug>/readiness.md`** — every `mock` attempt
  appends one row to the "Attempt history" table, `Type: mock`, per
  `references/state-schema.md`'s template: Date, Score, Unseen-question
  accuracy (the share of correct answers on questions the candidate had
  never been served before, per `question-attempts.md`), Time vs. limit
  (actual minutes used against `exam-facts.md`'s published `Duration`),
  Confidence calibration (this attempt's aggregate delta from
  `assessment-engine`'s `calibration(history)`), and Domain minimums met
  (yes/no against `exam-facts.md`'s per-domain floor). The `Verdict`
  column for that row is filled by `readiness-engine`'s `verdict(history)`
  recomputed over the full history including this new attempt, not
  decided by `mock` itself. A `mock` session that ends without this row
  written has not finished — the row is what makes the attempt count
  toward every downstream readiness signal.
- **`.certicoach/<cert-slug>/question-attempts.md`** — every question
  `mock` serves is recorded per `question-generator`'s "record on serve"
  step: Question ID, domain, type, `Served in: mock`, date, the
  `[GENERATED PRACTICE]` label, and (once answered) correctness and time
  taken. This is what keeps dedup and `readiness-engine`'s
  unseen-question-accuracy signal accurate for the next `mock`, `quiz`,
  `learn`, or `lab` session, regardless of which command serves next.
- **`.certicoach/<cert-slug>/mistake-ledger.md`** — every answer
  `assessment-engine` classifies as `has a misconception` or `cannot
  apply` becomes a new row: the question (tagged `[GENERATED PRACTICE]`),
  the candidate's answer, the correct answer, the root cause named from
  the candidate's stated reasoning, the exam objective, and `Next review`
  left for `spaced-repetition-engine` to schedule. `mock` never scores a
  miss silently — an attempt that produces misses with no corresponding
  ledger rows has not finished writing its outputs.

`mock` reports the attempt's per-domain and aggregate results (score,
unseen-question accuracy, time used vs. the limit, and calibration) back
to the candidate at session end, including whichever domains sat below
`exam-facts.md`'s per-domain floor, but the readiness verdict itself is
always `readiness-engine`'s to print, sourced from the row `mock` just
wrote alongside the candidate's prior attempt history — never a
first-person judgment `mock` makes about a single sitting.
