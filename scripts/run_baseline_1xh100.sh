#!/usr/bin/env bash
set -euo pipefail

PARAMETER_GOLF_DIR="${PARAMETER_GOLF_DIR:-/workspace/parameter-golf}"
VARIANT="${VARIANT:-sp1024}"
RUN_ID="${RUN_ID:-baseline_sp1024_1gpu}"
VOCAB_SIZE="${VOCAB_SIZE:-1024}"
MAX_WALLCLOCK_SECONDS="${MAX_WALLCLOCK_SECONDS:-0}"
TRAIN_LOG_EVERY="${TRAIN_LOG_EVERY:-50}"
VAL_LOSS_EVERY="${VAL_LOSS_EVERY:-200}"
NPROC_PER_NODE="${NPROC_PER_NODE:-1}"
TORCHRUN_BIN="${TORCHRUN_BIN:-torchrun}"
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

DATA_PATH="${DATA_PATH:-$PARAMETER_GOLF_DIR/data/datasets/fineweb10B_${VARIANT}}"
TOKENIZER_PATH="${TOKENIZER_PATH:-$PARAMETER_GOLF_DIR/data/tokenizers/fineweb_1024_bpe.model}"

run env \
  RUN_ID="$RUN_ID" \
  DATA_PATH="$DATA_PATH" \
  TOKENIZER_PATH="$TOKENIZER_PATH" \
  VOCAB_SIZE="$VOCAB_SIZE" \
  MAX_WALLCLOCK_SECONDS="$MAX_WALLCLOCK_SECONDS" \
  TRAIN_LOG_EVERY="$TRAIN_LOG_EVERY" \
  VAL_LOSS_EVERY="$VAL_LOSS_EVERY" \
  "$TORCHRUN_BIN" --standalone --nproc_per_node="$NPROC_PER_NODE" train_gpt.py

