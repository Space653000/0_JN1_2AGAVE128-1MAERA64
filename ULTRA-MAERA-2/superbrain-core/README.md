# SuperBrain Core（P4 骨架）

對應 BLUEPRINT.md §5、§5.1，ACCEPTANCE.md P4 Gate。這是要部署到 **ULTRA-MAERA-2**（`C:\SuperBrain`）的
Control Plane 骨架：SQLite state（rollback journal）、audit JSONL、`sb` CLI。

目前**還沒有**：FastAPI Ingress API、Router 分流、Worker heartbeat 背景程序、Approval Dashboard——
這些要接上真實網路與 Worker 才有意義，故意留到下一輪，避免做出半成品（見 `.ai/WORK-PLAN.md`）。

## 一鍵安裝（在 ULTRA-MAERA-2 上）

下載並執行 `../scripts/install-superbrain-core.ps1`（系統管理員 PowerShell）。它會：
1. 建立 venv 於 `C:\SuperBrain\venv`
2. 安裝 `requirements.txt`
3. 初始化 SQLite（`C:\SuperBrain\state.db`），種入三台機器
4. 跑一次 `pytest` 自我驗證
5. 印出 `sb workers` 的結果

## 手動使用（開發／除錯用）

```bash
cd superbrain-core
python3 -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\Activate.ps1
pip install -r requirements.txt
python -m pytest
python -m sb.cli workers
python -m sb.cli submit "整理 sandbox 資料夾"
python -m sb.cli status
```

## 資料表

| 表 | 用途 |
|---|---|
| `workers` | 三台機器的登記與健康狀態（種子：ultra-maera-2 / spark-agave-3 / spark-agave-4） |
| `tasks` | Queue，含 lease 欄位（heartbeat/lease 邏輯尚未實作，欄位先留） |
| `approvals` | RED 動作的 exact-action digest 與到期時間 |
| `audit_index` | audit event 的 DB 索引；完整內容在 `audit.jsonl`（已做 secret redact） |
