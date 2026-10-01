#!/bin/bash
# Helper script to run Mix tasks with production environment
# Usage: ./run_mix_prod.sh TASK [ARGS...]

set -e

python3 - "$@" <<'PY'
import os
import sys
import shlex
import subprocess

raw = subprocess.check_output(
    ["systemctl", "show", "urielm", "-p", "Environment", "--value"],
    text=True,
)
env = os.environ.copy()

for item in shlex.split(raw):
    key, separator, value = item.partition("=")
    if separator:
        env[key] = value

env["MIX_ENV"] = "prod"

# Get Mix task from command line args
mix_args = sys.argv[1:]
if not mix_args:
    print("Usage: ./run_mix_prod.sh TASK [ARGS...]", file=sys.stderr)
    sys.exit(1)

subprocess.run(
    ["mix"] + mix_args,
    cwd="/home/deploy/urielm",
    env=env,
    check=True,
)
PY
