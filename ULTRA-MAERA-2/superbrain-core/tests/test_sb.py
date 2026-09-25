import json
import subprocess
import sys
from pathlib import Path

from sb import db
from sb.cli import main


def _env_paths(tmp_path: Path):
    return tmp_path / "state.db", tmp_path / "audit.jsonl"


def test_init_db_seeds_three_workers(tmp_path):
    db_path, _ = _env_paths(tmp_path)
    conn = db.init_db(db_path)
    rows = conn.execute("SELECT name, role FROM workers ORDER BY name").fetchall()
    names = [row["name"] for row in rows]
    assert names == ["spark-agave-3", "spark-agave-4", "ultra-maera-2"]


def test_workers_command_lists_three(tmp_path, capsys):
    db_path, audit_path = _env_paths(tmp_path)
    rc = main(["--db", str(db_path), "--audit", str(audit_path), "workers"])
    assert rc == 0
    out = json.loads(capsys.readouterr().out)
    assert len(out) == 3
    assert {w["name"] for w in out} == {"ultra-maera-2", "spark-agave-3", "spark-agave-4"}


def test_status_with_no_tasks_is_deterministic_zero_llm_calls(tmp_path, capsys):
    """ACCEPTANCE.md T10: 確定性任務 0 次 LLM 呼叫。"""
    db_path, audit_path = _env_paths(tmp_path)
    rc = main(["--db", str(db_path), "--audit", str(audit_path), "status"])
    assert rc == 0
    summary = json.loads(capsys.readouterr().out)
    assert summary["task_counts"] == {}
    assert len(summary["workers"]) == 3


def test_submit_then_status_roundtrip(tmp_path, capsys):
    db_path, audit_path = _env_paths(tmp_path)
    rc = main(["--db", str(db_path), "--audit", str(audit_path), "submit", "測試任務"])
    assert rc == 0
    task_id = int(capsys.readouterr().out.split("task_id=")[1].split()[0])

    rc = main(["--db", str(db_path), "--audit", str(audit_path), "status", str(task_id)])
    assert rc == 0
    row = json.loads(capsys.readouterr().out)
    assert row["request"] == "測試任務"
    assert row["status"] == "NEW"

    audit_lines = audit_path.read_text(encoding="utf-8").strip().splitlines()
    assert any(json.loads(line)["event"] == "task_submitted" for line in audit_lines)


def test_approve_rejects_unknown_digest(tmp_path, capsys):
    db_path, audit_path = _env_paths(tmp_path)
    rc = main(["--db", str(db_path), "--audit", str(audit_path), "approve", "does-not-exist"])
    assert rc == 1


def test_approve_rejects_expired_digest(tmp_path, capsys):
    db_path, audit_path = _env_paths(tmp_path)
    conn = db.init_db(db_path)
    conn.execute(
        "INSERT INTO approvals (digest, task_id, action, expires_at) VALUES (?, 1, 'git push origin x', '2000-01-01T00:00:00+00:00')",
        ("expired-digest",),
    )
    conn.commit()
    rc = main(["--db", str(db_path), "--audit", str(audit_path), "approve", "expired-digest"])
    assert rc == 1


def test_cli_runs_as_module():
    result = subprocess.run(
        [sys.executable, "-m", "sb.cli", "--help"],
        cwd=Path(__file__).resolve().parent.parent,
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0
    assert "sb" in result.stdout
