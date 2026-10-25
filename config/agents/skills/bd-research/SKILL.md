---
name: bd-research
description: Research a beads (bd) epic before planning it — the "research" step of research → plan → implement. Runs inside a bd-dev plan worktree: grounds the question, fans out read-only sub-agents over the code, production data, vendor docs, and past PRs so the search traffic stays out of this context, and compacts their findings into one research document that states facts with sources and leaves every decision to the plan — no recommendations, no fixes. Once the user accepts it, it is stored on the epic (notes, or a path the user names) so create-plan / bd-plan build on it. Trigger on "/bd-research", "research this first", or when the user asks to investigate a bd issue before planning it.
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
- Vendor / library docs and specs: quote the relevant passage verbatim, add a
  translation if the document's language differs, and cite the URL
- History: past PRs, commits, issues, earlier docs (`gh`, `git log`). This is
  historical context only. The live code and current data are the source of
  truth
- Costs, quotas, limits from official pricing / quota pages

Read-only throughout. Never change resources, write to a database, or run
anything that writes outside the scratchpad while researching.

## Steps

1. **Ground the question.** Read the issue (`bd show <id> --json`: title,
   description, and `notes`, which may hold a previous research). Read in
   full any file, ticket, doc, or thread the user points to, in this
   context, before spawning anything. Write down:
   - the question: what has to be known before someone can plan this;
   - why it is being asked (the incident, request, or goal behind it);
   - what is out of scope.

   If the issue is too vague to say where to look, ask the user one targeted
   question (AskUserQuestion). The user's steering here matters more than
   anything else in this skill. Do not interview them about the solution.

2. **Decompose.** Split the question into independent research areas, for
   example: where the relevant code lives and how it is wired; the path a
   request or piece of data takes; what production data shows; what the
   vendor / library spec says; the existing conventions a change would have
   to follow; history (why it is the way it is). Track the areas as a todo
   list.

3. **Fan out read-only sub-agents in parallel** (one message, several agent
   calls), one per area. Use a read-only search/explore agent type where the
   harness has one. Each brief says:
   - the area and the overall question (one or two sentences of context);
   - read-only, and the facts-not-opinions rule;
   - the return shape: a compact summary, at most ~40 lines, a source for
     every claim (`path:line`, query + time range, URL), flows as ordered
     steps (`a.go:12 → b.go:40 → ...`), and an explicit "not found / unsure"
     list. No file dumps, no long excerpts.

   Locate first, then analyze. If the first pass only finds where things
   are, send a second round at the most relevant spots. Do not do that deep
   reading in this context. This context is for synthesis.

4. **Synthesize and verify.** Wait for every sub-agent. Merge the findings
   and connect them across areas. Spot-check the claims the summary depends
   on by opening the cited lines, re-running the query, or reading the cited
   passage yourself. A wrong source is worse than none. Drop or mark
   anything you could not confirm. Strip any recommendation a sub-agent
   slipped in. Where it pointed at a real trade-off, turn it into a question
   for the plan.

5. **Write the research document** to `<scratchpad>/research.md`. Write it
   in the user's language. The headings below are the structure, translate
   them as needed. Required sections are marked; include an optional
   section only when it has content.

   ```markdown
   # <topic> research (<YYYY-MM-DD>)

   <Intro paragraph (required): the question, why it is asked, what is out
   of scope.>

   - Issue: <id> / Commit: <short sha> on <branch>

   ## Summary (required)
   <The answer to the question, as facts. 3–6 bullets. No recommendation.>

   ## Findings (required)
   ### <Area>
   <What exists, where (`path:line`), how it connects to other areas.>

   ## Flow (optional)
   <The request / data / control path as numbered steps with `path:line`.>

   ## Observed data (optional)
   <Numbers from production, each with query, environment, time range.>

   ## External specs (optional)
   <Quoted passages (original + translation) with URLs; limits and quotas.>

   ## Conventions (required; write "none found" if so)
   <How this repo already does similar things — features, tests, error
   handling, generated files — with `path:line` examples.>

   ## Constraints (optional)
   <Facts the plan must respect and their direct consequences: ordering,
   limits, compatibility, cost. No "therefore do X".>

   ## Questions for the plan (required)
   <Each decision the plan has to make, phrased as a question, with the
   options that exist and the facts bearing on each. No pick. Then what
   could not be determined, and who could answer it.>

   ## Out of scope findings (optional)
   <Things noticed along the way that belong to another issue.>

   ## Sources (required)
   <URLs, PRs, queries.>
   ```

   Keep it short enough for the user to read in a few minutes, around 200
   lines at most. It is also the input to planning, so leave out noise.
   Paths are relative to the repo root. Never write absolute paths, `$HOME`,
   a username, credentials, or personal data from production: the issue
   data syncs off this machine (`.beads/config.yaml` has a `sync.remote`).

6. **Hand it to the user for review.** Show the Summary and Questions for
   the plan, and give the file path. Ask them to read the document, then:
   - **accept** → step 7;
   - **steer** ("it missed X", "Y is not the relevant path", "look at Z
     instead") → re-run steps 2–5 with the correction. If the research went
     down a wrong path, start the sub-agents over rather than patching:
     errors carried over from a wrong path keep the plan on it;
   - **discard** → stop. Nothing is stored.

   Never store research the user has not accepted.

7. **Store the accepted research on the epic.** By default it goes in the
   issue's `notes` (`design` is reserved for the plan, `description` for the
   original request):

   ```bash
   bd update <id> --notes "$(cat <scratchpad>/research.md)"
   bd comment <id> "Research stored in notes (commit <short-sha>)"
   ```

   Only if the user names a place for the document (a file path, a docs
   directory, a repo), write it there instead and record only the pointer:

   ```bash
   bd update <id> --set-metadata "research_doc=<path>"
   ```

   Never pick a location in some repo on your own. Paths in metadata follow
   the bd-dev rule: relative to the repo root, never absolute. Overwriting
   `notes` on a redo is intentional. Record why in the comment trail
   (`bd comment <id> "Research redone: <reason>"`).

8. **Report and point to the next step.** One-line summary plus the next
   step in THIS session: create-plan (clear-plan-skills:create-plan), which
   reads the research from `bd show <id> --json` → `.[0].notes` (or
   `.[0].metadata.research_doc`), starts from "Questions for the plan", and
   cites the research in its References; then `/bd-plan`. If this session
   has filled up during research, suggest planning in a fresh claude in the
   same worktree. The research is on the issue, so nothing is lost.

## Follow-up questions

If the user asks a follow-up before accepting, research it the same way and
add a `## Follow-up: <topic>` section to the same document. After the
research is stored, store it again only when the user accepts the revision.

## Notes

- Research is never a cache. Every run reads the live code and data. An
  older research in `notes` is something to compare against, not something
  to trust. If the code changed since its commit, say so.
- Research does not change the issue's type or status and cuts no children.
  That is bd-plan's job.
- Keep `bd-dev`, `bd-research`, `bd-plan`, and `bd-go` in sync. They share
  branch/session conventions and the lifecycle.
