#!/usr/bin/env bash
set -euo pipefail

PARAMETER_GOLF_DIR="${PARAMETER_GOLF_DIR:-/workspace/parameter-golf}"
TRACK="${TRACK:-track_non_record_16mb}"
DATE_STAMP="${DATE_STAMP:-$(date -u +%F)}"
SLUG="${SLUG:-candidate_run}"
NAME="${NAME:-Candidate Run}"
AUTHOR="${AUTHOR:-Your Name}"
GITHUB_ID="${GITHUB_ID:-your-github}"
BLURB="${BLURB:-Fill in a concise summary of this run.}"
DRY_RUN="${DRY_RUN:-0}"

RECORD_DIR="${PARAMETER_GOLF_DIR}/records/${TRACK}/${DATE_STAMP}_${SLUG}"

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

if [[ ! -f "$PARAMETER_GOLF_DIR/train_gpt.py" ]]; then
  echo "Could not find train_gpt.py in: $PARAMETER_GOLF_DIR" >&2
  exit 1
fi

run mkdir -p "$RECORD_DIR"
run cp "$PARAMETER_GOLF_DIR/train_gpt.py" "$RECORD_DIR/train_gpt.py"

if [[ "$DRY_RUN" == "0" ]]; then
  cat >"$RECORD_DIR/README.md" <<EOF
# ${NAME}

Describe the idea, exact run shape, and why it belongs in \`${TRACK}\`.
EOF

  cat >"$RECORD_DIR/submission.json" <<EOF
{
  "author": "${AUTHOR}",
  "github_id": "${GITHUB_ID}",
  "name": "${NAME}",
  "blurb": "${BLURB}",
  "date": "${DATE_STAMP}T00:00:00Z",
  "val_loss": 0.0,
  "val_bpb": 0.0,
  "bytes_total": 0,
  "bytes_code": 0
}
EOF
fi

cat <<EOF
Record scaffold ready:
  $RECORD_DIR

Next:
  - copy in your train log(s)
  - update README.md
  - fill submission.json with final metrics
EOF

