# STATUS：施工進度

> 最後更新：2026-09-25（Claude Code）
> 依據：[BLUEPRINT.md](BLUEPRINT.md)、[ACCEPTANCE.md](ACCEPTANCE.md)、[WORK-PLAN.md](WORK-PLAN.md)
> 狀態標記：✅ 已完成｜🔨 施工中｜⬜ 未完成｜⛔ 阻塞

## 目前階段

**P2（隔離網路）與 P4（Core 骨架）的雲端可做部分已完成，等你在實機上執行。** 詳細分工見 [WORK-PLAN.md](WORK-PLAN.md)。
P0 盤點、P1 影片同款、P3 UPS 以後全部需要實體機器與採購，雲端 Session 無法代勞。

## ✅ 已完成

| 項目 | 證據 |
|---|---|
| ChatGPT 深入研究三份報告 | `1_ChatGPT-deep-research-report/*.md` |
| 需求影片螢幕錄影（只保留在本地） | `1_ChatGPT-deep-research-report/*.mp4` |
| YouTube 字幕分析、逐段摘要與 SOP | BLUEPRINT §13 Q4、Q5 |
| 三份報告整合與勘誤 | BLUEPRINT §2 |
| Claude Code 整合藍圖 v2.1 | `.ai/BLUEPRINT.md` |
| 驗收標準 | `.ai/ACCEPTANCE.md` |
| Laptop 部分盤點（ARM64、RTX Spark N1X 24GB、OS 可見 38.1GB、SQLite 3.49.1、只有 Wi-Fi、Tailscale 未登入、Insider build） | BLUEPRINT §3.2 |
| 本地資料夾串接 GitHub | `origin` = github.com/Space653000/0_JN1_2AGAVE128-1MAERA64，branch `main` |
| 修正 git `user.email` 為 `space653000@gmail.com` | `git config --global user.email`（首個 commit `737581f` 的作者信箱仍是舊值，不改寫歷史） |
| P2 隔離網路安裝 SOP＋腳本（`spark-bootstrap.ps1`、金鑰產生、隔離網卡設定） | PR #2（已併入 main）：`ULTRA-MAERA-2/`、`SPARK-AGAVE-3/`、`SPARK-AGAVE-4/` |
| P0 一鍵盤點腳本（三台機器，依 BLUEPRINT §14 指令打包，自動寫出 `baseline` 報告） | `ULTRA-MAERA-2/scripts/laptop-inventory.ps1`、`SPARK-AGAVE-3/scripts/spark-inventory.ps1`、`SPARK-AGAVE-4/scripts/spark-inventory.ps1` |
| P4 Core 骨架（SQLite schema／rollback journal、audit JSONL＋redact、`sb` CLI：submit/status/workers/approve/cancel/snapshot、AGENTS.md）| `ULTRA-MAERA-2/superbrain-core/`；pytest 7 項全數通過（雲端 Session 已實跑，見 commit） |
| P4 一鍵安裝腳本（venv、裝依賴、初始化 DB、種入三台機器、自我驗證） | `ULTRA-MAERA-2/scripts/install-superbrain-core.ps1` |
| 詳細施工計畫作業書（哪些雲端可做、哪些要本地部署、Review 清單） | `.ai/WORK-PLAN.md` |

## 🔨 施工中

（無，P4 的骨架部分已完成；FastAPI Ingress、Router、heartbeat、Approval Dashboard 刻意留到下一輪，見 WORK-PLAN.md §3.2）

## ⬜ 未完成（依 Phase 順序）

| Phase | 項目 | 下一步 |
|---|---|---|
| P0 | 三台機器實際執行一鍵盤點腳本 | 你在各機器上跑對應的 `*-inventory.ps1`，回報 `baseline/` 結果 |
| P0 | 功率量測 | 購買插座功率計 |
| P1 | 影片同款：T01–T03 | ChatGPT 桌面版 + Remote 配對 |
| P2 | 隔離網路：T04、T05、T25 | 先採購交換器與 USB-C 網卡；SOP 與腳本已備妥，待實機執行後回報結果與 IP |
| P3 | UPS：T29 | 先量完功率再購買 |
| P4 | 在 ULTRA-MAERA-2 實機跑 `install-superbrain-core.ps1` 驗證 | 你在實機執行，回報 `sb workers` 輸出 |
| P4 | FastAPI Ingress API、Router 分流表讀取、Worker heartbeat、Approval Dashboard | 下一輪雲端工作 |
| P5–P12 | 見 ACCEPTANCE §1 | 需要實機 GPU／模型權重，全部要本地 |
| 文件 | Worker daemon API 細節（P8 前）、PWA 設計（P11 前）、golden set 題目（P6 前） | — |

## ⛔ 阻塞／待使用者決定

| 項目 | 需要的是 | 影響 |
|---|---|---|
| Tailscale 登入 | 使用者本人登入 | P11、iPhone 外出存取 |
| 採購（UPS、交換器、網卡、Hub、功率計） | 使用者決定與付款 | P2、P3 |
| 原始測試資料可否脫敏後上雲 | 使用者決定 | `test_data_analysis` 的 fallback |
| 喚醒詞名稱 | 使用者決定 | P10 |
| Insider build 是否換回正式版 | 使用者決定 | Laptop 穩定性 |
| Golden set 真實工作樣本 | 使用者提供 | P6 |

## 決策紀錄

| 日期 | 決策 | 來源 |
|---|---|---|
| 2026-09-24 | 驗收目標定為「多機調度」 | 使用者 |
| 2026-09-24 | 語音 Phase A：ChatGPT Voice → Codex → `sb` | 使用者 |
| 2026-09-24 | Router 依任務類型靜態分流，門檻 0.85 | 使用者 |
| 2026-09-24 | Laptop 是唯一連網節點，Spark 隔離 | 使用者 |
| 2026-09-24 | Spark 每月一次受控維護窗口 | Claude 判斷（BLUEPRINT §4.4） |
| 2026-09-24 | Gemini 改用 Antigravity CLI 免費額度，只當 best-effort | Claude 判斷 |
| 2026-09-24 | mp4 不上傳 GitHub（版權內容，且 37MB） | Claude 判斷 |
| 2026-09-25 | 機器名稱定案：Laptop Ultra → **ULTRA-MAERA-2**、Spark1（FAST）→ **SPARK-AGAVE-3**、Spark2（DEEP）→ **SPARK-AGAVE-4**。角色與 IP 配置（10.77.0.11 / .12）沿用 BLUEPRINT §3.1/§4.1 不變，只換名稱。BLUEPRINT.md 本文尚未全文改名，之後有需要再統一改寫 | 使用者 |
| 2026-09-25 | 新增 `ULTRA-MAERA-2/`、`SPARK-AGAVE-3/`、`SPARK-AGAVE-4/` 三個資料夾，各放安裝 SOP 與 PowerShell 腳本（金鑰產生、隔離網卡設定、`spark-bootstrap.ps1`）。停用密碼登入（`-KeyOnly`）仍維持 RED 動作，需要 ULTRA-MAERA-2 驗證金鑰登入成功後才執行，未做成略過驗證的全自動 | Claude 判斷（依 BLUEPRINT §4.2/§4.4、CLAUDE_REVIEWER 的 RED 動作規則） |
| 2026-09-25 | PR #2 併入 main | 使用者確認合併 |
| 2026-09-25 | 依 WORK-PLAN.md 分工，雲端 Session 只做 P0 一鍵盤點腳本與 P4 Core 骨架；FastAPI Ingress／Router／heartbeat／Approval Dashboard 因為要接真實網路與 Worker 才有意義，故意不做成半成品，留到下一輪 | Claude 判斷（CLAUDE_REVIEWER §1 的「先規劃、Review」職責） |
