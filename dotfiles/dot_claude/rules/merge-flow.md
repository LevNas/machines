# Merge Flow Rules

How a PR or MR moves from review to merge to cleanup. Plugins stay loosely coupled: none depends on another, and this rule is where they are composed.

## Review and Session Wrap

- **Before merging a PR or MR**: run the repository's merge-time review.
- **When the review returns pass or fail**: run `session-wrap`.
  - **On fail**: record the verdict, the blocking findings in short, the next step and the number of fix rounds.
  - Put these records on a **separate branch and PR into the default branch**, never on the feature branch (the feature branch may be abandoned).
- **Never wrap a session-wrap's own branch or PR again**, whatever its review returns. Fix a failing review of it in that same PR.

## Merge and Cleanup

- **Merge only on the user's word.**
- **After the merge**, follow the cleanup hint it prints:
  - Keep the merged branch's worktree; do not remove it yourself.
  - Run `worktree-sweep` from the main checkout.
  - Run delete-class commands only on the user's word. Never use `--force`.
- **Bring the PR's base branch up to date where it is checked out**: the main checkout, or the parent worktree for stacked worktrees.
  - `worktree-sweep` does this, or prints the command when that worktree is in use by another session.
  - Never touch a worktree that another live session holds.

## Plugin Coupling

- Plugins do not depend on each other. Compose them here, not inside a plugin.
- When writing or editing a plugin's text, name other plugins only as "if installed".
