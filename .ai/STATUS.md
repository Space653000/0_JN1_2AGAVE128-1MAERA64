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

**P0 盤點：Laptop 部分已完成（2026-09-24），Spark ×2 尚未。** 原始輸出在 `C:\SuperBrain\baseline\laptop\`（不進 repo）。

| 項目 | 實測 | 對藍圖的影響 |
|---|---|---|
| 硬體 | ARM64、20 核、RAM 64GB（Samsung 9400 MT/s）、SSD Micron NVMe 954GB（**C: 剩 210GB**） | 模型放在 Laptop 的空間有限，模型主要放 Spark |
| Windows | 11 Pro Insider Preview build 28020；韌體顯示 `OVMF 20130221`、廠商 `OEMQAJ`（預發行平台的特徵） | 凍結版本，避免自動更新 |
| USB | **有 USB4 host router**；XVF3800 已辨識（含 Echo Cancelling Speakerphone 端點）；reSpeaker Control/DFU 裝置都正常 | Hub 與 2.5GbE 網卡可以選 USB4/USB3 規格 |
| 鏡頭 | 外接的是 **Logi C922 Pro Stream**（不是 C920），另有 Surface 內建前鏡頭與 IR | 藍圖鏡頭名稱已修正；C922 也是 UVC，規劃不變 |
| 睡眠 | 只有 S0 低電源閒置（Modern Standby），電源計畫為「平衡」 | P1 前要改成插電永不睡眠，否則 Remote 會斷 |
| API key | 只有 `ANTHROPIC_BASE_URL=https://api.anthropic.com`（由 Claude 桌面 App 在行程層級設定，不是系統設定）；**沒有 API key** | 不會意外走 API 計費 ✅ |
| 工具 | git 2.55、node 24.17、OpenSSH client 9.5、codex 0.155.0-alpha、claude 2.1.214、ffmpeg 8.1.2、ollama client 0.32.5 | `agy`（Antigravity CLI）、`docker`、`sshd` 都沒有；ollama 服務未啟動 |

## ⬜ 未完成（依 Phase 順序）

| Phase | 項目 | 下一步 |
|---|---|---|
| P0 | Laptop：GPU/RAM 切分能否調整（OS 可見 38.1GB）、Insider 版本凍結、確認 Windows 更新設定 | 查 Surface/NVIDIA 設定；需要你決定是否換回正式版 |
| P1 前置 | 電源計畫改為插電永不睡眠（需要你同意，這是系統設定） | 見下方「待使用者決定」 |
| 工具 | 安裝 `agy`（Antigravity CLI）與 Docker（WSL）、啟動 ollama | 需要你同意 |
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
