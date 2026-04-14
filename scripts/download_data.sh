#!/usr/bin/env bash
set -euo pipefail

PARAMETER_GOLF_DIR="${PARAMETER_GOLF_DIR:-/workspace/parameter-golf}"
VARIANT="${VARIANT:-sp1024}"
TRAIN_SHARDS="${TRAIN_SHARDS:-10}"
PYTHON_BIN="${PYTHON_BIN:-python3}"
DRY_RUN="${DRY_RUN:-0}"

run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '+'
    for arg in "$@"; do
      printf ' %q' "$arg"
    done
    printf '\n'
    return 0
  fi
  "$@"
}

if [[ ! -d "$PARAMETER_GOLF_DIR" ]]; then
  echo "Parameter Golf repo not found: $PARAMETER_GOLF_DIR" >&2
  exit 1
fi

cd "$PARAMETER_GOLF_DIR"

run "$PYTHON_BIN" data/cached_challenge_fineweb.py --variant "$VARIANT" --train-shards "$TRAIN_SHARDS"

