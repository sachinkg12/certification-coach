# Post-Exam

Module 14: after the exam is complete, capture your result, analyze the
outcome, plan your next step (retake or forward progress), and track renewal
requirements. This module follows the exam itself and feeds into the next
certification cycle or completes the current one.

This module assumes `exam-facts.md` is complete and accessible (written by
`discover`), since renewal requirements and next-certification pathways are
sourced facts, never invented.

---

## Capture & analyze

Your score report is the single source of truth about what happened on the
exam. Capture it completely so later analysis has the full picture.

### Capturing your exam result

Within 24 hours of completing the exam, record these facts from your official
score report (the provider's certificate or email, not your memory):

- **Pass or fail** — the provider's binary verdict
- **Overall score** — the numeric or scaled score you received
- **Passing threshold** — the provider's minimum passing score, from `exam-facts.md`
- **Per-domain breakdown** — if the provider publishes per-domain scores or
  performance indicators, capture them exactly as reported; do not round or
  estimate. If the provider does not publish domain breakdowns, note "not
  provided" rather than deriving them yourself
- **Question types and performance** — if your report breaks down performance
  by question type (multiple choice vs. scenario vs. performance-based), record
  those; if not provided, note that
- **Exam date and time** — when you took it
- **Report retrieval date** — when you downloaded or retrieved the official
  score report (used later to validate whether your interpretation matches
  what the provider actually said)

Record all of this in `.certicoach/<cert-slug>/exam-result.md`, which is a
new file for this attempt. If you retake the exam, create a new dated entry
rather than overwriting — the history of attempts matters for understanding
your trajectory.

**Format:**

```markdown
# Exam Result — <cert-slug> — <exam date>

Reported: YYYY-MM-DD
Score report retrieved: YYYY-MM-DD

## Outcome

- Result: pass | fail
- Score: <numeric score or scaled score>
- Passing threshold: <score from exam-facts.md>
- Status: passed | failed

## Per-domain performance (if provided)

| Domain | Score / Performance indicator | Notes |
|---|---|---|

If per-domain breakdown not provided: not published by provider

## Question type performance (if provided)

| Question type | Accuracy | Count | Time |
|---|---|---|---|

If question-type breakdown not provided: not published by provider

## Weak areas identified (from score report)

- <specific concept or domain the report flags as lower performance>
- <specific concept or domain the report flags as lower performance>

If provider report does not flag specific weak areas: analysis not available
from provider; see "Analysis" section below.

## Analysis

### If you passed

- Domains with the strongest performance: <list from your score>
- Domains where you scored lowest (but still passing): <list from your score>
- Any patterns in the weak-but-passing domains: <what they have in common>

### If you failed

- Domains with the lowest performance: <list from your score, sorted by
  lowest-to-highest>
- Overall performance relative to passing threshold: <how far below the
  threshold, e.g., 20 points below>
- Question types where you struggled most (if data available): <specific
  types>
- Likely root causes based on your study history: <e.g., "did not reach
  practice-target accuracy on networking domain," "ran out of time on
  scenario questions," "weak-area queue for security was not completed
  before exam">
```

**Important:** Every number and fact in this report comes from your official
score report, not from your recollection or re-reading of the exam. If you're
unsure whether the provider publishes a metric, check the official report
directly rather than guessing.

### Analyzing weak areas

If your provider's score report identifies weak domains or concepts, use those
as your primary weak-area list. If the provider does not offer per-domain
scoring:

1. Cross-reference your low-performance questions (if you have access to an
   exam review) against the domains in `exam-facts.md`'s syllabus to map
   questions to domains
2. Note that this mapping is an inference, not an official breakdown — mark
   it as such in your analysis
3. If you don't have access to an exam review or question-level feedback,
   rely on your own recollection of which topics felt uncertain during the exam

Never invent a domain breakdown if the provider doesn't publish one and you
can't recall which questions belonged where. Instead, note "domain-level
analysis not available from provider; using question-attempt history as proxy"
and let the retake process (below) use your full study history rather than
guessing at domains.

---

## Next steps

Your next action depends on the outcome. There are two paths: retake (if you
didn't pass) or forward progress (if you passed).

### If you failed or will retake

Retaking requires a focused plan, not a full restart. The goal is to raise
your score above the passing threshold by fixing the specific weak domains
identified in your score report.

**Prepare for retake planning:**

1. **Open your score report** and list the domains where you scored lowest
2. **Check `exam-facts.md`** to confirm those domains are accurately named
3. **Run `gaps` to recompute priorities** — your diagnostic history, quiz
   results, and mistake-ledger are all unchanged, but `gaps` will show you
   which of your weak-exam-domains are still your study priorities (some may
   have improved during later study; some may still be high-priority)
4. **Review `progress-log.md`** to understand what changed between your last
   study session and the exam — did you miss weeks? Did you skip the
   revision schedule?
5. **Note any logistical issues** that affected the exam itself — ran out of
   time, technical failure, illness on exam day — these may change whether a
   retake plan focuses on study gaps or on exam-day strategy

**Building the retake plan:**

Once you've analyzed the weak domains and run `gaps`, retake planning reuses
the `plan` module's logic but with a tighter scope:

- Run `plan` and select the `fast-track` archetype
- When `plan` asks you to rank the domains you want to focus on, list only
  the domains where your exam score was lowest
- `plan` will generate a minimal-viable schedule that covers those domains
  at depth sufficient to pass (not just skim)
- The weeks in this retake plan will be shorter than your original plan was,
  since you're only reworking weak areas, not the full syllabus

**Set a new target exam date:**

Before running `plan`, update `profile.md`'s `Target exam date` to a date that
gives you enough weeks to:

1. Complete the retake plan weeks (the `plan` module will show you how many
   weeks `fast-track` needs for your weak domains)
2. Add one buffer week at the end (for contingency: missed weeks, a weak-area
   that needs more time, or a final readiness check before the retake)

Retake costs and deadlines are provider-specific facts in `exam-facts.md`'s
Cost & logistics section. Check whether retaking within your target window
incurs additional fees or has a registration deadline.

### If you passed

Passing this exam is a milestone on a longer path. The next step depends on
what you learned and what comes next.

**Immediate actions:**

1. **Update `index.md`** — change this certification's `Status` from `active`
   to `passed`, and record the exam date in a notes field so you have a
   timestamp of when you completed it
2. **Record the certification** — your provider will issue a credential (a
   digital badge, a certificate, or both). Download it and store it in a safe
   place; you'll reference it when updating resumes or portfolio profiles

**Identify your next step:**

Next-step options depend on your goal and what this certification opens:

- **Next certification in a sequence** — does your field have a natural
  progression (e.g., Foundational → Associate → Professional tier)? Check
  `exam-facts.md`'s prerequisites section to see if passing this exam is a
  prerequisite for the next one. If yes, consider registering for the next
  exam and starting a new `discover` session for that cert
- **Related but independent cert** — are there related certifications that
  complement this one but don't depend on it (e.g., multiple cloud-provider
  certs, or a specialization cert alongside a generalist cert)? Decide based
  on your role, goals, and available study time
- **Deepen mastery in this domain** — if your goal was "pass," you've
  succeeded; if your goal was "master," consider running an `advanced-topics`
  deep-dive (outside this skill's scope) to go beyond the exam blueprint
- **Shelve this cert** — if this was a one-time goal and you don't plan to
  recertify or pursue related certifications, note that in `index.md` and
  switch to a different certification or skill focus

**Convert learning into portfolio artifacts:**

Passing a certification proves you know the material. Converting that into
portfolio work makes it visible and valuable:

1. **Identify one real-world project or problem** that the certification
   covered and that you could solve end-to-end (e.g., if you passed a cloud
   infrastructure cert, design a multi-tier deployment; if you passed a
   security cert, audit a codebase for a specific class of vulnerability)
2. **Scope it small enough to complete in 1–2 weeks** — the goal is a
   concrete artifact (a writeup, a code repo, or a recorded walkthrough), not
   a massive production system
3. **Document it** — a README explaining what you built, why, and what you
   learned from the certification that made this project possible
4. **Link it** — add it to your portfolio or resume with a note that connects
   the project back to the certification (e.g., "Designed using patterns from
   the Google Cloud Architect certification")

**Generate interview-preparation material:**

Passing a certification proves mastery to yourself and to your resume; in an
interview, you need to explain what you know and why it matters.

Prepare 2–3 "story vignettes" that connect your certification to real work:

1. **Pick a domain from the exam** where you scored high or that felt most
   relevant to your role
2. **Recall a real situation** where you'd use that knowledge (a bug you
   debugged, a system you designed, or a problem you solved at work)
3. **Structure the story** in 2–3 sentences: "In [situation], we needed to
   [requirement]. I applied [specific concept from the cert] to [what you
   did], which resulted in [outcome]"
4. **Link back to the cert** — mention the certification name once per story
   so the interviewer connects your work experience to your credential

Examples:

- "We had a recurring outage in our authentication layer. Applying the IAM
  domain knowledge from the Google Cloud Architect cert, I redesigned our
  role-based access control to separate identity and resource permissions,
  which reduced our incident response time from 2 hours to 15 minutes."
- "Our CI/CD pipeline kept redeploying failed builds. Using the deployment
  patterns from the Kubernetes certification, I implemented deployment
  strategies with automated rollback, cutting our mean-time-to-recovery by
  70%."

These stories are conversational and specific. They're not scripted answers —
they're anchors you can adapt to whatever the interviewer asks about your
experience.

---

## Renewal tracking

Many certifications expire and require renewal: recertification exams,
continuing education credits, or periodic audits. Track yours so you don't
lose the credential by missing a deadline.

### Checking renewal requirements

Your provider publishes renewal rules in `exam-facts.md`. Before you do
anything else, open `exam-facts.md` and find the `Cost & logistics` section:

- **Renewal requirement** — the provider's official rule (e.g., "recertify
  every 3 years," "submit 30 continuing-education hours annually," "no
  renewal needed")
- **Renewal deadline** — when the current certification expires (if
  applicable)
- **Recertification exam** — if renewal requires an exam, is it the same exam
  you just took, a different exam, or a newer version?
- **Cost** — how much does recertification cost (sometimes free, sometimes
  equal to the original exam, sometimes different)

If any of these fields are missing from `exam-facts.md`, go back to `discover`
and look up the official renewal policy before scheduling anything.

### Calculating your renewal window

Once you have the renewal requirement from `exam-facts.md`, calculate your
personal renewal deadline:

- Exam date (from your `exam-result.md`): YYYY-MM-DD
- Renewal interval (from `exam-facts.md`): e.g., "3 years" or "1 year"
- Renewal deadline: exam date + interval (e.g., 3 years from exam date)
- "Renewal window" (when you should start renewing): typically 2–3 months
  before the deadline, so you have time to prepare without being rushed

Record this window in `index.md` so you have a single place to check all
upcoming renewal dates.

**Update `index.md`:**

```markdown
# CertiCoach Index

current: <cert-slug or empty>

## Certifications

| Slug | Name | Provider | Target date | Status | Last session |
|---|---|---|---|---|---|
| <cert-slug> | <exam name> | <provider> | <original target, or NA if passed> | passed | YYYY-MM-DD |

## Notes

- <cert-slug>: Passed 2025-06-15. Renewal required every 3 years; deadline 2028-06-15. Start renewal prep in 2028-03.
```

The renewal deadline itself is not a column in this table — per
`state-schema.md`'s canonical `index.md` template, it belongs in the
`## Notes` line above (and in `exam-result.md` / `exam-facts.md`, where the
underlying renewal facts are sourced).

### Renewal options

When your renewal deadline approaches (2–3 months before), you have options:

1. **Retake the exam** — if renewal requires an exam, register for it and use
   the retake workflow above (your study needs will be lighter, since you're
   re-certifying, not learning from scratch)
2. **Complete continuing-education credits** — if renewal requires CUs or
   equivalent, your provider publishes an approved list; select courses or
   certifications that maintain or advance your skills in this domain
3. **Automatic renewal** — some certifications renew automatically if you meet
   conditions (e.g., "if you're certified in the newer version of this exam,
   the older version renews automatically"). Check `exam-facts.md` to see if
   this applies
4. **Let it lapse** — if you've moved on to other goals and don't need this
   certification anymore, don't renew. You can always recertify later by
   retaking the exam from scratch

### Tracking renewal progress

Once you've started renewal preparation (retaking an exam, working on
continuing-education credits, etc.), treat it like a new certification cycle:

1. Create a new `discover` session for the renewal (e.g., a new cert-slug
   `google-cloud-architect-2025-renewal`)
2. Reuse `profile.md` from your original cert (your knowledge hasn't changed
   in the months since you passed)
3. Run `gaps` and `plan` as you normally would, targeting the renewal
   requirement instead of the original passing bar

Renewal prep is typically lighter than original prep — you're validating and
refreshing knowledge, not learning from scratch — so expect shorter weeks and
a faster timeline.

---

## Exam-specific renewal rules

Renewal requirements and recertification processes vary widely by provider.
Before relying on the general guidance above, check your provider's official
renewal page and any updates to `exam-facts.md`:

1. **Your provider's renewal / recertification FAQ** — this is gospel; it
   overrides anything in this module
2. **The "Renewal" field in `exam-facts.md`** — this should contain the
   official rule; if it says "verify with provider," do that before
   proceeding
3. **Any deadline alerts** from your provider (many send email reminders 6 and
   3 months before expiration)

All renewal facts that went into `exam-facts.md` were sourced by `discover`.
If your provider's policy has changed since `discover` ran, refresh `exam-facts.md`
before relying on it for renewal deadlines.
