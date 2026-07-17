# `quiz`

Module 10: self-directed, on-demand assessment — the command a candidate
reaches for outside the structured `learn` session to test standing on a
domain, a mix of domains, or the clock itself. Where `learn` teaches one
objective at a time through `adaptive-engine`'s loop, `quiz` assumes some
teaching has already happened and asks a different question: *does this
hold up under a testing condition, not just a teaching one?* Results feed
`gap-analysis` (a domain that scores worse under `quiz` than it did at the
end of its `learn` session is a forgetting-risk signal, not just a low
score) and `mistake-ledger.md`/`spaced-repetition.md` (every miss becomes a
tracked item), so a `quiz` session is never a dead end — it always changes
what the candidate reviews next.

`quiz` never drafts its own questions and never scores its own answers.
Every question served here is produced by `question-generator`'s
`generate(objective, form)`, and every answer is classified by
`assessment-engine`'s `classify(answer)` — this file does not restate
either engine's rules; see `references/engines/question-generator.md` and
`references/engines/assessment-engine.md` for the authoritative logic
`quiz` runs underneath. `quiz` is certification-agnostic: the same seven
modes below run identically whether the candidate is quizzing a security
domain or a project-scheduling domain — nothing about mode selection,
question sourcing, or scoring is hardcoded to a specific provider's
syllabus.

---

## Modes

`quiz` supports seven assessment modes. The candidate picks one when
invoking `quiz` (or `quiz` recommends one based on the active `plan.md`
week and `gap-analysis.md`'s ranked priorities, if none is named):

- **Topic quiz** — a fixed-length set of questions drawn from a single
  named domain or objective. Used when the candidate wants to confirm one
  specific area is solid before moving on, e.g. right after a `learn`
  session or before that domain's plan exit criteria are marked met.
- **Mixed-domain quiz** — questions drawn across multiple domains in one
  session, weighted toward `gap-analysis.md`'s current priorities rather
  than evenly split. This is what surfaces domain-switching cost — a
  candidate who is solid on each domain in isolation but stumbles when
  questions jump between them without warning, which is closer to the real
  exam's structure than any single-topic drill.
- **Timed mini-test** — a short set of questions run against a visible
  clock, proportioned from the real exam's per-question time budget (from
  `exam-facts.md`'s `Duration` and `Question count`) rather than an
  arbitrary limit. Tests pacing under pressure, not just correctness — a
  candidate who answers correctly but consistently blows the per-question
  budget is a distinct risk `readiness-engine`'s "Time vs. limit" signal
  needs to see.
- **Oral questioning** — the candidate answers out loud or in free-form
  prose rather than selecting from options; `quiz` asks the question
  conversationally and requires a spoken-style explanation, not a
  multiple-choice pick. This mode exercises the same "explain it in your
  own words" muscle a real interview panel or a scenario-heavy exam item
  demands, and it's the mode most likely to expose "memorized terminology"
  per `assessment-engine`'s classifier, since there's no option list to
  recognize from.
- **Rapid-fire terminology** — short, fast-paced conceptual questions with
  a tight per-question time budget and no scenario wrapper, aimed at
  building recall speed on core terms and definitions. Deliberately
  shallow by design — this mode is not where `quiz` expects to surface
  "cannot apply" gaps, since it never asks the candidate to apply anything.
- **Explanation-based** — every question, correct or not, is followed by
  "explain why" before moving on, regardless of the candidate's confidence
  or how quickly they answered. This is the mode most resistant to
  guessing inflating the score, since a correct guess with no coherent
  explanation still surfaces as `guessed correctly` rather than `knows`.
- **Adaptive** — question difficulty and domain selection shift in
  response to the running session's results: a domain the candidate is
  missing pulls more questions at a gentler difficulty, a domain the
  candidate is acing pulls fewer questions at a harder difficulty, per
  `question-generator`'s difficulty-aware generation. This mode is the
  closest `quiz` gets to a live tutoring session and is the default
  recommendation when the candidate doesn't name a mode or a domain.

---

## Behavior

**Sourcing.** Every question `quiz` serves comes from
`question-generator`'s `generate(objective, form)`, mapped to a specific
objective in the active certification's `exam-facts.md`, and labeled
`[GENERATED PRACTICE]` at presentation exactly as that engine's Labeling
section requires — `quiz` never presents a question without the tag and
never implies a question is drawn from the real exam. Before serving,
`quiz` relies on the engine's own dedup pass (`is_duplicate(candidate,
question-attempts)`) against `question-attempts.md` so the candidate is
never re-served a question they've already seen from `quiz`, `learn`,
`mock`, or `lab` — `quiz` does not run a second, competing dedup check of
its own.

**Scoring.** Every answer collected during a `quiz` session is passed to
`assessment-engine`'s `classify(answer)` for the six-way signal (knows,
partially understands, memorized terminology, guessed correctly, has a
misconception, cannot apply), using the same four inputs that engine
requires — the answer, a confidence rating (1-5) collected before
correctness is revealed, an explicit "I guessed" flag, and the candidate's
stated reasoning. `quiz` collects all four on every question in every
mode, including rapid-fire terminology and timed mini-tests, so a fast or
low-stakes mode never produces an under-specified answer the classifier
can't resolve. Where a session covers multiple questions,
`assessment-engine`'s `calibration(history)` is run over the full set
before results are written, exactly as `diagnose` runs it over a baseline
attempt.

**Explaining why the others are wrong.** On a meaningful share of
multiple-choice and multiple-response questions across every mode — not
just when the candidate answers incorrectly — `quiz` also asks the
candidate to explain why one or more of the *incorrect* options are wrong,
not only why the chosen option is right. This is deliberate: a candidate
who can eliminate a plausible-looking distractor by naming the specific
reason it fails demonstrates a sturdier grasp of the concept than one who
can only recognize the correct answer, and a candidate who cannot explain
why a wrong option is wrong — even after answering correctly — is often
one confusable surface-form away from the "memorized terminology" state
`assessment-engine` is built to catch. `quiz` treats the candidate's
answer to this follow-up as additional reasoning input to `classify`, not
as a separate graded item, and does not ask it on every single question
in every mode (rapid-fire terminology's tight per-question budget in
particular skips it) — it is a targeted probe used often enough that the
candidate cannot predict which questions will carry it, not a fixed drill
step.

---

## Outputs

`quiz` writes to two existing per-cert files — it does not introduce a
template of its own:

- **`.certicoach/<cert-slug>/question-attempts.md`** — every question
  `quiz` serves is recorded per `question-generator`'s "record on serve"
  step and `references/state-schema.md`'s template: Question ID, domain,
  type, `Served in: quiz`, date, the `[GENERATED PRACTICE]` label, and
  (once answered) correctness and time taken. This is what keeps dedup
  and `readiness-engine`'s unseen-question accuracy signal accurate for
  every later session, regardless of which command serves next.
- **`.certicoach/<cert-slug>/mistake-ledger.md`** — every answer
  `assessment-engine` classifies as `has a misconception` or `cannot
  apply` becomes a new row: the question (tagged `[GENERATED PRACTICE]`),
  the candidate's answer, the correct answer, the root cause named from
  the candidate's reasoning (including any misconception surfaced through
  the "explain why the others are wrong" follow-up), the exam objective,
  and `Next review` left for `spaced-repetition-engine` to schedule.
  `quiz` never scores a miss silently — a session that produces misses
  with no corresponding ledger rows has not finished writing its outputs.

`quiz` reports the session's per-domain and aggregate results (accuracy,
calibration verdict, and mode-specific signals like time-vs-budget for a
timed mini-test) back to the candidate at session end, but does not
maintain a separate results file — `gap-analysis.md` recomputes domain
standing from `question-attempts.md` and `mistake-ledger.md` the next time
`gaps` runs, rather than `quiz` writing a parallel, potentially
inconsistent summary of the same data.
