# CertiCoach Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build CertiCoach — a distributable, certification-agnostic Claude Code skill that coaches a user end-to-end through earning any professional certification, with a machine-checkable verification harness proving every spec requirement is implemented.

**Architecture:** The repo root is the skill: one `SKILL.md` orchestrator, a `references/commands/*.md` library (one per module), `references/engines/*.md` (shared logic), plus `references/state-schema.md` and `references/coaching-voice.md`. Per-user runtime state is written to a `.certicoach/` directory in the user's working directory. A `verify/` harness (shell + manifest files) provides structural, anti-hallucination, cross-reference, and spec-coverage checks that every task extends and re-runs.

**Tech Stack:** Markdown + YAML frontmatter (the skill). Bash + coreutils/grep for the verification harness (no runtime deps, matches "assume nothing beyond Claude Code + web access"). Git for version control.

## Global Constraints

Copied verbatim from the spec; every task's requirements implicitly include these.

- Certification-agnostic: nothing hardcoded to a provider; behavior derives from live-researched exam facts.
- Provenance-or-silence: no exam fact is written to `exam-facts.md` without a source URL + retrieval date; if web is unavailable the skill refuses to assert facts and asks the user to paste the official page.
- Three content tiers labeled in all output: `[OFFICIAL — source + date]`, `[COMMUNITY — source]`, `[GENERATED PRACTICE]`.
- Generated questions always labeled `[GENERATED PRACTICE]`, mapped to public objectives, deduped against `question-attempts.md`, never presented as leaked/real exam questions. No exam dumps.
- Every analogy ships with (a) a precise technical restatement mapped to exam terminology and (b) an explicit "where this analogy breaks down" caveat; analogies are labeled explanatory aids.
- Readiness is multi-signal, never a single mock percentage; verdict is one of: Not ready / Nearly ready / Exam ready / Ready with specific risks.
- Priority formula: `Priority = ExamWeight × KnowledgeGap × ForgettingRisk`.
- Per-user state lives in `.certicoach/` in the user's working directory, never inside the installed skill; `.gitignore` excludes `.certicoach/`.
- The name of the source skill that inspired the architecture must never appear anywhere in the repo (files or git history). The harness enforces this via a base64-encoded pattern (`verify/forbidden-encoded.txt`) decoded at runtime, so the literal string is never stored in any file.
- Install target: clone into `~/.claude/skills/certicoach/`; `SKILL.md` must be at repo root with valid `name` + `description` frontmatter.
- No environment assumptions beyond Claude Code + web access; degrade gracefully without web.
- Golden test fixture: AWS Solutions Architect Associate (SAA-C03), used for internal behavioral verification only; product stays cert-agnostic.

---

## File Structure

**Skill files (shipped):**
- `SKILL.md` — orchestrator: frontmatter, priority hierarchy, session protocol, command routing.
- `references/state-schema.md` — canonical `.certicoach/` file formats + templates.
- `references/coaching-voice.md` — explainability + tone rules.
- `references/engines/{provenance,assessment,priority,adaptive,readiness,spaced-repetition,question-generator,analogy}-engine.md`
- `references/commands/{discover,profile,diagnose,gaps,plan,resources,learn,explain,lab,quiz,mock,review,readiness,logistics,postexam,progress}.md`
- `README.md`, `LICENSE`, `VERSIONS.md`, `.gitignore`

**Verification harness (not shipped as skill logic, lives in repo):**
- `verify/verify.sh` — entry point; runs all check modules; non-zero exit on any failure.
- `verify/required-files.txt` — one path per line; every path must exist and be non-empty.
- `verify/required-sections.tsv` — `filepath<TAB>required heading text`; heading must be present in file.
- `verify/forbidden-patterns.tsv` — `pattern<TAB>human reason`; grep must find zero matches across the repo (excludes `verify/` so the manifest itself isn't a false positive).
- `verify/forbidden-encoded.txt` — base64-encoded forbidden strings (e.g. the source-skill name), decoded at runtime and grepped repo-wide; keeps the literal out of every file so even the manifest is clean.
- `verify/crossref.tsv` — `referencing-file<TAB>token that must exist as a file under references/`; ensures commands reference only real engines/files.
- `verify/spec-coverage.tsv` — `spec-section id<TAB>implementing filepath<TAB>short label`; the coverage gate asserts each implementing file exists and is non-empty.

Each task appends its own lines to these manifests (the "failing test"), then creates the file(s) that satisfy them.

---

## Task 1: Repo scaffolding + skill entry point

**Files:**
- Create: `SKILL.md`
- Create: `README.md`, `VERSIONS.md`
- Modify: `.gitignore` (already contains `.certicoach/`)
- Create: `LICENSE`

**Interfaces:**
- Produces: `SKILL.md` at repo root with frontmatter keys `name: certicoach` and a `description:` line; section headings `## Priority Hierarchy`, `## Session Protocol`, `## Commands`.

- [ ] **Step 1: Create `SKILL.md` with frontmatter + top-level skeleton headings**

```markdown
---
name: certicoach
description: Coaches a user end-to-end through earning any professional certification — discovers and validates the exam via live research with sourced facts, profiles the candidate, runs a baseline diagnostic, analyzes gaps, generates a personalized study plan, teaches adaptively with plain-language analogies, drills original practice questions and labs, simulates the real exam, and judges readiness. Use when someone names a certification they want to prepare for.
---

# CertiCoach

You are an expert certification coach. You combine adaptive teaching with rigorous, evidence-based, source-verified exam preparation.

## Priority Hierarchy
<!-- filled in Task 15 -->

## Session Protocol
<!-- filled in Task 15 -->

## Commands
<!-- routing table filled as commands are added -->
```

- [ ] **Step 2: Create `README.md`, `VERSIONS.md`, `LICENSE`**

`README.md` must contain headings `## Install` (with `git clone ... ~/.claude/skills/certicoach`) and `## Example` (the "Generative AI Leader, Google" worked example) and `## Commands`. `VERSIONS.md` starts with `## v0.1.0`. `LICENSE` = MIT with the repo owner's name.

- [ ] **Step 3: Run structural check (expect FAIL — harness not built yet)**

Run: `bash verify/verify.sh`
Expected: FAIL / "no such file" — harness is built in Task 2. This confirms the harness is the gate.

- [ ] **Step 4: Commit**

```bash
git add SKILL.md README.md VERSIONS.md LICENSE .gitignore
git commit -m "feat: scaffold certicoach skill entry point and repo files"
```

---

## Task 2: Verification harness (the spine)

**Files:**
- Create: `verify/verify.sh`, `verify/required-files.txt`, `verify/required-sections.tsv`, `verify/forbidden-patterns.tsv`, `verify/crossref.tsv`, `verify/spec-coverage.tsv`

**Interfaces:**
- Produces: `bash verify/verify.sh` — runs five check modules; prints per-check PASS/FAIL; exits non-zero if any fail. Later tasks extend the six manifest files and re-run this.

- [ ] **Step 1: Write the harness script**

```bash
#!/usr/bin/env bash
# verify/verify.sh — CertiCoach verification harness. Run from repo root.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 2
fail=0
pass(){ printf '  PASS  %s\n' "$1"; }
bad(){ printf '  FAIL  %s\n' "$1"; fail=1; }

echo "== required files exist and are non-empty =="
while IFS= read -r f; do
  [ -z "$f" ] && continue; case "$f" in \#*) continue;; esac
  if [ -s "$f" ]; then pass "$f"; else bad "missing/empty: $f"; fi
done < verify/required-files.txt

echo "== required sections present =="
while IFS=$'\t' read -r file heading; do
  [ -z "${file:-}" ] && continue; case "$file" in \#*) continue;; esac
  if [ -f "$file" ] && grep -qF "$heading" "$file"; then pass "$file :: $heading";
  else bad "missing section in $file: $heading"; fi
done < verify/required-sections.tsv

echo "== forbidden patterns absent (repo-wide, excluding .git and verify/) =="
while IFS=$'\t' read -r pat reason; do
  [ -z "${pat:-}" ] && continue; case "$pat" in \#*) continue;; esac
  if grep -rIl --exclude-dir=.git --exclude-dir=verify --exclude-dir=docs -- "$pat" . >/dev/null 2>&1; then
    bad "found forbidden pattern '$pat' ($reason)";
  else pass "absent: $pat"; fi
done < verify/forbidden-patterns.tsv

echo "== forbidden encoded patterns absent (literal never stored; scans whole repo) =="
_b64d(){ base64 -d 2>/dev/null <<<"$1" || base64 -D 2>/dev/null <<<"$1"; }
while IFS= read -r enc; do
  [ -z "${enc:-}" ] && continue; case "$enc" in \#*) continue;; esac
  dec="$(_b64d "$enc")"
  if grep -rIl --exclude-dir=.git -- "$dec" . >/dev/null 2>&1; then
    bad "found forbidden (encoded) pattern";
  else pass "absent (encoded): $enc"; fi
done < verify/forbidden-encoded.txt

echo "== cross-references resolve to real files =="
while IFS=$'\t' read -r src token; do
  [ -z "${src:-}" ] && continue; case "$src" in \#*) continue;; esac
  if find references -type f -name "*${token}*" | grep -q .; then pass "$src -> $token";
  else bad "$src references missing file token: $token"; fi
done < verify/crossref.tsv

echo "== spec coverage: every mapped requirement has an implementing file =="
while IFS=$'\t' read -r sid impl label; do
  [ -z "${sid:-}" ] && continue; case "$sid" in \#*) continue;; esac
  if [ -s "$impl" ]; then pass "$sid ($label) -> $impl";
  else bad "$sid ($label) not implemented: $impl"; fi
done < verify/spec-coverage.tsv

echo; if [ "$fail" -eq 0 ]; then echo "ALL CHECKS PASSED"; else echo "CHECKS FAILED"; fi
exit "$fail"
```

- [ ] **Step 2: Seed the six manifests with Task 1's deliverables + global forbidden patterns**

`verify/required-files.txt`:
```
SKILL.md
README.md
VERSIONS.md
LICENSE
.gitignore
```
`verify/required-sections.tsv` (tab-separated):
```
SKILL.md	name: certicoach
SKILL.md	## Priority Hierarchy
SKILL.md	## Session Protocol
SKILL.md	## Commands
README.md	## Install
README.md	## Example
.gitignore	.certicoach/
```
`verify/forbidden-patterns.tsv`:
```
TODO	no placeholders in shipped skill
TBD	no placeholders in shipped skill
```
`verify/forbidden-encoded.txt` (base64 of the source-skill name, so the literal is never stored anywhere in the repo; decoded and grepped at runtime):
```
aW50ZXJ2aWV3LWNvYWNo
```
`verify/crossref.tsv`: leave header comment only for now:
```
# src<TAB>token — populated as commands reference engines
```
`verify/spec-coverage.tsv`:
```
# spec-id<TAB>implementing-file<TAB>label — one row per numbered spec requirement
spec-9	README.md	distribution/install docs
```

- [ ] **Step 3: Make executable and run (expect PASS)**

Run: `chmod +x verify/verify.sh && bash verify/verify.sh`
Expected: `ALL CHECKS PASSED`, exit 0.

- [ ] **Step 4: Commit**

```bash
git add verify/
git commit -m "test: add verification harness with structural, anti-hallucination, crossref, and spec-coverage checks"
```

---

## Task 3: State schema

**Files:**
- Create: `references/state-schema.md`
- Test: extends `verify/required-files.txt`, `verify/required-sections.tsv`, `verify/spec-coverage.tsv`

**Interfaces:**
- Produces: canonical templates for `index.md` and every `<cert-slug>/*.md` file listed in spec §4. Consumed by every command that reads/writes state.

- [ ] **Step 1: Add failing checks**

Append to `verify/required-files.txt`: `references/state-schema.md`.
Append to `verify/required-sections.tsv`:
```
references/state-schema.md	### index.md
references/state-schema.md	### exam-facts.md
references/state-schema.md	### profile.md
references/state-schema.md	### diagnostic.md
references/state-schema.md	### gap-analysis.md
references/state-schema.md	### plan.md
references/state-schema.md	### resources.md
references/state-schema.md	### mistake-ledger.md
references/state-schema.md	### spaced-repetition.md
references/state-schema.md	### question-attempts.md
references/state-schema.md	### readiness.md
references/state-schema.md	### progress-log.md
```
Append to `verify/spec-coverage.tsv`: `spec-4	references/state-schema.md	per-user state data model`.

- [ ] **Step 2: Run harness (expect FAIL on the new lines)**

Run: `bash verify/verify.sh`
Expected: FAIL listing the missing file + sections.

- [ ] **Step 3: Author `references/state-schema.md`**

One `### <filename>` subsection per file in spec §4, each with a fenced markdown template showing exact fields. `exam-facts.md` template shows every fact line ending with `— [OFFICIAL — <url> — retrieved YYYY-MM-DD]` and a `Exam version:` field. `mistake-ledger.md` template columns: Question / User answer / Correct / Root cause / Objective / Next review (YYYY-MM-DD). `diagnostic.md` records per-answer confidence + `I guessed` flag + the 6-way signal. `readiness.md` records per-attempt score, unseen-accuracy, time-vs-limit, calibration, verdict. Include a machine-parseable `index.md` template with a `current:` field and a certs table.

- [ ] **Step 4: Run harness (expect PASS)**

Run: `bash verify/verify.sh`
Expected: `ALL CHECKS PASSED`.

- [ ] **Step 5: Commit**

```bash
git add references/state-schema.md verify/
git commit -m "feat: add canonical .certicoach state schema and templates"
```

---

## Task 4: Provenance engine

**Files:**
- Create: `references/engines/provenance-engine.md`

**Interfaces:**
- Produces: rules `label_fact(fact, tier, source, date)`, `may_persist(fact)` (true only if source+date present), and `version_alert(old_facts, new_facts)`. Consumed by `discover`, `resources`, and the session protocol.

- [ ] **Step 1: Add failing checks**

Append to `verify/required-files.txt`: `references/engines/provenance-engine.md`.
Append to `verify/required-sections.tsv`:
```
references/engines/provenance-engine.md	## Content tiers
references/engines/provenance-engine.md	## Persistence rule
references/engines/provenance-engine.md	## Version-awareness alerts
references/engines/provenance-engine.md	## No-web degradation
```
Append to `verify/spec-coverage.tsv`:
```
spec-8-provenance	references/engines/provenance-engine.md	3-tier labeling + provenance
spec-8-version	references/engines/provenance-engine.md	version awareness alerts
```

- [ ] **Step 2: Run harness (expect FAIL)** — `bash verify/verify.sh` → FAIL on new lines.

- [ ] **Step 3: Author the engine** with the three tier labels verbatim, the persistence rule (no source+date ⇒ do not write, ask user to paste official page), the four version-alert triggers (syllabus change, exam retiring, new code, materials outdated), and the no-web degradation behavior.

- [ ] **Step 4: Run harness (expect PASS)** — `bash verify/verify.sh`.

- [ ] **Step 5: Commit** — `git add ... && git commit -m "feat: add provenance engine (labeling, persistence rule, version alerts)"`.

---

## Task 5: `discover` command (Wave 1 — Foundation complete)

**Files:**
- Create: `references/commands/discover.md`

**Interfaces:**
- Consumes: `provenance-engine`, `state-schema` (`exam-facts.md`, `index.md`).
- Produces: writes `.certicoach/<slug>/exam-facts.md` and registers the cert in `index.md`.

- [ ] **Step 1: Add failing checks.** Append to `required-files.txt`: `references/commands/discover.md`. Append to `required-sections.tsv`: the six elicited inputs heading `## Inputs`, `## Research protocol`, `## Outputs`. Append to `crossref.tsv`:
```
references/commands/discover.md	provenance-engine
```
(Cross-ref tokens must name files under `references/` only; state files like `exam-facts.md` are validated via their `state-schema.md` templates, not crossref.) Append to `spec-coverage.tsv`: `spec-5-discover	references/commands/discover.md	module 1 discovery+validation`.

- [ ] **Step 2: Run harness (expect FAIL)** — `bash verify/verify.sh`.

- [ ] **Step 3: Author `discover.md`**: elicit the 6 identifying inputs (exact name, provider, target date, region, online/center, version); web-research + provenance-tag exam code, syllabus, duration, question count/types, passing policy, cost, renewal, prerequisites, recent changes; verify cert still active; write outputs via state-schema templates.

- [ ] **Step 4: Run harness (expect PASS).**

- [ ] **Step 5: Commit** — `git commit -m "feat: add discover command (module 1) — Wave 1 foundation complete"`.

---

## Task 6: `profile` command

Same 5-step rhythm. Author `references/commands/profile.md` (module 2): elicit experience relative to *this* platform, role, recent tech, prior certs, per-domain familiarity, hours/week, learning style, target date, budget, labs/cloud access, goal (pass/master/interview); writes `profile.md`. Checks: required-files + sections `## Inputs`/`## Outputs`; crossref to `profile` schema; spec-coverage `spec-5-profile`. Commit `feat: add profile command (module 2)`.

## Task 7: Assessment engine

Author `references/engines/assessment-engine.md`: the 6-way classifier (knows / partially understands / memorized terminology / guessed correctly / has a misconception / cannot apply) and confidence-calibration scoring (stated confidence vs correctness). Sections `## Six-way classifier`, `## Confidence calibration`. spec-coverage `spec-6-assessment`. Commit `feat: add assessment engine`.

## Task 8: `diagnose` command

Author `references/commands/diagnose.md` (module 3): baseline test across every domain — conceptual + scenario + hands-on/debugging; per-answer confidence rating + explicit "I guessed"; classify via assessment-engine; write `diagnostic.md`. crossref → `assessment-engine`. spec-coverage `spec-5-diagnose`. Commit.

## Task 9: Priority engine

Author `references/engines/priority-engine.md`: `Priority = ExamWeight × KnowledgeGap × ForgettingRisk` with the forgetting-risk decay model driven by last-review dates; worked example. Section `## Formula`, `## Forgetting-risk model`. spec-coverage `spec-6-priority`. Add forbidden-pattern check that the literal formula string appears (positive check via required-sections). Commit.

## Task 10: `gaps` command (Wave 2 — Assess complete)

Author `references/commands/gaps.md` (module 4): domain readiness table (weight, current level, priority) computed via priority-engine; write `gap-analysis.md`. crossref → `priority-engine`. spec-coverage `spec-5-gaps`. Commit `feat: add gaps command (module 4) — Wave 2 assess complete`.

---

## Task 11: `plan` command

Author `references/commands/plan.md` (module 5): generate the 6 path archetypes (fast-track / balanced / deep-mastery / weekend-only / experienced-professional / beginner); user selects; weekly granularity with what/why/objectives-covered/material/hands-on/revision/practice-target/exit-criteria; forbid vague items. required-sections must include all six archetype names (one check each) so the harness proves all six exist. Write `plan.md`. spec-coverage `spec-5-plan`. Commit.

## Task 12: Question generator engine

Author `references/engines/question-generator.md`: original questions mapped to public objectives, always labeled `[GENERATED PRACTICE]`, deduped against `question-attempts.md`, never leaked/real. Sections `## Generation rules`, `## Dedup against question-attempts`, `## Labeling`. Add a **positive** required-sections check that the literal label `[GENERATED PRACTICE]` appears in this engine. (Do not add blunt forbidden greps for `leaked`/`real exam`/`braindump` — they false-positive on the engine's own "never leaked/real" rule; integrity against dumps is enforced by the engine's rules plus the final review.) spec-coverage `spec-6-question-generator`, `spec-8-integrity`. Commit.

## Task 13: Adaptive engine

Author `references/engines/adaptive-engine.md`: teaching-loop state machine — evaluate → explain → name misconception → remedial micro-lesson → related-but-different question → update `plan.md`; branching rule for remediation vs advance (e.g. repeated auth-vs-authz). Sections `## Loop`, `## Remediation branch`. spec-coverage `spec-6-adaptive`. Commit.

## Task 14: Analogy engine

Author `references/engines/analogy-engine.md`: turns abstract exam wording into an everyday-operations analogy; MUST pair every analogy with (a) precise technical restatement mapped to exam terms and (b) explicit "where this analogy breaks down" caveat; labeled explanatory aid. Include the pub/sub notice-board reference example and its breakdown notes (independent copies, no ordering guarantee, doesn't wait for slow readers). Sections `## Analogy contract`, `## Where this breaks down`, `## Worked example`. Add required-sections check for the literal heading `## Where this breaks down`. spec-coverage `spec-6-analogy`. Commit.

## Task 15: `learn` + `explain` commands + fill SKILL.md orchestrator (Wave 3 — Plan & teach complete)

**Files:** Create `references/commands/learn.md`, `references/commands/explain.md`; Modify `SKILL.md`.

- Author `learn.md` (module 8): drives adaptive-engine; auto-invokes analogy-engine on terminology-confusion misconceptions. crossref → `adaptive-engine`, `analogy-engine`.
- Author `explain.md`: translate tough wording → analogy via analogy-engine → map back to exam terms → note breakdown. crossref → `analogy-engine`.
- Fill `SKILL.md` `## Priority Hierarchy` (session-state continuity → provenance/anti-hallucination → triage-before-template → one-question-at-a-time → coaching voice → schema compliance), `## Session Protocol` (load `index.md`, select current cert, staleness check on exam version + target date, recommend single highest-leverage next action; mid-session saves), and `## Commands` routing table listing all 16 commands.
- Also create `references/coaching-voice.md` (explainability narrative rule with the "networking 52%→78% but security 48%" example). required-sections: `SKILL.md :: ## Commands` already checked; add `references/coaching-voice.md :: ## Explainability`.
- spec-coverage: `spec-5-learn`, `spec-5-explain`, `spec-7-orchestration`, `spec-7-explainability`.
- Commit `feat: add learn+explain, fill orchestrator — Wave 3 plan & teach complete`.

## Task 16: `quiz` command

Author `references/commands/quiz.md` (module 10): assessment modes (topic, mixed-domain, timed mini-tests, oral, rapid-fire terminology, explanation-based, adaptive); sometimes asks user to explain why the *other* options are wrong; uses question-generator. crossref → `question-generator`. spec-coverage `spec-5-quiz`. Commit.

---

## Task 17: Spaced-repetition engine

Author `references/engines/spaced-repetition-engine.md`: 1/3/7/14-day scheduling + weak-area queue; feeds `review` and `mistake-ledger`. Section `## Schedule`, `## Weak-area queue`. spec-coverage `spec-6-spaced-repetition`. Commit.

## Task 18: `review` command

Author `references/commands/review.md` (module 9): spaced repetition, flashcards, daily-five, mistake-ledger review by due date, frequently-confused-concepts + weak-area queues; reads/writes `spaced-repetition.md` + `mistake-ledger.md`. crossref → `spaced-repetition-engine`. spec-coverage `spec-5-review`. Commit.

## Task 19: `lab` command

Author `references/commands/lab.md` (module 7): generate labs/troubleshooting/config/architecture/CLI/code/incident/"what next?" exercises; judge reasoning + implementation, not just final answer. spec-coverage `spec-5-lab`. Commit.

## Task 20: `resources` command (Wave 4 — Retention & rigor complete)

Author `references/commands/resources.md` (module 6): curate a minimum-sufficient set across 9 categories; track version-match, cost, est. time, difficulty, domain coverage, last-updated, primary/supplementary; avoid overlapping recommendations; provenance-tag official items. crossref → `provenance-engine`. spec-coverage `spec-5-resources`. Commit `feat: add resources command — Wave 4 retention & rigor complete`.

---

## Task 21: Readiness engine

Author `references/engines/readiness-engine.md`: multi-signal verdict considering average score, stability, per-domain minimums, unseen-question accuracy, confidence calibration, time/question, hands-on performance, unresolved misconceptions, multi-day performance; example rule set (≥3 passing mocks, no domain <70%, ≥80% unseen, within time, no critical misconception repeated in last two). Verdict enum: Not ready / Nearly ready / Exam ready / Ready with specific risks. required-sections check for each of the four verdict strings. spec-coverage `spec-6-readiness`. Commit.

## Task 22: `mock` command

Author `references/commands/mock.md` (module 11): realistic full simulation (question count, duration, domain distribution, difficulty progression, flag-for-review, negative wording, scenario length, time pressure, break rules, multi-select); simulate decision-making under uncertainty; write results to `readiness.md`. crossref → `question-generator`, `readiness-engine`. spec-coverage `spec-5-mock`. Commit.

## Task 23: `readiness` command

Author `references/commands/readiness.md` (module 12): produce the multi-signal verdict via readiness-engine; never a single mock %. crossref → `readiness-engine`. spec-coverage `spec-5-readiness`. Commit.

## Task 24: `logistics` command

Author `references/commands/logistics.md` (module 13): registration, ID requirements, online-proctoring setup, test-center rules, rescheduling policy, exam-day checklist, time-management strategy, handling unknown questions, final-24h plan. spec-coverage `spec-5-logistics`. Commit.

## Task 25: `postexam` command

Author `references/commands/postexam.md` (module 14): capture result, analyze weak areas from score report, retake plan when required, recommend next cert, convert learning into portfolio/interview questions, track renewal/continuing-education. spec-coverage `spec-5-postexam`. Commit.

## Task 26: `progress` command (Wave 5 — Exam & beyond complete)

Author `references/commands/progress.md`: weekly report, streak, milestones, missed-plan recovery, and the explainability narrative for *why* the plan changed (uses coaching-voice). crossref → `coaching-voice`. spec-coverage `spec-5-progress`. Commit `feat: add progress command — Wave 5 complete`.

---

## Task 27: Full spec-coverage gate + behavioral golden-fixture walkthrough

**Files:**
- Create: `verify/spec-checklist.md` (human-run behavioral checklist against AWS SAA-C03)
- Modify: `verify/spec-coverage.tsv` (final audit), `SKILL.md` (`## Commands` table completeness)

**Interfaces:**
- Produces: a green `bash verify/verify.sh` proving every numbered spec requirement (spec §1–§11) maps to an implementing file, plus a documented behavioral walkthrough.

- [ ] **Step 1: Audit spec → coverage manifest.** Re-read `docs/superpowers/specs/2026-07-14-certicoach-design.md`. For every numbered section and every module/engine, confirm a `spec-coverage.tsv` row exists. Add rows for any spec item still unmapped (§2 goals/non-goals → the engines/commands enforcing them; §3 architecture → `SKILL.md`; §10 build order → covered implicitly; §11 testing → `verify/spec-checklist.md`). Add row `spec-11	verify/spec-checklist.md	behavioral verification`.

- [ ] **Step 2: Write `verify/spec-checklist.md`** — a scripted transcript against the golden fixture (SAA-C03) with checkbox assertions: `discover` produces `exam-facts.md` where every fact line carries `[OFFICIAL — url — retrieved ...]`; a seeded `diagnose` run classifies a memorized-vs-knows case correctly; `gaps` computes `Priority` correctly on a seeded domain (hand-checked arithmetic); `quiz`/`mock` output carries `[GENERATED PRACTICE]` and no item repeats vs `question-attempts.md`; `explain` output includes a "where this analogy breaks down" line; `learn` branches to remediation on a seeded repeated misconception; `readiness` refuses "Exam ready" when a domain is <70%.

- [ ] **Step 3: Run the full harness (expect PASS)**

Run: `bash verify/verify.sh`
Expected: `ALL CHECKS PASSED`, exit 0 — every required file present, every required section present, zero forbidden patterns, all cross-references resolve, every spec requirement mapped to a non-empty implementing file.

- [ ] **Step 4: Verify git history is clean of the forbidden string** (decode the pattern at runtime so the literal is never typed into the repo or a committed script)

Run: `git log -p | grep -c "$(base64 -d 2>/dev/null <<<"$(cat verify/forbidden-encoded.txt)" || base64 -D <<<"$(cat verify/forbidden-encoded.txt)")"`
Expected: `0`.

- [ ] **Step 5: Commit**

```bash
git add verify/ SKILL.md
git commit -m "test: add spec-coverage gate and behavioral golden-fixture checklist"
```

---

## Self-Review (completed by plan author)

**1. Spec coverage:** Every spec section is mapped — §1 summary → SKILL.md (Task 1/15); §2 goals/non-goals → enforced by provenance/question-generator/analogy engines + global forbidden-pattern checks (Tasks 4, 12, 14); §3 architecture/file-tree → the file structure realized across all tasks; §4 data model → Task 3; §5 all 16 modules → Tasks 5,6,8,10,11,15,16,18,19,20,22,23,24,25,26; §6 all 8 engines → Tasks 4,7,9,12,13,14,17,21; §7 orchestration/explainability → Task 15; §8 anti-hallucination/integrity/version → Tasks 4,12 + forbidden-pattern checks; §9 distribution → Task 1; §10 build order → wave-completion markers on Tasks 5,10,15,20,26; §11 testing → Tasks 2 & 27. The `spec-coverage.tsv` gate mechanically enforces this at the end.

**2. Placeholder scan:** No "TBD/TODO/implement later" in the shipped skill; the harness actively forbids `TODO`/`TBD` strings repo-wide. Plan-internal `<!-- filled in Task 15 -->` markers in SKILL.md are resolved by Task 15 before its checks pass.

**3. Type consistency:** Manifest filenames, engine names, and command names are used identically across tasks (`analogy-engine`, `question-generator`, `readiness-engine`, `exam-facts`, `question-attempts`); crossref checks fail the build if any command references a non-existent engine/file, catching drift automatically.
