# STATUS：施工進度

> 最後更新：2026-09-24（Claude Code）
> 依據：[BLUEPRINT.md](BLUEPRINT.md)、[ACCEPTANCE.md](ACCEPTANCE.md)
> 狀態標記：✅ 已完成｜🔨 施工中｜⬜ 未完成｜⛔ 阻塞

## 目前階段

**研究與規劃已完成 → 尚未施工（P0 未開始）。** 依使用者指示，目前不施工。

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

## 🔨 施工中

（無）

## ⬜ 未完成（依 Phase 順序）

| Phase | 項目 | 下一步 |
|---|---|---|
| P0 | Laptop 盤點補完（SSD、USB4、GPU 記憶體切分、API key 環境變數、各 CLI 版本） | 跑 BLUEPRINT §14 的指令 |
| P0 | Spark1、Spark2 盤點 | 兩台開機，在本機跑 §14 的指令 |
| P0 | 功率量測 | 購買插座功率計 |
| P1 | 影片同款：T01–T03 | ChatGPT 桌面版 + Remote 配對 |
| P2 | 隔離網路：T04、T05、T25 | 先採購交換器與 USB-C 網卡 |
| P3 | UPS：T29 | 先量完功率再購買 |
| P4–P12 | 見 ACCEPTANCE §1 | — |
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
