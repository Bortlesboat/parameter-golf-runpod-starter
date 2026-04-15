#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARAMETER_GOLF_DIR="${PARAMETER_GOLF_DIR:-/workspace/parameter-golf}"
WORKSPACE_DIR="${WORKSPACE_DIR:-$(dirname "$PARAMETER_GOLF_DIR")}"
SIZE_CHECKER_DIR="${SIZE_CHECKER_DIR:-$WORKSPACE_DIR/parameter-golf-size-checker}"
RUN_ID="${RUN_ID:-baseline_sp1024_8gpu}"
LOG_SOURCE="${LOG_SOURCE:-$PARAMETER_GOLF_DIR/logs/${RUN_ID}.txt}"
TRACK="${TRACK:-track_non_record_16mb}"
DATE_STAMP="${DATE_STAMP:-$(date -u +%F)}"
SLUG="${SLUG:-$RUN_ID}"
NAME="${NAME:-$RUN_ID}"
AUTHOR="${AUTHOR:-Your Name}"
GITHUB_ID="${GITHUB_ID:-your-github}"
BLURB="${BLURB:-Fill in a concise summary of this run.}"

if [[ ! -f "$LOG_SOURCE" ]]; then
  echo "Run log not found: $LOG_SOURCE" >&2
  exit 1
fi

TRACK="$TRACK" \
  DATE_STAMP="$DATE_STAMP" \
  SLUG="$SLUG" \
  NAME="$NAME" \
  AUTHOR="$AUTHOR" \
  GITHUB_ID="$GITHUB_ID" \
  BLURB="$BLURB" \
  PARAMETER_GOLF_DIR="$PARAMETER_GOLF_DIR" \
  "$SCRIPT_DIR/scaffold_record_dir.sh"

RECORD_DIR="$PARAMETER_GOLF_DIR/records/$TRACK/${DATE_STAMP}_${SLUG}"
cp "$LOG_SOURCE" "$RECORD_DIR/train.log"

if [[ -f "$SIZE_CHECKER_DIR/parameter_golf_size_checker.py" ]]; then
  python3 "$SIZE_CHECKER_DIR/parameter_golf_size_checker.py" \
    --record-dir "$RECORD_DIR" \
    --author "$AUTHOR" \
    --github-id "$GITHUB_ID" \
    --name "$NAME" \
    --blurb "$BLURB" \
    --output "$RECORD_DIR/submission.generated.json" || true
fi

cat <<EOF
Record folder assembled:
  $RECORD_DIR

Included:
  - train_gpt.py
  - README.md
  - submission.json
  - train.log

Next:
  - review README.md wording
  - inspect submission.generated.json if it was created
  - add any extra run logs needed for significance
EOF
