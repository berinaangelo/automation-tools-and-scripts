# KOS Guidelines

Personal Knowledge Operating System — plain markdown, no Obsidian, queried via Claude Code (grep/glob, no vector reindexing).

## Purpose

Ground Claude's answers in facts specific to *you* — your projects, decisions, context — instead of relying on general training data. Works via retrieval: relevant notes get read into context at query time, not baked into the model ahead of time.

## Why no reindexing

Claude Code searches with `ripgrep`/`glob` directly on the files — near-instant even across thousands of notes, no embeddings, no vector DB, no stale index to rebuild after every edit. The KOS is always read live, so it's never out of date.

## Directory structure

```
knowledge-base/
├── CLAUDE.md              # tells Claude how to use this KOS
├── INDEX.md               # entry point — one-line pointer to everything
├── projects/
│   └── <project-name>/
│       ├── PLAN.md         # top-level overview + links to features
│       ├── features/
│       │   └── <feature-name>/
│       │       ├── PLAN.md
│       │       ├── mockups/
│       │       └── notes.md
│       └── notes/          # project-wide facts, not tied to one feature
├── decisions/              # why X over Y, one file per decision
├── reference/               # how-tos, gotchas, external links you've worked out
└── people/                  # optional — context on collaborators/contacts
```

## Promotion rules

- **Fact → flat file**: a single durable fact gets one markdown file (`projects/<name>.md`, `decisions/<name>.md`).
- **Flat file → project folder**: once a project needs more than one artifact (plan + mockups + notes), promote it to `projects/<name>/` with its own `PLAN.md`.
- **Project → feature split**: once a project has multiple features in flight simultaneously (not preemptively), give each its own `features/<feature-name>/` with its own `PLAN.md`, `mockups/`, `notes.md`.
- Don't build deeper layers speculatively — split only when the flat version actually gets confusing.

## Note format (atomic facts)

```markdown
---
title: <short-kebab-case-slug>
tags: [project-x, infra]
date: 2026-08-17
---

The fact, written for future-you or future-Claude with zero other
context assumed. Link related notes with [[other-slug]] (plain text
— grep-able, no special renderer needed).
```

One fact per file — keeps retrieval precise; Claude reads exactly what's relevant instead of loading one sprawling doc.

## PLAN.md ≠ atomic note

`PLAN.md` is a living document, not a fact — it changes shape as a project evolves. Keep it short by moving churny detail down a level (project → feature) rather than letting it grow indefinitely.

**Signs it's time to split a growing PLAN.md:**
- Scrolling past finished/abandoned sections to find the active one
- Two features being worked in parallel, notes interleaving
- Needing to read the whole file for context on one small feature

**How to split without losing history:**
```bash
mkdir -p features/<feature-name>
git mv PLAN.md features/<feature-name>/PLAN.md   # preserves git blame
```
Then rewrite the top-level `PLAN.md` as a short index linking to each feature's plan.

**Archive, don't delete** — move a finished feature's plan to its own file with a `Status: done` line rather than scrubbing it. The KOS's whole point is a durable record.

## INDEX.md — the entry point

One line per note/project, link + why-it-exists, mirroring the folder structure. Claude reads this first and only opens files it actually needs.

```markdown
# Knowledge Base Index

Last updated: 2026-08-17

## Projects
- [ecommerce-migration](projects/ecommerce-migration/PLAN.md) — moving cart/checkout off legacy PHP
  - [checkout-redesign](projects/ecommerce-migration/features/checkout-redesign/PLAN.md) — in progress

## Decisions
- [chose-postgres-over-mongo](decisions/chose-postgres-over-mongo.md) — relational fit, team familiarity

## Reference
- [terraform-gotchas](reference/terraform-gotchas.md) — state locking issues, workarounds
```

**Maintenance rule:** update `INDEX.md` in the same sitting as any create/finish/split — it's hand-maintained, only as good as your discipline keeping it current.

## CLAUDE.md — teaches Claude the convention

Place at KOS root so any Claude Code session opened there auto-understands the system without re-explaining:

```markdown
# Knowledge Base

- `INDEX.md` — always read this first to see what notes exist
- One fact/topic per `.md` file, frontmatter has `title`, `tags`, `date`
- `[[slug]]` links point to other files by their `title` frontmatter value

When asked to save something here: check INDEX.md for an existing
note to update before creating a new one. Always add new notes to
INDEX.md.
```

## Versioning

```bash
cd ~/knowledge-base
git init
git add -A
git commit -m "init knowledge base"
```
Free backup, free diff history on how your understanding evolved.

## When you'd need more than this

- **Thousands of notes** and grep starts feeling slow (rare for a personal KOS)
- **Semantic search** ("find things *like* this," not matching text) — this reintroduces the reindexing tradeoff (vector DB, embeddings, staleness) that this setup deliberately avoids. Don't reach for it until the flat-file approach demonstrably fails.
