# Ralph Wiggum Loop — Guide

## What Is It

Ralph runs Claude Code in a bash loop. Each iteration: reads progress
and the feature list, picks one feature, implements it, runs all feedback
loops, commits, logs what it did. The prompt stays the same — Claude sees
its own prior work through files and git history.

Based on Anthropic's [harness guide for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) and the [Ralph Wiggum technique](https://www.aihero.dev/tips-for-ai-coding-with-ralph-wiggum).

## Core Idea

AI agents are like super-smart experts who forget everything between
sessions. Context carries over through structured artifacts — progress
files, feature lists, and git history — not conversation memory.
Each session bootstraps understanding the same way a new team member
would: read docs, check recent commits, review the task board.

The feature list uses JSON instead of markdown checkboxes because models
are less likely to corrupt structured JSON than freeform markdown.

## File Structure (per project)

| File | Purpose | Who Edits It |
|------|---------|--------------|
| `northstar.md` | Vision, principles, quality bar | You (before starting) |
| `prd.md` | Requirements, architecture, feedback loops | You (before starting) |
| `features.json` | Feature list with verification steps | You write it; Ralph flips `passes` to `true` |
| `prompt.md` | Iteration prompt for Claude | You (tune as needed) |
| `init.sh` | Environment setup instructions | You (optional) |
| `claude-progress.txt` | Session log (what Ralph did) | Ralph appends; you read |

## Setup

### Option A: Separate documentation repo (recommended for existing projects)

If your code lives in one repo and your PRDs live in a documentation repo (like MindSage),
use `ralph.sh` at the documentation repo root. See `WORKFLOW.md` for the MindSage-specific workflow.

```bash
# From the documentation workspace root:
./ralph.sh 03                  # HITL, one iteration
./ralph.sh 03 10               # AFK, 10 iterations
./ralph.sh status              # progress overview
```

`ralph.sh` runs Claude from the feature directory. The `init.sh` in each feature
tells Ralph where the code repos live. Ralph works across both backend and frontend
automatically — no separate runs needed.

### Option B: PRD files alongside code (simpler for new projects)

1. Copy the templates into your project directory:
   ```bash
   cp northstar.md prd.md features.json prompt.md init.sh my-project/
   ```

2. Edit the files for your project:
   - `northstar.md` — fill in your vision, principles, and quality bar
   - `prd.md` — write requirements, architecture, and define feedback loops
   - `features.json` — define features with categories, steps, and verification
   - `prompt.md` — adjust the iteration prompt if needed (default works well)
   - `init.sh` — add env setup steps (dependency install, dev server, etc.)

3. Initialize a git repo in your project if one doesn't exist:
   ```bash
   cd my-project && git init
   ```

4. Run with the generic scripts:
   ```bash
   ./ralph-once.sh /path/to/my-project
   ./afk-ralph.sh 10 /path/to/my-project
   ```

## The features.json Format

Each feature is a JSON object:

```json
{
  "category": "core",
  "description": "CSV reader parses files with automatic type inference",
  "steps": [
    "Create src/reader.py with CsvReader class",
    "Implement type inference for int, float, bool, str, date columns",
    "Handle edge cases: empty cells, quoted strings, mixed types",
    "Write tests in tests/test_reader.py with >90% coverage",
    "Verify: pytest tests/test_reader.py passes"
  ],
  "passes": false
}
```

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `category` | string | `setup`, `core`, `integration`, or `polish` |
| `description` | string | Human-readable summary of the feature |
| `steps` | string[] | Ordered implementation + verification steps |
| `passes` | boolean | `false` initially; Ralph sets to `true` when verified |

### Rules

- Features are **never removed** from features.json
- Features are **never reordered**
- Only the `passes` field changes: `false` → `true`
- To un-complete a feature, manually set `passes` back to `false`

### Category Priority

Features are worked in order of appearance, but when writing them, group by:

1. **setup** — project scaffolding, dependencies, tooling
2. **core** — architecture, abstractions, main functionality
3. **integration** — wiring modules, end-to-end flows
4. **polish** — CLI, docs, error handling, cleanup

## Running

### MindSage (documentation workspace)

From the `mindsage-documentation/` root:

```bash
./ralph.sh 03                   # HITL: Search & Knowledge
./ralph.sh 05 10                # AFK:  Data Ingestion, 10 iterations
./ralph.sh status               # Progress across all 9 feature areas
```

### Generic (PRD files alongside code)

```bash
./ralph-once.sh /path/to/project        # HITL, one iteration
./afk-ralph.sh 10 /path/to/project      # AFK, 10 iterations
```

Logs saved to `ralph-log-YYYYMMDD-HHMMSS.txt`.

**Safety for AFK runs:**
- ALWAYS set iteration limits — never run infinite loops with stochastic systems
- Start small (5–10 for small tasks, 30–50 for larger projects)
- Monitor the first few iterations before walking away

## Writing Good Features

### Sizing

- **Small**: one logical concept per feature, completable in one session
- **Verifiable**: last step should be a concrete command that proves it works
- **Ordered**: setup → core → integration → polish
- **Independent**: later features shouldn't break earlier ones

If a feature takes multiple iterations, it's too big — split it.

### Example features.json

```json
[
  {
    "category": "setup",
    "description": "Python package with pyproject.toml and src layout",
    "steps": [
      "Create pyproject.toml with project metadata and dependencies",
      "Create src/csv2sqlite/__init__.py with version string",
      "Create src/csv2sqlite/py.typed marker file",
      "Verify: pip install -e . succeeds",
      "Verify: python -c 'import csv2sqlite' works"
    ],
    "passes": false
  },
  {
    "category": "setup",
    "description": "Pytest configuration with coverage reporting",
    "steps": [
      "Add pytest and pytest-cov to dev dependencies",
      "Create pyproject.toml [tool.pytest] section with coverage config",
      "Create tests/__init__.py and a placeholder test",
      "Verify: pytest --cov runs and reports coverage"
    ],
    "passes": false
  },
  {
    "category": "core",
    "description": "CSV reader parses files with automatic type inference",
    "steps": [
      "Create src/csv2sqlite/reader.py with CsvReader class",
      "Implement type inference for int, float, bool, str columns",
      "Handle edge cases: empty cells, quoted strings, mixed types",
      "Write tests in tests/test_reader.py covering all types",
      "Verify: pytest tests/test_reader.py passes with >90% coverage"
    ],
    "passes": false
  },
  {
    "category": "core",
    "description": "SQLite writer creates tables and inserts rows",
    "steps": [
      "Create src/csv2sqlite/writer.py with SqliteWriter class",
      "Generate CREATE TABLE from inferred column types",
      "Batch INSERT rows with parameterized queries",
      "Write tests in tests/test_writer.py",
      "Verify: pytest tests/test_writer.py passes"
    ],
    "passes": false
  },
  {
    "category": "integration",
    "description": "Pipeline wires reader and writer into a single convert function",
    "steps": [
      "Create src/csv2sqlite/pipeline.py with convert() function",
      "Wire CsvReader output into SqliteWriter input",
      "Write integration test with a sample CSV file",
      "Verify: pytest tests/test_pipeline.py passes",
      "Verify: python -m csv2sqlite sample.csv out.db && sqlite3 out.db '.tables'"
    ],
    "passes": false
  },
  {
    "category": "polish",
    "description": "CLI entry point with argparse and --help",
    "steps": [
      "Create src/csv2sqlite/cli.py with argument parser",
      "Add [project.scripts] entry in pyproject.toml",
      "Handle errors gracefully with user-friendly messages",
      "Verify: csv2sqlite --help prints usage",
      "Verify: csv2sqlite sample.csv out.db produces valid database"
    ],
    "passes": false
  }
]
```

## Feedback Loops

Define these in your `prd.md`. Ralph runs them **before every commit**
and refuses to commit if any fail.

| Loop | Catches | Example Command |
|------|---------|-----------------|
| Type checker | Type mismatches, missing props | `mypy` / `npm run typecheck` |
| Tests | Broken logic, regressions | `pytest` / `npm run test` |
| Linter | Code style, potential bugs | `ruff check` / `eslint` |
| Formatter | Inconsistent formatting | `ruff format --check` / `prettier --check` |

### Pre-commit hooks (optional but recommended)

If your project uses pre-commit hooks, they act as a final safety
net — even if Ralph skips a feedback loop, the hook blocks the commit.

## Alternative Loop Types

Ralph isn't just for feature backlogs. Swap the prompt for:

| Loop | What It Does |
|------|-------------|
| **Test Coverage** | "Find untested code, write tests, increase coverage by 5%" |
| **Lint Cleanup** | "Fix one lint error, run linter, commit" |
| **Duplication** | "Run jscpd, extract one duplicate into shared code" |
| **Entropy** | "Find one code smell or dead code, fix it, commit" |

## Cost & Safety

- Each iteration: **~$0.50–$2.00** depending on context size
- ALWAYS set iteration limits for AFK runs
- Start with 3–5 HITL iterations to calibrate
- Ralph commits after each feature — use `git revert` to undo mistakes
- Permission mode is `acceptEdits` (file edits allowed, dangerous bash still gated)

## Recovery

```bash
cat claude-progress.txt          # what Ralph says it did
git log --oneline -20            # actual commits
git diff HEAD~3                  # what changed
git revert <hash>                # undo a bad commit
```

To un-complete a feature, edit features.json and set `"passes": true`
back to `"passes": false`.

## Tuning prompt.md

If Ralph is misbehaving:

| Problem | Add to prompt.md |
|---------|-----------------|
| Tasks too big | "Break large features into sub-steps before implementing" |
| Skipping tests | "Run ALL feedback loops and show output before committing" |
| Editing features | "NEVER modify any field in features.json except passes" |
| Going off-track | "Re-read northstar.md before starting any work" |
| Premature done | "Walk through every step in the steps array before marking passes: true" |
| Sloppy code | "This is a production codebase. Follow all standards in northstar.md" |
| Removing tests | "It is UNACCEPTABLE to remove or edit existing tests" |
| Corrupting JSON | "Validate features.json is valid JSON before committing" |

## Session Flow (What Ralph Actually Does)

```
1. STARTUP
   ├── pwd (feature PRD directory)
   ├── Read claude-progress.txt
   ├── Read init.sh → locate project directories
   ├── git log --oneline -20 (in each project dir)
   └── Run existing tests (in project dirs, verify clean state)

2. PICK FEATURE
   └── First "passes": false in features.json

3. IMPLEMENT
   ├── Walk through steps array
   ├── Write code (not stubs)
   ├── Write tests
   └── Verify every step

4. FEEDBACK LOOPS
   ├── Type check → must pass
   ├── Tests → must pass
   ├── Lint → must pass
   └── If any fail → fix and re-run

5. COMMIT
   ├── git commit with descriptive message
   ├── Set "passes": true in features.json
   └── Append to claude-progress.txt

6. EXIT
   └── Output <promise>DONE</promise>
```
