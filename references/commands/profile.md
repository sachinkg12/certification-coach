# `profile`

Module 2: captures the candidate's background relative to *this specific
certification*, not as a generic résumé. A candidate may have 15 years of
engineering experience but minimal time on this platform — `profile` surfaces
that mismatch by asking about platform familiarity per domain, not just total
years. The resulting `profile.md` feeds into all downstream commands
(`diagnose`, `gaps`, `plan`, `resources`) as the personalization anchor for
study archetype selection, pacing, and material difficulty.

`profile` runs after `discover` has established the target certification. It
elicits inputs via a conversational flow, then writes a structured candidate
profile to `.certicoach/<cert-slug>/profile.md` using the exact template
defined in `state-schema.md`.

---

## Inputs

`profile` elicits ten broad input categories from the user, one at a time, in a
natural conversational style — not a form dump. If the user's opening message
already supplies some of these (e.g., "I'm a DevOps engineer with 8 years
experience, targeting November, 20 hours per week"), acknowledge what was
given and ask only for what's missing — never re-ask for a value already
stated.

1. **Years of relevant experience** — how long the candidate has worked in a
   domain related to this certification (e.g. "3 years as a solutions
   architect," "6 months as a junior developer," "none — I'm switching
   fields"). Context matters: "15 years in IT" is different from "15 years
   with this platform."

2. **Current role / function** — the candidate's current job title or primary
   responsibility (e.g. "DevOps Engineer at Acme Inc.," "Full-time parent
   returning to tech," "Freelance consultant"). This shapes pacing and
   material difficulty selection (a senior architect needs different
   scaffolding than a new entrant).

3. **Recent hands-on technologies** — specific tools, platforms, or languages
   the candidate has used in the last 3–12 months (e.g. "Terraform, AWS EC2,
   Python," "Google Workspace, Sheets," "just SQL — no cloud work yet"). This
   is what matters for readiness, not past résumé items.

4. **Prior certifications** — any relevant certifications already held (e.g.
   "AWS Solutions Architect Associate," "CompTIA Network+," "none"). This
   signals study discipline and background patterns.

5. **Per-domain familiarity** — *the core of this step* — for each domain in
   the target exam's syllabus (from `exam-facts.md`), ask the candidate to
   self-rate their current familiarity on a 1–5 scale and add a brief note.
   For example, if the exam has domains `Authentication & Access Control`,
   `Compute`, and `Storage`, ask three separate questions like: "On a scale of
   1–5, how familiar are you with Authentication & Access Control on this
   platform? (1 = haven't heard of it; 5 = hands-on daily)." Capture the
   rating and any context (e.g. "1 — we use OAuth, but haven't configured it
   myself"). **This is not general seniority.** A candidate with 15 years of
   infrastructure experience might rate "3" for a specific platform's
   authentication model because they've never deployed it.

6. **Hours available per week** — realistically, how many hours per week can
   the candidate dedicate to study (e.g. "5 hours," "20 hours," "weekends
   only, roughly 8 hours"). This directly shapes plan archetype selection
   (fast-track, balanced, deep-mastery, weekend-only, etc.).

7. **Preferred learning style** — how the candidate learns best (visual,
   reading, hands-on, or mixed). This informs resource selection and how to
   scaffold new domains.

8. **Target exam date** — the date the candidate intends to sit the exam, or a
   best-guess timeframe (e.g. "November 15, 2025," "sometime in Q1 2026,"
   "I'm unsure — help me pick a realistic date"). Recorded as `YYYY-MM-DD`.
   If the candidate has no date in mind, offer to help them pick one after
   sizing the study effort (plan.md will compute this).

9. **Budget for materials** — how much the candidate is willing to spend on
   courses, books, labs, or practice exams (e.g. "$200," "free only,"
   "unlimited"). This informs whether to recommend official paid courses vs.
   community resources.

10. **Labs / cloud sandbox access** — whether the candidate has access to a
    lab environment or a cloud sandbox (e.g. "yes, AWS account with free
    tier," "no, but my employer provides a lab," "none"). Hands-on domains
    need hands-on practice; this determines whether practice-questions alone
    suffice or if lab work is essential.

11. **Goal** — what the candidate is ultimately trying to achieve: pass (meet
    the passing score), master (deep understanding of all domains), or
    interview-prep (credible talking points for job interviews, often less
    comprehensive than mastery). This shapes question depth and whether gaps
    matter: interview-prep might tolerate a weaker domain if it's not asked
    often; master would not.

Once gathered, these inputs are written to `profile.md` in the structured form
defined below, ready for `gaps`, `plan`, and `resources` to read and
personalize decisions.

---

## Outputs

`profile` writes exactly one thing, conforming byte-for-byte to the template in
`state-schema.md`:

**`.certicoach/<cert-slug>/profile.md`** — created using the `profile.md`
template: `# Candidate Profile — <cert-slug>` headline, `Captured: YYYY-MM-DD`
date field, then the `## Experience`, `## Per-domain familiarity`, `##
Constraints & preferences`, and `## Notes` sections. All fields must be
populated with the user's inputs; no placeholder values.

The `## Per-domain familiarity` table must include one row per domain listed in
the target exam's `exam-facts.md :: Syllabus / domains` section. If per-domain
familiarities were not captured (legacy profile or rerun), note that in the
`## Notes` section: "Per-domain familiarity was not separately assessed;
applicant reports general experience with <domain group> per `## Experience`
section. Re-run profile to capture per-domain ratings against current
exam-facts.md." This preserves continuity for downstream commands while
flagging incompleteness for the diagnostic and plan engines.
