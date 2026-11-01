---
name: bd-research
description: Research a beads (bd) epic before planning it — the "research" step of research → plan → implement. Runs inside a bd-dev plan worktree, agrees on the purpose and scenario with the user first, then fans out read-only sub-agents over the code, production data, vendor docs, and past PRs so the search traffic stays out of this context, and compacts their findings into one research document that states facts with sources and leaves every decision to the plan — no recommendations, no fixes. Once the user accepts it, it is stored on the epic (notes, or a path the user names) so create-plan / bd-plan build on it. Trigger on "/bd-research", "research this first", or when the user asks to investigate a bd issue before planning it.
---

# bd-research

The research step of the beads flow: `bd-dev` cuts issue + plan worktree,
**`bd-research` finds out what is true**, create-plan → `bd-plan` turns it into
a plan and child issues, `bd-go` implements.

Based on "frequent intentional compaction" (humanlayer, ACE-FCA). Agent output
depends only on what is in the context window, and the worst things in it are,
in order, wrong information, missing information, and noise. Research moves
the expensive part (searching, reading, querying) into sub-agents with fresh
contexts and keeps only a compact, sourced artifact. A wrong line of research
can turn into thousands of wrong lines of code, so the user's review of the
research is where review pays off most.

Optional: for a small, well-understood change, the user can go straight to
create-plan.

## Where to run

In the epic's plan worktree (branch `<issue-id>-<slug>-plan`), before
`/bd-plan`. Derive the issue from the branch exactly as bd-plan does (its
"Parent issue" snippet, with `bd list --all -n 0`, since the default list
stops at 50 open issues). An explicit issue ID as argument overrides
that. With no issue, research anyway, keep the document in the scratchpad, and
say that nothing was stored.

**Issue IDs are internal plumbing.** Refer to the issue by title (the ID can
appear alongside, small).

## The one rule: facts, not opinions

The research states what is true, with a source for every claim. It does NOT
recommend an approach, rank options, propose a fix, or critique the code.
Choosing is the plan's job, and the plan is reviewed separately. Research that
leans toward an answer biases the plan before anyone has reviewed the choice.

- Allowed: facts and their direct consequences ("if the probe changes before
  the endpoint ships, the new revision fails with 404"), options that exist
  ("the API offers A and B"), and the questions the plan must decide.
- Not allowed: "we should", "recommended", "the better option is", a fix
  plan, a preferred option in a comparison table.

Pass this rule on to every sub-agent.

## Sources

Not just code. Use whatever the question needs:

- Code and config in the repo (`path:line`)
- Production data: metrics, logs, traces, warehouse queries, through whatever
  tools the session has (Datadog, BigQuery, Cloud Logging, ...). Record the
  query, the environment, and the time range with every number
- Vendor / library docs and specs: quote the relevant passage verbatim and
  cite the URL
- History: past PRs, commits, issues, earlier docs (`gh`, `git log`). This is
  historical context only. The live code and current data are the source of
  truth
- Costs, quotas, limits from official pricing / quota pages

Read-only throughout. Never change resources, write to a database, or run
anything that writes outside the scratchpad while researching. The only
files written are in the scratchpad: the sub-agents' findings files and
the two research documents.

## Steps

1. **Agree on the purpose before researching.** Read the issue (`bd show
   <id> --json`: title, description, and `notes`, which may hold a
   previous research). Read in full any file, ticket, doc, or thread the
   user points to, in this context, before spawning anything. Then draft:
   - the purpose: what decision or plan this research feeds, and why now
     (the incident, request, or goal behind it);
   - the scenario it assumes: who uses the result, what is already fixed
     (platform, accounts, budget, who operates it), so the research looks
     at one concrete case, not every case the goal could mean;
   - done: the questions that must have answers (or a named "could not
     determine") before planning can start;
   - out of scope.

   Show the draft and confirm it with the user (AskUserQuestion) every
   time, not only when the issue looks vague: a broad goal ("a platform
   for X") read one way sends every sub-agent down that reading, and a
   scenario corrected after the research means doing it again. Ask about
   the goal and the fixed facts, a few questions at most; do not interview
   the user about the solution. Spawn nothing until the user agrees. The
   user's steering here matters more than anything else in this skill.

2. **Decompose.** Split the done questions into independent research
   areas, for example: where the relevant code lives and how it is wired;
   the path a request or piece of data takes; what production data shows;
   what the vendor / library spec says; the existing conventions a change
   would have to follow; history (why it is the way it is). Track the
   areas as a todo list.

3. **Fan out read-only sub-agents in parallel** (one message, several agent
   calls), one per area. Each one gets its own findings file,
   `<scratchpad>/research/<nn>-<area>.md`, and that file is the only thing
   it may write. Use an agent type that can write a file (a read-only
   explore type usually cannot); the brief restricts it to that one file.
   Each brief says:
   - the area, the purpose, the scenario, and the numbered done questions
     (one or two sentences of context);
   - read-only apart from its findings file, and the facts-not-opinions
     rule;
   - **the findings file holds everything it found**, in the evidence
     format (step 5): per done question, a table of fact | source
     (`path:line`, query + environment + time range, URL with the passage
     quoted) | bears on; flows as ordered steps (`a.go:12 → b.go:40 →
     ...`); and searched, not found | where (paths, queries, URLs). Facts,
     not file dumps or long excerpts, but nothing left out for length;
   - **the reply is short**: a summary of at most ~40 lines, each point
     tagged with its done question, the "not found / unsure" headlines,
     and the findings file path.

   The details stay in the files, not in this context: what a summary
   left out is still on disk for the evidence. Locate first, then
   analyze. If the first pass only finds where things are, send a second
   round at the most relevant spots, each with a findings file of its
   own. Do not do that deep reading in this context. This context is for
   synthesis.

4. **Synthesize, verify, and finish the evidence.** Wait for every
   sub-agent. Build the evidence from the findings files, not from the
   summaries: merge their rows under each done question, and write
   nothing into it that no file or check of yours backs. Use the
   summaries to connect the areas.
   Spot-check the claims a question for the plan rests on by opening the
   cited lines, re-running the query, or reading the cited passage
   yourself. A wrong source is worse than none. Mark what you did not
   confirm, and drop what you found to be wrong. Strip any recommendation
   a sub-agent slipped in. Where it pointed at a real trade-off, turn it
   into a question for the plan. Every fact from the files that serves the
   purpose goes into the evidence file (format below), so no later
   session has to search for it again. The evidence is final before the
   review is started.

5. **Write the review from the evidence alone, in a fresh agent.** This
   context is full of search traffic, half-read files, and sub-agent
   guesses that did not hold up; a review written here picks some of it
   up as if it were fact. Spawn one agent with a fresh context and give
   it only: the evidence file path and the review format and drawing
   rules below. It writes `<scratchpad>/research.md`
   from the evidence and nothing else: no searching, no reading code, no
   facts of its own. When the review needs a fact the evidence does not
   hold, it lists the gap instead of filling it; go back to step 3 or 4
   for that fact, add it to the evidence, and have the review redone.
   Then check its output here: every `→ Qn` points at an evidence section
   that holds the fact, every question for the plan is backed by the
   evidence rows that bear on it, and every diagram matches the evidence.

   **The two files**: the **evidence**,
   `<scratchpad>/research-evidence.md`, and the **review**,
   `<scratchpad>/research.md`. The headings below are the structure.
   Required sections are marked; include an optional section only when it
   has content.

   The review is for the user: the shape, the scenario, what is left to
   decide, readable in a few minutes. The evidence is for the agent that
   plans or picks the work up later: every fact found, with its source,
   so nothing has to be researched twice. **The evidence is the source of
   truth.** The review is a view of it for reading; where the two
   disagree, the evidence is right and the review is fixed. Two files, one
   set of facts:
   - number the done questions (Q1, Q2, ...) and use the same numbers in
     both files;
   - everything in the review has its evidence: a fact in the review
     names the done question it comes from (`→ Q2`), and that section of
     the evidence holds its source;
   - any evidence that bears on a question for the plan shows up in that
     question's table in the review, so the user has reviewed everything
     a decision rests on;
   - the evidence is written toward the purpose too. A fact that serves
     none of the done questions belongs in Out of scope findings, not in
     the evidence;
   - a fact changes in the evidence first, and the review follows it,
     never the other way round.

   The evidence, `research-evidence.md`:

   ```markdown
   # <topic> research evidence (<YYYY-MM-DD>)

   <Frame (required): the purpose, the scenario, the numbered done
   questions, the issue, and the commit, restated so an agent that reads
   only this file knows what the facts were gathered for, and can tell
   which ones no longer hold if the scenario or the code changes.>

   ## Q<n>: <done question>
   <Status: answered / partly / could not determine. Then a table: fact |
   source (`path:line`, query + environment + time range, URL with the
   passage quoted) | verified (by you / sub-agent only) | bears on (a
   question for the plan, or none). Then: searched, not found | where
   (paths, queries, URLs). The not-found list is what saves the next
   session the most time; never leave it out.>
   ## Other facts
   <Facts that serve the purpose but no single done question.>
   ```

   The review, `research.md`:

   ```markdown
   # <topic> research (<YYYY-MM-DD>)

   <Intro (required): the purpose, the scenario, the numbered done
   questions, and what is out of scope, as agreed in step 1.>

   - Issue: <id> / Commit: <short sha> on <branch>

   ## Findings (required)
   <Opens with one Mermaid flowchart of the areas: components as nodes,
   how they connect as labeled edges.>
   ### <Area>
   <A diagram of the area first: what talks to what (flowchart), what
   state a resource or process can be in (stateDiagram), what is
   enabled / missing (flowchart, one class per status). Then a table only
   for the attributes the diagram cannot carry, `path:line` per row.>

   ## Flow (required when there is any path)
   <One Mermaid sequenceDiagram per path the question touches: a request,
   a login, a token refresh, a job run, a deploy. `path:line` or a doc URL
   on each step. Omit the section only when nothing in the question
   happens in order. Never fill it with a table of options.>

   ## Observed data (optional)
   <Table: metric | value | query | environment | time range.>

   ## External specs (optional)
   <Quoted passages (verbatim) with URLs; limits and quotas
   as a table.>

   ## Conventions (required; write "none found" if so)
   <Table: concern (feature layout, tests, error handling, generated
   files, ...) | how this repo does it | `path:line` example.>

   ## Constraints (optional)
   <A flowchart from each constraint to its direct consequences (what it
   blocks, what it leaves undetermined), source on each node. No
   "therefore do X".>

   ## Questions for the plan (required)
   <Opens with a flowchart of the questions as nodes and which one's
   answer changes another as edges, so the plan sees where to start; all
   nodes drawn alike. Per question: the question as a `###` heading, then
   a table of options | facts for | facts against, each fact with its
   source. No pick, no ranking. Then a table of what could not be
   determined | who could answer it.>

   ## Out of scope findings (optional)
   <Things noticed along the way that belong to another issue.>

   ## Sources (required)
   <URLs, PRs, queries.>
   ```

   **Diagrams first, then tables, prose last.** The reader should get the
   shape at a glance and drop into tables and text only for detail. Every
   `##` section with more than one fact opens with a diagram, except
   Observed data, External specs, Conventions, and Sources. Draw anything
   with relations, order, states, or dependencies: connections and
   dependencies as `flowchart`, paths as `sequenceDiagram`, lifecycles as
   `stateDiagram`. Tables are for attributes of things already in a
   diagram and for side-by-side comparisons; a section that is only a
   table where a diagram would show how its rows relate is not done.
   Prose is for what neither can carry, a sentence or two per block. Keep
   each diagram small enough to read without zooming (about 12 nodes;
   split it otherwise), and give every node or edge that states a fact a
   `path:line` or URL in its label or in the table under it. A diagram is
   a claim like any other: check it against the evidence in step 5, and
   never draw a preferred option highlighted.

   The drawing rule applies to the review. The evidence is tables:
   precise, complete, sourced; no diagrams needed.

   There is no summary section: the intro states the purpose and
   "Questions for the plan" carries what is left to decide, and anything
   else a summary would say is repeated from the sections below it. Keep
   the review short enough for the user to read in a few minutes, around
   200 lines at most, follow-ups included. The evidence has no line limit,
   but it holds facts, not file dumps or long excerpts. The rules below
   apply to both files.
   Paths are relative to the repo root. Never write absolute paths, `$HOME`,
   a username, credentials, or personal data from production: the issue
   data syncs off this machine (`.beads/config.yaml` has a `sync.remote`).

6. **Hand it to the user for review.** Show the Questions for the plan
   (the dependency flowchart and the question headings), and give the
   paths of both files. Ask them to read the review; the evidence is
   there to check any claim they doubt. Then:
   - **accept** → step 7;
   - **steer** ("it missed X", "Y is not the relevant path", "look at Z
     instead") → re-run steps 2–5 with the correction: the evidence first,
     then the review from it. If the research went
     down a wrong path, start the sub-agents over rather than patching:
     errors carried over from a wrong path keep the plan on it;
   - **discard** → stop. Nothing is stored.

   Never store research the user has not accepted.

7. **Store the accepted research on the epic.** By default both files go
   in the issue's `notes`, the review first and the evidence after it, so
   they are stored, read, and overwritten together (`design` is reserved
   for the plan, `description` for the original request):

   ```bash
   bd update <id> --notes "$(cat <scratchpad>/research.md; printf '\n\n'; cat <scratchpad>/research-evidence.md)"
   bd comment <id> "Research stored in notes (commit <short-sha>)"
   ```

   Only if the user names a place for the documents (a directory, a repo),
   write both files there instead and record only the pointers:

   ```bash
   bd update <id> --set-metadata "research_doc=<path>/research.md" \
     --set-metadata "research_evidence=<path>/research-evidence.md"
   ```

   Never pick a location in some repo on your own. Paths in metadata follow
   the bd-dev rule: relative to the repo root, never absolute. Overwriting
   `notes` on a redo is intentional. Record why in the comment trail
   (`bd comment <id> "Research redone: <reason>"`).

8. **Report and point to the next step.** One-line summary plus the next
   step in THIS session: create-plan (clear-plan-skills:create-plan), which
   reads the research from `bd show <id> --json` → `.[0].notes` (or the
   two files in `.[0].metadata.research_doc` / `research_evidence`),
   starts from "Questions for the plan", takes every fact from the
   evidence (the source of truth, not the review), and cites the research
   in its References; then `/bd-plan`.
   If this session has filled up during research, suggest planning in a
   fresh claude in the same worktree. The research is on the issue, so nothing is lost.

## Follow-up questions

If the user asks a follow-up before accepting, research it the same way and
add a `## Follow-up: <topic>` section to the review and its facts to the
evidence (a new numbered done question if it adds one). It follows the
same rules: diagrams first, its questions in the options | facts for |
facts against form, and it counts toward the 200-line limit of the
review. If it would push the review past that, fold what it found into
the existing sections instead of appending. After the research is
stored, store it again only when the user accepts the revision.

## Notes

- Research is never a cache. Every run reads the live code and data. An
  older research in `notes` is something to compare against, not something
  to trust. If the code changed since its commit, say so. Its evidence
  tells a new run where to look first and what was already searched
  without result; re-check those facts whose source changed since, and
  the rest only when a question for the plan rests on them.
- Research does not change the issue's type or status and cuts no children.
  That is bd-plan's job.
- Keep `bd-dev`, `bd-research`, `bd-plan`, `bd-go`, and `bd-review` in sync. They share
  branch/session conventions and the lifecycle.
