#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="${WORKSPACE_DIR:-/workspace}"
PARAMETER_GOLF_DIR="${PARAMETER_GOLF_DIR:-$WORKSPACE_DIR/parameter-golf}"
VARIANT="${VARIANT:-sp1024}"
TRAIN_SHARDS="${TRAIN_SHARDS:-1}"
RUN_ID="${RUN_ID:-smoke_${VARIANT}_1gpu}"
MAX_WALLCLOCK_SECONDS="${MAX_WALLCLOCK_SECONDS:-120}"
TRAIN_LOG_EVERY="${TRAIN_LOG_EVERY:-20}"
VAL_LOSS_EVERY="${VAL_LOSS_EVERY:-50}"
DRY_RUN="${DRY_RUN:-0}"
SKIP_PREFLIGHT="${SKIP_PREFLIGHT:-0}"

if [[ "$SKIP_PREFLIGHT" != "1" ]]; then
  echo "==> preflight"
  GPU_COUNT_EXPECTED=1 \
    WORKSPACE_DIR="$WORKSPACE_DIR" \
    PARAMETER_GOLF_DIR="$PARAMETER_GOLF_DIR" \
    VARIANT="$VARIANT" \
    bash "$SCRIPT_DIR/preflight_pod.sh"
fi

echo "==> bootstrap"
DRY_RUN="$DRY_RUN" \
  WORKSPACE_DIR="$WORKSPACE_DIR" \
  PARAMETER_GOLF_DIR="$PARAMETER_GOLF_DIR" \
  bash "$SCRIPT_DIR/bootstrap_parameter_golf.sh"

echo "==> download_data"
DRY_RUN="$DRY_RUN" \
  PARAMETER_GOLF_DIR="$PARAMETER_GOLF_DIR" \
  VARIANT="$VARIANT" \
  TRAIN_SHARDS="$TRAIN_SHARDS" \
  bash "$SCRIPT_DIR/download_data.sh"

echo "==> train_smoke"
DRY_RUN="$DRY_RUN" \
  PARAMETER_GOLF_DIR="$PARAMETER_GOLF_DIR" \
  VARIANT="$VARIANT" \
  RUN_ID="$RUN_ID" \
  MAX_WALLCLOCK_SECONDS="$MAX_WALLCLOCK_SECONDS" \
  TRAIN_LOG_EVERY="$TRAIN_LOG_EVERY" \
  VAL_LOSS_EVERY="$VAL_LOSS_EVERY" \
  NPROC_PER_NODE=1 \
  bash "$SCRIPT_DIR/run_baseline_1xh100.sh"

cat <<EOF
Smoke run launched with:
  RUN_ID=$RUN_ID
  TRAIN_SHARDS=$TRAIN_SHARDS
  MAX_WALLCLOCK_SECONDS=$MAX_WALLCLOCK_SECONDS

If it completed cleanly, the next higher-confidence steps are:
  bash scripts/preflight_pod.sh
  bash scripts/run_baseline_1xh100.sh
EOF
