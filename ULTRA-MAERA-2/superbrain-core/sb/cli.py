"""`sb` CLI 骨架（BLUEPRINT.md §5.1）。

目前只做 Queue/Approval 的資料層骨架，不接 Router、不呼叫任何雲端/本地 LLM。
`sb status`（不帶參數）只對 SQLite 做 COUNT，符合 ACCEPTANCE.md T10：0 次 LLM 呼叫。
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from . import audit, db


def _get_conn(db_path: Path):
    return db.init_db(db_path)


def cmd_submit(args: argparse.Namespace) -> int:
    conn = _get_conn(args.db)
    ts = db.now_iso()
    cur = conn.execute(
        "INSERT INTO tasks (request, status, created_at, updated_at) VALUES (?, 'NEW', ?, ?)",
        (args.text, ts, ts),
    )
    conn.commit()
    task_id = cur.lastrowid
    audit.write_event("task_submitted", path=args.audit, task_id=task_id, request=args.text)
    print(f"task_id={task_id} status=NEW")
    return 0


def cmd_status(args: argparse.Namespace) -> int:
    conn = _get_conn(args.db)
    if args.task_id is not None:
        row = conn.execute("SELECT * FROM tasks WHERE id = ?", (args.task_id,)).fetchone()
        if row is None:
            print(f"task {args.task_id} not found", file=sys.stderr)
            return 1
        print(json.dumps(dict(row), ensure_ascii=False))
        return 0

    # 一句話摘要：對應 T08。這裡輸出結構化 JSON，語音前端自己組句子唸出來。
    counts = {
        row["status"]: row["n"]
        for row in conn.execute("SELECT status, COUNT(*) AS n FROM tasks GROUP BY status")
    }
    workers = [dict(row) for row in conn.execute("SELECT name, role, status FROM workers")]
    summary = {"task_counts": counts, "workers": workers}
    print(json.dumps(summary, ensure_ascii=False))
    return 0


def cmd_workers(args: argparse.Namespace) -> int:
    conn = _get_conn(args.db)
    rows = [dict(row) for row in conn.execute("SELECT * FROM workers ORDER BY name")]
    print(json.dumps(rows, ensure_ascii=False, indent=2))
    return 0


def cmd_approve(args: argparse.Namespace) -> int:
    conn = _get_conn(args.db)
    row = conn.execute("SELECT * FROM approvals WHERE digest = ?", (args.approval_id,)).fetchone()
    if row is None:
        print("approval not found", file=sys.stderr)
        return 1
    if row["expires_at"] < db.now_iso():
        audit.write_event("approval_rejected_expired", path=args.audit, digest=args.approval_id)
        print("approval expired", file=sys.stderr)
        return 1
    conn.execute(
        "UPDATE approvals SET approved = 1, approved_at = ? WHERE digest = ?",
        (db.now_iso(), args.approval_id),
    )
    conn.commit()
    audit.write_event("approval_granted", path=args.audit, digest=args.approval_id, task_id=row["task_id"])
    print(f"approved: {args.approval_id}")
    return 0


def cmd_cancel(args: argparse.Namespace) -> int:
    conn = _get_conn(args.db)
    conn.execute(
        "UPDATE tasks SET status = 'CANCELLED', updated_at = ? WHERE id = ?",
        (db.now_iso(), args.task_id),
    )
    conn.commit()
    audit.write_event("task_cancelled", path=args.audit, task_id=args.task_id)
    print(f"task_id={args.task_id} status=CANCELLED")
    return 0


def cmd_snapshot(args: argparse.Namespace) -> int:
    # 實際快照（driver/CUDA/WSL/Windows build）要在對應機器本地執行；
    # 這裡只負責在 audit 留下「要求快照」這件事，供之後對帳。
    audit.write_event("snapshot_requested", path=args.audit, node=args.node)
    print(f"snapshot requested for {args.node} (實際快照內容請在該機器本地執行對應腳本)")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="sb", description="SuperBrain control-plane CLI")
    parser.add_argument("--db", type=Path, default=db.DEFAULT_DB_PATH, help="SQLite state DB 路徑")
    parser.add_argument("--audit", type=Path, default=audit.DEFAULT_AUDIT_PATH, help="audit JSONL 路徑")

    sub = parser.add_subparsers(dest="command", required=True)

    p_submit = sub.add_parser("submit", help="送出一個任務")
    p_submit.add_argument("text", help="自然語言需求")
    p_submit.set_defaults(func=cmd_submit)

    p_status = sub.add_parser("status", help="查詢狀態")
    p_status.add_argument("task_id", nargs="?", type=int, default=None)
    p_status.set_defaults(func=cmd_status)

    p_workers = sub.add_parser("workers", help="列出三台機器的健康狀態")
    p_workers.set_defaults(func=cmd_workers)

    p_approve = sub.add_parser("approve", help="核准一個 RED 動作（exact-action digest）")
    p_approve.add_argument("approval_id")
    p_approve.set_defaults(func=cmd_approve)

    p_cancel = sub.add_parser("cancel", help="取消任務")
    p_cancel.add_argument("task_id", type=int)
    p_cancel.set_defaults(func=cmd_cancel)

    p_snapshot = sub.add_parser("snapshot", help="要求對某節點做快照")
    p_snapshot.add_argument("node")
    p_snapshot.set_defaults(func=cmd_snapshot)

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
