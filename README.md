# Ralph Wiggum Loop

Run [Claude Code](https://docs.anthropic.com/en/docs/claude-code) in an autonomous bash loop. Each iteration picks the next task from a checklist, implements it, runs all feedback loops, commits, and logs progress — then hands off cleanly to the next iteration.

Based on Anthropic's [harness guide for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) and the [Ralph Wiggum technique](https://www.aihero.dev/tips-for-ai-coding-with-ralph-wiggum).

## Why This Works

AI agents are like super-smart experts who forget everything between sessions. Rather than fighting this, Ralph embraces it — each session bootstraps context from structured artifacts the same way a new team member would:

1. Read the progress log and recent git history
2. Check the task board (PRD checklist)
3. Pick one task, implement it, verify it, commit it
4. Log what was done for the next session

Context carries over through files and git history, not conversation memory.

## How It Works

```
ralph-once.sh / afk-ralph.sh
        │
        ├── reads prompt.md             ← instruction prompt
        ├── passes @northstar.md        ← vision & principles
        ├── passes @prd.md              ← requirements + task checklist
        └── passes @claude-progress.txt ← prior work log
                │
                ▼
        Claude session starts:
         1. Reads progress + git log
         2. Runs existing tests (verify clean state)
         3. Picks ONE task from checklist
         4. Implements it fully
         5. Runs all feedback loops (types, tests, lint)
         6. Commits only if all pass
         7. Logs progress, exits
```

## Prerequisites

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) installed and authenticated
- Git configured (`git config --global user.name` / `user.email`)
- Bash 4+

## Quick Start

### 1. Clone

```bash
git clone https://github.com/skipauthenticate/ralph-wiggum-loop.git
cd ralph-wiggum-loop
```

### 2. Set Up Your Project

```bash
mkdir my-project
cp northstar.md prd.md prompt.md init.sh my-project/
cd my-project && git init && cd ..
```

### 3. Fill In the Templates

**`northstar.md`** — Vision, principles, and quality bar:

```markdown
# Northstar

## Vision
Build a CLI tool that converts CSV files to SQLite databases.

## Guiding Principles
- Simple over clever — prefer readable code
- Test everything — pytest coverage > 80%
- Fight entropy — leave it better than you found it

## Non-Goals
- No GUI, no web interface

## Quality Bar
### Repo Type: production
### Standards
- pytest coverage > 80%
- All code must pass ruff check + ruff format
- Never remove or weaken existing tests
```

**`prd.md`** — Requirements, feedback loops, and task checklist:

```markdown
# PRD: csv2sqlite

## Overview
CLI tool to convert CSV files to SQLite databases with type inference.

## Feedback Loops
- Tests: `pytest`
- Lint: `ruff check`
- Format: `ruff format --check`

## Task Checklist

### Phase 1: Setup
- [ ] Create Python package with pyproject.toml and src layout
  - Verify: `pip install -e .` succeeds
- [ ] Add pytest config with coverage
  - Verify: `pytest --cov` runs

### Phase 2: Core
- [ ] Implement CSV reader with type inference
  - Verify: `pytest tests/test_reader.py` passes
- [ ] Implement SQLite writer
  - Verify: `pytest tests/test_writer.py` passes

### Phase 3: Polish
- [ ] Add CLI entry point with argparse
  - Verify: `csv2sqlite sample.csv out.db` produces valid database
```

**`prompt.md`** — The instruction prompt. The default works well — customize only if needed.

**`init.sh`** — Environment setup. Ralph reads this at the start of every session:

```bash
# How to set up the dev environment
source .venv/bin/activate
pip install -e ".[dev]"
```

### 4. Run (HITL First)

```bash
./ralph-once.sh my-project
```

Watch the output. If it looks good, run again. Do **3–5 HITL iterations** to calibrate before going AFK.

### 5. Go AFK

```bash
./afk-ralph.sh 10 my-project      # 10 iterations, then stop
```

### 6. Check Progress

```bash
cat my-project/claude-progress.txt    # what Ralph says it did
git -C my-project log --oneline -10   # actual commits
```

## File Reference

| File | Purpose | Who Edits It |
|------|---------|--------------|
| `ralph-once.sh` | Run one HITL iteration | You don't — just run it |
| `afk-ralph.sh` | Run N autonomous iterations | You don't — just run it |
| `northstar.md` | Vision, principles, quality bar | You (before starting) |
| `prd.md` | Requirements + feedback loops + task checklist | You write tasks; Ralph checks them off |
| `prompt.md` | Iteration prompt for Claude | You (tune if needed) |
| `init.sh` | Environment setup instructions | You (optional) |
| `claude-progress.txt` | Session-by-session log | Ralph appends; you read |
| `ralph-guide.md` | Detailed usage guide | Reference |

## Feedback Loops

Define these in your `prd.md`. Ralph runs them **before every commit** and refuses to commit if any fail.

| Loop | Catches | Example |
|------|---------|---------|
| Type checker | Type mismatches, missing props | `mypy` / `npm run typecheck` |
| Tests | Broken logic, regressions | `pytest` / `npm run test` |
| Linter | Code style, potential bugs | `ruff check` / `eslint` |
| Formatter | Inconsistent formatting | `ruff format --check` / `prettier --check` |

## Writing Good Tasks

### Priority Order

1. **Architectural decisions** and core abstractions
2. **Integration points** between modules
3. **Unknowns and spikes** — explore before committing
4. **Standard features** and implementation
5. **Polish, cleanup, quick wins**

### Sizing

- **One concept per task** — if it takes multiple iterations, split it
- **Ordered** — setup > core > integration > polish
- **Verifiable** — every task has a `Verify:` line with a concrete command
- **Independent** — later tasks shouldn't break earlier ones

## Alternative Loops

Ralph isn't just for feature backlogs. Swap the prompt for:

| Loop | What It Does |
|------|-------------|
| **Test Coverage** | "Find untested code, write tests, increase coverage by 5%" |
| **Lint Cleanup** | "Fix one lint error, run linter, commit" |
| **Duplication** | "Run jscpd, extract one duplicate into shared code" |
| **Entropy** | "Find one code smell or dead code, fix it, commit" |

## Tuning prompt.md

| Problem | Add to prompt |
|---------|---------------|
| Tasks too big | "Break large tasks into sub-steps before implementing" |
| Skipping tests | "Run ALL feedback loops and show output before committing" |
| Rewriting tasks | "ABSOLUTELY DO NOT modify task descriptions in prd.md" |
| Going off-track | "Re-read northstar.md before starting any work" |
| Premature done | "Verify end-to-end before marking complete" |
| Removing tests | "It is UNACCEPTABLE to remove or edit existing tests" |

## Cost & Safety

- Each iteration: **~$0.50–$2.00** (depends on context size)
- **Always** set iteration limits for AFK runs — never infinite loops with stochastic systems
- Start with 3–5 HITL iterations to calibrate
- Ralph commits after each task — use `git revert <hash>` to undo mistakes
- Permission mode is `acceptEdits` (file edits allowed, dangerous bash still gated)

## Recovery

```bash
cat claude-progress.txt          # Ralph's own log
git log --oneline -20            # actual commits
git diff HEAD~3                  # review recent changes
git revert <hash>                # undo a bad commit
```

## Further Reading

- [Anthropic: Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [AI Hero: Tips for AI Coding with Ralph Wiggum](https://www.aihero.dev/tips-for-ai-coding-with-ralph-wiggum)

## License

MIT
