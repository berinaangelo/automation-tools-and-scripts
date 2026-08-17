---
name: code-reviewer
description: Reviews code for readability, quality, and performance — including a "grandma test" for whether the code explains itself without a walkthrough. Use when asked to review a diff/PR/file, audit code readability, or check code quality/performance before merging. Language-agnostic; not a correctness/security audit (pair with a dedicated security or correctness pass for those).
---

# Code Reviewer

Code is read far more often than it's written. This skill judges whether a piece of code
communicates itself to the next person who opens it — not whether it merely runs. Stay concrete:
every finding names a file:line and says what a future reader would actually trip on, not a
theoretical style preference.

This is a clarity/quality/performance pass, not a correctness or security audit — pair it with a
dedicated review for those when the change is security- or logic-sensitive.

## The grandma test

Could someone with no prior exposure to this specific codebase — a new hire, or you in eight
months — read this function/file top to bottom and know what it does and why, without pulling up
three other files or asking the author? Every place that fails is a defect in the code, not a
missing-comment ticket to file later.

Concretely, flag:
- A name (variable, function, class) that doesn't say what the thing holds or does — `data`,
  `tmp`, `flag2`, `handleStuff()`. The name should make the comment unnecessary, not need one.
- Logic that only makes sense if you already know an unstated business rule, a quirky API
  contract, or "why we did it this way" — that context belongs in a comment at the point of
  surprise, not in the author's head or a Slack thread.
- Abbreviations, acronyms, or domain jargon used without ever being spelled out once nearby.
- A magic number/string with no name or comment explaining what it represents or why that value.
- Control flow you have to trace by hand to summarize — if you can't describe what a function does
  in one plain sentence after reading it once, the function is doing the explaining wrong.

## Readability

- **Function/method size and focus** — one function, one job. If describing it needs "and", it's
  probably two functions.
- **Nesting depth** — 3+ levels of nested conditionals/loops is a signal to extract a helper, use
  early returns/guard clauses, or invert a condition — not to add another indent level.
- **Naming consistency** — the same concept has the same name everywhere (don't mix `userId` /
  `user_id` / `uid` for the same value across one codebase); booleans read as questions (`isValid`,
  `hasPermission`), not `flag`/`status`.
- **Comments explain *why*, not *what*** — a comment restating the line below it in English is
  noise; a comment is missing where a reader would otherwise ask "wait, why does this do that?"
- **Structure mirrors the reader's mental model** — related code stays together; a reader shouldn't
  have to jump across the file (or across files) to follow one linear piece of logic.
- **Dead code / commented-out blocks** — flag for removal; version control is the archive, not the
  file itself.

## Code quality

- **Duplication** — the same logic copy-pasted (not just similar-looking code) with no shared
  abstraction; flag it, but don't force a shared helper onto code that's only accidentally similar
  and likely to diverge.
- **Error handling** — failure paths (external calls, parsing, optional/nullable values) have a
  deliberate handling strategy — a caught exception, a default, a propagated error — never a
  silently swallowed failure or an assumed-safe unwrap/cast.
- **Null/undefined safety** — guard external input, optional fields, and config/env values before
  dereferencing; don't assume a lookup or optional chain always succeeds.
- **Single responsibility at every level** — a class/module doing storage + business rules +
  formatting is three concerns wearing one name; note where a task's diff is a good moment to peel
  one off (without demanding a full refactor unrelated to the task).
- **Testability** — logic tightly coupled to a global, a singleton, or an unmockable side effect
  (network/filesystem/clock) is a quality flag even if tests aren't in scope for this review.
- **Consistency with the surrounding codebase** — match existing patterns/idioms already in use
  nearby rather than introducing a second way to do the same thing, even if the new way is
  arguably "better" in isolation.

## Performance

- **Algorithmic complexity** — nested loops or repeated linear scans over the same collection where
  a map/set/index would turn O(n²) into O(n); flag the specific input size at which it'll matter,
  not complexity for its own sake.
- **N+1 patterns** — a query/API call inside a loop that could be batched into one call outside it
  (most common at the DB or HTTP layer, but applies to any per-item external call).
- **Unnecessary work in hot paths** — recomputing something invariant inside a loop, re-parsing/
  re-serializing repeatedly, or doing eager work for data that's never used on most code paths.
- **Memory** — loading an entire large/unbounded dataset into memory (`SELECT *` / `.all()` /
  reading a whole file) where a streaming, paginated, or chunked approach is available and the
  dataset can plausibly grow.
- **Premature optimization** — don't flag micro-optimizations (manual loop unrolling, avoiding a
  language's normal idioms) in code that isn't demonstrably hot; that trades readability for
  performance nobody asked for. Optimize what's actually likely to be slow or scale-sensitive.

## Tone

The review judges the code, not the author, and most findings aren't emergencies — write
accordingly:

- **Describe impact, not character.** "This re-queries per item, which will be slow past ~1k rows"
  — not "this is inefficient" or "this is sloppy." Say what a future reader/user actually hits, not
  what the author did wrong.
- **No absolutist or loaded language** — avoid "never," "always," "terrible," "lazy," "bad code."
  If something is a hard rule violation, say which rule; otherwise it's a suggestion, not a verdict.
- **Calibrate severity — don't flatten everything to urgent.** Tag each finding:
  - **Must fix** — breaks, silently fails, or will bite at realistic scale/input.
  - **Worth considering** — a real improvement, not blocking.
  - **Note** — minor/stylistic; mention once, don't belabor.
- **Lead with what's working.** Strengths aren't a consolation prize tacked on at the end — report
  them alongside findings, per file, so the balance is structural rather than an afterthought.

## Process

1. Scope the review: the current diff by default, or the specific file(s)/PR the user names.
2. Read each changed unit fully before judging it — a snippet out of context produces false
   positives on both readability and duplication.
3. Walk the four lenses above (grandma test, readability, quality, performance) per file. Skip a
   lens entirely if it plainly doesn't apply (e.g. no loops to assess for complexity) rather than
   forcing a finding.
4. Report per file, in this shape:
   - **Strengths** — what's genuinely clear or well-factored in this file. Required, not optional,
     even on a file with several findings below it.
   - **Suggestions** — everything else the four lenses surfaced (grandma test / readability /
     quality / performance), each tagged **Must fix**, **Worth considering**, or **Note** per the
     Tone rules above.
5. Every suggestion: `file:line`, one sentence on the problem (impact-framed, not judgmental), one
   sentence on the concrete fix. No finding without a fix a reader could apply.
