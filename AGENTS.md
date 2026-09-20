# Repository instructions for Codex

This file is the entry point for agents working in this repository. Read it first,
then read `README.md` and the complete `CLAUDE.md` before making changes. The
project's architecture, coding conventions, active codebase, build commands, and
GitHub workflow are maintained in `CLAUDE.md`; follow those rules as repository
instructions, even where they were originally written for Claude Code.

`CLAUDE.md` is a hub for detailed guidance. Before work in a relevant area, read
the matching document under `docs/claude/` listed in its reference tables. In
particular, consult the Tuist file mapping before moving or porting legacy files.

Use `UMCApp/` for all implementation work. `AppProduct/` is frozen at v2.2.0 and
must remain unchanged unless the maintainer explicitly directs otherwise.

If `CLAUDE.local.md` exists in this checkout, read it for local environment
details and current working context. Apply relevant project preferences when
they fit the current Codex environment. Claude-specific model names, slash
commands, and agent invocation syntax do not apply directly; use available
Codex capabilities while preserving the intent of those workflow preferences.
Do not copy local-only settings into shared repository files.

For Git or GitHub artifacts, do not include AI attribution or generated-by
footers. Follow the repository's branch, commit, issue, and PR conventions in
`CLAUDE.md` and the referenced workflow/template files.
