---
name: mo
description: Open every Markdown file created or updated in this session in the browser with the mo viewer (live-reload). Collects the .md files this session wrote or edited, registers them all with mo, and opens the browser. Trigger on "/mo", "open the markdown in the browser", "show me the docs you wrote", or when the user wants to read this session's Markdown output rendered.
---

# mo

Register every Markdown file this session created or updated with `mo` (a
background Markdown viewer with live-reload, default http://localhost:6275)
and open it in the browser. Read-only: never edit, move or delete the files.

## Steps

1. **Collect the files.** The source of truth is this session's own file
   writes: every `.md` / `.mdx` file you created or modified (write and edit
   tools, shell redirects, generators you ran), wherever it lives — the repo,
   other repos, the scratchpad or temp directories. After a context compaction,
   recover the list from the summary or the session transcript; do not guess.
   - In a git repo, `git status --porcelain` is a cross-check only: it also
     shows the user's own changes, which are not part of this session unless
     you touched them.
   - Skip text written only to feed another tool, such as a GitHub PR or
     issue description, commit message or PR comment body (e.g. a file
     passed to `gh pr create --body-file`). It is published elsewhere, not
     a document to read here.
   - Keep only files that still exist. Use absolute paths. Deduplicate.
   - If there are none, say so and stop. Do not fall back to "all Markdown in
     the repo".

2. **Pick the group.** One mo group per working directory, so separate
   sessions and repos do not pile into one sidebar:
   `group=$(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")`.
   Use the user's group name instead if they give one.

3. **Register and open**, all files in one call:

   ```bash
   mo --target "$group" --open <abs-path> <abs-path> ...
   ```

   `--open` opens the browser even when the group already exists. mo starts
   its server in the background if none is running, and adds to the running
   one otherwise. Do not pass `--port`, `--watch`, `--bind`, `--clear`,
   `--shutdown` or `--restart` unless the user asks.

4. **Report**: the URL (`http://localhost:6275/<group>`) and the files
   registered, as paths relative to the working directory where possible.
   If `mo` is not installed (`command -v mo` fails), say so and stop; do not
   install it.

Files keep live-reloading, so re-running this skill is only needed when new
Markdown files appear later in the session.
