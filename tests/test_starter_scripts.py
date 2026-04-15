from __future__ import annotations

import subprocess
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]


def to_wsl(path: Path) -> str:
    resolved = path.resolve()
    drive = resolved.drive.rstrip(":").lower()
    parts = resolved.as_posix().split(":", 1)[1]
    return f"/mnt/{drive}{parts}"


def run_wsl(command: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(  # noqa: S603
        ["wsl.exe", "bash", "-lc", command],
        cwd=str(REPO_ROOT),
        capture_output=True,
        text=True,
        check=False,
    )


class StarterScriptTests(unittest.TestCase):
    def test_run_smoke_8xh100_dry_run_prints_expected_commands(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir_raw:
            tmp_dir = Path(tmp_dir_raw)
            parameter_golf_dir = tmp_dir / "parameter-golf"
            parameter_golf_dir.mkdir()
            output = run_wsl(
                "cd {repo} && "
                "SKIP_PREFLIGHT=1 DRY_RUN=1 "
                "WORKSPACE_DIR={workspace} "
                "PARAMETER_GOLF_DIR={parameter_golf} "
                "bash scripts/run_smoke_8xh100.sh".format(
                    repo=to_wsl(REPO_ROOT),
                    workspace=to_wsl(tmp_dir),
                    parameter_golf=to_wsl(parameter_golf_dir),
                )
            )

            self.assertEqual(output.returncode, 0, output.stderr)
            self.assertIn("--train-shards 1", output.stdout)
            self.assertIn("--nproc_per_node=8", output.stdout)
            self.assertIn("RUN_ID=smoke_sp1024_8gpu", output.stdout)
            self.assertIn("MAX_WALLCLOCK_SECONDS=120", output.stdout)

    def test_create_record_from_run_copies_train_log_into_record_folder(self) -> None:
        with tempfile.TemporaryDirectory() as tmp_dir_raw:
            tmp_dir = Path(tmp_dir_raw)
            parameter_golf_dir = tmp_dir / "parameter-golf"
            logs_dir = parameter_golf_dir / "logs"
            logs_dir.mkdir(parents=True)
            (parameter_golf_dir / "train_gpt.py").write_text("print('ok')\n", encoding="utf-8")
            (logs_dir / "smoke_sp1024_8gpu.txt").write_text(
                "Code size: 12 bytes\n"
                "Total submission size int8+zlib: 34 bytes\n"
                "final_int8_zlib_roundtrip_exact val_loss:1.0 val_bpb:0.5\n",
                encoding="utf-8",
            )

            output = run_wsl(
                "cd {repo} && "
                "PARAMETER_GOLF_DIR={parameter_golf} "
                "RUN_ID=smoke_sp1024_8gpu "
                "DATE_STAMP=2026-04-15 "
                "SLUG=smoke8 "
                "NAME=Smoke8 "
                "AUTHOR=Andre "
                "GITHUB_ID=Bortlesboat "
                "BLURB=Smoke8 "
                "bash scripts/create_record_from_run.sh".format(
                    repo=to_wsl(REPO_ROOT),
                    parameter_golf=to_wsl(parameter_golf_dir),
                )
            )

            self.assertEqual(output.returncode, 0, output.stderr)
            record_dir = parameter_golf_dir / "records" / "track_non_record_16mb" / "2026-04-15_smoke8"
            self.assertTrue((record_dir / "train_gpt.py").is_file())
            self.assertTrue((record_dir / "train.log").is_file())
            self.assertIn("final_int8_zlib_roundtrip_exact", (record_dir / "train.log").read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
