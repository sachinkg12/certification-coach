# CertiCoach — Behavioral Verification Checklist

**Purpose:** the harness in `verify/verify.sh` proves every spec requirement
maps to a non-empty implementing file, but that only proves the file exists —
it says nothing about whether running the skill actually behaves per spec.
This checklist is the behavioral half of verification (spec §11): a scripted,
hand-checkable walkthrough a human (or an agent driving the skill) runs
against a fixed **golden fixture certification** and checks off.

**Golden fixture:** AWS Certified Solutions Architect – Associate (SAA-C03).
Chosen because it is stable, well-documented, and has a public exam guide, so
facts gathered by `discover` are independently verifiable.

**This fixture is for internal verification only.** CertiCoach itself is
certification-agnostic — nothing in the shipped skill hardcodes AWS, SAA-C03,
or any other provider. Every assertion below is phrased as "the mechanism
behaves correctly," never "the skill knows about AWS."

Run this checklist end-to-end (or wave-by-wave, per spec §10) whenever a
command or engine file changes in a way that could alter behavior, not just
structure.

---

## Wave 1 — Foundation: `discover`

- [ ] Running `discover` for "AWS Certified Solutions Architect – Associate,
      Amazon Web Services" elicits all six identifying inputs one at a time
      (exact name, provider, target date, region, online/center, version) —
      never as a bulk form dump (Priority Hierarchy rule 4).
- [ ] The resulting `.certicoach/<cert-slug>/exam-facts.md` contains a line
      for exam code, syllabus/domains, duration, question count/types,
      passing-score policy, cost, renewal, prerequisites, and recent changes.
- [ ] **Every single fact line** in `exam-facts.md` carries a provenance tag
      in the form `[OFFICIAL — <url> — retrieved <date>]` (or `[COMMUNITY —
      <source>]` for non-official corroboration). No line is unlabeled.
- [ ] `exam-facts.md` records an explicit exam version and a "last verified"
      date.
- [ ] If web access is unavailable during `discover`, the skill refuses to
      assert facts and instead asks the candidate to paste the official page
      — it never fabricates a plausible-looking exam-facts row.

## Wave 2 — Assess: `diagnose`, `gaps`

- [ ] Seeded `diagnose` case — assessment-engine classification, hand-checked:
      Given a candidate who answers a networking question **correctly**, with
      **high stated confidence**, but whose free-text justification uses the
      right term with an inverted definition (e.g. correctly picks "NAT
      gateway" but explains it as "letting outside traffic reach private
      instances" — backwards), the assessment-engine classifies this as
      **"memorized terminology"** or **"has a misconception,"** not
      **"knows."** A second seeded case — correct answer, high confidence,
      justification that correctly explains *why* the other options are
      wrong — classifies as **"knows."** The two seeded cases must not
      produce the same classification.
- [ ] `gaps` seeded `Priority` arithmetic, hand-checked: for a domain with
      `ExamWeight = 0.30`, `KnowledgeGap = 0.6` (i.e. 40% mastery), and
      `ForgettingRisk = 1.2` (last reviewed 10 days ago, past the 7-day
      threshold), `gaps` computes
      `Priority = 0.30 × 0.6 × 1.2 = 0.216`.
      Re-running with a fresher `last-review` date (`ForgettingRisk = 1.0`)
      must lower `Priority` to `0.30 × 0.6 × 1.0 = 0.18` — confirming the
      forgetting-risk decay term actually moves the score, not just the
      exam-weight or gap terms.
- [ ] The domain with the highest computed `Priority` is the domain `gaps`
      surfaces first in its readiness table (table is priority-sorted, not
      insertion-order).

## Wave 3 — Plan & teach: `plan`, `learn`, `explain`, `quiz`

- [ ] `plan` presents distinct path archetypes (fast-track / balanced /
      deep-mastery / weekend-only / experienced-professional / beginner) and
      waits for the candidate to choose — it does not silently pick one.
- [ ] Every week item in the generated `plan.md` names concrete
      objectives-covered, material, and an exit criterion. No week item reads
      as a vague "study X for 3 days" with nothing else specified.
- [ ] `quiz` and `mock` output: every generated question is labeled
      `[GENERATED PRACTICE]`. No question is ever presented as a real,
      leaked, or official exam question.
- [ ] Dedup check: running `quiz` twice in a row against the same
      `question-attempts.md` produces **zero overlapping question IDs**
      between the two runs (question-generator consults `question-attempts.md`
      before serving).
- [ ] `explain`, run against a genuinely abstract exam term (e.g.
      "eventual consistency" or "publish/subscribe"), produces three parts in
      order: (1) a plain-language restatement, (2) a concrete real-world
      analogy, and (3) an explicit **"where this analogy breaks down"** line
      that names a specific way the analogy would mislead if taken literally.
      Output missing part (3) fails this check.
- [ ] `learn`, run on a seeded case where the same misconception (e.g.
      confusing authentication with authorization) appears on two consecutive
      questions, branches into a remedial micro-lesson on the second
      occurrence rather than simply moving to the next question — i.e. the
      adaptive-engine's repeated-misconception rule actually fires and is
      observable in the transcript (a distinct "let's slow down on X" beat
      before the next question).
- [ ] `learn`'s remedial branch, when the misconception is rooted in
      confused/abstract terminology, automatically invokes the analogy-engine
      (visible as an analogy appearing without the candidate typing
      `explain`).

## Wave 4 — Retention & rigor: `review`, `lab`, `resources`

- [ ] A `mistake-ledger.md` entry with a `Next review` date in the past shows
      up in `review`'s due list; an entry with a future `Next review` date
      does not.
- [ ] After a `review` answer is marked correct, the entry's next scheduled
      review date advances along the 1/3/7/14-day sequence (not reset to 1
      day, not left unchanged).
- [ ] `lab` output judges the candidate's stated reasoning path, not only
      whether the final answer matches — a wrong final answer reached via
      sound reasoning is scored differently from a "lucky" correct answer
      reached via unsound reasoning (both are distinguishable in feedback).
- [ ] `resources` returns a **minimum-sufficient** set — no two recommended
      items in the same category cover the same domain redundantly without a
      stated reason (e.g. "supplementary, adds hands-on labs the primary
      guide lacks").

## Wave 5 — Exam & beyond: `mock`, `readiness`, `logistics`, `postexam`,
`progress`

- [ ] `mock` output reflects the real exam's question count, duration, and
      domain distribution as recorded in `exam-facts.md` — not a fixed
      hardcoded count.
- [ ] Seeded `readiness` refusal case: a candidate profile with 3 passing
      mock scores, ≥80% on unseen questions, and mocks within the time limit,
      but **one domain at 65%** (below the 70% per-domain minimum), must
      **not** return "Exam ready." It returns "Nearly ready" or "Ready with
      specific risks" instead — the domain-minimum rule overrides the
      otherwise-passing aggregate signals.
- [ ] A second seeded case with the same aggregate signals and **all domains
      ≥70%** returns "Exam ready" — confirming the domain-floor rule is the
      actual gate, not a decorative check.
- [ ] `progress`'s explainability narrative, run after a plan change, states
      the change in concrete before/after terms (e.g. a percentage-point
      shift and the resulting reallocation of upcoming sessions) rather than
      a generic "your plan has been updated."
- [ ] `postexam`, given a captured fail result with a domain-level score
      report, produces a retake plan that specifically targets the weak
      domains from that score report — not a full restart of the original
      plan.

## Cross-cutting: anti-hallucination pass

- [ ] Scan every `.certicoach/<cert-slug>/*.md` file produced during this
      walkthrough: every factual claim about the exam itself carries an
      `[OFFICIAL — ...]` or `[COMMUNITY — ...]` tag, and every generated
      question or exercise carries `[GENERATED PRACTICE]`. No line asserts an
      exam fact with no tag, and no generated content is described as "real"
      or "leaked."
- [ ] No output at any point in this walkthrough claims SAA-C03-specific
      knowledge as if hardcoded — every fact traces to a `discover`-time
      citation, confirming the mechanism is agnostic and this run is only
      exercising it against one example cert.
