Maintenance pass for this repo, in order; stop at the first section that
produces work and finish it before moving on.

1. Continue any unfinished work from the conversation.
2. If the current branch has a PR: address review comments, diagnose failed CI
   runs, resolve merge conflicts.
3. Check surface sync: run `bash scripts/sync-plugin.sh` and report any diff it
   produces (`git status --short plugins/`). A dirty plugin tree means `.claude/`
   changed without a sync.
4. Run the validation suites that don't invoke a live model:
   `bash tests/workflow-contract.sh` and `bash tests/codex-workflow-contract.sh`.
   Report failures with file and line.
5. If everything is green and quiet, say so in one line.

Never run destructive or exploratory eval prompts against this repo itself.
