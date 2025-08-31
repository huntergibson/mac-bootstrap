#!/usr/bin/env bash
# Shared helpers for nice output and safer scripts
set -euo pipefail

# Colors if stdout is a TTY
if [[ -t 1 ]]; then
  RED='\033[31m'; GREEN='\033[32m'; YELLOW='\033[33m'; BLUE='\033[34m'; BOLD='\033[1m'; RESET='\033[0m'
else
  RED=''; GREEN=''; YELLOW=''; BLUE=''; BOLD=''; RESET=''
fi

step(){ echo; echo -e "${BOLD}${BLUE}==>${RESET} $*"; }
ok(){   echo -e "${GREEN}✓${RESET} $*"; }
warn(){ echo -e "${YELLOW}⚠${RESET} $*"; }
die(){  echo -e "${RED}✗${RESET} $*"; exit 1; }

# Print command then run it (honors DRY_RUN=1)
run(){ echo "+ $*"; [[ "${DRY_RUN:-}" == "1" ]] || eval "$@"; }

# Require a command to exist
require(){ command -v "$1" >/dev/null 2>&1 || die "Missing requirement: $1"; }
