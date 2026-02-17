# PRD: [Project Name]

## Overview
[1-2 sentences: what are we building and why]

## Requirements
- [Requirement 1]
- [Requirement 2]

## Architecture
[Key technical decisions, dependencies, constraints]

## Feedback Loops
[Commands Ralph must run before every commit]
- Types: `[e.g. npm run typecheck / mypy]`
- Tests: `[e.g. pytest / npm run test]`
- Lint: `[e.g. ruff check / npm run lint]`

## Feature List

The task checklist lives in `features.json` — a JSON array of feature objects.

Each feature has:
- `category`: setup | core | integration | polish
- `description`: what the feature does (human-readable)
- `steps`: ordered verification steps (last step should be the acceptance test)
- `passes`: `false` initially, set to `true` only after all steps verified

### Category Priority
1. **setup** — project scaffolding, dependencies, config
2. **core** — architectural decisions, core abstractions, main functionality
3. **integration** — wiring modules together, end-to-end flows
4. **polish** — CLI, docs, error handling, cleanup

### Rules
- Features are NEVER removed from features.json
- Features are NEVER reordered
- Only the `passes` field changes: `false` → `true`
- Add notes to `claude-progress.txt`, not to features.json
