# Assessment Engine

Classifies every diagnostic and quiz answer into one of six knowledge
states and scores how well the candidate's stated confidence tracks their
actual correctness. Correctness alone is never enough to judge what a
candidate knows — two candidates who both answer correctly can be in very
different states, and two who both answer incorrectly can need very
different remediation. This engine exists to make that distinction
explicit and repeatable everywhere an answer is scored.

Produces the operations `classify(answer)` and `calibration(history)`.
Consumed by `diagnose` (Task 8) to populate the `Signal` column and
`Confidence calibration` fields in `diagnostic.md`, and by any later
quiz/mock module that records answers against
`references/state-schema.md`'s per-cert files. No command derives its own
classification logic — every answer routes through `classify` before it is
written to state.

---

## Six-way classifier

`classify(answer)` takes four observed signals per answer — stated
confidence (1-5), the explicit "I guessed" flag, whether the answer was
correct, and (where available) the candidate's stated reasoning or
explanation — and returns exactly one of six states. The term strings
below are written verbatim into the `Signal` column of `diagnostic.md`;
no synonym, abbreviation, or rewording is ever substituted.

- **knows** — Correct, `I guessed: no`, confidence 4-5, and the candidate
  can explain *why* the answer is correct (not just recite the term). This
  is the only state where correctness, high confidence, and demonstrated
  reasoning all align. Distinguishing signal: ask "why" and the candidate
  gives a mechanism or a scenario-grounded justification, not a
  restatement of the answer text.

- **partially understands** — Correct, `I guessed: no`, but confidence is
  mid-range (2-3) or the explanation is incomplete — the candidate gets
  the right answer but hedges, names only part of the reasoning, or
  conflates it with an adjacent concept. This state flags "close but not
  solid" rather than "wrong."

- **memorized terminology** — Correct, `I guessed: no`, confidence 4-5,
  but the explanation only recites a definition or term and cannot be
  extended to a scenario or hands-on variant of the question. Distinguish
  this from "knows" with one test: pose a follow-up that requires applying
  the term to a new, slightly different scenario. "Knows" candidates
  transfer the concept; "memorized terminology" candidates can state the
  definition verbatim but stall or fall back to guessing when the surface
  form of the question changes. This is the highest-risk false positive in
  raw scoring — it looks identical to "knows" on a single conceptual
  question and only diverges on application.

- **guessed correctly** — Correct, but `I guessed: yes`, or confidence is
  low (1-2) with no coherent explanation offered. Distinguishing signal
  from "knows": the explicit guess flag is authoritative — if the
  candidate marked "I guessed: yes," the answer is guessed correctly
  regardless of confidence rating, because self-reported guessing is a
  stronger signal than a confidence number that may itself be miscalibrated.
  When the guess flag is absent or ambiguous, low confidence (1-2) plus
  inability to articulate reasoning is the fallback test.

- **has a misconception** — Incorrect, `I guessed: no`, and the candidate's
  stated reasoning reveals a specific, coherent (but wrong) mental model —
  they didn't fail to recall, they recalled something incorrect with
  conviction. Distinguish from "cannot apply" by whether an explanation
  exists at all: a misconception comes with a wrong-but-articulated theory
  ("I thought X does Y because..."); this is the state most valuable to
  `gap-analysis` and `mistake-ledger` because it names a specific belief to
  correct, not just a blank spot.

- **cannot apply** — Incorrect, and either `I guessed: no` with no
  coherent reasoning offered (a blank or "I don't know"), or the
  explanation shows the candidate recognized relevant terminology but
  could not connect it to the scenario. This is the default incorrect
  state when no specific wrong mental model is articulated — it signals a
  gap to fill with instruction, not a misconception to correct.

### Decision order

Apply the checks in this order, since correctness alone is ambiguous and
several states share a correctness value:

1. Was the answer correct?
2. If correct: check `I guessed` first (yes -> **guessed correctly**,
   overriding confidence). If no, check whether the explanation
   transfers to a changed scenario (no -> **memorized terminology**),
   is confident and transferable (**knows**), or is hedged/partial
   (**partially understands**).
3. If incorrect: check whether a specific wrong mental model is
   articulated (yes -> **has a misconception**) or reasoning is absent/
   terminology-only (**cannot apply**).

---

## Confidence calibration

`calibration(history)` compares a candidate's stated confidence (1-5)
against actual correctness across a set of answers — one diagnostic
attempt, one quiz, or a running history — and reports a calibration
verdict per answer and an aggregate delta for the set.

### Per-answer calibration

- **Calibrated** — Confidence and correctness agree: high confidence
  (4-5) paired with a correct answer, or low confidence (1-2) paired
  with an incorrect answer. The candidate's self-assessment can be
  trusted as a readiness signal.
- **Overconfident** — High confidence (4-5) paired with an incorrect
  answer. This is the more dangerous miscalibration for exam readiness:
  the candidate will walk into the real exam expecting to get these
  right and will not flag them for review. Overconfidence on a domain
  is weighted more heavily than plain incorrectness when `gap-analysis`
  and `readiness-engine` compute risk, because it hides gaps from the
  candidate's own self-monitoring.
- **Underconfident** — Low confidence (1-2) paired with a correct
  answer. Lower-severity than overconfidence, but still worth surfacing:
  the candidate may be burning review time re-studying material they
  already hold, or second-guessing correct answers under exam time
  pressure.
- **Mid-range / inconclusive** — Confidence of 3 does not cleanly signal
  calibration or miscalibration either way and is recorded as-is without
  a verdict; it is neither penalized nor credited in the aggregate delta.

### Aggregate delta

Across a set of answers, compute the calibration delta as the difference
between mean stated confidence (normalized to a 0-1 scale) and the actual
accuracy rate (0-1) for that set:

- `delta > 0` — net overconfident: stated confidence runs ahead of actual
  performance. A large positive delta on a domain is a specific readiness
  risk even if raw accuracy looks acceptable, because it predicts the
  candidate will under-review that domain before the exam.
- `delta < 0` — net underconfident: actual performance exceeds stated
  confidence. Worth noting but lower priority to correct.
- `delta ~ 0` — well calibrated: the candidate's confidence ratings are a
  reliable proxy for actual mastery, which means future self-reported
  confidence (e.g. in `profile.md`'s per-domain familiarity ratings) can be
  weighted more heavily in later planning decisions.

### Why calibration matters for readiness

Raw accuracy answers "how much does the candidate know." Calibration
answers a different question: "can the candidate's own signal be trusted
to know what they don't know." A candidate at 80% accuracy who is
consistently overconfident on the missed 20% is a worse exam-day risk
than a candidate at 70% accuracy who accurately flags their own weak
spots, because the second candidate will actually use remaining study
time on the right material. `readiness-engine`'s "Confidence calibration"
signal in `readiness.md` and `gap-analysis`'s priority computation both
depend on this engine's per-domain aggregate delta, not on accuracy
numbers alone.
