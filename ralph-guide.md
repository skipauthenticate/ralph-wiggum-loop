# Ralph Wiggum Loop — Quick Guide

## What Is It

Ralph runs Claude Code in a bash loop. Each iteration: reads progress
and the PRD, picks one task, implements it, tests it, commits, logs
what it did. The prompt (prompt.md) stays the same — Claude sees its
own prior work through files and git history.

## File Structure (per project)

| File | Purpose | Who edits it |
|------|---------|--------------|
| northstar.md | Vision, principles, non-goals | You (before starting) |
| prd.md | Requirements + task checklist | You write it; Ralph checks off tasks |
| prompt.md | The prompt fed to Claude each iteration | You (tune as needed) |
| claude-progress.txt | Session log (what Ralph did) | Ralph appends; you read |
| init.sh | Environment setup instructions | You (optional) |

## Setup

1. Copy the templates into your project directory:
   ```bash
   cp northstar.md prd.md prompt.md init.sh mindsage/
   ```

2. Edit the three .md files for your project:
   - `northstar.md` — fill in your vision and principles
   - `prd.md` — write requirements and break work into checkbox tasks
   - `prompt.md` — adjust the iteration prompt if needed (default works well)

3. Optionally edit `init.sh` with your project's setup commands

## Running

### HITL (Start Here)

```bash
./ralph-once.sh                    # workspace root
./ralph-once.sh mindsage           # mindsage project
```

Watch the output. If it looks good, run again. Do this 3-5 times
before going AFK.

### AFK

```bash
./afk-ralph.sh 10 mindsage        # 10 iterations
./afk-ralph.sh 5                   # 5 iterations at workspace root
```

Logs saved to `ralph-log-YYYYMMDD-HHMMSS.txt`.

## Writing Good Tasks in prd.md

- **Small**: one concept per task, completable in one iteration
- **Ordered**: setup > core > integration > polish
- **Verifiable**: each task has a "Verify:" line
- **Independent**: later tasks shouldn't break earlier ones

Example:
```markdown
### Phase 1: Setup
- [ ] Create Python package structure with src layout
  - Verify: `pip install -e .` succeeds and `import mypackage` works
- [ ] Add pytest configuration with coverage
  - Verify: `pytest --cov` runs and reports 0% coverage
```

## Cost & Safety

- Each iteration: ~$0.50-2.00 (depends on context size)
- ALWAYS set iteration limits for AFK runs
- Start with 3-5 iterations to calibrate
- Ralph commits after each task — use `git revert` to undo mistakes

## Recovery

```bash
cat claude-progress.txt          # what Ralph says it did
git log --oneline -10            # actual commits
git diff HEAD~3                  # what changed
git revert <hash>                # undo a bad commit
```

## Tuning prompt.md

If Ralph is misbehaving, edit prompt.md:
- Tasks too big? Add: "Break large tasks into sub-steps before implementing"
- Skipping tests? Add: "Run pytest and show output before committing"
- Editing tasks? Strengthen: "ABSOLUTELY DO NOT modify task descriptions"
- Going off-track? Add: "Re-read northstar.md if unsure about direction"
