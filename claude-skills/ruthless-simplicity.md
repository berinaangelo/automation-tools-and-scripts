---
name: ruthless-simplicity
description: Draft a new product/feature plan, or audit an existing one, through a ruthless-simplicity lens — one coherent core flow, aggressive cuts, plain language, zero-manual usability — instead of a checklist of independent features. Use when writing a plan/roadmap/spec from scratch, or reviewing one for scope creep, jargon, or unnecessary complexity before committing to it.
---

# Ruthless Simplicity

A plan is judged on how little it can get away with, not how much it covers. Simplicity is the
deliverable, not a side effect of trimming features at the end.

## The five gates

Every plan — new or existing — must pass all five before it's good, not just correct:

1. **One-sentence test** — can you describe what the product/feature does in one sentence a
   non-technical person understands, with no "and" stacking two ideas together? If it takes two
   sentences, the scope isn't focused yet.
2. **Grandma test** — could someone with no technical background use the primary flow with zero
   instructions, config, or a manual? Every place a user has to be told something first is a
   defect in the plan, not a documentation task.
3. **Demo test** — could you walk someone through the whole thing live, start to finish, without
   saying "and then in a future version..." or apologizing for a rough edge? Anything you'd wave
   hands past isn't done — it isn't real yet.
4. **"Why does this exist" test** — for every feature/task, the honest answer must be "the core
   flow breaks without it." If the answer is "someone might want it," "just in case," or "it's
   already partly built," it's cut, not deferred.
5. **One-narrative test** — does the plan read as a single story the user lives through start to
   finish, or as an independent checklist of features bolted on next to each other? A pile of
   options is design by committee, not a decision.

## Generate mode — drafting a new plan

1. Write the one-sentence description first. If you can't, the scope isn't known yet — go find
   that out before writing a single task.
2. Identify the single primary flow (the thing the product is *for*) and write it out step by
   step, in plain language, as the user experiences it — not as a feature list.
3. List every other thing anyone has asked for. For each, force one of two answers: "breaks the
   core flow without it" (in) or "cut" — no third bucket. A long "later / someday" list means the
   cutting didn't actually happen; the goal is a short, plainly-stated "not doing this" list, not
   a backlog.
4. Draft the plan only around what's "in." Each step of the core flow gets its own concrete,
   demoable unit of work — no step should need a caveat to demo.
5. Re-run the five gates against the draft before calling it done.

## Review mode — auditing an existing plan

1. Read the whole plan/doc, then extract the one-sentence description implied by everything in
   it. If it can't compress to one sentence, that's the headline finding.
2. Count the independent, unrelated feature threads (not steps of one flow — genuinely separate
   capabilities). More than one or two means this is several products stapled together, not one
   plan.
3. For each feature thread, apply the "why does this exist" test. Flag anything justified by
   "nice to have," "might need it," "already half-built," or "low effort" — those survive by
   inertia, not because they're needed.
4. Flag jargon: any label, task name, or step a non-technical reader would need explained to them.
5. Flag any step in the primary flow that requires configuration, a setting, or a decision the
   user shouldn't have to make — surface it as "needs a sensible default," not "needs a settings
   page."
6. Produce the review as three sections, not prose:
   - **Keep** — the core flow, stated as the one-sentence description.
   - **Cut** — everything that failed a gate, one line each, naming the gate it failed.
   - **Simplify** — anything kept but bloated: same capability, fewer steps/screens/fields.

## What "ruthless" does not mean

Not: fewer words in the doc, or technically minimal effort. It means fewer *things the user has to
think about*. A plan that's short but still asks the user to configure five optional settings
hasn't been simplified — it's been shortened. Cutting a feature because it's hard to build is not
this exercise; cutting a feature because the core flow doesn't need it is.