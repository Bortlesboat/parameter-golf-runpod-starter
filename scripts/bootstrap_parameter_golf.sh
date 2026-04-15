#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/openai/parameter-golf.git}"
WORKSPACE_DIR="${WORKSPACE_DIR:-/workspace}"
PARAMETER_GOLF_DIR="${PARAMETER_GOLF_DIR:-$WORKSPACE_DIR/parameter-golf}"
USE_VENV="${USE_VENV:-0}"
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

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

need_cmd git
need_cmd python3

run mkdir -p "$WORKSPACE_DIR"

if [[ -d "$PARAMETER_GOLF_DIR" && ! -d "$PARAMETER_GOLF_DIR/.git" ]]; then
  existing_entry_count="$(find "$PARAMETER_GOLF_DIR" -mindepth 1 -maxdepth 1 | wc -l | tr -d ' ')"
  if [[ "$existing_entry_count" == "1" && -f "$PARAMETER_GOLF_DIR/requirements.txt" ]]; then
    run rm -f "$PARAMETER_GOLF_DIR/requirements.txt"
  elif [[ "$existing_entry_count" != "0" ]]; then
    echo "Target directory exists and is not a git checkout: $PARAMETER_GOLF_DIR" >&2
    echo "If this is intentional, move it aside or set PARAMETER_GOLF_DIR to a clean path." >&2
    exit 1
  fi
fi

if [[ ! -d "$PARAMETER_GOLF_DIR/.git" ]]; then
  run git clone "$REPO_URL" "$PARAMETER_GOLF_DIR"
fi

if [[ "$USE_VENV" == "1" ]]; then
  run python3 -m venv "$PARAMETER_GOLF_DIR/.venv"
  run "$PARAMETER_GOLF_DIR/.venv/bin/python" -m pip install --upgrade pip
  run "$PARAMETER_GOLF_DIR/.venv/bin/pip" install -r "$PARAMETER_GOLF_DIR/requirements.txt"
fi

cat <<EOF
Parameter Golf repo ready at:
  $PARAMETER_GOLF_DIR

Recommended next steps:
  bash scripts/download_data.sh
  bash scripts/run_baseline_1xh100.sh

Tips:
  - Set USE_VENV=1 if you are not using the official RunPod template image.
  - Set DRY_RUN=1 to print commands without executing them.
EOF
