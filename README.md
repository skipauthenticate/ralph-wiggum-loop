# Ralph Wiggum Loop

Run [Claude Code](https://docs.anthropic.com/en/docs/claude-code) in an autonomous bash loop. Each iteration picks the next feature from a JSON checklist, implements it, runs all feedback loops, commits, and logs progress — then hands off cleanly to the next iteration.

Based on Anthropic's [harness guide for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) and the [Ralph Wiggum technique](https://www.aihero.dev/tips-for-ai-coding-with-ralph-wiggum).

## Why This Works

AI agents are like super-smart experts who forget everything between sessions. Rather than fighting this, Ralph embraces it — each session bootstraps context from structured artifacts the same way a new team member would:

1. Read the progress log and recent git history
2. Check the feature list (`features.json`)
3. Pick one feature, implement it, verify every step, commit
4. Log what was done for the next session

The feature list uses **JSON instead of markdown checkboxes** — models are less likely to corrupt structured JSON than freeform text. Only the `passes` boolean flips from `false` to `true`.

## How It Works

```
ralph-once.sh / afk-ralph.sh
        │
        ├── reads prompt.md             ← instruction prompt
        ├── passes @northstar.md        ← vision & principles
        ├── passes @prd.md              ← requirements & feedback loops
        ├── passes @features.json       ← feature list (the task board)
        └── passes @claude-progress.txt ← prior work log
                │
                ▼
        Claude session starts:
         1. Reads progress + git log
         2. Runs existing tests (verify clean state)
         3. Picks first "passes": false feature
         4. Walks through its steps array
         5. Runs all feedback loops (types, tests, lint)
         6. Commits only if all pass
         7. Sets "passes": true, logs progress, exits
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
cp northstar.md prd.md features.json prompt.md init.sh my-project/
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

**`prd.md`** — Requirements and feedback loop definitions:

```markdown
# PRD: csv2sqlite

## Overview
CLI tool to convert CSV files to SQLite databases with type inference.

## Feedback Loops
- Tests: `pytest`
- Lint: `ruff check`
- Format: `ruff format --check`
```

**`features.json`** — The task board. Each feature has a category, description, verification steps, and a `passes` boolean:

```json
[
  {
    "category": "setup",
    "description": "Python package with pyproject.toml and src layout",
    "steps": [
      "Create pyproject.toml with project metadata",
      "Create src/csv2sqlite/__init__.py",
      "Verify: pip install -e . succeeds",
      "Verify: python -c 'import csv2sqlite' works"
    ],
    "passes": false
  },
  {
    "category": "core",
    "description": "CSV reader with automatic type inference",
    "steps": [
      "Create src/csv2sqlite/reader.py with CsvReader class",
      "Implement type inference for int, float, bool, str columns",
      "Write tests in tests/test_reader.py",
      "Verify: pytest tests/test_reader.py passes"
    ],
    "passes": false
  },
  {
    "category": "polish",
    "description": "CLI entry point with argparse and --help",
    "steps": [
      "Create src/csv2sqlite/cli.py with argument parser",
      "Add [project.scripts] entry in pyproject.toml",
      "Verify: csv2sqlite --help prints usage",
      "Verify: csv2sqlite sample.csv out.db works"
    ],
    "passes": false
  }
]
```

**`prompt.md`** — The instruction prompt. The default works well out of the box.

**`init.sh`** — Environment setup. Ralph reads this at every session start:

```bash
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
cat my-project/claude-progress.txt                         # what Ralph says it did
git -C my-project log --oneline -10                        # actual commits
python3 -c "
import json
features = json.load(open('my-project/features.json'))
done = sum(1 for f in features if f['passes'])
print(f'{done}/{len(features)} features complete')
"
```

## File Reference

| File | Purpose | Who Edits It |
|------|---------|--------------|
| `ralph-once.sh` | Run one HITL iteration | You don't — just run it |
| `afk-ralph.sh` | Run N autonomous iterations | You don't — just run it |
| `northstar.md` | Vision, principles, quality bar | You (before starting) |
| `prd.md` | Requirements, architecture, feedback loops | You (before starting) |
| `features.json` | Feature list with verification steps | You write features; Ralph flips `passes` to `true` |
| `prompt.md` | Iteration prompt for Claude | You (tune if needed) |
| `init.sh` | Environment setup instructions | You (optional) |
| `claude-progress.txt` | Session-by-session log | Ralph appends; you read |
| `ralph-guide.md` | Detailed usage guide | Reference |

## The features.json Format

```json
{
  "category": "core",
  "description": "Human-readable summary of the feature",
  "steps": [
    "Implementation step 1",
    "Implementation step 2",
    "Verify: concrete command that proves it works"
  ],
  "passes": false
}
```

| Field | Type | Description |
|-------|------|-------------|
| `category` | string | `setup` / `core` / `integration` / `polish` |
| `description` | string | What the feature does |
| `steps` | string[] | Ordered implementation + verification checklist |
| `passes` | boolean | `false` → `true` when all steps verified |

**Rules:** Features are never removed, never reordered. Only `passes` changes.

## Feedback Loops

Define in `prd.md`. Ralph runs these **before every commit** and refuses to commit if any fail.

| Loop | Catches | Example |
|------|---------|---------|
| Type checker | Type mismatches, missing props | `mypy` / `npm run typecheck` |
| Tests | Broken logic, regressions | `pytest` / `npm run test` |
| Linter | Code style, potential bugs | `ruff check` / `eslint` |
| Formatter | Inconsistent formatting | `ruff format --check` / `prettier --check` |

## Writing Good Features

### Priority Order (when writing features.json)

1. **setup** — scaffolding, dependencies, config
2. **core** — architecture, abstractions, main functionality
3. **integration** — wiring modules, end-to-end flows
4. **polish** — CLI, docs, error handling, cleanup

### Sizing

- **One concept per feature** — if it takes multiple iterations, split it
- **Verifiable** — last step(s) should be concrete `Verify:` commands
- **Ordered** — setup → core → integration → polish
- **Independent** — later features shouldn't break earlier ones

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
| Features too big | "Break large features into sub-steps before implementing" |
| Skipping tests | "Run ALL feedback loops and show output before committing" |
| Editing features | "NEVER modify any field in features.json except passes" |
| Going off-track | "Re-read northstar.md before starting any work" |
| Premature done | "Walk through every step before marking passes: true" |
| Removing tests | "It is UNACCEPTABLE to remove or edit existing tests" |
| Corrupting JSON | "Validate features.json is valid JSON before committing" |

## Cost & Safety

- Each iteration: **~$0.50–$2.00** (depends on context size)
- **Always** set iteration limits for AFK runs
- Start with 3–5 HITL iterations to calibrate
- Ralph commits after each feature — use `git revert <hash>` to undo mistakes
- Permission mode is `acceptEdits` (file edits allowed, dangerous bash still gated)

## Recovery

```bash
cat claude-progress.txt          # Ralph's own log
git log --oneline -20            # actual commits
git diff HEAD~3                  # review recent changes
git revert <hash>                # undo a bad commit
```

To un-complete a feature, set `"passes": true` back to `"passes": false` in features.json.

## Further Reading

- [Anthropic: Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [AI Hero: Tips for AI Coding with Ralph Wiggum](https://www.aihero.dev/tips-for-ai-coding-with-ralph-wiggum)

## License

MIT
