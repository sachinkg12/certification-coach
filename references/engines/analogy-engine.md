# Analogy Engine

Turns abstract exam wording into a concrete, everyday-operations analogy so
a candidate can hold onto a new idea by anchoring it to something they
already understand. A flagship feature of the skill, but also its riskiest
one: an analogy that overstays its welcome quietly plants the very
misconception this skill exists to prevent. This engine exists to make
every analogy self-correcting — it explains, then immediately tells the
candidate exactly where to stop trusting it.

Produces the operation `analogize(concept, exam_terms)`, returning the
three-part structure defined below. Consumed by `explain` directly (a
candidate can ask for an analogy on demand) and auto-invoked by `learn`
whenever the teaching loop introduces a concept flagged as abstract or
commonly confused. Certification-agnostic — the engine has no built-in
library of domain-specific comparisons; it generates a fresh
everyday-operations comparison for whatever concept is in front of it.

---

## Analogy contract

Every analogy this engine produces ships with exactly three parts, in this
order, and none of the three is optional:

1. **The everyday-operations analogy.** A comparison drawn from ordinary
   life or business operations that the candidate has plausibly already
   experienced — a warehouse, a restaurant kitchen, a mailroom, a shift
   schedule, a subscription magazine. It must not be built from *more*
   technical jargon than the concept it explains; reaching for a different
   piece of specialized vocabulary to explain the first piece of
   specialized vocabulary defeats the purpose and is never acceptable
   here.
2. **The precise technical restatement.** Every element named in the
   analogy is mapped, one to one, back to the exact exam terminology it
   stands in for. The candidate should be able to read the analogy, then
   read the restatement, and see the same structure named twice — once in
   plain language, once in the vocabulary the exam actually uses. A
   restatement that introduces a concept the analogy never touched is
   incomplete.
3. **An explicit "where this analogy breaks down" caveat.** Named limits
   on the comparison — the specific points at which continuing to reason
   from the everyday analogy would produce a wrong answer on the real
   exam.

The caveat in part 3 is mandatory, not a nicety, for one reason: **every
analogy is a simplification, and every simplification is wrong somewhere.**
An analogy that is presented without its failure points invites the
candidate to extend it past where it holds — and the resulting wrong
inference feels *earned*, because it came from a comparison the skill
itself supplied. That is how a well-intentioned teaching aid manufactures
a misconception indistinguishable, from the candidate's side, from one
they picked up from a bad blog post. Naming the breakdown points closes
that gap: the candidate leaves knowing not just what the analogy explains,
but exactly where their own reasoning needs to switch back to the
technical model.

Analogies are always labeled as explanatory aids the moment they are
shown — never phrased as, or allowed to be mistaken for, official exam
wording. Per `provenance-engine`'s content tiers, an analogy is generated
teaching content, not a claim about the certification body's own
materials; if the concept being explained also carries a factual claim
about the exam (e.g. "this appears in Domain 2"), that claim is labeled
and sourced independently through `provenance-engine` rather than riding
along inside the analogy.

---

## Where this breaks down

Naming an analogy's limits is a discipline, not an afterthought bolted on
after the comparison is already written. Two failure points are worth
looking for on every analogy this engine produces:

- **Structural mismatch.** Find the place where the everyday system and
  the technical system stop having the same shape. A mailroom delivers
  one letter to one recipient; if the technical concept involves
  broadcasting the same message to many independent recipients, the
  one-to-one mailroom picture is already wrong at the structural level,
  not just in some edge case. Look for cardinality (one-to-one vs.
  one-to-many vs. many-to-many), ordering, and shared-vs-independent state
  as the usual suspects.
- **Behavioral mismatch under stress.** Find the place where the everyday
  system's behavior under load, failure, or timing pressure diverges from
  the technical system's actual guarantees (or lack of them). A physical
  bulletin board doesn't crash, doesn't retry, and doesn't have to decide
  what happens when a reader is slow — the technical system usually does,
  and usually decides differently than intuition about the physical
  object would suggest.

The test for whether a breakdown point is worth naming: would a candidate
who took the analogy completely literally answer an exam question
*wrong*? If yes, it belongs in the caveat. If the mismatch is cosmetic and
wouldn't change an answer, it doesn't need to be listed — the goal is
guarding against real wrong inferences, not exhaustively cataloguing every
way the metaphor is imperfect.

---

## Worked example

**Concept: publish/subscribe messaging.**

**1. The everyday-operations analogy.** Picture a notice pinned to a
shared office bulletin board. Every team that cares about that kind of
announcement has already told the front desk, "put a copy of that notice
in our team mailbox whenever one goes up." The person posting the notice
pins it once, walks away, and never needs to know which teams are
subscribed, how many there are, or whether they've read it yet. Each
subscribed team gets their own copy delivered to their own mailbox.

**2. The precise technical restatement.** The person pinning the notice is
the **publisher**. The announcement itself is a **message** sent on a
**topic** (the specific bulletin-board category, e.g. "facilities
notices"). Each team that registered interest is a **subscriber**. The
front desk's job of copying the notice into every registered mailbox is
**fan-out** — one publish operation reaching every current subscriber
without the publisher addressing any of them individually. The publisher
never holds a reference to any subscriber and would work identically if
subscribers were added or removed tomorrow — that's the **decoupling**
pub/sub is designed to provide: publishers and subscribers depend on the
topic, never on each other.

**3. Where this analogy breaks down.**

- **Subscribers get independent copies, not a shared one.** In the
  bulletin-board picture it's tempting to imagine one physical notice that
  everyone reads off the same board. Technically, each subscriber
  receives its own independent copy of the message, delivered through its
  own channel — one subscriber mutating or consuming its copy has no
  effect on any other subscriber's copy. Reasoning from "they're all
  reading the same notice" leads to wrongly assuming subscribers can
  interfere with or block each other, which they cannot.
- **Message ordering is not guaranteed.** A physical board preserves
  posting order for anyone walking past — notice A pinned before notice B
  is read in that order by everyone. Most pub/sub systems make no such
  promise across subscribers, and sometimes not even for a single
  subscriber across topic partitions or delivery retries. A candidate who
  assumes "published in order" means "received in order" on the exam will
  get ordering-dependent scenario questions wrong.
- **The announcer/board does not wait for slow readers.** Pinning a
  physical notice is instantaneous and the poster's job ends there. In the
  technical system this maps to the publisher not blocking on any
  subscriber's consumption — a slow, backlogged, or temporarily offline
  subscriber does not slow down or fail the publish operation. The
  bulletin board can't literally mimic "delivery," so it's easy to
  half-imagine the poster standing there until everyone's collected their
  copy; that mental image is exactly backwards from how decoupled fan-out
  behaves.
