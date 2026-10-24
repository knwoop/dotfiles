---
name: platform-engineering-radar
description: Catch up on what shipped across Platform Engineering / SRE / Observability / Cloud Native — CNCF, Kubernetes, OpenTelemetry, Go / Rust / TypeScript releases, and influential practitioner blogs. Use when the user asks for the "latest", "this week", "catch-up", "trends", "what's new", or wants a weekly report or blog draft in this space. Combine with `/loop` or `/schedule` for recurring runs.
---

# Platform Engineering Radar

Information-collection skill for "what happened" across the Platform Engineering space. Fans out across CNCF, OpenTelemetry, language releases, and practitioner blogs, then produces a category-organized summary.

## When to use this skill

- Weekly or monthly catch-up report
- Deep-dive on a specific topic (CNCF trends, OTel spec changes, Go releases…)
- Blog post / internal-share doc draft
- Scouting topics for a reading club or lightning talk

This skill runs once per invocation. For recurring cadence, combine with `/loop` or `/schedule` — e.g. `/schedule weekly Monday 9am /platform-engineering-radar`. The skill itself stays stateless; scheduling lives in the runner.

## Core principles

1. **Sources live in `references/sources.md`** — the skill body stays stable; adding/removing sources happens in one file.
2. **Fan out with parallel `WebFetch` calls in a single turn** — never chain sequentially.
3. **Windows vary by source cadence** (see Step 1). Always state the window up front.
4. **Output is in English.** Preserve proper nouns, commands, API names, spec terms verbatim.
5. **Always attach the source list at the end** so the reader can trace back.
6. **Rewrite every item in your own words** — no copy-paste. Quoted phrases under 15 words, at most one quote per source.
7. **The skill is organization-neutral.** Stakeholder framing ("why it matters for our team") is opt-in via the `context=` arg or an explicit user hint.

## Workflow

### Step 1: Decide the scope

Extract four things from the user's request. If ambiguous, apply the default and state the assumption up front — do not ask back.

- **Categories**
  - Specified ("just CNCF", "OTel only") → only those
  - Unspecified → **all categories at `core` tier**
- **Time window** — defaults vary by source cadence. Language releases are slow; a 7-day window misses them every week.
  | Source type | Default window |
  | --- | --- |
  | CNCF / Kubernetes / Observability / Platform Eng / Cloud vendor / Influencers / Security / Media | **7 days** |
  | Go | **30 days** |
  | Rust, TypeScript | **90 days** |
  If the user specifies a window ("past 2 weeks", "past month"), that overrides all categories uniformly.
- **Output format**
  - Specified → follow it (blog draft / bullet summary / Obsidian note, etc.)
  - Unspecified → **category-organized Markdown summary**
- **Org context** (optional)
  - `context=<org-or-team>` arg, or a user hint like "for our platform team" → append a one-line relevance note under each item, framed for that context
  - Unspecified → omit org framing entirely

### Step 2: Consult the source list

Read `references/sources.md` and pull URLs for the target categories. Each entry carries a tier tag:

- **core**: always fetched on a default run
- **featured**: added when the user says "in detail", "broader", "full coverage"
- **archive**: only consulted when a specific topic is called out

Tier resolution:
- Default run → `core` only
- "In detail / full / broader" → `core` + `featured`
- Specific category called out → all tiers (`core` + `featured` + `archive`) become candidates

### Step 3: Parallel `WebFetch`

Issue multiple `WebFetch` calls in the **same turn**. Sequential fetching wastes time — always batch.

URL selection hints:
- Prefer `/releases/latest` or `CHANGELOG.md` on GitHub repos (explicit dates, easier to summarize)
- Blog landing pages are for scanning recent titles and excerpts — only chase individual posts if the headline is genuinely unclear
- Fall back to `WebSearch` only when a primary source can't be reached

### Step 4: Filter by time window

Drop items outside the applicable window (per Step 1's table).

- Date present → strict filter
- Date missing (list pages, excerpts) → keep the top few as candidates, mark them "date unknown"
- **Never infer a date**; if unknown, say so

### Step 5: Dedupe across sources

The same release or announcement often shows up in multiple sources — e.g. a Kubernetes release appears in both `kubernetes.io/blog` and `cncf.io/blog`; an OTel spec cut appears in both `opentelemetry.io/blog` and the spec repo's releases page.

- Group items by topic (release tag, feature name, CVE id, incident handle, etc.)
- Keep the **primary source** — the one closest to the change:
  - Official project blog for releases
  - Spec or CHANGELOG for spec changes
  - GitHub release notes for detailed feature lists
  - Vendor engineering blog for vendor incidents / launches
- Drop duplicates from the main body; note them in the "Sources checked" list as `(dup of <kept-source>)`

### Step 6: Write the summary

Use the template below. If a category has no qualifying items, drop the whole section — never leave empty sections.

```markdown
# Platform Engineering Radar (as of YYYY-MM-DD)

> Scope: <categories> / Tier: <core | core+featured | ...>
> Windows: general 7d, Go 30d, Rust/TS 90d (or user-specified override)
> Fetched: N OK / M failed / K deduped

## 🌐 Cloud Native / CNCF

- **[Post title](URL)** (YYYY-MM-DD)
  - One or two lines summarizing the point in your own words.

## 🔭 Observability / OpenTelemetry

(same shape)

## 🐹 Go / 🦀 Rust / 🟦 TypeScript

(same shape; sub-headings per language are fine)

## 🏗️ Platform Engineering / SRE

(same shape)

## 🔥 Influencers / Performance

(same shape)

## ☁️ Cloud / Infra vendor blogs

(same shape)

---

## 📚 Sources checked this run

- <URL> — <category> — <OK / no items in window / fetch failed / dup of <URL>>
- ...
```

Each item:
1. Title link
2. Date (or "date unknown")
3. 1–2 line summary in your own words

If `context=<org>` was set (Step 1), add a third line: `_Relevance for <org>: …_`. Otherwise omit entirely.

### Step 7: Blog-draft mode (optional)

If the user says "make this a Zenn / Hatena draft" or "turn it into a blog post":

- Add a short intro paragraph (three lines on this run's headline topics)
- Append a one-line "why it matters" to each item
- Add a "References" section at the end
- Tone: measured, technical, engineer-to-engineer

## Output quality checklist

Before returning, verify:

- [ ] Time window stated at the top (including per-category overrides)
- [ ] Each item has (1) title link, (2) date or "date unknown", (3) 1–2 line summary
- [ ] Summaries are rewritten — no copy-paste
- [ ] Quoted phrases stay under 15 words, at most once per source
- [ ] Uncertain claims use "reportedly", "appears to", or similar
- [ ] "Sources checked this run" section exists, listing OK / no-items / failed / dup
- [ ] Empty-category sections dropped, not left blank
- [ ] Org framing appears only when `context=` or an equivalent hint was given

## Adding or removing sources

All sources and category assignments live in `references/sources.md`. Adding, re-tiering, or removing a source happens entirely in that file — no SKILL.md edits needed.

Maintenance rules for `references/sources.md`:

- New entries always carry a tier (`core` / `featured` / `archive`)
- Within a category, sort by tier ascending (`core` first)
- Sources that are persistently unreachable (404, consistently aborted) → demote to `archive` or remove
- Keep entries organization-neutral. Team-specific annotations ("we use this") belong in an optional overlay, not in this list.
