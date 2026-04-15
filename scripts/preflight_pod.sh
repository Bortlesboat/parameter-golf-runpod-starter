#!/usr/bin/env bash
set -euo pipefail

WORKSPACE_DIR="${WORKSPACE_DIR:-/workspace}"
PARAMETER_GOLF_DIR="${PARAMETER_GOLF_DIR:-$WORKSPACE_DIR/parameter-golf}"
VARIANT="${VARIANT:-sp1024}"
GPU_COUNT_EXPECTED="${GPU_COUNT_EXPECTED:-1}"
EXPECT_DATA="${EXPECT_DATA:-0}"

missing_critical=0

status() {
  printf '%s: %s\n' "$1" "$2"
}

have_cmd() {
  command -v "$1" >/dev/null 2>&1
}

check_required_cmd() {
  local cmd="$1"
  if have_cmd "$cmd"; then
    status "command_${cmd}" "present"
  else
    status "command_${cmd}" "missing"
    missing_critical=1
  fi
}

check_required_cmd git
check_required_cmd python3
check_required_cmd torchrun
check_required_cmd nvidia-smi

if have_cmd nvidia-smi; then
  gpu_count="$(nvidia-smi --query-gpu=name --format=csv,noheader | wc -l | tr -d ' ')"
  status "gpu_count" "$gpu_count"
  nvidia-smi --query-gpu=name,memory.total --format=csv,noheader | while IFS= read -r line; do
    status "gpu" "$line"
  done
  if [[ "$gpu_count" -lt "$GPU_COUNT_EXPECTED" ]]; then
    status "gpu_expectation" "wanted_at_least_${GPU_COUNT_EXPECTED}_found_${gpu_count}"
    missing_critical=1
  fi
fi

if have_cmd python3; then
  if ! python3 - <<'PY'
import importlib.util
import sys

torch_spec = importlib.util.find_spec("torch")
if torch_spec is None:
    print("python_torch: missing")
    sys.exit(1)

import torch
print(f"python_torch: present {torch.__version__}")
print(f"python_cuda_available: {torch.cuda.is_available()}")
if not torch.cuda.is_available():
    sys.exit(1)
PY
  then
    missing_critical=1
  fi
fi

if [[ -d "$PARAMETER_GOLF_DIR/.git" ]]; then
  status "repo" "cloned"
else
  status "repo" "missing"
fi

if [[ -f "$PARAMETER_GOLF_DIR/train_gpt.py" ]]; then
  status "train_gpt.py" "present"
else
  status "train_gpt.py" "missing"
fi

tokenizer_path="$PARAMETER_GOLF_DIR/data/tokenizers/fineweb_1024_bpe.model"
dataset_dir="$PARAMETER_GOLF_DIR/data/datasets/fineweb10B_${VARIANT}"

if [[ -f "$tokenizer_path" ]]; then
  status "tokenizer" "present"
else
  status "tokenizer" "missing"
fi

if [[ -d "$dataset_dir" ]]; then
  status "dataset_${VARIANT}" "present"
else
  status "dataset_${VARIANT}" "missing"
  if [[ "$EXPECT_DATA" == "1" ]]; then
    missing_critical=1
  fi
fi

if [[ "$missing_critical" == "1" ]]; then
  status "preflight_status" "blocked"
  exit 1
fi

if [[ ! -d "$PARAMETER_GOLF_DIR/.git" ]]; then
  status "preflight_status" "ready_for_bootstrap"
elif [[ ! -f "$tokenizer_path" || ! -d "$dataset_dir" ]]; then
  status "preflight_status" "ready_for_data_download"
else
  status "preflight_status" "ready_for_training"
fi
