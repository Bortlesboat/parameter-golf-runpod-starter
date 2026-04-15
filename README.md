# Parameter Golf RunPod Starter

RunPod-first starter scripts for the live [OpenAI Parameter Golf challenge](https://github.com/openai/parameter-golf).

This repo is for people who want the fastest path from a fresh RunPod pod to:

- cloning the official challenge repo,
- downloading the published FineWeb cache,
- proving the pod is healthy before a longer run,
- running a baseline on `1x H100`,
- rerunning the same shape on `8x H100`,
- scaffolding a record folder for a later PR.

## Why this exists

The official `parameter-golf` README is good, but it mixes challenge rules, leaderboard context, local MLX notes, and cloud instructions together. This repo narrows the focus to the RunPod path that most participants actually use.

## Official references

- Challenge repo: `https://github.com/openai/parameter-golf`
- Official RunPod template link from the current README:
  - `https://console.runpod.io/deploy?template=y5cejece4j&ref=nl2r56th`

## Scripts

- `scripts/bootstrap_parameter_golf.sh`
  - clones `openai/parameter-golf` into `/workspace/parameter-golf` by default
- `scripts/preflight_pod.sh`
  - checks whether the pod has the required tools, GPU visibility, and challenge files
- `scripts/download_data.sh`
  - downloads the cached FineWeb export for the selected tokenizer variant
- `scripts/run_smoke_1xh100.sh`
  - one-command bootstrap + `1` train shard + short `1x H100` smoke run
- `scripts/run_baseline_1xh100.sh`
  - runs a single-GPU baseline that mirrors the official quickstart shape
- `scripts/run_baseline_8xh100.sh`
  - runs an `8x H100` baseline with the record-track wallclock cap
- `scripts/scaffold_record_dir.sh`
  - creates a record folder with placeholder metadata and copies the current `train_gpt.py`

## Quickstart

```bash
git clone https://github.com/Bortlesboat/parameter-golf-runpod-starter.git
cd parameter-golf-runpod-starter

bash scripts/preflight_pod.sh
bash scripts/run_smoke_1xh100.sh
```

If the smoke run looks healthy, move to the full single-GPU baseline:

```bash
bash scripts/run_baseline_1xh100.sh
```

When you're ready for a real record-track run:

```bash
bash scripts/run_baseline_8xh100.sh
```

To scaffold a submission folder after a run:

```bash
SLUG=my-idea \
NAME="My Idea" \
AUTHOR="Your Name" \
GITHUB_ID="your-github" \
bash scripts/scaffold_record_dir.sh
```

## Notes

- These scripts assume the challenge repo layout stays close to the current `main` branch.
- They intentionally do not try to hide the official commands; the goal is to make them repeatable.
- The smoke flow is tuned to catch setup mistakes cheaply:
  - `TRAIN_SHARDS=1`
  - `MAX_WALLCLOCK_SECONDS=120`
  - `TRAIN_LOG_EVERY=20`
  - `VAL_LOSS_EVERY=50`
- On April 15, 2026 this repo was live-validated on the official RunPod `Parameter Golf` template on `1x H100`.
- For submission-size validation and sweep automation, see the companion repos:
  - `https://github.com/Bortlesboat/parameter-golf-size-checker`
  - `https://github.com/Bortlesboat/parameter-golf-sweeps`
