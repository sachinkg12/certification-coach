# `progress`

Module 15: weekly accountability and explainability. Every study session
changes your standing relative to the exam and relative to your schedule.
`progress` surfaces that change clearly — what improved, why the numbers
matter, and whether the plan is still tracking toward the target date or has
shifted. When the plan shifts, `progress` uses the coaching-voice's
explainability rule to state why in concrete, numeric terms rather than
leaving you to infer it from raw state files.

`progress` runs at the end of every study session, after `learn`, `quiz`,
`lab`, or `review` have written their results to `mistake-ledger.md` and
`spaced-repetition.md`. It reads the full study history (diagnostic baseline,
all quiz and mock results, current `gap-analysis.md` priorities, the
`plan.md` schedule and change log, and the `progress-log.md` session history)
and produces a weekly summary that explains how today's work moved the needle
and whether you're on track.

---

## Weekly report

A weekly progress summary captures what improved this week, which domains
shifted in priority or confidence, and how that positions you against the
plan and the target exam date.

### Structure of a weekly report

Every week, produce a summary answering these four questions — never skip any
of them, and ground every answer in concrete numbers from state:

1. **What improved this week?** List domains and metrics that moved
   measurably — a domain's score increased from 62% to 71%, unseen-question
   accuracy climbed from 74% to 81%, a weak-area misconception moved from
   "open" to "resolved," a domain moved from Priority rank #3 to #2. State
   the before/after number always; "improved" is meaningless without the
   basis for comparison.

2. **Where are the weak spots?** Name domains or concepts still below their
   target threshold (e.g., "Security remains at 48%, below the 70% minimum"
   or "Hands-on performance in Configuration Management: 3 of 5 labs passed").
   Reference the `exam-facts.md` domain weights if applicable — a weak domain
   matters more if it's 30% of the exam than if it's 5%.

3. **Position vs. plan.** Compare today's standing to the plan milestone for
   this week. The plan says "Week 3 exit criteria: 80% accuracy on Domain A
   and Domain B misconceptions resolved." Did you hit that? If not, how far
   off? This is the binary check: on-track or behind.

4. **Position vs. target date.** Calculate days remaining to the exam date in
   `profile.md`. How many weeks are left? How many weeks remain in the
   current plan? If weeks remaining < plan weeks remaining, you're behind
   and must re-sequence (see "Missed-plan recovery" below). If weeks
   remaining > plan weeks remaining, you have buffer.

### Explainability narrative

Whenever any of the following change from last week to this week, include
the coaching-voice's explainability narrative: state the before/after
number, the exam context (weight or priority) that makes it matter, and the
concrete action that follows.

**Plan changes trigger narrative:**

- A domain re-ranked in `gap-analysis.md`'s priority order (e.g., "Security
  moved from Priority rank #3 to #1 after your mock score dropped from 72%
  to 64%, and it's 25% of the exam, so next week focuses on identity and
  access control before moving back to networking").
- The `plan.md` schedule itself re-sequenced (e.g., "Week 3 and Week 4 were
  swapped because your readiness assessment for Domain B came in below 70%;
  the plan now concentrates on Domain B remediation before advancing to
  Domain C").
- Exit criteria extended or tightened (e.g., "Week 2's exit criteria
  originally called for 75% accuracy on practice questions; you hit 78%, so
  Week 3 advances as scheduled" or "You hit 71%, which misses the 75% bar by
  4%, so Week 2 extends by one additional day to target 75%").
- Target exam date shifted in `profile.md` (only if the candidate requested
  it; `progress` reports the shift with the reasoning, e.g., "Target date
  moved from 2025-08-30 to 2025-09-13 to allow three additional weeks for
  deep-mastery coverage per your request").

**New milestone reached:**

- First passing mock (e.g., "First passing mock: 73%, cleared the 70% bar.
  Security domain at 68%, one point away from the 70% minimum; focus next
  session there").
- All domains at or above 70% for the first time (major checkpoint).
- Streak milestone reached (see Streak & milestones below).
- Weak-area misconception fully resolved (one less open item in the
  `mistake-ledger.md` Resolved section).

**Session disruption:**

- Missed a scheduled session (see "Missed-plan recovery" below).
- Extended a session beyond the plan's hour budget to finish an exit
  criterion (state why: "Lab exercise ran 45 minutes over budget to debug a
  hands-on config issue; decision to extend rather than defer").

Every explanation follows the coaching-voice shape: concrete before/after or
current number, the exam-weight or priority context that makes the number
matter, and the specific action that follows from it. This is the single
place a candidate reads the "why" behind a plan change or milestone — the
row exists in `plan.md`'s change log and the raw data is in `gap-analysis.md`,
but the narrative that ties them together appears here, in plain language, at
the moment it's relevant.

---

## Streak & milestones

Motivation and accountability are built on visibility. Track your study
continuity and mark progress toward certification completion.

### Study streak

A streak is an unbroken chain of days on which you ran at least one command
from the `learn`, `quiz`, `lab`, `review`, or `mock` modules (commands that
serve practice content or assessment, not admin commands like `progress`
itself). Streak counts are written to `progress-log.md` so the orchestrator
can use them to trigger motivational alerts (e.g., "27-day streak; aim for
30?") and recovery recommendations when a streak breaks.

Track:

- **Current streak** — how many consecutive days (inclusive of today) since
  the last day with zero study commands. If today is a study day, the streak
  includes today.
- **Longest streak** — the longest unbroken streak recorded to date in this
  certification's `progress-log.md` history.
- **Last active date** — the most recent day on which any study command ran
  (YYYY-MM-DD). If today is a study day, this is today. If you didn't study
  today, this is the prior study day.

**Streak reset rule:** A streak breaks if a day passes with zero study
commands. The command-line orchestrator tracks this automatically by checking
the "Last active" date on every session load; if `today > Last active + 1
day`, the streak resets to 0. If you study today (day N) after a missed day
(day N-1), you begin a new streak starting today; the old streak is recorded
as the "Longest streak" if it exceeded the prior record.

### Milestones

Milestones mark progress toward the exam. They are checkpoints that matter,
not every quiz result — they're infrequent enough to be memorable and
frequent enough to sustain momentum through a multi-week study program.

Standard milestones:

1. **First diagnostic completed** — baseline established; gap-analysis and
   plan generated for the first time.
2. **First week exit criteria met** — the plan's first week is complete; you
   've mastered the first domain block.
3. **All domains above 50%** — no domain is failing; you have something to
   build on everywhere.
4. **Halfway through the plan** — the schedule's midpoint; visual signal of
   progress through the multi-week arc.
5. **All domains above 70%** — every domain clears the passing threshold; the
   minimum-to-pass bar is met across the board.
6. **First passing mock** — a full-length mock under exam conditions exceeds
   the passing score; readiness assessment begins in earnest.
7. **Three consecutive passing mocks** — stability signal; 80%+ readiness
   signal.
8. **Readiness verdict: "Exam ready"** — the final gate; you're cleared to
   schedule the exam.

Additional milestones may be domain-specific (e.g., "Networking domain clears
70% for first time") or archetype-specific (e.g., "beginner archetype:
foundational-week scaffolding complete"). Record all milestones in
`progress-log.md` with the date reached and a one-line note of the context.

### Daily-task tracking

Study streaks are built on daily consistency. Within each day's session,
track:

- **Commands run** — list the modules you ran today (`learn`, `quiz`, `lab`,
  `review`, `mock`, etc.), not the time spent. The presence of work matters
  more than the duration for streak purposes.
- **Time spent** — the cumulative minutes spent in study commands today
  (excludes admin time like running `progress` itself or reading coaching
  tips).
- **Primary focus** — if today's work concentrated on one domain, name it
  (e.g., "Security domain focus" or "Weak-area remediation: networking
  misconceptions"). If work spanned multiple domains, name the highest-weight
  domain or the one with the lowest current score.

This data is appended to `progress-log.md`'s `## Sessions` table row by row,
so you and the orchestrator can see the breadth and consistency of your study
rhythm at a glance.

---

## Missed-plan recovery

When you miss a scheduled session, the plan doesn't auto-slip — instead, you
re-sequence it to recover time and stay on track for the target exam date.
This is the difference between "I'll catch up later" (which becomes a month
later) and "I've rerouted the next three weeks to absorb this missed day"
(which actually works).

### Detection and decision point

On the day you would have studied but didn't:

1. On your next study day, run `progress`. The command detects the missed day
   by comparing today's date to `progress-log.md`'s "Last active" date; if a
   gap exists, `progress` alerts: "You missed a session on [date]. The plan
   included [what was due]. Recover now?"

2. Answer the recovery prompt:
   - **Recover**: you have time to re-sequence and make up the lost day's
     work within the remaining schedule. Choose this if you have buffer weeks
     left or if the missed domain is low-priority enough to absorb one missed
     session without dropping below the readiness bar.
   - **Accept and advance**: you're skipping the lost day's work and moving
     forward. Choose this only if the domain is already strong (above 80%)
     or if you've run out of time. The consequence is visible: that domain's
     "Priority" in `gap-analysis.md` will likely rise on the next recomputation
     because you skipped rehearsal time.

### Recovery re-sequencing

If you choose "Recover," `progress` re-derives the remaining weeks of the
plan to absorb the lost day's work. The algorithm:

1. **Identify what was due.** Look at `plan.md`'s `## Plan change log` to
   find the week that includes today's date. That week's objectives are
   "what was due."

2. **Re-estimate effort.** The lost day typically carries 1–3 hours of work
   (depending on archetype and domain). Ask: "How many of the remaining weeks
   have slack (work that fits in less than the budgeted hours)?" For each
   week with slack, you can absorb the lost work into that week without
   adding hours.

3. **Spread the work.** If you have 2 remaining weeks with slack, split the
   lost work across them (e.g., if you missed a 2-hour session, add 1 hour
   to each of the next 2 weeks). If you have no slack, extend one week by a
   full day (e.g., if the plan says "Week 4: 10 hours," change it to "Week 4:
   14 hours" to fit the missed work plus the week's original work).

4. **Update `plan.md`.** Append a row to the `## Plan change log`:
   - **Date**: today (recovery date)
   - **Change**: "Week N re-sequenced to absorb missed session from [date]:
     [what was due] moved to Week N+1 with [time absorbed] added to budget."
   - **Reason**: "Missed session on [date]; re-sequencing to recover toward
     target date without slipping deadline."

5. **Update `progress-log.md`'s "Missed-plan recovery" section with a row:**
   - **Missed item**: reference to the original plan (e.g., "Week 3: Domain A
     practice target")
   - **Originally due**: YYYY-MM-DD
   - **Recovery action**: "Merged into Week 4; added 1.5 hours to Week 4
     budget"
   - **Recovered on**: today's date

### When recovery is impossible

If you've missed multiple sessions and the remaining weeks can't absorb the
backlog (e.g., 5 days missed, 2 weeks left, all weeks are already at hour
budget), the target exam date must move. Don't silently drop weeks of
material; instead:

1. Calculate new target date: `today + (remaining plan weeks + missed-week
   backlog) × days-per-week`.
2. Update `profile.md`'s `Target exam date` field to the new date.
3. Append a row to `plan.md`'s `## Plan change log`:
   - **Change**: "Target exam date shifted from [old] to [new] due to
     missed-session backlog."
   - **Reason**: "Missed [N] sessions between [dates]; absorbing [M weeks of
     work into remaining [K] weeks is unsustainable; target date extended by
     [N weeks]."

4. Update `progress-log.md`'s "Missed-plan recovery" section:
   - **Missed item**: "Weeks N–M (backlog)"
   - **Originally due**: YYYY-MM-DD (original target date)
   - **Recovery action**: "Target date extended to [new date]; re-sequencing
     plan to cover all material with sustainable weekly hours"
   - **Recovered on**: today's date (recovery assessment date; actual recovery
     spans the extended weeks)

This is the accounting step — making explicit what happened, why, and when.

---

## Outputs

`progress` writes to one per-cert state file after every session:

**`.certicoach/<cert-slug>/progress-log.md`** — appends or updates the
following sections (conforming to the `### progress-log.md` template in
`references/state-schema.md`):

### Sessions table

Append one row per session (per call to `progress`):

| Date | Commands run | Time spent (min) | Milestone | Notes |
|---|---|---|---|---|
| YYYY-MM-DD | `<learn>`, `<quiz>` (list of modules run today) | <n> | <milestone name if reached, else empty> | <free-text session notes: focus domain, why time was extended/shortened, or recovery action taken> |

- **Date**: today's date (YYYY-MM-DD); the row is added once per session.
- **Commands run**: comma-separated list of module names executed today
  (`learn`, `quiz`, `lab`, `review`, `mock`, etc.). Include only commands
  that serve practice or assessment; exclude `progress` itself and admin
  commands like `discover` or `plan`.
- **Time spent**: cumulative minutes in study commands (exclude admin time).
- **Milestone**: if a milestone was reached this session, name it; otherwise
  leave empty. Examples: "First passing mock", "All domains above 70%", "Streak:
  14 days".
- **Notes**: brief context (e.g., "Security domain focus", "Lab session
  extended 30 min to debug hands-on exercise", "Recovered Week 2 missed
  session by extending today to 180 min").

### Streak section

Update after every session:

```markdown
## Streak

Current streak: <n> days
Longest streak: <n> days
Last active: YYYY-MM-DD
```

- **Current streak**: count of consecutive days including today. If today is
  a study day (contains any study command), increment the streak. If today is
  not a study day and the streak was broken, reset to 0 and begin a new
  streak when study resumes.
- **Longest streak**: the maximum streak value recorded to date in this
  file's history.
- **Last active**: today's date if you studied today; otherwise the prior
  study date (YYYY-MM-DD).

### Missed-plan recovery section

Append one row for each missed session that was assessed and recovered:

| Missed item | Originally due | Recovery action | Recovered on |
|---|---|---|---|
| <plan.md week/objective reference> | YYYY-MM-DD | <re-sequencing action or target-date shift> | YYYY-MM-DD |

- **Missed item**: reference to the original plan (e.g., "Week 3: Domain A
  practice target, 15 questions at 80% accuracy").
- **Originally due**: the date the original plan scheduled this item
  (YYYY-MM-DD).
- **Recovery action**: what changed (e.g., "Merged into Week 4, added 1.5
  hours to Week 4 budget"; or "Target date extended by 2 weeks").
- **Recovered on**: the date of the recovery assessment (today if this is the
  session where recovery was decided, YYYY-MM-DD).

Never delete rows from this section; it is the history of when the plan
shifted and why. See plan.md's `## Plan change log` for the corresponding
plan modifications.

---

## Certification-agnostic implementation

`progress` contains no exam-specific logic. The same module workflow applies
to any certification — same streak rules, same milestone definitions, same
recovery re-sequencing algorithm — because the underlying data model
(`gap-analysis.md`, `plan.md`, `progress-log.md`, `mistake-ledger.md`,
`readiness.md`) and the coaching-voice principles are agnostic. An exam with
three domains and an exam with twelve domains use the same `progress` module,
the same weekly-report questions, and the same explainability narrative
shape.
