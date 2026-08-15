---
name: laws-of-ux
description: Design a new screen/flow/form, or audit an existing UI, against the Laws of UX — psychology-grounded heuristics (Jakob's, Fitts's, Hick's, Miller's, Gestalt grouping, Peak-End, etc.) for how people actually perceive, remember, and decide inside an interface. Use before calling a UI "done," when laying out a form/nav/flow, or when reviewing a screen for usability problems.
---

# Laws of UX

A UI is judged on how it feels to a human nervous system moving through it, not on whether every
element is present and technically functional. These laws aren't taste — they're observed regularities
in attention, memory, and decision-making. Treat a violation as a bug, not a style preference.

## The laws

**Attention & decision-making**
- **Jakob's Law** — users spend most of their time on *other* apps; they expect yours to work like the
  ones they already know. Novelty in a core interaction (nav, forms, icons) is a tax on the user, not a
  feature — reserve invention for what's actually new about the product.
- **Fitts's Law** — time to hit a target scales with distance and inversely with size. Primary actions
  should be big and close to where attention already is; never shrink or distance the thing you most
  want clicked.
- **Hick's Law** — decision time grows with the number and complexity of choices. Every extra visible
  option slows the primary path down, even ones the user won't pick.
- **Doherty Threshold** — keep response under ~400ms, or give immediate feedback (spinner, optimistic
  UI, disabled-state) if it can't be. Unacknowledged latency reads as broken, not slow.

**Memory & cognitive load**
- **Miller's Law / Chunking** — working memory holds about 7±2 items. Group long lists/forms into
  labeled clusters of a handful of items rather than one flat list.
- **Serial Position Effect** — first and last items in a list/nav are remembered best, the middle is
  where things get lost. Put the most important items at the start or end, never buried mid-list.
- **Zeigarnik Effect** — interrupted/incomplete tasks stick in memory and nag at the user. Persist
  partial progress (drafts, saved form state) instead of discarding it on navigation away.
- **Peak-End Rule** — an experience is judged mostly by its most intense moment and how it ends. Put
  disproportionate care into error states (the peak of frustration) and the final confirmation/success
  screen (the end) — polishing the middle steps more than these is effort in the wrong place.

**Visual grouping (Gestalt)**
- **Law of Proximity** — elements placed close together read as related, regardless of labels. Spacing
  *is* the grouping mechanism — don't rely on a heading alone to convey structure whitespace contradicts.
- **Law of Similarity** — visually similar elements (color, shape, size) read as the same kind of thing.
  Don't reuse a style across elements with different behavior (e.g., link-blue text that isn't a link).
- **Law of Common Region** — a shared boundary (card, border, background) groups elements more strongly
  than proximity or similarity alone. Use containment deliberately for the groupings that matter most.
- **Von Restorff Effect** — the one element that looks different is the one that gets noticed. Reserve
  visual distinctness for the single action that should stand out; if everything is emphasized, nothing is.

**Complexity & motivation**
- **Tesler's Law** — every system has an irreducible amount of complexity; it can only be moved, not
  removed, between the system and the user. Every "advanced setting" you don't build is complexity you
  chose to absorb yourself via a sensible default — make that trade deliberately. See [[ruthless-simplicity]].
- **Goal-Gradient Effect** — motivation to finish increases as the end gets closer. Surface progress
  ("2 of 3 steps," a filling bar) especially near completion, where it does the most to prevent drop-off.
- **Aesthetic-Usability Effect** — users perceive polished interfaces as more usable, independent of
  whether they actually are. Useful for first impressions; never let visual polish substitute for fixing
  a real usability defect underneath it.
- **Postel's Law** — be liberal in what you accept, conservative in what you produce. Parse loose/messy
  user input forgivingly (phone formats, whitespace, case); keep the system's own output and states
  predictable and strict.

## Generate mode — designing a new screen/flow

1. Name the primary action on the screen before laying anything out. Everything else is secondary by
   construction — apply Fitts's/Von Restorff to make the primary action the biggest, closest, most
   visually distinct thing present.
2. Count the visible choices at each step. If it's more than what Hick's Law comfortably allows for a
   quick decision, cut or progressively disclose the rest — don't flatten every option into view at once.
3. Group related fields/content using proximity, similarity, and common region *together*, not as
   alternatives — spacing, matching style, and containment should all agree with each other about what
   belongs together.
4. Decide explicitly, per unit of complexity, whether the system absorbs it (sensible default, no user
   decision) or the user does (an exposed control) — Tesler's Law says it doesn't just vanish.
5. Design the error state and the completion state with as much care as the main flow — Peak-End Rule
   means those are what the user actually remembers.
6. If a response can't complete in ~400ms, design the waiting state now, not as an afterthought.

## Review mode — auditing an existing UI

1. Walk the primary flow start to finish as a first-time user would, not as someone who already knows
   where everything is.
2. Check each law above against what's on screen; a screen doesn't need to violate all of them to be
   worth flagging — one real violation on the primary path outweighs several on secondary screens.
3. Produce the review as three sections, not prose:
   - **Violations** — one line each: which law, where, and the concrete symptom (not just the law's name).
   - **Fix** — the specific change, stated as a UI change, not a principle restated.
   - **Fine as-is** — parts that look rough but don't actually violate a law; don't manufacture findings
     to pad the review.

## What this doesn't mean

Not a checklist to cite as jargon in a design doc — a law name isn't a justification unless the concrete
symptom is named too. Not a mandate for visual maximalism (adding borders/cards/color "for grouping"
can itself violate Hick's Law by adding visual noise) — the laws trade off against each other, and the
primary action's clarity always outranks decorating secondary content correctly. And polish is not a
substitute for fixing what it's covering up — the Aesthetic-Usability Effect describes a bias to guard
against, not a technique to lean on.
