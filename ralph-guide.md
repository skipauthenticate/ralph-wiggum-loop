# Ralph Wiggum Loop — Guide

## What Is It

Ralph runs Claude Code in a bash loop. Each iteration: reads progress
and the PRD, picks one task, implements it, runs all feedback loops,
commits, logs what it did. The prompt stays the same — Claude sees its
own prior work through files and git history.

Based on Anthropic's [harness guide for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) and the [Ralph Wiggum technique](https://www.aihero.dev/tips-for-ai-coding-with-ralph-wiggum).

## Core Idea

AI agents are like super-smart experts who forget everything between
sessions. Context carries over through structured artifacts — progress
files, task checklists, and git history — not conversation memory.
Each session bootstraps understanding the same way a new team member
would: read docs, check recent commits, review the task board.

## File Structure (per project)

| File | Purpose | Who Edits It |
|------|---------|--------------|
| `northstar.md` | Vision, principles, quality bar | You (before starting) |
| `prd.md` | Requirements + task checklist | You write it; Ralph checks off tasks |
| `prompt.md` | Instruction prompt for Claude | You (tune as needed) |
| `init.sh` | Environment setup instructions | You (optional) |
| `claude-progress.txt` | Session log (what Ralph did) | Ralph appends; you read |

## Setup

1. Copy the templates into your project directory:
   ```bash
   cp northstar.md prd.md prompt.md init.sh my-project/
   ```

2. Edit the files for your project:
   - `northstar.md` — fill in your vision, principles, and quality bar
   - `prd.md` — write requirements, define feedback loops, break work into tasks
   - `prompt.md` — adjust the iteration prompt if needed (default works well)
   - `init.sh` — add env setup steps (dependency install, dev server, etc.)

3. Initialize a git repo in your project if one doesn't exist:
   ```bash
   cd my-project && git init
   ```

## Running

### HITL — Human-in-the-Loop (Start Here)

```bash
./ralph-once.sh my-project
```

Watch the output. If it looks good, run again. Do 3–5 iterations
before going AFK. This calibrates whether your tasks are the right
size and your prompt is dialed in.

### AFK — Autonomous Loop

```bash
./afk-ralph.sh 10 my-project      # 10 iterations
./afk-ralph.sh 5                   # 5 iterations at workspace root
```

Logs saved to `ralph-log-YYYYMMDD-HHMMSS.txt`.

**Safety for AFK runs:**
- ALWAYS set iteration limits — never run infinite loops with stochastic systems
- Start small (5–10 for small tasks, 30–50 for larger projects)
- Monitor the first few iterations before walking away

## Writing Good Tasks in prd.md

### Prioritization Order

Write tasks in this priority:
1. **Architectural decisions** and core abstractions
2. **Integration points** between modules
3. **Unknowns and spikes** — explore before committing to an approach
4. **Standard features** and implementation
5. **Polish, cleanup, quick wins**

### Task Sizing

- **Small**: one logical concept per task, completable in one session
- **Verifiable**: every task has a `Verify:` line with a concrete command
- **Ordered**: setup > core > integration > polish
- **Independent**: later tasks shouldn't break earlier ones

If you find a task takes multiple iterations, it's too big — split it.

### Example

```markdown
### Phase 1: Setup
- [ ] Create Python package with pyproject.toml and src layout
  - Verify: `pip install -e .` succeeds and `python -c "import mypackage"` works
- [ ] Add pytest config with coverage reporting
  - Verify: `pytest --cov` runs and shows 0% coverage

### Phase 2: Core
- [ ] Implement CSV reader with automatic type inference
  - Verify: `pytest tests/test_reader.py` passes with >90% coverage
- [ ] Implement SQLite writer with table creation
  - Verify: `pytest tests/test_writer.py` passes

### Phase 3: Integration
- [ ] Wire reader + writer together in a pipeline function
  - Verify: `python -m mypackage sample.csv out.db && sqlite3 out.db ".tables"` shows table

### Phase 4: Polish
- [ ] Add CLI entry point with argparse and --help
  - Verify: `csv2sqlite --help` prints usage and `csv2sqlite sample.csv out.db` works
```

## Feedback Loops

Define these in your `prd.md` and `northstar.md`. Ralph runs them
before every commit.

| Loop Type | What It Catches | Example Command |
|-----------|-----------------|-----------------|
| Type checker | Type mismatches, missing props | `npm run typecheck` / `mypy` |
| Tests | Broken logic, regressions | `pytest` / `npm run test` |
| Linter | Code style, potential bugs | `ruff check` / `eslint` |
| Formatter | Formatting inconsistencies | `ruff format --check` / `prettier --check` |

Ralph will NOT commit if any loop fails. This is by design.

### Pre-commit hooks (optional but recommended)

If your project uses pre-commit hooks, they act as a final safety
net — even if Ralph skips a feedback loop, the hook blocks the commit.

## Alternative Loop Types

Ralph isn't just for feature backlogs. Swap the prompt for:

| Loop Type | Prompt Tweak | Use Case |
|-----------|-------------|----------|
| **Test Coverage** | "Find untested code, write tests, increase coverage by 5%" | Reaching a coverage target |
| **Lint Cleanup** | "Fix one lint error at a time, run linter after each fix" | Cleaning up a messy codebase |
| **Duplication** | "Run jscpd, extract one duplicate into a shared function" | Reducing copy-paste code |
| **Entropy** | "Find one code smell or dead code, fix it, commit" | General codebase health |

## Cost & Safety

- Each iteration: **~$0.50–$2.00** depending on context size
- ALWAYS set iteration limits for AFK runs
- Start with 3–5 HITL iterations to calibrate
- Ralph commits after each task — use `git revert` to undo mistakes
- Permission mode is `acceptEdits` (file edits allowed, dangerous bash still gated)

## Recovery

```bash
cat claude-progress.txt          # what Ralph says it did
git log --oneline -20            # actual commits
git diff HEAD~3                  # what changed
git revert <hash>                # undo a bad commit
```

## Tuning prompt.md

If Ralph is misbehaving:

| Problem | Add to prompt.md |
|---------|-----------------|
| Tasks too big | "Break large tasks into sub-steps before implementing" |
| Skipping tests | "Run ALL feedback loops and show output before committing" |
| Rewriting tasks | "ABSOLUTELY DO NOT modify task descriptions in prd.md" |
| Going off-track | "Re-read northstar.md before starting any work" |
| Premature done | "Verify the task works end-to-end before marking complete" |
| Sloppy code | "This is a production codebase. Follow all standards in northstar.md" |
| Removing tests | "It is UNACCEPTABLE to remove or edit existing tests" |

## Session Flow (What Ralph Actually Does)

```
1. STARTUP
   ├── pwd
   ├── Read claude-progress.txt
   ├── git log --oneline -20
   ├── Read init.sh → set up environment
   └── Run existing tests (verify clean state)

2. PICK TASK
   └── First unchecked `- [ ]` in prd.md

3. IMPLEMENT
   ├── Write code (not stubs)
   ├── Write tests
   └── Test end-to-end

4. FEEDBACK LOOPS
   ├── Type check → must pass
   ├── Tests → must pass
   ├── Lint → must pass
   └── If any fail → fix and re-run

5. COMMIT
   ├── git commit with descriptive message
   ├── Mark `- [x]` in prd.md
   └── Append to claude-progress.txt

6. EXIT
   └── Output <promise>DONE</promise>
```
