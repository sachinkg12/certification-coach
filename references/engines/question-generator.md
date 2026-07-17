# Question Generator Engine

Produces every practice question CertiCoach shows a candidate. This engine
is the copyright and integrity core of the skill: it manufactures original
content mapped to a certification's public syllabus, never reproduces or
approximates a real exam item, and stamps everything it emits with the
`[GENERATED PRACTICE]` tag defined in `provenance-engine`'s content-tier
list so a generated question can never be mistaken for a leaked or
official one.

Produces the operations `generate(objective, form)`, `is_duplicate(candidate,
question-attempts)`, and `label(question)`. Consumed by `learn`, `quiz`,
and `mock` — no command drafts its own practice question or writes its own
served-question row to `question-attempts.md`; every question a candidate
sees routes through this engine first.

---

## Generation rules

Every question this engine produces must satisfy all of the following
before it is eligible to be served:

- **Original** — the question text, scenario, distractors, and
  explanation are freshly composed by CertiCoach for this candidate. This
  engine never reproduces, quotes, closely paraphrases, or lightly
  reworks an item from a real exam, a braindump site, a leaked question
  bank, or any other third-party question source. If a topic is only
  known to this engine because of memorized exam-dump content, it is not
  eligible material — the engine drafts a new question that tests the
  same underlying concept from a different angle (different scenario,
  different framing, different distractors) rather than adapting a
  recalled item.
- **Mapped to a public objective** — every question cites the specific
  syllabus objective it tests, drawn from `exam-facts.md`'s "Syllabus /
  domains" table (e.g. "Domain: Security — Objective: configure
  least-privilege access policies"). A question with no traceable
  objective is not eligible to be served, since `gap-analysis` and
  `plan` depend on every practice item being attributable to a real
  domain the candidate is being measured against.
- **Form-appropriate** — the engine supports the question forms the
  calling command needs and does not silently substitute one for
  another:
  - **Conceptual** — tests recall and understanding of a definition,
    principle, or relationship without a narrative wrapper.
  - **Scenario-based** — poses a short, realistic situation (a task, an
    incident, a design constraint) and asks what the candidate would do
    or conclude, exercising application rather than recall.
  - **Multiple-choice** — exactly one correct option among plausible
    distractors; distractors reflect real misconceptions (per
    `assessment-engine`'s "has a misconception" state) rather than
    obviously-wrong filler.
  - **Multiple-response** — more than one correct option, explicitly
    labeled as "select all that apply" so the candidate is not misled
    into single-answer habits that don't transfer to the real exam
    format.
  - Additional forms (e.g. ordering, matching, short free-response for
    `learn`'s explanatory mode) are permitted as long as they meet every
    rule on this list; the form itself never changes the originality or
    labeling requirements.
- **Difficulty-aware** — the engine accepts a target difficulty
  (aligned to the candidate's current mastery for that domain, per
  `priority-engine`'s `KnowledgeGap`) and composes distractors and
  scenario complexity to match, so `quiz` and `mock` can request harder
  items for domains near mastery and gentler items for domains still
  being built up.

**Hard boundary:** this engine never presents generated content as an
actual, leaked, or verbatim exam question, and never claims a generated
question appeared on anyone's real exam. Every question is, and is
described as, CertiCoach's own practice material written to exercise a
public objective — nothing this engine emits is a substitute claim for
"this is what the real exam asks," only for "this is what mastering this
objective requires you to be able to do."

---

## Dedup against question-attempts

Before a candidate question is served, `generate(objective, form)` checks
the candidate text against `question-attempts.md` for the active
`<cert-slug>` so the same question is never repeated to the same
candidate:

1. **Derive a stable Question ID.** Each generated question gets a stable
   hash or slug derived from its objective, form, and core text, matching
   the `Question ID` column contract in `references/state-schema.md`'s
   `question-attempts.md` template. The ID must be stable across sessions
   so a re-derivation of the same underlying question (same objective,
   same phrasing) produces the same ID rather than silently duplicating
   under a new key.
2. **Check `is_duplicate(candidate, question-attempts)`.** Look up the
   candidate's Question ID (and, as a secondary check, near-identical
   text under a different ID — e.g. the same scenario reworded) against
   every row already logged for this `<cert-slug>` in
   `question-attempts.md`, regardless of which command served it
   (`learn`, `quiz`, `mock`, or `lab`). A match on either check means the
   candidate has already seen this question and it is not eligible to be
   served again.
3. **Regenerate on collision.** If the candidate question is a duplicate,
   the engine drafts a new candidate for the same objective and form —
   varying the scenario, the numbers, the distractor set, or the framing
   — and re-runs the duplicate check. This repeats until an unseen
   question is produced or the objective's reasonable variation is
   exhausted, in which case the calling command is told this objective
   has no fresh question available right now rather than being served a
   repeat silently.
4. **Record on serve.** Once a question clears the duplicate check and is
   shown to the candidate, the serving command appends a row to
   `question-attempts.md` with the Question ID, domain, type, which
   command served it, the date, the `[GENERATED PRACTICE]` label, and
   (once answered) correctness and time taken — exactly the columns
   `references/state-schema.md` defines. This is what keeps the dedup
   check complete for the next call: a question generated but never
   logged would be re-servable by mistake, so recording happens as part
   of serving, not as an optional follow-up.

This dedup pass is also what makes "accuracy on unseen questions" — a
signal `readiness-engine` depends on for its readiness verdict —
meaningful: a question only counts as "unseen" if it is genuinely absent
from the candidate's `question-attempts.md` history, and this engine is
the sole gate that guarantees that absence is real rather than a logging
gap.

---

## Labeling

Every question this engine produces carries the `[GENERATED PRACTICE]`
tag from `provenance-engine`'s three-tier content model, applied by
`label(question)` at two points:

- **At presentation** — the tag is shown alongside the question text
  wherever `learn`, `quiz`, or `mock` displays it to the candidate, so
  the candidate can see at a glance that this is CertiCoach-authored
  practice material, not a claim about the real exam's actual content.
- **In stored records** — every row this engine's output produces in
  `question-attempts.md` carries `[GENERATED PRACTICE]` in the `Label`
  column, and any row a missed question generates in
  `mistake-ledger.md` carries the same tag in its `Question` field.
  `references/state-schema.md` treats this as a hard constraint for
  `question-attempts.md`: no other tier is valid there, because that
  file only ever logs originally generated practice content.

No other tier — `[OFFICIAL — source + date]` or `[COMMUNITY — source]` —
is ever attached to output from this engine, and this engine never
generates a question that omits the tag under any calling command's
request. This is the anti-hallucination guarantee `provenance-engine`
establishes for practice content specifically: a candidate reviewing
their `question-attempts.md` history, their `mistake-ledger.md`, or a
live `quiz`/`mock` session can never encounter a question that looks like
it came from the certification provider when it did not. The label is
not cosmetic — it is what lets every downstream engine and every human
reviewing this state tell generated practice apart from a verified fact
about the real exam, with zero ambiguity.
