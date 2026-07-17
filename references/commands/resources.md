# `resources`

Module 6: curates a **minimum-sufficient** set of study materials for the
certification — not an exhaustive reading list. `resources` runs after
`discover` has produced `exam-facts.md` (the syllabus and exam version this
curation targets) and typically after `gaps` has produced
`gap-analysis.md` (so material can be weighted toward priority domains),
though it can also run early to give the candidate a starting kit before
any gap data exists. `plan` reads `resources.md` directly — every week's
`Material` field names a specific entry from this file, never a generic
"look this up." `resources` is certification-agnostic: the same nine
categories and the same curation discipline apply whether the target is a
cloud-provider exam with a rich official ecosystem or a niche certification
with almost no third-party material.

`resources` never invents a labeling or persistence rule of its own.
Every candidate resource is routed through `provenance-engine`'s
`label_fact`, `may_persist`, and `version_alert` behavior before it is
shown to the user or written to `.certicoach/`, exactly as `discover`
does for exam facts.

---

## Categories

`resources` researches and curates across exactly nine categories. Every
entry in the curated set is tagged with one of these tokens (matching
`resources.md`'s `Category` column in `state-schema.md`):

1. **official guide** — the provider's own exam guide or blueprint
   document (the syllabus PDF or page `discover` already fetched into
   `exam-facts.md`'s `## Syllabus / domains`).
2. **official docs** — the provider's product/platform documentation
   (reference docs, architecture guides, API references) that the exam
   objectives are drawn from.
3. **official training** — the provider's own paid or free training
   courses, learning paths, or certification-prep offerings.
4. **books** — published books (from any publisher, official or
   third-party) that cover the exam's domains.
5. **video** — video courses: third-party or official video training
   (course platforms, structured video series) distinct from
   `official training` when produced by a non-provider instructor or
   platform.
6. **labs** — hands-on labs: sandboxes, guided labs, or scenario-based
   exercises the candidate can perform, not just read.
7. **community notes** — forum threads, blog posts, study-group writeups,
   and other non-official material that clarifies exam-day experience or
   fills gaps official material leaves vague.
8. **practice exams** — full-length or domain-scoped practice tests
   (official or third-party) used to rehearse exam conditions.
9. **cheat sheets** — condensed reference sheets or quick-recall summaries
   for last-mile review, not first-pass learning.

A category is never left uncurated for domains the syllabus actually
covers — if no strong resource exists in a category for a given domain,
`resources` says so plainly in `## Excluded / superseded` rather than
silently omitting the category or padding it with a weak match.

---

## Curation

For **every** resource `resources` considers adding to the curated set, it
records all eight of the following before the resource is allowed into
`resources.md`'s table — a resource missing any of these fields is not
yet curated, it is still a candidate:

1. **Exam-version match** — whether the resource's own content was
   published against the `Exam version` currently recorded in
   `exam-facts.md` (`yes`), was published against a prior version and has
   not been confirmed updated (`no`), or the match could not be determined
   from what the resource publishes (`unknown`). A `no` match is a strong
   signal to exclude or demote the resource, not a detail to bury.
2. **Cost** — the amount and currency, or `free`, as published by the
   resource itself (never guessed).
3. **Estimated completion time** — in hours, sized to the resource's own
   stated length (course duration, book page count at a normal reading
   pace, lab count) rather than a round-number guess.
4. **Difficulty** — `beginner`, `intermediate`, or `advanced`, judged
   against the candidate's own starting point where `profile.md` or
   `diagnostic.md` already exist, or against the resource's own stated
   audience otherwise.
5. **Exam domains covered** — the specific domain(s) from `exam-facts.md`'s
   `## Syllabus / domains` the resource actually addresses, never "covers
   everything" as an unverified claim.
6. **Last-updated date** — the resource's own publish or last-revised
   date, used both to judge freshness and to feed the version-match
   determination above.
7. **Primary vs. supplementary** — `primary` for a resource the plan
   should be built around for its domain(s), `supplementary` for one that
   adds depth, an alternate explanation style, or extra practice once the
   primary resource is done. Every domain in the syllabus needs exactly
   one `primary` resource driving its coverage; everything else supporting
   that domain is `supplementary` by construction.
8. **Provenance tag** — official resources (official guide, official docs,
   official training, and any provider-published practice exams or cheat
   sheets) are labeled `[OFFICIAL — <url> — retrieved YYYY-MM-DD]` via
   `provenance-engine`'s `label_fact`; third-party and community resources
   are labeled `[COMMUNITY — <source>]`. A resource with neither a URL nor
   a named source is never added to the curated set — the same hard gate
   `may_persist` applies to exam facts applies here.

### Minimum-sufficient, not exhaustive

The governing rule of this section: `resources` produces the **smallest**
set of resources that covers every exam domain at a defensible depth, not
the longest list that could plausibly help. Concretely:

- Every domain in `exam-facts.md`'s syllabus must be covered by at least
  one `primary` resource. Beyond that floor, a second resource is added to
  a domain only when it fills a gap the first one does not close (a
  hands-on lab where the primary is text-only, a cheap alternative where
  the primary is costly, a different explanation style for a domain the
  candidate's `diagnostic.md` shows genuine trouble with) — never simply
  because another good resource exists.
- **Forbidden**: recommending three or more video courses that all cover
  the same domains at the same depth, multiple books that substantially
  overlap in content and audience, or padding the set to "look thorough."
  If two resources would teach the same objective at the same depth to
  the same audience, `resources` picks the better one (by cost, currency,
  or completeness) and moves the other to `## Excluded / superseded` with
  the concrete reason — "overlaps primary pick," not left uncurated.
- When a domain's coverage genuinely needs more than one resource (e.g. a
  conceptual primary plus a hands-on lab, since neither alone teaches
  both knowing and doing), each is kept only if it is doing distinct work
  — the pairing is named as such (one `primary`, the supporting one
  `supplementary`) rather than presented as two equally-weighted options.

### Version-awareness

Official items are subject to the same `version_alert` triggers
`provenance-engine` defines for `exam-facts.md`. In particular, trigger 4
(`Previously-selected materials outdated`) fires specifically here: when a
`discover` re-run changes `exam-facts.md`'s `Exam version`, `resources`
re-checks every entry's `Exam-version match` against the new version and
flags — in plain language, at the next session boundary — any `primary`
resource whose match flips to `no`, since a stale primary resource left
silently in place would have the candidate studying against a retired
syllabus. A flagged resource is not auto-removed; the candidate is told
what changed and a replacement is proposed before `resources.md` is
overwritten, mirroring `discover`'s re-run behavior.

---

## Outputs

`resources` writes exactly one thing, conforming byte-for-byte to the
`resources.md` template in `state-schema.md`:

**`.certicoach/<cert-slug>/resources.md`** — created (or regenerated on a
version-alert-triggered re-curation, see above) with:

- **Headline fields** — `Curated: YYYY-MM-DD` and
  `Exam version matched: <version identifier>`, the latter copied from
  `exam-facts.md`'s `Exam version` at the time of curation so a future
  `discover` re-run can detect drift.
- **`## Curated set`** — one table row per resource that survived
  curation, with every column populated: `Category` (one of the nine
  tokens above), `Title` carrying its provenance tag
  (`[OFFICIAL — <url> — retrieved YYYY-MM-DD]` or
  `[COMMUNITY — <source>]`), `Version match` (`yes | no | unknown`),
  `Cost`, `Est. time`, `Difficulty` (`beginner | intermediate | advanced`),
  `Domain coverage`, `Last updated`, and `Role` (`primary | supplementary`)
  — no field left blank or as a placeholder.
- **`## Excluded / superseded`** — every resource that was considered but
  not added, with the concrete reason (version mismatch, overlaps a
  primary pick, no longer maintained, cost with no material advantage over
  the chosen primary), so the candidate and future re-curations can see
  what was deliberately left out rather than wonder if it was missed.
