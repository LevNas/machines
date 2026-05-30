# Global Claude Code Rules

Cross-project default rules for Claude Code behavior. Project-specific overrides live in each project's `CLAUDE.md` and `.claude/rules/`.

## Rule Index

- [knowledge-recording.md](rules/knowledge-recording.md) — When and how to invoke ccmemo `/record-knowledge`

## Conventions

- Global rules in this directory are written in **English** (portability, model accuracy).
- Personal / project-specific rules (e.g., `notebooks/.claude/rules/`) may use Japanese.

## Related

- Memory system: auto-memory is disabled (`autoMemoryEnabled: false`). Knowledge is recorded via the ccmemo plugin to `notebooks/.claude/knowledge/entries/`.
- Plugin marketplace: `LevNas/claudecode-plugins`.
