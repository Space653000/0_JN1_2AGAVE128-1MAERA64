"""Append-only JSONL audit log with secret redaction.

BLUEPRINT.md §9：「Secrets：DB 與 audit 裡只存參照；進入 audit 前先做 redact」。
這裡先擋常見的 key/token 樣式；正式接上 PowerShell SecretStore 後再擴充規則。
"""

from __future__ import annotations

import json
import os
import re
from pathlib import Path

from .db import now_iso

DEFAULT_AUDIT_PATH = Path(
    os.environ.get("SUPERBRAIN_AUDIT_LOG", str(Path.home() / "SuperBrain" / "audit.jsonl"))
)

# 常見的 secret 樣式：長度夠長的 hex/base64-ish token、明顯標示 key/secret/password 的欄位。
_REDACT_PATTERNS = [
    re.compile(r"(?i)(api[_-]?key|token|secret|password)\s*[:=]\s*\S+"),
    re.compile(r"\bsk-[A-Za-z0-9]{16,}\b"),
    re.compile(r"\b[A-Za-z0-9+/]{32,}={0,2}\b"),
]


def redact(text: str) -> str:
    redacted = text
    for pattern in _REDACT_PATTERNS:
        redacted = pattern.sub("[REDACTED]", redacted)
    return redacted


def write_event(event: str, path: Path = DEFAULT_AUDIT_PATH, **fields) -> dict:
    """寫一筆 audit event。任何字串欄位都會先跑過 redact()。"""
    record = {"ts": now_iso(), "event": event}
    for key, value in fields.items():
        record[key] = redact(value) if isinstance(value, str) else value

    path.parent.mkdir(parents=True, exist_ok=True)
    try:
        with path.open("a", encoding="utf-8") as f:
            f.write(json.dumps(record, ensure_ascii=False) + "\n")
    except OSError as exc:
        # BLUEPRINT §16：「Audit 寫入失敗 → 停止所有寫入」。
        raise RuntimeError(f"AUDIT_WRITE_FAILED: {exc}") from exc

    return record
