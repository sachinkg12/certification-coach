# CertiCoach

CertiCoach is a Claude Code skill that coaches you end-to-end through earning any professional certification. It discovers and validates the exam through live research with sourced facts, profiles you as a candidate, runs a baseline diagnostic, analyzes your gaps, generates a personalized study plan, teaches adaptively with plain-language analogies, drills original practice questions and hands-on labs, simulates the real exam, and judges your readiness.

## Install

```bash
git clone https://github.com/sachinkg12/certicoach.git ~/.claude/skills/certicoach
```

## Example

Say "Generative AI Leader, Google" and CertiCoach runs `discover` to research that exact certification live — exam code, syllabus, duration, question count and types, passing-score policy, cost, renewal, and prerequisites — provenance-tagging every fact it finds. From those sourced facts it then profiles you as a candidate, runs a baseline diagnostic, and builds a personalized study plan tailored to your gaps and target date.

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

## License

MIT — see [LICENSE](LICENSE).
