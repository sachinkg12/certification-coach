# `diagnose`

Module 3: a baseline test across every domain in the target exam's syllabus,
taken before any study has happened and before a plan exists. `diagnose`
exists to answer one question honestly: what does the candidate already
know, right now, and how much can their own confidence be trusted? The
answer becomes the starting line every later module measures progress
against — `gaps` computes its first `gap-analysis.md` from this baseline,
`plan` sizes the study effort against it, and `readiness` later compares
final performance back to it to show how far the candidate has come.

`diagnose` runs after `discover` has produced `exam-facts.md` (the domain
list this baseline must cover) and, where available, after `profile` has
captured self-reported per-domain familiarity — but it does not trust
self-reported familiarity as a substitute for testing. A candidate who
rates themselves "5" on a domain in `profile.md` is still asked baseline
questions on that domain here, because self-report and demonstrated
knowledge are exactly the gap this module is built to measure.

`diagnose` never invents its own way of judging an answer. Every answer
collected here is routed through `assessment-engine`'s `classify(answer)`
for the six-way signal and `calibration(history)` for the confidence
verdict before it is written to `diagnostic.md` — no shortcut scoring
("correct = knows") is ever applied. `diagnose` is certification-agnostic:
it runs identically whether the syllabus in `exam-facts.md` lists three
domains or twelve — nothing about the protocol or the output format is
hardcoded to a specific provider or exam.

---

## Coverage

`diagnose` tests **every domain** listed in the target certification's
`exam-facts.md :: Syllabus / domains` table — no domain is skipped, and no
domain is over-sampled just because it carries a higher exam weight. A
baseline exists to find out what's true everywhere, not to spend the
candidate's limited attention pre-emptively on the domains `exam-facts.md`
already says matter most; that weighting is `priority-engine`'s job later,
using this baseline as one of its inputs.

Because this is a baseline and not a full mock exam, `diagnose` keeps the
question count per domain small (typically two to three) rather than
exhaustive — enough to distinguish a domain the candidate can reason about
from one that's a blind spot, not enough to burn the question budget that
`quiz` and `mock` need later. Every domain still receives a **mix** of
question types so a single lucky guess on one format doesn't stand in for
the whole domain:

- **Conceptual** — tests whether the candidate can state and reason about a
  core idea from the domain (e.g. "What is the difference between X and Y,
  and when would you choose one over the other?").
- **Scenario-based** — places the concept in a realistic situation drawn
  from the domain's stated objectives and asks what the candidate would do
  or why a given outcome occurred. This is what separates "memorized
  terminology" from "knows" per `assessment-engine`'s classifier.
- **Hands-on / debugging** — presents a concrete artifact (a config
  snippet, an error message, a command's output, a broken setup) and asks
  the candidate to diagnose or fix it. For domains where the certification
  is inherently conceptual and no hands-on objective exists in
  `exam-facts.md`, this slot is replaced with a second scenario-based
  question rather than fabricated hands-on content that doesn't match the
  exam.

`diagnose` maps every question it asks back to a specific objective in
`exam-facts.md`'s syllabus table, never to a generic domain label alone —
this mapping is what lets `gap-analysis` and `mistake-ledger` later name a
gap precisely instead of vaguely.

---

## Protocol

`diagnose` runs one question at a time, in spirit: it presents a single
question, waits for the candidate's answer, and only then asks the two
follow-up items below before moving to the next question. It does not
front-load a wall of questions for the candidate to answer in one pass —
each question's confidence rating and "I guessed" flag must be captured
while the answer is still fresh, not reconstructed afterward.

For each question, in order:

1. **Present the question**, tagged with its domain, objective, and
   question type (conceptual, scenario, or hands-on), and labeled
   `[GENERATED PRACTICE]` per the Integrity rule below.
2. **Collect the answer.**
3. **Collect a confidence rating (1-5)** — "How confident are you in that
   answer?" — captured before revealing correctness, so the rating reflects
   the candidate's actual state of mind and not a reaction to being told
   right or wrong.
4. **Collect an explicit "I guessed" flag (yes/no)** — asked as its own
   question, distinct from the confidence rating, since a candidate can be
   confident in a guess or unconfident in reasoned recall; `assessment-engine`
   treats this flag as authoritative over confidence when the two disagree.
5. **Ask for the candidate's reasoning** — "Why do you think that's the
   answer?" — even on a question the candidate feels sure about. This is
   the input `assessment-engine` needs to distinguish "knows" from
   "memorized terminology" and "has a misconception" from "cannot apply";
   skipping it collapses four of the six signal states down to two.
6. **Reveal correctness and classify** — once the answer, confidence,
   guess flag, and reasoning are all collected, `diagnose` calls
   `assessment-engine`'s `classify(answer)` to produce exactly one of the
   six verbatim signal terms (knows, partially understands, memorized
   terminology, guessed correctly, has a misconception, cannot apply) and
   records the result. The candidate is told whether they were correct and
   given a brief, plain-language explanation before the next question.

Because no study has happened yet, `diagnose` keeps this baseline short but
domain-complete: it does not chase every follow-up scenario the way `quiz`
or `mock` might, and it does not stop early just because a candidate is
answering well — a domain-complete baseline is what `gaps` and `plan` need,
even from a candidate who is clearly strong in most areas. Once every
domain has been covered, `diagnose` runs `assessment-engine`'s
`calibration(history)` over the full attempt to produce the per-domain and
aggregate calibration verdicts, then writes the results.

---

## Outputs

`diagnose` writes exactly one thing, conforming byte-for-byte to the
`diagnostic.md` template in `state-schema.md`:

**`.certicoach/<cert-slug>/diagnostic.md`** — a new `## Attempt: YYYY-MM-DD`
entry is appended (prior attempts are never discarded, per
`state-schema.md`'s additive-history rule) containing:

- **Domains covered** — the full domain list from `exam-facts.md`, confirming
  no domain was skipped.
- **`### Answers`** table — one row per question, with columns `#`, `Domain`,
  `Question type` (conceptual | scenario | hands-on), `Confidence (1-5)`,
  `I guessed` (yes | no), `Correct` (yes | no), and `Signal`. The `Signal`
  value is always one of the six verbatim terms produced by
  `assessment-engine`'s `classify(answer)` — knows, partially understands,
  memorized terminology, guessed correctly, has a misconception, cannot
  apply — never a paraphrase or a shortened form.
- **`### Per-domain baseline`** table — one row per domain with a computed
  score and a short signal summary (e.g. "2/3 correct, 1 guessed correctly,
  1 misconception on retry semantics") so `gaps` can read domain standing
  without re-deriving it from the raw answer rows.
- **`### Notes`** — misconceptions surfaced during the reasoning step, and
  any cross-domain pattern worth flagging to `gap-analysis` (e.g. the
  candidate consistently guesses on hands-on questions across multiple
  domains, suggesting a lab-access or practice gap rather than a
  per-domain knowledge gap).

**INTEGRITY.** Every question `diagnose` presents is original content
written by `diagnose` itself, mapped to a public objective from
`exam-facts.md`'s syllabus table — never a real, leaked, or memorized exam
question. Every such question is labeled `[GENERATED PRACTICE]` when
presented to the candidate and wherever it is referenced in
`diagnostic.md`, per `state-schema.md`'s content-tier rule, so the
candidate can never mistake a baseline question for the real exam.
