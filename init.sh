#!/bin/bash
# init.sh — Project environment setup
#
# Ralph reads this file at the start of every session to understand
# how to set up the development environment. It is NOT executed
# automatically — Claude reads and follows the instructions.
#
# Include everything a new team member would need:
# - How to install dependencies
# - How to start dev servers
# - Environment variables needed
# - How to run tests

# Example:
# source .venv/bin/activate
# pip install -e ".[dev]"
# export DATABASE_URL="sqlite:///data/dev.db"
# npm run dev          # start dev server on port 3000
# pytest               # run tests
# npm run typecheck    # check types

echo "No project-specific setup configured. Edit init.sh for your project."
