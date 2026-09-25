"""SQLite schema and connection helpers.

BLUEPRINT.md 勘誤 #4：Laptop 實測 SQLite runtime 是 3.49.1，屬 WAL bug 受影響版本，
所以這裡固定用 rollback journal（journal_mode=DELETE），不開 WAL。
"""

from __future__ import annotations

import os
import sqlite3
from datetime import datetime, timezone
from pathlib import Path

DEFAULT_DB_PATH = Path(os.environ.get("SUPERBRAIN_DB", str(Path.home() / "SuperBrain" / "state.db")))

# 三台機器的種子資料，對應 BLUEPRINT §3.1 與這次改名後的名稱。
SEED_WORKERS = [
    ("ultra-maera-2", "control_plane", "10.77.0.1"),
    ("spark-agave-3", "fast", "10.77.0.11"),
    ("spark-agave-4", "deep", "10.77.0.12"),
]

SCHEMA = """
CREATE TABLE IF NOT EXISTS workers (
    name            TEXT PRIMARY KEY,
    role            TEXT NOT NULL,
    ip              TEXT NOT NULL,
    status          TEXT NOT NULL DEFAULT 'UNKNOWN',
    last_heartbeat  TEXT
);

CREATE TABLE IF NOT EXISTS tasks (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    request           TEXT NOT NULL,
    status            TEXT NOT NULL DEFAULT 'NEW',
    assigned_worker   TEXT,
    lease_owner       TEXT,
    lease_expires_at  TEXT,
    attempts          INTEGER NOT NULL DEFAULT 0,
    created_at        TEXT NOT NULL,
    updated_at        TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS approvals (
    digest       TEXT PRIMARY KEY,
    task_id      INTEGER,
    action       TEXT NOT NULL,
    expires_at   TEXT NOT NULL,
    approved     INTEGER NOT NULL DEFAULT 0,
    approved_at  TEXT
);

CREATE TABLE IF NOT EXISTS audit_index (
    id       INTEGER PRIMARY KEY AUTOINCREMENT,
    ts       TEXT NOT NULL,
    event    TEXT NOT NULL,
    task_id  INTEGER
);
"""


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def connect(db_path: Path) -> sqlite3.Connection:
    db_path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(db_path)
    conn.execute("PRAGMA journal_mode=DELETE;")
    conn.row_factory = sqlite3.Row
    return conn


def init_db(db_path: Path) -> sqlite3.Connection:
    conn = connect(db_path)
    conn.executescript(SCHEMA)
    existing = {row["name"] for row in conn.execute("SELECT name FROM workers")}
    for name, role, ip in SEED_WORKERS:
        if name not in existing:
            conn.execute(
                "INSERT INTO workers (name, role, ip, status) VALUES (?, ?, ?, 'UNKNOWN')",
                (name, role, ip),
            )
    conn.commit()
    return conn
