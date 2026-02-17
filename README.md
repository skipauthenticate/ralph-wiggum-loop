# Ralph Wiggum Loop

Run [Claude Code](https://docs.anthropic.com/en/docs/claude-code) in an autonomous bash loop. Each iteration picks the next task from a checklist, implements it, tests it, commits, and logs progress — then hands off cleanly to the next iteration.

Inspired by Anthropic's [harness guide for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents).

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
        Claude implements ONE task,
        checks it off in prd.md,
        logs to claude-progress.txt,
        commits, exits.
```

Each iteration is a fresh Claude session. Context carries over through files and git history, not conversation memory.

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

### 2. Create Your Project Files

Copy the templates into your project directory:

```bash
mkdir my-project
cp northstar.md prd.md prompt.md init.sh my-project/
cd my-project
```

### 3. Fill In the Templates

**`northstar.md`** — Your project's vision and guiding principles:

```markdown
# Northstar

## Vision
Build a CLI tool that converts CSV files to SQLite databases.

## Guiding Principles
- Simple over clever — prefer readable code
- Test everything — pytest coverage > 80%

## Non-Goals
- No GUI, no web interface
```

**`prd.md`** — Requirements and a task checklist. Tasks must use `- [ ]` checkboxes:

```markdown
# PRD: csv2sqlite

## Overview
CLI tool to convert CSV files to SQLite databases with type inference.

## Task Checklist

### Phase 1: Setup
- [ ] Create Python package with pyproject.toml and src layout
  - Verify: `pip install -e .` succeeds
- [ ] Add pytest with coverage config
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

**`prompt.md`** — The instruction prompt fed to Claude each iteration. The default works well out of the box. Customize if needed.

### 4. Run

**Human-in-the-loop** (start here):

```bash
./ralph-once.sh my-project
```

Watch the output. If it looks good, run it again. Do 3–5 iterations before going AFK.

**Autonomous** (AFK mode):

```bash
./afk-ralph.sh 10 my-project      # 10 iterations, then stop
```

### 5. Check Progress

```bash
cat my-project/claude-progress.txt    # what Ralph says it did
git log --oneline -10                  # actual commits
```

## File Reference

| File | Purpose | Who Edits It |
|------|---------|--------------|
| `ralph-once.sh` | Run one iteration (HITL) | You don't — just run it |
| `afk-ralph.sh` | Run N iterations (AFK) | You don't — just run it |
| `northstar.md` | Vision, principles, non-goals | You (before starting) |
| `prd.md` | Requirements + task checklist | You write it; Ralph checks off tasks |
| `prompt.md` | Instruction prompt for Claude | You (tune as needed) |
| `init.sh` | Environment setup notes | You (optional) |
| `claude-progress.txt` | Session log | Ralph appends; you read |
| `ralph-guide.md` | Detailed usage guide | Reference |

## Writing Good Tasks

- **Small** — one concept per task, completable in one Claude session
- **Ordered** — setup before core before integration before polish
- **Verifiable** — every task has a `Verify:` line with a concrete command
- **Independent** — later tasks shouldn't break earlier ones

## Tuning prompt.md

If Ralph misbehaves, edit `prompt.md`:

| Problem | Add to prompt |
|---------|---------------|
| Tasks too big | "Break large tasks into sub-steps before implementing" |
| Skipping tests | "Run pytest and show output before committing" |
| Rewriting tasks | "ABSOLUTELY DO NOT modify task descriptions" |
| Going off-track | "Re-read northstar.md if unsure about direction" |

## Cost & Safety

- Each iteration costs roughly **$0.50–$2.00** depending on context size
- Always set iteration limits for AFK runs
- Ralph commits after each task — use `git revert <hash>` to undo mistakes
- Permission mode is `acceptEdits` (file edits allowed, dangerous bash still gated)

## Recovery

```bash
cat claude-progress.txt          # Ralph's own log
git log --oneline -10            # actual commits
git diff HEAD~3                  # review recent changes
git revert <hash>                # undo a bad commit
```

## License

MIT
