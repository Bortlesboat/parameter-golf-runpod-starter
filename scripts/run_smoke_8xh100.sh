#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="${WORKSPACE_DIR:-/workspace}"
PARAMETER_GOLF_DIR="${PARAMETER_GOLF_DIR:-$WORKSPACE_DIR/parameter-golf}"
VARIANT="${VARIANT:-sp1024}"
TRAIN_SHARDS="${TRAIN_SHARDS:-1}"
RUN_ID="${RUN_ID:-smoke_${VARIANT}_8gpu}"
MAX_WALLCLOCK_SECONDS="${MAX_WALLCLOCK_SECONDS:-120}"
TRAIN_LOG_EVERY="${TRAIN_LOG_EVERY:-10}"
VAL_LOSS_EVERY="${VAL_LOSS_EVERY:-20}"
DRY_RUN="${DRY_RUN:-0}"
SKIP_PREFLIGHT="${SKIP_PREFLIGHT:-0}"

if [[ "$SKIP_PREFLIGHT" != "1" ]]; then
  echo "==> preflight"
  GPU_COUNT_EXPECTED=8 \
    WORKSPACE_DIR="$WORKSPACE_DIR" \
    PARAMETER_GOLF_DIR="$PARAMETER_GOLF_DIR" \
    VARIANT="$VARIANT" \
    "$SCRIPT_DIR/preflight_pod.sh"
fi

echo "==> bootstrap"
DRY_RUN="$DRY_RUN" \
  WORKSPACE_DIR="$WORKSPACE_DIR" \
  PARAMETER_GOLF_DIR="$PARAMETER_GOLF_DIR" \
  "$SCRIPT_DIR/bootstrap_parameter_golf.sh"

echo "==> download_data"
DRY_RUN="$DRY_RUN" \
  PARAMETER_GOLF_DIR="$PARAMETER_GOLF_DIR" \
  VARIANT="$VARIANT" \
  TRAIN_SHARDS="$TRAIN_SHARDS" \
  "$SCRIPT_DIR/download_data.sh"

echo "==> train_smoke"
DRY_RUN="$DRY_RUN" \
  PARAMETER_GOLF_DIR="$PARAMETER_GOLF_DIR" \
  VARIANT="$VARIANT" \
  RUN_ID="$RUN_ID" \
  MAX_WALLCLOCK_SECONDS="$MAX_WALLCLOCK_SECONDS" \
  TRAIN_LOG_EVERY="$TRAIN_LOG_EVERY" \
  VAL_LOSS_EVERY="$VAL_LOSS_EVERY" \
  NPROC_PER_NODE=8 \
  "$SCRIPT_DIR/run_baseline_8xh100.sh"

cat <<EOF
8x smoke run launched with:
  RUN_ID=$RUN_ID
  TRAIN_SHARDS=$TRAIN_SHARDS
  MAX_WALLCLOCK_SECONDS=$MAX_WALLCLOCK_SECONDS

If it completed cleanly, the next steps are:
  RUN_ID=$RUN_ID bash scripts/create_record_from_run.sh
  bash scripts/run_baseline_8xh100.sh
EOF
