# Adaptive Engine

Drives the teaching loop that runs underneath `learn`: the state machine
that decides, question by question, whether the candidate advances to the
next objective or gets pulled into targeted remediation. A tutor that
simply marches through a syllabus and marks answers right or wrong is not
adaptive — this engine is what makes `learn` respond to *why* an answer
was wrong, not just *that* it was wrong, and what stops the loop from
mechanically advancing past a misconception the candidate has not
actually resolved.

This engine does not classify answers and does not write questions itself.
Every answer routes through `assessment-engine`'s `classify(answer)` before
this loop reasons about it, and every new question routes through
`question-generator`'s `generate(objective, form)` before it is shown to
the candidate. This engine's job is the orchestration between those two —
deciding what happens next and when the state should branch — not
restating either engine's logic.

Produces the operation `advance(session-state)`. Consumed by `learn`
(Task 15) as the per-question control loop; also the branching authority
that `readiness-engine` checks when it counts "critical misconception
repeated" as a readiness risk. No command runs its own teach-and-branch
logic independently of this engine — every adaptive question-answer cycle
in `learn` executes the loop below.

---

## Loop

Each question `learn` serves runs through six steps in order. The loop is
per-question, but step 6's writes accumulate across the whole session, so
later steps in later iterations can see what earlier ones recorded.

1. **Evaluate the answer via `assessment-engine`.** Pass the candidate's
   answer, stated confidence (1-5), the `I guessed` flag, and their
   explanation to `assessment-engine`'s `classify(answer)`. This is the
   only source of truth for whether the answer was correct and which of
   the six knowledge states it falls into (`knows`, `partially
   understands`, `memorized terminology`, `guessed correctly`, `has a
   misconception`, `cannot apply`). This step never re-derives correctness
   or re-implements the classifier; it consumes the returned state as-is.

2. **Explain why the answer is right or wrong.** Using the classified
   state from step 1, give a direct explanation grounded in the specific
   question just answered — not a generic restatement of the topic. For
   a correct answer, explain the mechanism that makes it correct (this
   matters most for `memorized terminology`, where the candidate got the
   right answer but has not shown they understand why). For an incorrect
   answer, explain what the correct answer is and walk through the
   reasoning that gets there, in plain language the candidate's own
   wording can be checked against.

3. **Name the underlying misconception (when one exists).** This step
   only produces output for the `has a misconception` and `memorized
   terminology` states — the two states where something specific and
   nameable is wrong or missing, as opposed to `cannot apply` (a gap with
   no specific wrong belief to name) or the three "correct" states other
   than `memorized terminology`. State the misconception as a concrete,
   falsifiable belief (e.g. "treats authorization as a synonym for
   authentication — believes verifying *who* the user is also determines
   *what* the user can do") rather than a vague label like "confused
   security concepts." A precisely named misconception is what makes step
   6's ledger entry and step 4's remedial content useful instead of
   generic.

4. **Generate a smaller remedial micro-lesson.** For any state below
   `knows` (i.e. `partially understands`, `memorized terminology`,
   `guessed correctly`, `has a misconception`, `cannot apply`), produce a
   short, targeted lesson scoped to exactly the gap or misconception named
   in step 3 — not a re-teach of the whole objective. The micro-lesson is
   proportional to what's missing: a `partially understands` answer might
   need one clarifying sentence and a contrast with the adjacent concept
   it was hedging against; a `has a misconception` answer needs the wrong
   mental model named, why it's wrong, and the correct model substituted
   in its place. `knows` answers skip this step entirely and move straight
   to step 5.

5. **Ask a related-but-different question.** Request a new question from
   `question-generator`'s `generate(objective, form)` for the same
   objective just tested, so the candidate applies the (possibly just
   corrected) understanding immediately rather than moving on before it's
   verified. This new question must exercise the same underlying concept
   from a different angle — different scenario, different framing, or a
   different form (e.g. a conceptual question followed by a scenario-based
   one on the same objective) — never a reworded copy of the question just
   answered. `question-generator`'s own dedup pass (`is_duplicate` against
   `question-attempts.md`) is what guarantees this question is unseen; this
   step supplies the objective and form, not the duplicate check itself.
   The answer to this question is what step 1 evaluates on the next
   iteration of the loop, which is how the loop measures whether a
   micro-lesson actually landed.

6. **Update `plan.md` and record misses in `mistake-ledger.md`.**
   - If the classified state is `has a misconception` or `cannot apply`
     (an incorrect answer), append a row to `mistake-ledger.md` per
     `references/state-schema.md`'s template: the question (tagged
     `[GENERATED PRACTICE]`), the candidate's answer, the correct answer,
     the root cause (the misconception named in step 3, or "gap — no
     specific misconception" when step 3 produced nothing), the exam
     objective, and a `Next review` date left for `spaced-repetition-engine`
     to set.
   - If the question's objective was the current session's plan item and
     the candidate's answer was `knows` or `partially understands`,
     progress that objective toward `plan.md`'s exit criteria for the
     active week.
   - If this iteration triggered a remediation branch (see below), log
     the branch in `plan.md`'s "Plan change log" table with the concrete
     reason (e.g. "remediation: auth-vs-authz misconception seen 3x
     consecutive") rather than silently extending the session, so a later
     read of `plan.md` explains why a week ran longer than scheduled.

This six-step sequence repeats for every question `learn` serves until the
session's planned objectives are exhausted or the candidate stops the
session; the "Remediation branch" section below governs when step 5's
next question stays on the same narrow point instead of moving the
session on to the next objective.

---

## Remediation branch

Advancing to the next objective is the default after a `knows` answer.
Remediation is the exception the loop must actively branch into — and
once branched, it must not silently fall back to advancing just because a
session is running long.

### Trigger

Track, per session and per candidate across sessions (via
`mistake-ledger.md`'s history for the active `<cert-slug>`), how many
times the *same* named misconception (step 3's output, matched on the
concrete belief stated, not just the objective) has been observed. The
loop branches into remediation — instead of advancing to a new objective
after step 5's follow-up question — when either condition holds:

- **Same misconception, 2 consecutive occurrences.** The candidate
  produces the identical misconception (e.g. "treats authorization as a
  synonym for authentication") on the follow-up question from step 5 that
  was specifically designed to re-test it. Two in a row on the targeted
  retest is sufficient because step 5's question was already chosen to
  probe exactly this point — a second miss there is not noise.
- **Same misconception, 3 occurrences within the session** (not
  necessarily consecutive — e.g. it resurfaces on an unrelated question
  two objectives later). A misconception that keeps resurfacing across
  different questions signals it is load-bearing to how the candidate
  reasons about the domain, not a one-off slip, even if it didn't repeat
  back-to-back.

A single miss, or a miss followed by a correct related-but-different
answer, does not trigger remediation — that is the loop working as
intended (step 4's micro-lesson corrected it on the first try) and the
session advances normally.

### What remediation does differently from the normal loop

Once triggered, the loop does not run step 5's "ask a related-but-different
question, then move on" as normal — it stays anchored to the same
misconception across multiple cycles:

1. Deliver a **smaller** micro-lesson than step 4's first attempt —
   narrower in scope, and this time built around the specific pattern of
   repeated confusion (e.g. contrast the two concepts side by side with
   the exact distinction the candidate keeps missing, using a concrete
   example that isolates just that distinction).
2. Re-test the same concept from a **fresh scenario** — a different
   surface form than either of the two prior attempts (different
   framing, different narrative, different phrasing of the distinction),
   requested from `question-generator` for the same objective. This
   guards against the candidate pattern-matching the retest to the
   micro-lesson's example rather than actually resolving the confusion.
3. Re-run step 1's evaluation on that answer. If the misconception
   resurfaces again, repeat this three-step remediation cycle — smaller
   lesson, fresh scenario, re-evaluate — rather than escalating session
   length limits or giving up; if it clears, proceed to the exit
   condition below.

### Exit condition

Remediation ends, and the loop resumes normal advancement, only when the
candidate demonstrates the concept correctly under a **fresh scenario** —
a question the candidate has not seen before, on the same objective, that
is classified `knows` or `partially understands` (not `guessed correctly`
or `memorized terminology`, since either of those would mean the
underlying confusion is still there, just not surfaced by this particular
phrasing). A single correct answer under the *original* question's
framing does not count as clearing the misconception — only a correct
answer under a new framing counts, because the whole point of remediation
is verifying the concept transfers, not that the candidate memorized the
correction.

When the misconception clears, record the resolution: update the
`mistake-ledger.md` row (or rows) for that misconception per its
"Resolved" table — `Resolved on` date and "confirmed by" the fresh-scenario
correct answer — and log the recovery in `plan.md`'s "Plan change log"
(e.g. "remediation resolved: auth-vs-authz, 4 cycles, cleared on fresh
scenario") so the plan's history explains both why the week ran long and
that the extra time paid off. The loop then resumes step 5's normal
related-but-different question on the *next* objective in the plan, not a
further retest of the now-cleared concept — spaced review of it going
forward is `spaced-repetition-engine`'s responsibility, not this loop's.

If a misconception has not cleared after 5 remediation cycles within one
session, the loop does not force a 6th cycle in the same sitting — it logs
the unresolved misconception in `plan.md`'s change log as carried over,
leaves the `mistake-ledger.md` row open (not resolved), and lets the
session move on to other planned objectives so the candidate is not stuck
in an unproductive loop; the carried-over misconception re-enters
remediation the next time `learn` serves a question on that objective or
that concept surfaces via `spaced-repetition.md`'s weak-area queue.
