# `discover`

Module 1: identifies the certification the user wants to earn, researches it
live on the web, and writes a sourced, provenance-tagged fact base to
`.certicoach/`. This is the first command in any new certification journey —
every downstream command (`profile`, `diagnose`, `gaps`, `plan`, `resources`,
`learn`, `quiz`, `mock`, `readiness`) reads `exam-facts.md` as its ground
truth about the target exam, so `discover` is the only place those facts are
allowed to enter state.

`discover` never invents a labeling or persistence rule of its own. Every
fact it produces is routed through `provenance-engine`'s `label_fact`,
`may_persist`, and no-web degradation behavior before it reaches the user or
`.certicoach/`. `discover` is certification-agnostic: it runs identically
whether the user names an AWS exam, a Google "Generative AI Leader" exam, a
CompTIA exam, or any other provider's certification — nothing about the
research protocol or the output format is hardcoded to a specific provider.

---

## Inputs

`discover` elicits six identifying inputs from the user before researching
anything. If the user's opening message already supplies some of these
(e.g. "I want to prepare for the AWS Solutions Architect Associate exam,
targeting October"), acknowledge what was given and ask only for what's
missing — never re-ask for a value already stated.

1. **Exact certification name** — the full, precise name of the
   certification, not a shorthand or a guess at which exam the user means.
   If the user's phrasing is ambiguous between two real certifications, ask
   which one before researching either.
2. **Provider** — the organization that issues the certification (e.g. AWS,
   Google, CompTIA, Microsoft, PMI, Cisco).
3. **Target exam date** — the date the user intends to sit the exam, or a
   best-guess timeframe if no date is booked yet. Recorded as `YYYY-MM-DD`
   for use in `plan.md` and `profile.md` later.
4. **Country / testing region** — cost, availability, and even exam content
   can vary by region; this also affects which registration/pricing page is
   authoritative for the cost and logistics facts below.
5. **Delivery preference** — online proctored vs. test center vs. either,
   since some certifications differ in duration, allowed materials, or
   availability by delivery mode.
6. **Certification / exam version** — if the user knows it (e.g. a named
   syllabus revision, "v3," or a specific exam code), capture it as a
   starting hint; `discover` still verifies this independently in the
   research protocol below rather than trusting the user's memory of it.

These six inputs are captured as a short, plain-language exchange — not a
form dump. Once gathered, `discover` derives `<cert-slug>` (lowercase,
hyphenated, from exam name + provider, per `state-schema.md`) and proceeds to
research.

---

## Research protocol

`discover` researches the certification live on the web — it does not
answer from memory. For each fact below, it fetches the provider's official
exam page(s) (exam guide, syllabus/exam-guide PDF, pricing page, exam-code
registry, official changelog/blog) and calls `provenance-engine`'s
`label_fact(fact, tier, source, date)` before treating the fact as usable:

- **Exam code** — the provider's official identifier for this exam.
- **Latest syllabus / domain list** — the current domains or objectives and
  their weightings, as published by the provider (not a third-party recap).
- **Exam duration** — in minutes, as stated by the provider.
- **Number and type of questions** — total count and the question formats
  used (multiple choice, multi-select, performance-based, case study, etc.).
- **Passing-score policy** — the provider's own description of how passing
  is determined (scaled score, percentage, or an undisclosed scoring model
  stated as such — never a guessed number).
- **Registration cost** — amount and currency, for the region the user gave
  in Inputs.
- **Renewal requirements** — recertification interval and how it's
  satisfied (retake, continuing education, higher-level cert, etc.).
- **Prerequisites** — required certifications, experience, or none.
- **Recent syllabus changes** — anything the provider has published about a
  version bump, retiring exam code, or objective changes, dated so
  `provenance-engine`'s `version_alert` can compare against it on future
  `discover` re-runs.

`discover` also explicitly verifies the certification is still **active**
(not retired or scheduled for retirement) as part of confirming the exam
code and status — a retired or retiring certification is surfaced to the
user immediately rather than silently researched as if it were current.

Every fact gathered here is a candidate for `exam-facts.md`'s official
sections; per `provenance-engine`'s persistence rule, only facts carrying
both a source URL and a retrieval date are eligible to be written as
`[OFFICIAL — <url> — retrieved YYYY-MM-DD]`. Details worth keeping but not
sourced to an official page (forum clarifications, community tips on exam
day experience) are labeled `[COMMUNITY — <source>]` and never mixed into
the official sections.

If web access is unavailable, or fetch attempts for the provider's official
pages fail, `discover` follows `provenance-engine`'s no-web degradation
behavior in full: it stops before writing any facts, tells the user plainly
that web access is unavailable, and asks the user to paste the relevant
official page text so the pasted content can be labeled and persisted under
the normal rule. `discover` never fills a field with a recalled or inferred
value to appear complete — an absent field is preferred over a fabricated
one.

---

## Outputs

`discover` writes exactly two things, both conforming byte-for-byte to the
templates in `state-schema.md`:

1. **`.certicoach/<cert-slug>/exam-facts.md`** — created (or overwritten on
   a re-run, see below) using the `exam-facts.md` template: `Exam version`
   and `Last verified` headline fields, then the `## Identity`, `## Format`,
   `## Passing policy`, `## Cost & logistics`, `## Syllabus / domains`,
   `## Recent changes`, and `## Community notes` sections. Every line
   asserting a fact carries the provenance tag produced by
   `provenance-engine` in the research protocol above — `discover` never
   writes a fact line without one. Fields that could not be verified (no-web
   degradation, or the provider simply doesn't publish that detail) are left
   absent from the file rather than populated with a placeholder.

2. **`.certicoach/index.md`** — registered or updated per the `index.md`
   template: a new row is added to the `## Certifications` table for
   `<cert-slug>` (Name, Provider, Target date from Inputs, `Status: active`,
   `Last session` set to today) if this is a new certification, or the
   existing row is updated in place if the user is re-running `discover` for
   a certification already tracked. `current:` is set to `<cert-slug>` when
   it is the certification the user is now actively working on.

On a **re-run** for a certification that already has an `exam-facts.md`
(the user is refreshing facts mid-preparation), `discover` first loads the
existing file as `old_facts`, performs the research protocol to produce
`new_facts`, and calls `provenance-engine`'s `version_alert(old_facts,
new_facts)` before overwriting. Any of the four triggers (syllabus change,
exam retiring, new exam code, previously-selected materials outdated) is
surfaced to the user in plain language before `exam-facts.md` is replaced,
so a stale plan or resource set is never silently left in place against a
changed target.
