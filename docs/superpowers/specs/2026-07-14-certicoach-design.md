# CertiCoach — Design Spec

**Date:** 2026-07-14
**Status:** Approved for implementation planning
**Type:** Claude Code skill, distributed via GitHub

## 1. Summary

CertiCoach is a distributable Claude Code skill that coaches a person through
earning any professional certification end-to-end: discovering and validating
the exam, profiling the candidate, running a baseline diagnostic, analyzing
gaps, generating a personalized study plan, teaching adaptively, drilling with
original practice questions and labs, simulating the real exam, judging
readiness, and handling exam-day logistics and post-exam follow-up.

It is **certification-agnostic**. Nothing is hardcoded to a provider. When a
user names a cert — e.g. *"Generative AI Leader, Google"* — the skill researches
that specific exam live and drives every downstream module from the sourced
facts.

The skill is published on GitHub and installed by cloning into
`~/.claude/skills/certicoach/`. It is structured as one `SKILL.md` orchestrator,
a `references/` library, per-module command files, shared engines, and a
persistent per-user state directory.

## 2. Goals & non-goals

**Goals**
- Work for any active certification from any provider via live web research.
- Make every factual claim about an exam traceable to a source and dated.
- Produce a personalized plan grounded in a real diagnostic, not a generic
  template.
- Maintain continuity across sessions (weak areas, scores, mistakes, schedule).
- Judge readiness on multiple signals, never a single mock-test percentage.
- Ship as a clean, documented, downloadable GitHub repo.

**Non-goals**
- No literal autonomous subagents in v1. The "12 agents" are modes/commands
  within one skill (deterministic stages, same model, different prompts).
- No collection or reproduction of exam dumps. All practice content is original
  and mapped to public objectives.
- No assumption of any environment beyond Claude Code + web access; degrade
  gracefully when web is unavailable.

## 3. Architecture

The repo root **is** the skill.

```
certicoach/                        # git repo root == installed skill
  SKILL.md                         # orchestrator: priority hierarchy, session protocol, routing
  README.md                        # what it is, worked example, install instructions
  LICENSE
  VERSIONS.md
  .gitignore                       # excludes users' .certicoach/ state
  references/
    commands/                      # one file per module (see §5)
      discover.md  profile.md  diagnose.md  gaps.md  plan.md
      resources.md  learn.md  explain.md  lab.md  quiz.md  mock.md
      review.md  readiness.md  logistics.md  postexam.md  progress.md
    engines/                       # shared cross-cutting logic, called by many commands (see §6)
      provenance-engine.md  assessment-engine.md  priority-engine.md
      adaptive-engine.md  readiness-engine.md  spaced-repetition-engine.md
      question-generator.md  analogy-engine.md
    state-schema.md                # canonical .certicoach/ file formats
    coaching-voice.md              # explainability + tone rules
```

**Agents → modes.** Each of the 12 proposed agents (Exam Researcher, Candidate
Assessor, Curriculum Planner, Resource Curator, Tutor, Lab Generator, Question
Generator, Evaluator, Adaptive Coach, Exam Simulator, Readiness Judge, Progress
Tracker) is realized as a command and/or engine, not a separate autonomous
process.

## 4. Data model — per-user runtime state

Written to `.certicoach/` in the **user's working directory** (never inside the
installed skill), so prep data travels with the user and multi-cert prep is
isolated per certification.

```
.certicoach/
  index.md                         # registry of active certs + which is current
  <cert-slug>/
    exam-facts.md                  # code, syllabus, duration, question count/types,
                                   #   passing policy, cost, renewal, prerequisites,
                                   #   recent changes — every line source-tagged
                                   #   (URL + retrieval date) + exam version
    profile.md                     # experience vs THIS platform, role, tech used,
                                   #   prior certs, per-domain familiarity, hours/wk,
                                   #   learning style, target date, budget, labs access, goal
    diagnostic.md                  # baseline per domain; each answer carries confidence
                                   #   rating + explicit "I guessed"; 6-way signal
    gap-analysis.md                # domain readiness table + Priority score per domain
    plan.md                        # chosen path archetype, week-by-week, exit criteria
    resources.md                   # curated minimum-sufficient set, version-matched
    mistake-ledger.md              # Q / user answer / correct / root cause / objective / next-review
    spaced-repetition.md           # review queue, 1/3/7/14-day scheduling, weak-area queue
    question-attempts.md           # every question served (dedupe + unseen-question tracking)
    readiness.md                   # score history, calibration, verdict over time
    progress-log.md                # sessions, streak, milestones, missed-plan recovery
```

`.gitignore` in the skill repo excludes `.certicoach/` so users never commit
personal prep data.

## 5. Modules (commands)

Invoked by word after the skill loads. Numbers refer to the original 14-module
brief.

| Command | Module | Responsibility |
|---|---|---|
| `discover` | 1 | Elicit the 6 identifying inputs (exact name, provider, target date, region, online/center, version); web-research + provenance-tag exam code, syllabus, duration, question count/types, passing-score policy, cost, renewal, prerequisites, recent changes. Verify cert is still active. Writes `exam-facts.md`. |
| `profile` | 2 | Candidate profiling: experience relative to *this* platform, role, recent tech, prior certs, per-domain familiarity, hours/week, learning style, target date, budget, labs/cloud access, goal (pass / master / interview). |
| `diagnose` | 3 | Baseline test spanning every domain: conceptual + scenario + hands-on/debugging; per-answer confidence rating + explicit "I guessed" option. Classifies via assessment-engine. |
| `gaps` | 4 | Domain readiness table (weight, current level, priority). `Priority = ExamWeight × KnowledgeGap × ForgettingRisk`. |
| `plan` | 5 | Generate the 6 path archetypes (fast-track / balanced / deep-mastery / weekend-only / experienced-professional / beginner); user selects; weekly granularity — what/why/objectives-covered/material/hands-on/revision/practice-target/exit-criteria. No vague "study X for 3 days" items. |
| `resources` | 6 | Curate a **minimum-sufficient** set across 9 categories (official guide, official docs, official training, books, video, labs, community notes, practice exams, cheat sheets). Track version-match, cost, est. time, difficulty, domain coverage, last-updated, primary/supplementary. Avoid overlapping recommendations. |
| `learn` | 8 | Adaptive teaching loop: evaluate → explain why right/wrong → name underlying misconception → generate remedial micro-lesson → ask a related-but-different question → update the plan. Invokes `analogy-engine` automatically when a misconception is rooted in confused/abstract terminology. |
| `explain` | — | Translate tough exam wording into plain language plus a concrete real-world analogy (via `analogy-engine`), then map the analogy back to the exact exam terminology and note where the analogy breaks down. |
| `lab` | 7 | Generate hands-on work: labs, troubleshooting, config tasks, architecture decisions, CLI exercises, code snippets, incident scenarios, "what next?" Judges reasoning and implementation, not just final answer. |
| `quiz` | 10 | Assessment modes: topic, mixed-domain, timed mini-tests, oral questioning, rapid-fire terminology, explanation-based, adaptive. Sometimes asks the user to explain why the *other* options are wrong. |
| `mock` | 11 | Realistic full simulation: question count, duration, domain distribution, difficulty progression, flag-for-review, negative wording, scenario length, time pressure, break rules, multi-select formats; simulates decision-making under uncertainty. |
| `review` | 9 | Spaced repetition, flashcards, daily-five revision, mistake-ledger review by due date, frequently-confused-concepts and weak-area queues. |
| `readiness` | 12 | Multi-signal verdict (see readiness-engine). Output one of: Not ready / Nearly ready / Exam ready / Ready with specific risks. |
| `logistics` | 13 | Registration, ID requirements, online-proctoring setup, test-center rules, rescheduling policy, exam-day checklist, time-management strategy, handling unknown questions, final-24h plan. |
| `postexam` | 14 | Capture result, analyze weak areas from score report, retake plan when required, recommend next cert, convert learning into a project/portfolio item, generate interview questions, track renewal / continuing-education. |
| `progress` | — | Weekly progress report, streak, milestones, missed-plan recovery, and the explainability narrative for *why* the plan changed. |

## 6. Shared engines

Logic used by multiple commands lives once in `references/engines/`.

- **provenance-engine** — the 3-tier content labeling used everywhere:
  `[OFFICIAL — source + date]`, `[COMMUNITY — source]`, `[GENERATED PRACTICE]`.
  Rules for what may be written to `exam-facts.md` (must carry provenance).
  Version-awareness alerts: syllabus change, exam retiring, new exam code,
  previously-selected materials now outdated. If web is unavailable, the engine
  refuses to assert facts and asks the user to paste the official page.
- **assessment-engine** — the 6-way answer classifier: knows / partially
  understands / memorized terminology / guessed correctly / has a misconception /
  cannot apply. Confidence-calibration scoring (compare stated confidence to
  correctness).
- **priority-engine** — `Priority = ExamWeight × KnowledgeGap × ForgettingRisk`,
  including the forgetting-risk decay model driven by last-review dates.
- **adaptive-engine** — the teaching-loop state machine; decides when to branch
  into remediation (e.g. repeated auth-vs-authz confusion) vs advance, and how a
  result updates `plan.md`.
- **readiness-engine** — multi-rule verdict. Considers average score, score
  stability, per-domain minimums, accuracy on unseen questions, confidence
  calibration, time per question, hands-on performance, count of unresolved
  misconceptions, and performance across several days. Example rule set:
  ≥3 passing mock exams, no major domain <70%, ≥80% on unseen questions, mocks
  within time limit, no critical misconception repeated in the last two
  assessments.
- **spaced-repetition-engine** — 1/3/7/14-day review scheduling + weak-area
  queue; feeds `review` and `mistake-ledger`.
- **question-generator** — produces original questions mapped to public exam
  objectives, always labeled `[GENERATED PRACTICE]`, deduped against
  `question-attempts.md`. Never presented as leaked/real exam questions.
- **analogy-engine** — turns tough, abstract exam wording into a concrete
  real-world analogy drawn from everyday operations (not more jargon). Example:
  publish/subscribe explained as a notice pinned to a board that every
  interested team subscribes to, each getting its own copy, so the announcer
  posts once and never needs to know who is listening. Every analogy ships with
  two mandatory companions: (a) the precise technical restatement mapped back to
  the exam's exact terminology, and (b) an explicit **"where this analogy breaks
  down"** caveat, because a leaky analogy manufactures the very misconceptions
  the skill exists to prevent (e.g. the board analogy must note that subscribers
  get independent copies, ordering isn't guaranteed, and the announcer doesn't
  wait for slow readers). Analogies are labeled explanatory aids, never
  presented as official exam wording. Called on demand by `explain` and
  automatically by `learn` when a misconception is rooted in terminology
  confusion.

## 7. Orchestration & session protocol

The orchestrator behaves as follows:

- **On load:** read `.certicoach/index.md`, select the current cert, run any
  schema migration + a staleness check on the exam version and target date, then
  recommend the single highest-leverage next action (e.g. diagnostic not yet
  taken → `diagnose`; mock overdue → `mock`; ledger items past review date →
  `review`; target date passed → re-scope).
- **State saves** happen mid-session after any major workflow completes, not just
  at session end, so an interrupted session loses nothing.
- **Explainability:** whenever the plan changes, state why in concrete terms
  (e.g. *"Networking improved 52%→78%, but security is 48% and is 25% of the
  exam, so the next three sessions focus on identity, access control, and
  encryption"*).
- **Priority hierarchy** (when instructions compete): session state continuity →
  provenance/anti-hallucination → triage-before-template (personalize, never run
  the same assembly line) → one-question-at-a-time → coaching voice → schema
  compliance.

## 8. Anti-hallucination, integrity & version awareness

- Three content tiers labeled in all output (§6 provenance-engine).
- Exam facts require provenance to be persisted; unsourced facts are not written.
- Generated practice is always marked as such and mapped to public objectives;
  no exam dumps, no "real/leaked" claims.
- Version awareness: `exam-facts.md` stores the exam version; the skill alerts
  when the syllabus changes, an exam is retiring, a new code is released, or
  selected materials become outdated.

## 9. Distribution (GitHub)

- Repo root is the skill; install = clone into `~/.claude/skills/certicoach/`.
- `README.md`: description, the "Generative AI Leader, Google" worked example,
  install steps, command list, the anti-dump/integrity stance.
- `LICENSE`, `VERSIONS.md`, and `.gitignore` excluding `.certicoach/`.
- No environment assumptions beyond Claude Code + web access.

## 10. Build order (waves)

The skill is fully specified; implementation proceeds in waves, each usable on
its own.

1. **Foundation** — `SKILL.md`, `.certicoach/` state schema + `index.md`
   registry, session protocol, provenance-engine, `discover`. → Identify and
   validate any cert with sourced facts.
2. **Assess** — `profile`, assessment-engine, `diagnose`, priority-engine,
   `gaps`. → Personalized readiness picture.
3. **Plan & teach** — `plan` (6 archetypes), question-generator, `learn` +
   adaptive-engine, analogy-engine + `explain`, `quiz`. → Core study loop with
   plain-language analogies for tough wording.
4. **Retention & rigor** — spaced-repetition-engine, `review`, mistake-ledger
   wiring, `lab`, `resources`. → Memory system + hands-on + curation.
5. **Exam & beyond** — `mock`, readiness-engine + `readiness`, `logistics`,
   `postexam`, `progress`. → End-to-end through exam day and after.

## 11. Testing / verification

A skill is verified behaviorally, not unit-tested. Using a fixed **golden
fixture cert** (AWS Solutions Architect Associate, SAA-C03 — stable and
well-documented), each wave has a scripted walkthrough asserting:

- Files land in the correct `.certicoach/` shape and formats.
- Every exam fact in `exam-facts.md` carries a source + retrieval date.
- Generated questions are labeled `[GENERATED PRACTICE]` and deduped against
  `question-attempts.md`.
- `Priority` and readiness rules compute correctly on known seeded inputs.
- The adaptive loop branches to remediation on a seeded repeated misconception.
- An anti-hallucination assertion pass finds no unsourced facts and no
  "real exam" claims.

The fixture is for internal testing only; the shipped product is cert-agnostic.
