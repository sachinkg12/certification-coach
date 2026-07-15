# `lab`

Module 7: hands-on competency assessment — the command a candidate reaches
for when the objective is to demonstrate *doing*, not just knowing.
Where `quiz` tests whether a candidate can pick the right answer under time
pressure, `lab` asks a different question: *can this candidate build,
troubleshoot, design, and explain their way through the decisions an expert
would face in real work?* `lab` judges both the final deliverable and the
reasoning that led to it, making explicit the difference between a candidate
who got lucky and one who knows.

`lab` never drafts its own exercises and never scores its own work. Every
exercise `lab` presents comes from `question-generator`'s `generate(objective,
form)` (adapted to hands-on forms), and every submission is classified by
`assessment-engine`'s `classify(answer)` — this file does not restate either
engine's rules; see `references/engines/question-generator.md` and
`references/engines/assessment-engine.md` for the authoritative logic `lab`
runs underneath. `lab` is certification-agnostic: the same exercise types
below run identically whether the candidate is building infrastructure, 
writing code, designing systems, or configuring services — nothing about
exercise sourcing, evaluation, or scoring is hardcoded to a specific
provider's domain.

---

## Exercise types

`lab` serves eight hands-on exercise forms. The candidate encounters them
mixed through their study plan (not isolated by type), and each form tests
the candidate's ability to apply knowledge in conditions closer to real work
than a multiple-choice question allows:

- **Hands-on labs** — the candidate performs a concrete task in a simulated
  or real environment: write code, deploy a service, configure a system,
  run a command. The deliverable is the working result (code that runs,
  output from a deployed resource, a configuration file that passes
  validation). Judgment is not "does the code look pretty" — it is "does the
  code solve the stated problem and demonstrate understanding of the
  underlying concept," per `assessment-engine`'s classifier applied to the
  reasoning the candidate explains alongside the code.

- **Troubleshooting exercises** — given a broken system, incorrect output, or
  a failing deployment, the candidate must diagnose the root cause, explain
  what went wrong and why, and either fix it or prescribe the fix. The
  challenge is not "find the typo" (surface-level) — it is "trace the
  failure back to a misconception or gap in understanding." A candidate
  who fixes the symptom without naming the cause is scored as "guessed
  correctly" or "cannot apply"; one who misdiagnoses but for a articulate
  wrong reason is "has a misconception" and feeds mistake-ledger. One who
  diagnoses correctly and explains the failure mechanism is "knows."

- **Configuration tasks** — the candidate provisions, configures, or
  policies a system to meet stated requirements (least privilege, cost
  optimization, compliance). The deliverable is a config file, a set of
  policy statements, or a step-by-step procedure. Evaluation focuses on
  whether the candidate understood *why* these specific settings solve the
  problem (not just copy-pasted a template), tested for completeness, and
  can articulate trade-offs (e.g., "I chose X over Y because...").

- **Architecture decisions** — the candidate is given a scenario (a new
  feature, a scaling bottleneck, a security incident) and asked "what would
  you do and why?" The deliverable is a design sketch, a decision matrix, or
  a narrative explaining the approach. Evaluation judges the reasoning
  (is the candidate aware of relevant trade-offs?), not perfection.
  A candidate who chooses a suboptimal but well-reasoned path and explains
  the constraints they optimized for is "partially understands" or "knows"
  depending on how complete the reasoning is; one who chooses the right
  design for incoherent reasons is "guessed correctly."

- **CLI exercises** — the candidate must construct command lines, scripts, or
  queries that accomplish a task. The deliverable is the command, the
  script, or the query output. Evaluation includes both correctness and the
  candidate's explanation of what each part does — a command that works by
  accident (they tried 5 variations and picked the one that happened to
  work) is "guessed correctly"; one where the candidate explains the flag
  choices and the pipeline is "knows."

- **Code snippet analysis** — given a code snippet (working or broken, from
  an exam domain like infrastructure-as-code, a query language, a
  configuration DSL), the candidate must explain what it does, predict what
  it outputs, identify a bug, or explain why a specific line is necessary.
  Evaluation judges whether the candidate read and understood the code or
  merely recognized a familiar pattern. A candidate who can extend the
  snippet to a changed scenario (e.g., "what if the input changed to X?")
  is "knows"; one who recites the code's visible terms is "memorized
  terminology."

- **Incident scenarios** — the candidate is presented with a timeline of
  events (alerts fired, logs appeared, a service degraded) and asked to
  trace the root cause or prescribe the next debugging step. Unlike
  troubleshooting exercises, these are open-ended — multiple valid next
  steps may exist, and the candidate must justify their choice. Evaluation
  focuses on reasoning: does the candidate understand the system well enough
  to rule out irrelevant hypotheses and prioritize investigations? A
  candidate who names the right next step for incoherent reasons is "cannot
  apply"; one who names a less-obvious-but-justified next step is "knows."

- **"What would you do next?" exercises** — given a partial task or a
  decision point, the candidate must name and justify the next logical step.
  Examples: "You've deployed the service. What would you do next to ensure
  it's stable?" or "Your test suite passes locally but fails in CI. What
  would you check?" These are rapid exercises, not essay questions. A
  coherent, justified answer (even if not the only right answer) signals
  "knows" or "partially understands"; an answer that misses the context or
  assumes a fact not in evidence signals a gap.

---

## Evaluation

`lab` judges every submission on two dimensions: **correctness of the final
deliverable** and **soundness of the reasoning behind it.** Correctness alone
is never sufficient to pass — a candidate can produce working code or a
correct answer while fundamentally misunderstanding the concept, and `lab`
is designed to surface that difference.

### Scoring inputs

Every submission collects the same four inputs that `assessment-engine`'s
`classify(answer)` requires:

- **The deliverable** — the code, config, design, command, or explanation the
  candidate produced.
- **Stated confidence** (1-5) — collected *before* the deliverable is
  evaluated, so the candidate cannot adjust their confidence post-hoc based
  on feedback.
- **The "I guessed" flag** — an explicit yes/no: did the candidate work
  through the problem systematically, or did they try multiple approaches
  until something worked?
- **Stated reasoning** — the candidate is always asked to explain their
  approach: "Why did you write this code this way?", "What does this config
  accomplish and why is it necessary?", "Walk me through your
  troubleshooting logic."

On exercises where the deliverable is inherently observable (working code, a
passing deployment, correct command output), the evaluation also includes
objective correctness. On more open-ended exercises (architecture decisions,
incident investigation), correctness is replaced with *soundness* — does the
reasoning hold up, even if not every detail is perfect?

### Classification per exercise form

`lab` applies the same six-way classification (`knows`, `partially
understands`, `memorized terminology`, `guessed correctly`, `has a
misconception`, `cannot apply`) as `assessment-engine` defines, but the
decision path is sensitive to the exercise form:

- **Hands-on labs / Configuration tasks / CLI exercises** — An exercise with
  a verifiable correct answer. Evaluation order:
  1. Check whether the deliverable is functionally correct.
  2. If correct: check `I guessed: yes` (yes -> **guessed correctly**,
     overriding confidence). If no, check the stated reasoning: does the
     candidate explain *why* this approach solves the problem in terms of
     the underlying concept (e.g., "I used -r for recursive because...")?
     If yes and confidence is 4-5, **knows**. If the reasoning is partial
     or confidence is 2-3, **partially understands**. If the explanation
     only recites the command/code verbatim and doesn't extend to a variant,
     **memorized terminology**.
  3. If incorrect: check the reasoning. If it reveals a specific wrong
     mental model articulated (e.g., "I thought the flag did X when it
     actually does Y"), **has a misconception**. If reasoning is absent or
     vague, **cannot apply**.

- **Troubleshooting exercises** — Evaluation order:
  1. Check whether the candidate identified the root cause correctly.
  2. If correct: check the explanation. Does it reveal understanding of
     *why* the failure occurred (a chain of causation, not just naming the
     symptom)? If yes and confidence is 4-5, **knows**. If the explanation
     is incomplete or confidence is lower, **partially understands**. If
     the candidate named the right fix but couldn't explain the underlying
     mechanism, **guessed correctly**.
  3. If incorrect: does the reasoning reveal a specific misconception (the
     candidate believed the system worked differently)? **has a
     misconception**. Otherwise, **cannot apply**.

- **Architecture decisions** — No single correct answer, so evaluation
  focuses entirely on reasoning:
  1. Is the candidate aware of relevant trade-offs (cost vs. performance,
     simplicity vs. flexibility, etc.)?
  2. Did they articulate constraints and explain which ones they optimized
     for?
  3. Is the proposed design internally coherent (does it actually solve the
     stated problem)?
  Answers that score **knows** are those where reasoning is complete,
  trade-offs are articulated, and the design is coherent. **Partially
  understands** when the reasoning addresses some but not all relevant
  factors. **Cannot apply** when the candidate proposes a design without
  meaningful justification or misunderstands the scenario. **Has a
  misconception** if the reasoning reveals a specific wrong belief about
  how systems or trade-offs work.

- **Incident scenarios / "What next?" exercises** — Evaluation focuses on
  whether the candidate can prioritize and justify:
  1. Is the named next step relevant to the problem?
  2. Is the justification sound (would this step actually narrow down the
     hypothesis space)?
  **Knows** when step + justification are both solid. **Partially
  understands** when the step is reasonable but the justification is
  incomplete. **Cannot apply** when the step is off-base or reasoning is
  absent.

### Reasoning transparency

`lab` does not ask for reasoning as optional extra credit. On every exercise,
every candidate is asked to explain their approach *before* the deliverable
is judged correct/incorrect. This is what allows `assessment-engine` to
distinguish a right answer by lucky guessing from a right answer by
understanding — the reasoning statement is the evidence that separates them.

Candidates are also not told "your answer is correct" first and then asked
to explain; explanation is collected upfront, so the candidate cannot
rationalize backwards from a revealed answer. This preserves the integrity
of the reasoning signal and keeps `lab` honest about whether the candidate
understood or merely recognized.

---

## Outputs

`lab` writes to two existing per-cert files — it does not introduce a
template of its own, only appends to ones `quiz`, `mock`, and other
assessment commands already populate:

- **`.certicoach/<cert-slug>/question-attempts.md`** — every exercise `lab`
  serves is recorded per `question-generator`'s "record on serve" step and
  `references/state-schema.md`'s template: Exercise ID, domain, type
  (`hands-on`, `troubleshooting`, `configuration`, `architecture`,
  `cli-exercise`, `code-snippet`, `incident`, `what-next`), `Served in:
  lab`, date, the `[GENERATED PRACTICE]` label, and (once answered)
  correctness and time taken. This is what keeps dedup and
  `readiness-engine`'s unseen-question accuracy signal accurate for every
  later session, regardless of which command serves next.

- **`.certicoach/<cert-slug>/mistake-ledger.md`** — every submission
  `assessment-engine` classifies as `has a misconception` or `cannot apply`
  becomes a new row: the exercise (tagged `[GENERATED PRACTICE]`), the
  candidate's stated approach (not the final code/config, but the reasoning),
  the correct approach or expected reasoning, the root cause named from the
  candidate's explanation (e.g., "conflated concurrency with parallelism",
  "assumed config inheritance without checking precedence"), the exam
  objective, and `Next review` left for `spaced-repetition-engine` to
  schedule. `lab` never scores a miss silently — a session that produces
  misses with no corresponding ledger rows has not finished writing its
  outputs.

`lab` reports the session's per-domain and aggregate results (accuracy, a
confidence calibration verdict per `assessment-engine`'s `calibration(history)`
across the full session, and form-specific signals like whether the
candidate's reasoning showed understanding or guessing) back to the candidate
at session end, but does not maintain a separate results file — `gap-analysis.md`
recomputes domain standing from `question-attempts.md` and `mistake-ledger.md`
the next time `gaps` runs, rather than `lab` writing a parallel, potentially
inconsistent summary of the same data.

### Why `lab` matters alongside `quiz` and `mock`

A candidate can ace a multiple-choice `quiz` (select the right option, even
if by recognition) and still fail to *apply* the concept in a real
environment. `lab` catches the difference: a candidate who can explain the
reasoning behind a design or a troubleshooting decision but struggles with
the hands-on execution is a different failure mode than one who guesses
correctly on five multiple-choice questions but can name zero supporting
reason. Conversely, a candidate who can build working code but cannot
articulate why the code works (a misconception masked by pattern-matching or
trial-and-error) is caught when `lab` requires explanation. The three
commands — `quiz`, `lab`, `mock` — together form a multi-signal readiness
picture: quiz + lab catch reasoning gaps that raw accuracy misses, and mock
validates transfer to an exam-like time-pressure scenario. No one command
sees the full picture.
