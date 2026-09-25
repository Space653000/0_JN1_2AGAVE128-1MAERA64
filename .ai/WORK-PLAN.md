# WORK-PLAN：施工計畫作業書（雲端可做的部分）

> 依據：[BLUEPRINT.md](BLUEPRINT.md) §12（施工階段與 Gate）、[ACCEPTANCE.md](ACCEPTANCE.md)、[CLAUDE_REVIEWER.md](CLAUDE_REVIEWER.md)。
> 本文件回答一件事：**在這個雲端 Session 裡，哪些 Phase 的工作可以直接做，哪些一定要等你把東西下載到 ULTRA-MAERA-2 / SPARK-AGAVE-3 / SPARK-AGAVE-4 上才能繼續**。
> 更新時機：每完成一個雲端可做的項目就勾掉，並把證據路徑寫回 [STATUS.md](STATUS.md)。

---

## 1. 分類原則

| 類型 | 定義 | 誰做 |
|---|---|---|
| ☁️ 雲端可做 | 純程式碼／文件／設定，不需要碰到實體 Laptop 或 Spark | Claude Code（這個 Session） |
| 🖥️ 需要本地部署 | 要在實機上跑（Windows Update、驅動、SSH 服務、網卡設定、功耗量測、GPU/OS 實測） | 你，依照對應資料夾的 SOP 一鍵腳本 |
| ⛔ 需要你決定 | 採購、帳號登入、隱私政策等 | 你 |

---

## 2. Phase 對照表

| Phase | 內容 | 本次雲端進度 | 剩下要本地做的部分 |
|---|---|---|---|
| P0 盤點 | 三台機器 inventory | ☁️ 已產出三份「一鍵盤點」腳本（見 §3.1），會自動寫出 baseline 檔 | 🖥️ 實際在三台機器上執行一次，並把 `C:\SuperBrain\baseline\*` 回傳/回報 |
| P1 影片同款 | ChatGPT 桌面 Voice + Codex + iPhone Remote | — 不在本次範圍 | 🖥️ 你在 Laptop／iPhone 操作，這件事不需要程式碼 |
| P2 隔離網路 | 交換器、金鑰、防火牆、斷網驗收 | ☁️ 已完成（PR #2，已併入 main）：`ULTRA-MAERA-2/`、`SPARK-AGAVE-3/`、`SPARK-AGAVE-4/` 三個安裝資料夾 | 🖥️ 實際接線、執行 `spark-bootstrap.ps1`、驗證 SSH、執行 `-KeyOnly` |
| P3 UPS | 安裝 UPS、自動關機鏈 | — 需要實機與採購 | 🖥️⛔ 全部要本地／採購 |
| P4 Core 骨架 | `C:\SuperBrain`、venv、SQLite schema、`sb` CLI、AGENTS.md、audit | ☁️ 本次新增：`ULTRA-MAERA-2/superbrain-core/`（見 §3.2），已在雲端跑過 pytest 全綠 | 🖥️ 下載到 ULTRA-MAERA-2、跑一鍵安裝腳本、在實機上再跑一次驗收 |
| P5 Spark1(→AGAVE-3) FAST | 離線供應鏈送模型、llama.cpp、API | — 需要下載大型模型權重與實機 GPU | 🖥️ 全部要本地 |
| P6 Golden set | 100 題 × 雲端 × 本地 | ☁️ 可以先幫你把題目框架、評分腳本骨架寫出來（尚未做，屬下一輪） | 🖥️ 需要你提供真實工作樣本，且要在本地模型上實跑 |
| P7 Spark2(→AGAVE-4) DEEP | 同 P5 | — | 🖥️ 全部要本地 |
| P8 Queue/Approval/Recovery | lease、heartbeat、RED 核准、重試、worktree | ☁️ 部分骨架已隨 P4 一起做（DB schema 有 lease/heartbeat 欄位），核准流程與 worktree 隔離邏輯留待下一輪 | 🖥️ 要接上真實 Worker 才能跑 T08–T16 |
| P9–P12 | 收件、視覺、語音、PWA、Heavy Mode | — 都需要硬體（C920、XVF3800、UPS、雙 Spark） | 🖥️⛔ |

**結論**：這個 Session 能繼續往前推的，就是 **P0 的一鍵盤點腳本** 與 **P4 的 Core 骨架**。P1、P3、P5 以後全部需要實體機器，不能在雲端 Session 裡完成。

---

## 3. 本次雲端施工內容

### 3.1 一鍵盤點腳本（P0）

依 BLUEPRINT §14 的指令，各自包成**一個檔案、下載後直接在系統管理員 PowerShell 執行**，跑完自動把結果寫到 `C:\SuperBrain\baseline\<機器名>\` 底下（對應 ACCEPTANCE.md P0 Gate 要求的證據路徑），不用你手動一條一條貼指令。

| 機器 | 腳本 |
|---|---|
| ULTRA-MAERA-2 | `ULTRA-MAERA-2/scripts/laptop-inventory.ps1` |
| SPARK-AGAVE-3 | `SPARK-AGAVE-3/scripts/spark-inventory.ps1` |
| SPARK-AGAVE-4 | `SPARK-AGAVE-4/scripts/spark-inventory.ps1` |

### 3.2 SuperBrain Core 骨架（P4）

新增 `ULTRA-MAERA-2/superbrain-core/`：Windows native Python 3.12 專案，對應 BLUEPRINT §5、§5.1。

- `sb/db.py`：SQLite schema（**rollback journal**，不是 WAL，理由見 BLUEPRINT 勘誤 #4）。資料表：`workers`（含三台機器種子資料）、`tasks`（queue/lease 欄位）、`approvals`（exact-action digest + 到期時間）、`audit`（JSONL 之外，DB 也留一份索引）。
- `sb/audit.py`：JSONL audit writer，寫入前做 secret redact（pattern-based，先擋常見的 key/token 格式）。
- `sb/cli.py`：`sb` 指令骨架 —— `submit / status / workers / approve / cancel / snapshot`。`sb status`（不帶參數）**0 次 LLM 呼叫**，直接對 SQLite 做 COUNT，對應 T10。
- `AGENTS.md`：§5.1 給 Codex 的規則，原文照搬。
- `tests/`：pytest，涵蓋 DB 初始化、`workers` 種子資料、`status` 的確定性輸出、`approve` 對過期／不符 digest 的核准要拒絕。**這次雲端 Session 已經實際跑過 `pytest`，全數通過**（證據：本次 commit 的 CI 或你本機重跑 `pytest` 皆可重現）。
- `scripts/install-superbrain-core.ps1`（放在 `ULTRA-MAERA-2/scripts/`）：**一鍵安裝**——建立 venv、裝依賴、初始化 DB、種入三台機器、跑一次 `pytest` 自我驗證、印出 `sb workers` 結果。你只要下載這一個檔案、在 ULTRA-MAERA-2 用系統管理員 PowerShell 執行即可。

> 尚未做（下一輪再補）：FastAPI Ingress API（127.0.0.1:8765）、Router 分流表讀取、Worker heartbeat 背景程序、Approval 的 Dashboard。這些要接上真實網路與 Worker 才有意義，先不做半成品。

---

## 4. Review 清單（對照 CLAUDE_REVIEWER.md §3）

- [x] 是否符合 BLUEPRINT 的決策？SQLite 用 rollback journal、Router／FastAPI 尚未做因為會變半成品——都有記錄。
- [x] 是否違反「T01–T08 PASS 前禁止導入」清單？沒有導入 K8s/Redis/NATS/RabbitMQ/PostgreSQL/Grafana/向量 DB/agent swarm/雙 Spark 叢集/GPT-Live API。
- [x] RED 動作是否都有 exact-action 核准？`sb approve` 目前只接受完全比對的 digest 字串，過期或不符會拒絕（有測試）。
- [x] Agent 能不能自己把任務寫成 DONE？`sb` 目前沒有任何指令把 task 標成 DONE，只有 Verifier（未來實作）能寫，符合 §9「DONE 只能由 Verifier 寫入」。
- [x] Spark 是否仍然保持隔離？本次沒有改動任何連網設定。
- [x] secret 是否出現在程式碼、log 或 commit 中？audit writer 有 redact，且沒有任何私鑰或帳密寫進 repo。
- [x] 外部資料是否被當成指令執行？`sb submit` 目前只是把文字存進 DB，不會執行；之後接 Router 時要再檢查一次。
- [x] 是否有測試，並且實際執行過？有，見 §3.2。
- [x] 雲端額度是否被浪費在本地就能做好的類別？本次全部是確定性程式碼工作，沒有呼叫任何雲端 LLM 工人。

---

## 5. 交給你的下一步（🖥️ 需要本地部署）

1. 三台機器各自跑一次對應資料夾的一鍵盤點腳本，回傳/回報 `baseline` 結果。
2. 在 ULTRA-MAERA-2 跑 `install-superbrain-core.ps1`，確認 `sb workers` 印出三台機器、`pytest` 全綠。
3. P2 隔離網路：依 `SPARK-AGAVE-3/README.md`、`SPARK-AGAVE-4/README.md`、`ULTRA-MAERA-2/README.md` 的步驟，實際接線、跑 `spark-bootstrap.ps1`、驗證 SSH、才執行 `-KeyOnly`。
4. 做完以上，PASS 的部分我會再幫你把 STATUS.md 的 ⬜ 改成 ✅，並列出證據路徑。
