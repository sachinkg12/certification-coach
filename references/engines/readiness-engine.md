# Readiness Engine

Decides whether a candidate is ready to sit the real exam. A single mock
score is the least trustworthy signal available for this decision — a
candidate can clear 85% on one mock by getting lucky on the domains that
happened to come up, while carrying a domain gap or a repeated
misconception that the next mock's question mix would expose. This engine
exists so that "ready" is never a synonym for "scored well once." It
weighs a mock/quiz score alongside stability across attempts, per-domain
minimums, accuracy on questions the candidate has never seen before,
confidence calibration, time discipline, hands-on performance, and the
count of misconceptions still unresolved, and only then produces one of
four fixed verdicts.

Produces the operation `verdict(history)`, which reads `readiness.md`'s
full attempt history (never a single row in isolation), the relevant
`mistake-ledger.md` rows, and `assessment-engine`'s calibration output,
and writes the "Current verdict" section of `readiness.md` per
`references/state-schema.md`'s template. Consumed by `readiness` (Task
23) as the sole source of the verdict shown to the candidate — no command
prints a readiness judgment computed by any other logic, and no command
declares readiness off a single graded attempt.

---

## Signals

Readiness is never declared on one mock percentage. Every verdict is
computed from all of the following signals, read across the candidate's
full `readiness.md` attempt history, not the most recent row alone:

- **Average score across mocks.** The mean score across the most recent
  mock attempts (not quizzes — mocks are the full-length, exam-format
  attempts). A single high score is one data point; the average is what
  the rule set below actually gates on.
- **Score stability across several days.** Whether recent mock scores hold
  steady or trend upward across attempts taken on different days, versus
  swinging widely from attempt to attempt. A candidate who scores 90% one
  day and 62% the next is not stable even if the average looks
  acceptable — the swing itself is a risk signal, because it means the
  real exam's particular question mix is what will decide pass/fail, not
  the candidate's actual mastery.
- **Per-domain minimums.** The lowest-scoring domain across recent
  attempts, read against `exam-facts.md`'s syllabus weighting — an
  average score can look strong while one domain sits well below a safe
  floor. A single soft domain never gets averaged away by strong domains
  elsewhere.
- **Accuracy on unseen questions.** Of the questions answered correctly,
  the share that were being served for the first time (per
  `question-attempts.md`'s `Question ID` log), as opposed to questions the
  candidate has already drilled via `learn`, `quiz`, or `review`. High
  accuracy driven mostly by repeated, memorized questions overstates
  readiness for the real exam, which will present exclusively unseen
  items.
- **Confidence calibration.** The aggregate calibration delta from
  `assessment-engine`'s `calibration(history)`, read per-domain and
  overall. A candidate who is net overconfident is a higher exam-day risk
  than raw accuracy alone suggests, because overconfidence predicts the
  candidate will not use remaining prep time on the material that
  actually needs it — see `assessment-engine`'s "Why calibration matters
  for readiness" for the full reasoning this signal inherits.
- **Time per question / time vs. limit.** Whether mock attempts complete
  within the exam's actual time limit (from `exam-facts.md`'s "Format"
  section), not just whether the score is passing. A candidate who only
  passes by taking twice the allotted time has not demonstrated exam-day
  readiness, regardless of accuracy.
- **Hands-on performance.** Results from `lab` exercises, for
  certifications with a performance-based or hands-on component. A
  candidate who passes multiple-choice mocks but has not demonstrated the
  hands-on objectives is not ready for an exam format that tests both.
- **Unresolved misconceptions.** The count of `mistake-ledger.md` rows
  still open (not moved to `## Resolved`) whose root cause is a specific,
  named misconception — per `assessment-engine`'s "has a misconception"
  classification — especially any that recur across more than one recent
  graded attempt. A misconception that keeps resurfacing is a stronger
  readiness blocker than an equivalent count of one-off "cannot apply"
  misses, because it represents an active wrong belief the candidate will
  carry into the real exam rather than a gap that instruction can still
  close before the next attempt.

No single signal above is sufficient on its own to produce any verdict.
The rule set below always evaluates the full set together.

---

## Verdict rules

`verdict(history)` produces exactly one of four fixed strings, written
verbatim to `readiness.md`'s `Verdict` column and "Current verdict"
section: **Not ready**, **Nearly ready**, **Exam ready**, **Ready with
specific risks**. No synonym, abbreviation, or rewording is ever
substituted for any of the four.

### Example rule set

The following thresholds are the reference rule set this engine applies
unless a certification's `exam-facts.md` passing policy requires a
different bar (in which case the passing-score threshold below is
replaced with that policy's figure, but the structure of the rules stays
the same):

1. **At least 3 passing mock exams**, each scoring at or above the exam's
   published passing score, among the most recent attempts in
   `readiness.md`.
2. **No major domain below 70%**, checked against the per-domain scores
   backing the most recent mocks, not the overall average.
3. **At least 80% accuracy on unseen questions**, per the "Accuracy on
   unseen questions" signal above.
4. **Mocks completed within the time limit** — `Time vs. limit` in
   `readiness.md` at or under the published duration for the passing
   attempts counted in rule 1.
5. **No critical misconception repeated in the last two assessments** —
   no single named misconception appears as an open, unresolved
   `mistake-ledger.md` root cause across both of the two most recent
   graded attempts.

### Decision order

Apply the checks in this order, since a candidate can pass most rules
individually while still carrying one disqualifying signal:

1. **Not ready** — Fewer than 3 passing mocks recorded, or the average
   score across recent attempts is below the passing threshold, or scores
   are unstable (wide swings across days with no upward trend), or two or
   more domains sit below the 70% minimum. This is the default verdict
   whenever the core score/stability/domain-floor signals have not yet
   been met — no combination of strong secondary signals (fast times,
   good calibration) upgrades a candidate out of **Not ready** while the
   primary bar is unmet.
2. **Nearly ready** — The primary score bar is close but not yet met: for
   example, 1-2 passing mocks with an upward trend, or exactly one domain
   marginally below 70%, or unseen-question accuracy in the mid-70s
   rather than at 80%. The candidate is progressing correctly and the gap
   is specific and closeable, but rule 1, 2, or 3 above is not yet
   satisfied outright.
3. **Ready with specific risks** — All of rules 1-4 are satisfied (score,
   domain floors, unseen accuracy, and timing all clear), but rule 5 or
   one narrower residual risk remains — a single domain that clears 70%
   but sits meaningfully below the candidate's other domains, a
   persistent overconfidence delta in one area, or one misconception that
   resurfaced once but has since been reviewed only a single time (not
   yet the two consecutive clean assessments needed to close it). This
   verdict is chosen instead of **Exam ready** specifically because a
   named, bounded risk remains — the "Risks" section of `readiness.md` is
   populated with exactly that risk so the candidate knows what to
   double-check before sitting the exam, rather than being told either
   "not ready" (which would understate genuine overall preparation) or
   "exam ready" (which would silently drop a known risk).
4. **Exam ready** — All five rules in the example rule set are satisfied
   with no residual risk left to name: 3+ passing mocks, every domain at
   or above 70%, unseen-question accuracy at or above 80%, every counted
   mock within the time limit, and no critical misconception repeated
   across the last two assessments. This verdict is never produced from a
   single attempt, regardless of how strong that attempt's score is —
   rule 1's "at least 3 passing mock exams" is a hard floor on every path
   to **Exam ready**.

### Why the rules are evaluated together, not score-first

A candidate can satisfy rule 1 (3 passing mocks) and still land on **Not
ready** if two domains sit below the floor, because domain floors and
unresolved misconceptions catch exactly the failure mode an average score
hides: strong performance in weighted domains masking a specific,
exam-day-fatal gap in a lighter one. Conversely, a candidate can be one
domain point short of a clean **Exam ready** and still land on **Ready
with specific risks** rather than **Not ready**, because the rest of the
signal set — score, stability, timing, unseen accuracy — already
demonstrates broad readiness; downgrading that candidate all the way to
**Not ready** over one bounded, named gap would understate real
preparation as much as ignoring the gap would overstate it. This is the
same reasoning `priority-engine` applies by multiplying rather than
averaging its factors: a readiness verdict is a judgment about the whole
signal set, not a score computed from any one number in isolation.
