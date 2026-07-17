# CertiCoach

CertiCoach is a Claude Code skill that coaches you end-to-end through earning any professional certification. It discovers and validates the exam through live research with sourced facts, profiles you as a candidate, runs a baseline diagnostic, analyzes your gaps, generates a personalized study plan, teaches adaptively with plain-language analogies, drills original practice questions and hands-on labs, simulates the real exam, judges your readiness, and renders your progress as a private local dashboard.

It is **certification-agnostic** — nothing is hardcoded to a provider. Name any active certification and CertiCoach researches *that* exam live and drives everything from the sourced facts.

## Install

```bash
git clone https://github.com/sachinkg12/certification-coach.git ~/.claude/skills/certicoach
```

Then, in any Claude Code session: *"use certicoach — I want to prepare for &lt;any certification&gt;."*

To update later: `cd ~/.claude/skills/certicoach && git pull`.

## Example

Say "Generative AI Leader, Google" and CertiCoach runs `discover` to research that exact certification live — exam code, syllabus, duration, question count and types, passing-score policy, cost, renewal, and prerequisites — provenance-tagging every fact it finds. From those sourced facts it then profiles you as a candidate, runs a baseline diagnostic, and builds a personalized study plan tailored to your gaps and target date. As you study, `dashboard` renders a local snapshot of your readiness, due reviews, and plan position.

## Commands

| Command | Responsibility |
|---|---|
| `discover` | Research and validate the exam, writing sourced facts to `exam-facts.md`. |
| `profile` | Build a candidate profile: experience, role, learning style, hours/week, goal. |
| `diagnose` | Run a baseline diagnostic across every exam domain. |
| `gaps` | Produce a domain readiness table ranked by priority. |
| `plan` | Generate a personalized, weekly study plan. |
| `resources` | Curate a minimum-sufficient set of study materials. |
| `learn` | Adaptive teaching loop with remediation and misconception tracking. |
| `explain` | Translate tough exam wording into plain language with an analogy. |
| `lab` | Generate hands-on labs, troubleshooting, and scenario tasks. |
| `quiz` | Run topic, mixed-domain, timed, or explanation-based assessments. |
| `mock` | Simulate a realistic, full-length exam. |
| `review` | Spaced-repetition review of due and weak-area material. |
| `readiness` | Give a multi-signal readiness verdict. |
| `logistics` | Cover exam-day logistics and final preparation. |
| `postexam` | Capture results, plan retakes, and recommend next steps. |
| `progress` | Report weekly progress and explain plan changes. |
| `dashboard` | Render your local progress as a self-contained HTML tracker. |

## Progress tracker

`dashboard` reads your local state and writes a self-contained `.certicoach/dashboard.html`
— readiness, per-domain bars, cards due, streak, plan position, and mistake ledger —
that you open in a browser. It is **offline and fully local**: no external requests, no
data leaves your machine (a build check fails on any external URL). It's a snapshot,
regenerated on demand and at the end of each session.

## How it stays trustworthy

- **Sourced, not guessed.** Every exam fact is tagged with its source and retrieval date; facts with no source are never written. Content is labeled by tier: `[OFFICIAL]`, `[COMMUNITY]`, `[GENERATED PRACTICE]`.
- **Original practice only.** Generated questions are original, mapped to public exam objectives, and never presented as real or leaked exam questions. No exam dumps.
- **Multi-signal readiness.** Readiness is judged on many signals (scores across days, per-domain minimums, unseen-question accuracy, calibration, unresolved misconceptions) — never a single mock percentage.
- **Local and private.** Your prep lives in a `.certicoach/` folder in your working directory (git-ignored). It never enters this repo.

## License

MIT — see [LICENSE](LICENSE).
