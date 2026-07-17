# `plan`

Module 5: turns a ranked readiness report into a week-by-week study
schedule the candidate can actually follow. `plan` runs after `gaps` has
produced `gap-analysis.md` (the domain priority order this plan sequences
against) and after `profile` has captured `profile.md` (the hours-per-week,
target-exam-date, and other constraints this plan sizes itself against).
Every downstream module leans on the result: `learn`, `quiz`, and `lab`
pull "what's due this week" from `plan.md`, `review` reconciles missed
items against it, and `progress` explains what changed and why by
comparing today's `plan.md` against the `## Plan change log` history.

`plan` never invents a schedule from a generic template. It runs in two
phases — present path archetypes, then generate the selected archetype's
week-by-week schedule — and both phases read directly from state rather
than guessing: domain order comes from `gap-analysis.md`'s
`## Ranked priorities`, pacing comes from `profile.md`'s
`## Constraints & preferences`. `plan` is certification-agnostic: the same
six archetypes and the same weekly template apply whether the underlying
exam has three domains or twelve, and whether the candidate is a total
beginner or a ten-year veteran of the platform.

---

## Path archetypes

`plan` first presents the candidate with **all six** path archetypes as
selectable options — never auto-selects one on the candidate's behalf —
so the candidate can see the trade-off before committing time to a
schedule. Each option is described in terms of who it fits and what it
costs, using the exam's actual domain count and the candidate's own
`gap-analysis.md` and `profile.md` numbers rather than generic marketing
copy (e.g. "fast-track would take you 3 weeks at your 10 hours/week and
covers only the domains scoring `Priority > 0.05`, skipping deep practice
on your two mastered domains").

1. **fast-track** — minimum-to-pass. Sequences only the domains
   `gap-analysis.md` ranks as priority (skips or gives a single light-touch
   revision pass to domains already at or near mastery), targets the
   passing score rather than deep fluency, and compresses weekly scope to
   the fewest weeks the candidate's `Hours available per week` can sustain
   before `Target exam date`. Trade-off: the least schedule slack — a
   missed week has nowhere to absorb the loss — and the shallowest margin
   above the passing bar, so it fits a candidate under real time pressure
   who has accepted a tighter risk band, not a candidate who wants comfort
   room.
2. **balanced** — the default recommendation absent a stated reason to pick
   another archetype. Covers every domain in `exam-facts.md`'s syllabus at
   a depth proportional to its `Priority`, with weekly load sized to use
   the candidate's stated hours without idle slack or crunch. Trade-off:
   not the fastest path to the exam date and not the deepest mastery
   either — it fits a candidate with no unusual constraint (no severe time
   pressure, no unusually low or high hours/week, no stated preference for
   comprehensive mastery).
3. **deep-mastery** — extends coverage beyond the passing bar: every domain
   gets full hands-on practice regardless of `Priority`, revision cycles
   run past the point a domain first clears its exit criteria, and the
   practice-test targets are set above the passing threshold. Trade-off:
   the longest schedule for a given hours/week budget, and it will push
   `Target exam date` outward if the date in `profile.md` doesn't leave
   room — it fits a candidate whose stated `Goal` is "master" rather than
   "pass," or who has explicitly said the exam date is flexible.
4. **weekend-only** — built for a candidate whose `Hours available per
   week` in `profile.md` is concentrated into one or two weekend days
   rather than spread across the week. Each week's material, hands-on
   exercise, and revision task are sized to fit that concentrated block
   (longer single sessions, fewer but larger units of work) instead of the
   daily-drip pacing the other archetypes assume. Trade-off: longer gaps
   between study sessions raise `ForgettingRisk` between weekends, so this
   archetype leans more heavily on the revision task each week to counter
   decay — it fits a candidate who cannot study on weekdays at all, not
   one who merely prefers weekends.
5. **experienced-professional** — built for a candidate whose
   `profile.md :: ## Experience` and `Per-domain familiarity` show real
   hands-on background on this platform. Domains where `gap-analysis.md`'s
   `Current level` is already high get a single validation week (practice
   questions and one targeted hands-on check, no re-teaching of material
   the candidate has demonstrably used on the job) instead of a full
   teaching week, freeing the schedule to concentrate on the domains that
   are genuinely new. Trade-off: it compresses or skips foundational
   explanation for domains the profile and diagnostic both support skipping
   — it fits a candidate with demonstrated (not just self-rated) prior
   depth, not someone who merely feels confident.
6. **beginner** — built for a candidate new to the platform or the field.
   Adds foundational scaffolding weeks ahead of the domain-specific
   sequence (terminology, core concepts, environment setup) before tackling
   `gap-analysis.md`'s ranked domains, and paces each domain week more
   slowly with smaller hands-on steps and lower initial practice-test
   targets that ramp up as exit criteria are repeatedly met. Trade-off: the
   most weeks for a given syllabus, since foundational time is added on top
   of domain coverage rather than assumed — it fits a candidate with little
   or no relevant background, not one who is simply new to this specific
   certification but experienced in the field.

The candidate selects exactly one archetype. `plan` records the choice
(and the date it was made) in `plan.md`'s `Archetype:` and `Chosen:`
fields before generating a single week of schedule — the weekly breakdown
in `## Weekly structure` is only ever built for the archetype actually
chosen, never pre-generated for all six.

---

## Weekly structure

Once an archetype is chosen, `plan` builds the week-by-week schedule for
*that* archetype only. The number of weeks is derived from `profile.md`'s
`Target exam date` (today to target, in whole weeks) and the archetype's
own pacing rule above (fast-track compresses toward the minimum weeks the
candidate's `Hours available per week` can sustain; deep-mastery may push
back on a `Target exam date` that leaves too little room and say so rather
than silently under-covering the syllabus).

Weeks are **sequenced by domain priority**: the domain (or domains, if
several fit inside one week's hour budget) with the highest `Priority` in
`gap-analysis.md`'s `## Ranked priorities` comes first, working down the
ranked list — except where an archetype's own rule overrides that order
(`beginner`'s foundational weeks precede the ranked sequence;
`experienced-professional`'s validation weeks for already-strong domains
may be pulled later or compressed regardless of rank, since there is
little to gain from front-loading a domain the candidate has already
demonstrated).

Every week must specify all eight of the following, and every one of the
eight must be concrete and traceable to a specific source in state — never
a generic placeholder line. **Forbidden**: vague items like "study
networking for three days," "review cloud concepts," or "practice more
questions" — these name no objective, no material, and no way to tell
whether the week succeeded. A compliant week names the exact objective
code, the exact resource, the exact exercise, and the exact numeric bar
that marks the week done, matching the `plan.md` template's week fields
byte-for-byte:

1. **What** — the specific topic(s) and task(s) for the week (e.g.
   "IAM custom roles and conditional bindings" — not "IAM").
2. **Why** — the concrete link back to `gap-analysis.md`'s ranked reason
   for this domain's position (e.g. "ranked #1: 30% exam weight, mostly
   'cannot apply' signals, last reviewed 20 days ago").
3. **Objectives covered** — the exact objective(s) from `exam-facts.md`'s
   `## Syllabus / domains` table that this week's work maps to, never the
   domain name alone.
4. **Material** — a specific resource reference from `resources.md` (title
   and section/chapter/timestamp where applicable), never "look this up"
   or an un-named category.
5. **Hands-on** — a specific lab or exercise the candidate performs this
   week (a named lab, a config task with a concrete goal, a
   debugging/build exercise), sized to fit the week's hour budget; for a
   domain with no hands-on objective in `exam-facts.md`, this is a named
   applied exercise (e.g. a worked scenario) rather than omitted.
6. **Revision** — the specific `spaced-repetition.md` items due that week
   (named, not "review old material"), keeping prior weeks' domains from
   decaying while new domains are being learned.
7. **Practice target** — a specific question count and target accuracy
   (e.g. "15 questions, 80% accuracy") sized to the archetype (fast-track
   targets the passing bar; deep-mastery sets the bar above it).
8. **Exit criteria** — the specific, measurable condition that must be met
   before the plan advances to the next week (e.g. "practice target met
   and zero open `mistake-ledger.md` rows for this week's objectives"),
   never a subjective judgment call.

A week's hour budget always matches `profile.md`'s `Hours available per
week` (or the weekend-block sizing for the `weekend-only` archetype); a
week that would need more hours than the candidate has available is split
across additional weeks rather than compressed past what "what/why/
material/hands-on/revision/practice target/exit criteria" can honestly
support in the stated time.

When a later `gaps` recomputation, a missed exit criterion, or a change to
`profile.md`'s constraints changes the schedule, `plan` re-derives the
affected weeks (never hand-patches a single field) and appends a row to
`plan.md`'s `## Plan change log` naming what changed and the concrete
reason — e.g. "Week 3 replaced: Security re-ranked to #1 after a failed
quiz attempt raised its `KnowledgeGap`."

---

## Outputs

`plan` writes exactly one thing, conforming byte-for-byte to the
`plan.md` template in `state-schema.md`:

**`.certicoach/<cert-slug>/plan.md`** — regenerated when the archetype
changes or the schedule is rebuilt, with prior weeks preserved in the
`## Plan change log` rather than silently overwritten:

- **Headline fields** — `Archetype:` set to exactly one of the six
  archetype tokens the candidate chose (`fast-track | balanced |
  deep-mastery | weekend-only | experienced-professional | beginner`),
  `Chosen: YYYY-MM-DD` recording the selection date, and
  `Target exam date: YYYY-MM-DD` copied from `profile.md`.
- **`## Weeks`** — one `### Week N (YYYY-MM-DD to YYYY-MM-DD)` entry per
  week of the selected archetype's schedule, each populated with the
  eight concrete fields from `## Weekly structure` above (Objectives
  covered, What, Why, Material, Hands-on, Revision, Practice target, Exit
  criteria) — no field left as a placeholder.
- **`## Plan change log`** — starts with a first row recording the
  initial generation (`<archetype> plan generated` / the reason the
  archetype was chosen), then one row per subsequent change with a
  concrete explainability narrative, per the re-derivation rule above.
