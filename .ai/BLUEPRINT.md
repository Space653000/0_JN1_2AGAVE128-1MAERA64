# SuperBrain BLUEPRINT：語音多機調度的混合式 AI 系統

> **本文件是本專案唯一的藍圖依據（Single Source of Truth）。** 其他藍圖均為參考來源，索引見 §17；內容衝突時以本文件為準。
> 配套文件：[ACCEPTANCE.md](ACCEPTANCE.md)（驗收標準）｜[STATUS.md](STATUS.md)（進度）｜[CLAUDE_REVIEWER.md](CLAUDE_REVIEWER.md)（Claude Code 職責）

- **版本**：v2.1（Claude Code 整合版＋來源索引與完整性檢查）
- **日期**：2026-09-24
- **取代**：ChatGPT 深入研究 (1)(2)(3)。三份報告仍保留為參考資料；內容衝突時，以本文件為準。
- **輸入來源**：本地螢幕錄影（mp4）、YouTube〈ChatGPT Voice Mode 實測，用嘴巴完成所有工作？〉字幕、三份深入研究報告、Laptop 實機盤點（2026-09-24）、網路檢索（來源列在文末）
- **核心原則**：One SuperBrain, Many Replaceable Workers。ChatGPT、Claude、Gemini 與兩台 Spark 都是可以替換的工人；State、Policy、Approval、Evidence 則由你自己掌握。

---

## 0. 一頁決策摘要

| 決策 | 定案 |
|---|---|
| 驗收目標 | **多機調度**：一句話就能把工作分派到 Laptop、Spark1、Spark2，並具備 Queue、核准、驗證與稽核 |
| 網路角色 | **Laptop 是唯一連網的 Gateway**；兩台 Spark **不連網**，只接隔離 LAN |
| 雲端 AI | ChatGPT Plus（含 Codex）、Claude Pro（含 Claude Code），加上 Gemini（Antigravity CLI 免費額度）。**不另外購買 API** |
| 本地優先規則 | 在 golden set 上，本地分數 ≥ 雲端 85% 的任務類型預設走本地；其餘走雲端 |
| 第一階段語音 | ChatGPT 桌面版 Voice → Codex → 本地 `sb` CLI → SuperBrain（零新增費用） |
| 最終語音 | reSpeaker XVF3800 + 本地 ASR/TTS，接到**同一個** SuperBrain API（可離線） |
| 視覺 | Logi C922 Pro → Laptop → Spark1 本地 VLM；影像預設不上雲 |
| 外部資料 | 測試電腦與工作站資料 → Laptop 上的 **SFTP 收件區**（FTP 只作為舊設備的過渡方案）→ 隔離與雜湊 → 轉送 Spark 分析 |
| State/Queue | Laptop 上的 SQLite；**目前 runtime 為 3.49.1，屬 WAL bug 受影響版本 → 先用 rollback journal** |
| 必要採購 | **UPS ×1**（兩台 Spark + 交換器）、2.5GbE 交換器、USB-C 網卡、USB-C Hub；合計約 NT$9,000～14,000 |
| 未來擴充 | NAS（模型庫與備份）、10GbE、Heavy Mode（雙 Spark 叢集），都等 Gate 通過才買 |
| 每月固定費用 | 維持 **US$40**（ChatGPT Plus + Claude Pro） |

---

## 1. 需求基線（使用者已確認）

1. 體驗要像影片那樣：講一句話就開始做事、可以隨時打斷、背景執行、完成後口頭回報、手機可以接續操作。
2. 規模要做到多機調度，不能只停在單機聊天。
3. 盡量不花錢、不浪費額度；**本地能做到雲端 80～90% 水準的工作，就交給本地**。
4. Laptop Ultra（Windows 11 ARM64）負責對外連網，串接雲端 AI（Claude、ChatGPT、Gemini）、測試電腦與工作站 FTP。
5. 兩台 Spark 盡量不連網，只跑本地 AI 並把能力發揮到極致；做不到的部分，**透過 Laptop 向雲端求援**。
6. Laptop 擴充的周邊：Logi C922 Pro 鏡頭、reSpeaker XMOS XVF3800 四麥克風陣列（含外殼）、USB-C 耳機。
7. 若必須讓 Spark 連網，由 Claude 判斷（見 §4.4 維護窗口）。

---

## 2. 三份 ChatGPT 報告的整合與勘誤

三份報告的主體架構一致，本文件全部沿用：Hybrid 架構、自建 Control Plane、SQLite、FAST/DEEP 分工、確定性優先的 Router、核准綁定具體動作、Agent 不能自行宣告 DONE、每個任務使用獨立的 worktree、Heavy Mode 預設關閉。

需要修正的地方如下：

| # | 報告說法 | 修正 | 依據 |
|---|---|---|---|
| 1 | (1)(2) 說有「Codex Python SDK」 | 官方 SDK 是 **TypeScript**。Python Core 應先用 `codex exec`，之後再改用 app-server JSON-RPC | 報告 (3) |
| 2 | (2) 說 Claude Pro 另有每月 US$20 Agent SDK credit | **不寫入成本模型**；Claude 與 Claude Code 共用 Pro 額度 | 報告 (3) |
| 3 | 原始需求說 Spark 是「ARM Linux」 | Spark 是 **Windows 11 Pro + WSL2** | Microsoft 產品頁 |
| 4 | SQLite WAL 需 ≥3.51.3 | Laptop 實測 **3.49.1** → MVP 先用 rollback journal，升級後再開 WAL | 實機 |
| 5 | 三份報告都沒有處理 Spark 斷網 | Spark 不連網之後，模型、套件、驅動與 Windows Update 都必須有**離線供應鏈**（§4.4） | 本文件新增 |
| 6 | 三份報告的雲端只有 OpenAI 與 Anthropic | 加入 Gemini。注意：**Gemini CLI 的個人 Google 登入已於 2026-06-18 停止**，改用 **Antigravity CLI（`agy -p`）** 的免費 Starter 額度 | 網路檢索 |
| 7 | 報告把「Laptop RAM 64GB」當成全部可用 | 實測 OS 只看到 **38.1GB**，GPU 另有 **24,512 MiB**，合計約 62GB，可見 unified memory 被切給 GPU。Control Plane 的預算要按 38GB 計 | 實機 |
| 8 | 報告建議 headset first | 你已經有 XVF3800，它內建硬體 AEC、波束成形與 DoA，可以提早嘗試 room mode。耳機仍保留，用在吵雜環境與隱私需求 | Seeed 官方 |

---

## 3. 硬體角色與實測基線

### 3.1 三機角色

| 節點 | 主要角色 | 次要角色 | 連網 |
|---|---|---|---|
| **Laptop Ultra**（`testpc`） | Control Plane、Gateway、語音與視覺 I/O、雲端代理、SFTP 收件 | 小型本地推論（ASR、嵌入、以 24GB GPU 跑小型 VLM） | ✅ Internet + 隔離 LAN |
| **Spark1** | FAST：批次處理、RAG、嵌入、VLM、便宜推論、本地 ASR（大模型版） | 資料前處理、測試數據分析 | ❌ 僅隔離 LAN |
| **Spark2** | DEEP：大模型推理、審查、Verifier、長上下文 | 夜間批次、模型評測 | ❌ 僅隔離 LAN |
| Spark1+2 | Heavy Mode（預設關閉） | 超大模型 | ❌ |

### 3.2 Laptop 實測值（2026-09-24，本機盤點）

| 項目 | 實測 | 判讀／行動 |
|---|---|---|
| 主機名 | `testpc` | 之後改成 `sb-laptop` 較好辨識（選做） |
| CPU | 20 cores，Architecture=12（**ARM64**） | 所有 Python 原生套件都要先確認 ARM64 wheel |
| GPU | NVIDIA **RTX Spark N1X**（6,144-core Blackwell），24,512 MiB；另有 NVIDIA NPU；driver 616.00 | 可以跑 ASR、VLM 小模型 |
| OS 可見 RAM | 38.1 GB | 64GB unified memory 中約 24GB 切給 GPU；Phase-0 要確認是否可調 |
| OS | **Windows 11 Pro Insider Preview** | ⚠️ Control Plane 跑在 Insider build 有穩定性風險。建議停止接收新的 Insider build，並凍結版本 |
| WSL | Ubuntu-24.04（WSL2，Stopped） | 可用 |
| 網路 | **只有 Wi-Fi 7**（866 Mbps），沒有有線網路 | ⚠️ 需加 USB-C 2.5GbE 網卡接隔離 LAN |
| Tailscale | 已安裝，**未登入** | iPhone 外出存取用；需要你自己登入 |
| Python | 3.12 ARM64、3.11 | 用 3.12 ARM64 作為 Core |
| SQLite | **3.49.1** | 屬 WAL bug 受影響範圍，先用 rollback journal |
| CUDA | v13.4（arm64） | |
| 已安裝 | Ollama、LM Studio、Antigravity IDE、Node.js、gh、ffmpeg、pandoc、CMake | Ollama/LM Studio 可以當 Laptop 的本地小模型快速通道 |

### 3.3 Spark（兩台，待 Phase-0 實測）

| 項目 | 目前狀態 |
|---|---|
| OS | Windows 11 Pro（官方），build 未知 |
| Memory | 128GB unified |
| 埠 | 2×USB-C、USB-A、HDMI、Ethernet、耳機孔；**Ethernet 速度未公開** |
| ConnectX/QSFP | **未公開，禁止假設**。200Gb 線材、交換器與光模組一律不買 |
| 散熱 | 100W thermal envelope（這不是牆上實際功耗，需用插座功率計實測） |

---

## 4. 網路架構：Laptop 單一出口 + Spark 隔離

### 4.1 拓撲

```text
                  Internet
                     │
              家用 Router / Wi-Fi
                     │ (Wi-Fi 7)
          ┌──────────┴──────────┐
          │   Laptop Ultra      │  ← 唯一連網節點
          │   Control Plane     │     不做 NAT、不開 ICS、不轉送封包
          │   SFTP 收件區       │
          └──────────┬──────────┘
                     │ USB-C 2.5GbE（靜態 IP 10.77.0.1/24，無 Gateway）
          ┌──────────┴──────────┐
          │  2.5GbE 隔離交換器   │  ← 不接家用 Router
          └───┬─────────────┬───┘
              │             │
          Spark1         Spark2
       10.77.0.11      10.77.0.12
       無 Default GW   無 Default GW
       無 DNS          無 DNS

  iPhone ──(ChatGPT Remote / Claude Remote / Tailscale)──► Laptop（只到 Laptop）
  測試電腦 / 工作站 ──(SFTP 或 LAN FTP)──► Laptop 收件區
```

### 4.2 隔離原則

| 規則 | 做法 |
|---|---|
| Spark 沒有出網路徑 | 隔離網卡設靜態 IP、**不設 Default Gateway 與 DNS**；Spark 的 Wi-Fi 關閉，或在裝置管理員停用 |
| Laptop 不能變成跳板 | 關閉 Internet Connection Sharing；`Get-NetIPInterface \| Where Forwarding -eq Enabled` 必須為空 |
| 最小開放 | Spark 的 Windows 防火牆只允許 `10.77.0.1` 連入 TCP 22（SSH）與 30000–30010（模型 API） |
| Spark 之間 | Spark1 ↔ Spark2 預設不通；Heavy Mode 核准後才開 |
| 驗收 | 在 Spark 上 `Test-NetConnection 8.8.8.8` 與 `Resolve-DnsName microsoft.com` **必須失敗** |

### 4.3 Spark 需要雲端時：透過 Laptop 升級

Spark 本身從不直接連雲端，流程如下：

```text
Spark worker 回報 status = NEEDS_ESCALATION
   + reason（例如：驗證兩次失敗 / 超出能力 / 需要最新網路資訊）
   + 已脫敏的最小上下文
          │
          ▼
Laptop Router
   ├─ 資料分級檢查（privacy_class = LOCAL_ONLY → 禁止上雲，改問你）
   ├─ 脫敏（路徑、IP、客戶名、序號、token）
   ├─ 選擇雲端工人（Codex / Claude / Gemini）
   └─ 結果回寫 SQLite → 需要時再派回 Spark 繼續
```

### 4.4 離線供應鏈與維護窗口（Claude 的判斷）

完全斷網的 Windows 機器無法自動更新；模型、Docker image、apt 與 pip 套件也需要來源。本文件的規劃如下：

| 需求 | 平時做法（Spark 不連網） |
|---|---|
| LLM 權重 | Laptop 下載（HF、NGC）→ 驗 SHA256 → `scp`/`robocopy` 到 Spark 的 `D:\models`；未來改放 NAS |
| Docker image | Laptop 的 WSL 執行 `docker pull --platform linux/arm64` → `docker save` → 傳到 Spark → `docker load` |
| pip | Laptop 執行 `pip download --platform manylinux2014_aarch64 --only-binary=:all:` → 傳輸 → `pip install --no-index --find-links` |
| apt | 少量套件用 `apt-get download` 帶過去；大量需求可在 Laptop 建本地 apt mirror（Phase 後期再做） |
| **Windows Update／NVIDIA driver** | **每月一次維護窗口**（見下方流程） |

**維護窗口 SOP（每月 1 次，屬 RED 動作，需要你核准）：**
1. 先做快照：記錄 driver、CUDA、WSL 與 Windows build（`sb snapshot spark1`）。
2. 把 Spark 的網路線暫時接到家用 Router，或切換到「維護」VLAN。
3. 執行 Windows Update 與 NVIDIA driver 更新（**一次只更新一台**，先更新 Spark1）。
4. 拔掉網路線，恢復隔離，並重跑 §4.2 的驗收。
5. 跑 health 與 benchmark 回歸測試。沒過就還原到 Known-Good。
6. Spark1 穩定 3 天後，再照同樣流程更新 Spark2。

> 為什麼不做到永遠不更新：Spark 與 Laptop 目前都還是 pre-release 平台，早期 driver 和韌體修正的價值很高。「平時隔離、定期受控更新」是風險最低的折衷。

---

## 5. 系統架構

```text
 你（語音／iPhone／鍵盤）
   │
   ├─ Phase A：ChatGPT 桌面 Voice ─► Codex ─► `sb` CLI ─┐
   ├─ Phase C：XVF3800 → 本地 ASR ────────────────────┤
   └─ iPhone：ChatGPT/Claude Remote、之後改用自建 PWA ─┤
                                                      ▼
 ┌──────────────── SuperBrain Core（Laptop，Windows native Python 3.12 ARM64）────────────────┐
 │ Ingress API (FastAPI, 127.0.0.1:8765)                                                       │
 │ Intent → Policy → Router(靜態分流表) → Dispatcher → Queue/Lease → Verifier → Approval → Audit │
 │ SQLite（rollback journal；升級後改 WAL）  JSONL audit  Secrets(SecretStore)                    │
 └──────┬──────────────┬──────────────┬───────────────┬───────────────┬──────────────────────────┘
        │              │              │               │               │
   Deterministic   Cloud Agents   Local-Laptop     Spark1 FAST     Spark2 DEEP
   PowerShell/Git  codex exec     Ollama/LMStudio  (SSH→WSL,       (SSH→WSL,
   Python/SSH      claude -p      ASR/VLM-small    HTTP :30000)    HTTP :30000)
   SFTP ingest     agy -p         Camera tool
```

### 5.1 `sb` CLI：語音與 Agent 對 SuperBrain 的唯一入口

```text
sb submit "<自然語言需求>" [--local-only] [--no-push] [--max-attempts 2]
sb status [task_id]        # 省略時回傳一句話的系統摘要，也就是 T08
sb workers                 # Laptop / Spark1 / Spark2 健康狀態
sb approve <approval_id>   # 只接受 exact-action digest
sb cancel <task_id>
sb snapshot <node>
sb camera snap [--analyze "問題"]
sb ingest list
```

讓 Codex（ChatGPT Voice 的後端）知道該呼叫 `sb`：在 `C:\SuperBrain\AGENTS.md` 寫入以下內容。

```markdown
# SuperBrain 規則（給 Codex）
- 任何涉及 Spark1、Spark2、多機、長任務、測試數據分析的需求：一律執行 `sb submit "<原話>"`，不要自己 SSH。
- 使用者問「現在在幹嘛／進度」：執行 `sb status`，用一句中文唸出結果。
- 不得執行 `sb approve`。核准只能由使用者在 Dashboard 或手機上點選。
- `sb` 回傳 WAITING_APPROVAL 時，把 approval 內容原文唸給使用者。
```

### 5.2 雲端工人分工（只用既有訂閱）

| 工人 | 呼叫方式 | 用途 | 額度注意 |
|---|---|---|---|
| **Codex**（ChatGPT Plus） | `codex exec --json`，sandbox=workspace-write | 實作、修 bug、跑測試、Windows 操作、語音前端 | 在你登入的 Windows session 下執行；認證失敗時設為 `BLOCKED_AUTH` 並通知你 |
| **Claude Code**（Pro） | `claude -p --output-format json` | 架構、審查、計畫挑戰、第二意見 | ⚠️ 確認系統**沒有** `ANTHROPIC_API_KEY`，否則會改走 API 計費 |
| **Gemini**（Antigravity CLI 免費 Starter） | `agy -p "<prompt>"` | 長上下文閱讀（大文件、log）、網路資訊查證、第三意見 | 免費層節流很重；**只能當 best-effort，不能列入關鍵路徑**；不得使用 `--dangerously-skip-permissions`，除非是在沙盒內 |

### 5.3 Router：依任務類型靜態分流（使用者選定）

**判定順序**：安全閘門 → 隱私閘門 → 確定性工具 → 分流表 → 工人健康與額度 → 升級。

```yaml
# config/routing.yaml（初值。Phase 6 跑完 golden set 後依實測改寫）
threshold: 0.85            # 本地分數 / 雲端分數 ≥ 0.85 → 預設走本地
escalate_on: [verify_fail_x2, worker_offline, needs_internet]
classes:
  file_count_hash_status:  {route: tool}              # 0 次 LLM 呼叫（T10）
  zh_summary:              {route: spark1, fallback: claude}
  test_data_analysis:      {route: spark1, fallback: spark2}
  log_triage:              {route: spark1, fallback: gemini}
  repo_analysis:           {route: spark2, fallback: claude}
  code_edit:               {route: codex}             # 待 golden set 證明本地夠好再改
  architecture_review:     {route: claude, fallback: spark2}
  verification_review:     {route: spark2}
  vision_camera:           {route: spark1, privacy: local_only}
  web_research:            {route: gemini, fallback: claude}
  windows_ui:              {route: laptop_codex}
```

**Golden set（100 題，都用你真實工作的資料）**：20 題繁中技術摘要、15 題中英混合指令、15 題 repo 分析、15 題程式修補、10 題除錯、10 題工具呼叫、5 題 JSON、5 題驗證、5 題 prompt injection。
每個類別先由雲端（Claude 或 Codex）跑出基準分，本地模型再跑一次；**比值 ≥ 0.85 的類別切到本地**。之後每季重跑一次，本地模型有進步就把更多類別移到本地。

### 5.4 本地模型候選（只作為首輪 benchmark，不是最終選擇）

| 節點 | 候選 | 引擎 |
|---|---|---|
| Spark1 FAST | Qwen3.6-35B-A3B（NVIDIA playbook 基準）、Qwen3.8-27B（社群實測在 DGX Spark 上以 SGLang+NVFP4 約 34–38 tok/s）、GPT-OSS-20B | llama.cpp 優先，vLLM 次之 |
| Spark1 VLM | Qwen VL 系列 30B 級 | llama.cpp / vLLM |
| Spark2 DEEP | GPT-OSS-120B、Nemotron-3-Super-120B、Qwen 大型 MoE | llama.cpp → TensorRT-LLM 挑戰者 |
| Laptop | ASR（Breeze-ASR / Qwen3-ASR）、嵌入模型、7–14B 小模型（Ollama） | Ollama / sherpa-onnx |

> 以上 tok/s 數據都來自 DGX Spark 的 Linux 環境。**Surface Spark 跑在 WSL2 上，必須重新實測**；在 SGLang 官方 playbook 中，WSL 不屬於 validated path。

---

## 6. 語音

### 6.1 三階段

| 階段 | 路徑 | 成本 | 目的 |
|---|---|---|---|
| **A（現在）** | ChatGPT 桌面 Voice → Codex → `sb` | US$0 新增 | 做到影片同款體驗，並完成多機調度的 UX 驗收 |
| B（選做） | GPT-Live-1 API → Voice Gateway → `sb` API | US$0.05/分鐘，每天 30 分鐘約 US$45/月 | **依你的成本原則預設不做**，除非 A 和 C 都不夠用 |
| **C（離線）** | XVF3800 → KWS → VAD → 本地 ASR → Intent（Spark1）→ `sb` → 本地 TTS | US$0 | 斷網也能用，且隱私資料不上雲 |

### 6.2 Phase C 元件（Laptop 端）

| 層 | Baseline | 挑戰者 | 備註 |
|---|---|---|---|
| 收音 | **reSpeaker XVF3800**（USB UAC 2.0 免驅動；4 麥克風、360°、最遠約 5m；硬體 AEC、波束成形、DoA、降噪、去殘響、AGC） | USB-C 耳機 | **TTS 播放要走 XVF3800 自身的音訊輸出**，AEC 才有參考訊號，插話打斷才可靠（請依 Seeed wiki 確認韌體模式） |
| 喚醒詞 | sherpa-onnx KWS（自訂中文詞，例如「小腦」） | openWakeWord（英文 hey jarvis） | |
| VAD | Silero VAD | XVF3800 內建 VAD | |
| ASR | **Breeze-ASR**（聯發科，針對台灣華語與中英混說） | Qwen3-ASR-1.7B（sherpa-onnx）、SenseVoice | Qwen3-ASR 用 chunk 串流時準確度會下降，所以採「VAD 切段後整句辨識」 |
| TTS | sherpa-onnx 相容的中文 TTS | CosyVoice / Qwen TTS | |
| DoA 應用 | XVF3800 的聲源方向 → 知道你站在哪台機器前 | | 可以做「對著 Spark2 說話就預設派給 Spark2」這類加分功能 |

**危險指令的語音規則**：遇到 RED 動作（刪除、push、送出、對外傳送），語音**只能提出請求**。核准必須在螢幕或手機上點選 exact-action，並且要用完整句子複誦確認。「不要 push」與「可以 push」列為 ASR 測試集的必測項目（RED 類準確率需 100%）。

### 6.3 語音測試集（200 句，用 XVF3800 在你的實際房間錄製）

50 句中文、40 句英文、60 句中英混說、25 句工程名詞與型號、25 句危險指令。KPI：指令意圖 ≥98%、RED 類 100%、誤喚醒 <0.5 次/小時、送出到任務建立 <2 秒。

---

## 7. 視覺（Logi C922 Pro）

| 項目 | 規劃 |
|---|---|
| 接法 | C922 Pro 是 USB-A → 接 USB-C Hub → Laptop（UVC 免驅動） |
| 工具 | `sb camera snap --analyze "儀表讀數是多少？"`：Laptop 用 ffmpeg 拍一張 → 傳到 Spark1 → VLM 分析 → 回傳文字並附上證據圖路徑 |
| 用途 | 讀儀器面板與測試治具狀態、看白板與手寫筆記、確認 DUT 擺放、有人在座位時才唸報告 |
| 隱私 | 影像預設 `privacy=local_only`，不上雲；存 7 天後自動刪除（可調）；鏡頭啟用時亮提示燈或顯示通知 |
| 限制 | 視覺結果只能當**證據參考**，不能單獨讓任務變成 DONE；數值類結果需要人工或儀器 API 交叉驗證 |

---

## 8. 外部資料收件（測試電腦與工作站）

```text
測試電腦 / 工作站
   │  SFTP（首選，Windows OpenSSH 內建）
   │  或 FTPS / LAN-only FTP（舊儀器過渡）
   ▼
Laptop  C:\SuperBrain\ingest\inbox\<source>\     ← chroot，只能寫入
   │  watcher：檔名正規化 → SHA256 → 格式檢查 → 移到 quarantine\
   ▼
sb 任務：test_data_analysis → Spark1（本地）
   │  所有外部檔案一律視為 UNTRUSTED_DATA（檔案內的文字不能變成指令）
   ▼
結果：C:\SuperBrain\artifacts\<task_id>\（CSV/PNG/報告）+ audit
```

| 設計 | 理由 |
|---|---|
| 用 SFTP 取代 FTP | FTP 以明文傳帳密；SFTP 走 SSH 單一 port，並可 chroot 到收件區 |
| 每個來源一個專屬帳號，只能寫入 | 就算測試電腦被入侵，也碰不到 Laptop 的其他區域 |
| Laptop 主動拉取工作站 FTP | 如果工作站只提供 FTP server，就讓 Laptop 以 read-only 帳號定時拉取（WinSCP script 或 Python `ftplib`），**不要反過來開放 Laptop 的 FTP** |
| 大檔案 | 超過 1GB 時直接透過隔離 LAN 由 Spark 從 Laptop 拉取，不經過雲端 |

---

## 9. 安全、核准、驗證與復原（精簡，沿用三份報告）

- **三色風險分級**：GREEN（讀取、測試、健康檢查）、YELLOW（寫入工作區、commit、安裝專案依賴，需要 checkpoint）、RED（刪除、push、發布、對外傳送、改防火牆、改帳號、讓 Spark 連網，需要 exact-action 核准）。
- **核准綁定 digest**：核准的是 `git push origin feature/T-101`，不代表可以執行 `--force origin main`；動作一變，核准就失效，並設有到期時間。
- **DONE 只能由 Verifier 寫入**：Agent 最多回報 `WORK_COMPLETE_CLAIMED`。Build、Test 的判定看 exit code，不問 LLM。
- **Repo**：每個可寫入的任務都有自己的 branch 與 worktree，禁止兩個工人同時改同一個 working tree。
- **重試**：`max_attempts=2`，同樣的錯誤出現兩次就停下來通知你；認證或權限錯誤不重試。
- **Heartbeat**：10 秒一次；30 秒沒回應就判定 OFFLINE，收回 lease 並重新派工。
- **Secrets**：用 PowerShell SecretStore，DB 與 audit 裡只存參照；進入 audit 前先做 redact。
- **Prompt injection**：外部資料可以包含任何文字，但永遠不會因此取得權限。

---

## 10. 電力與儲存

### 10.1 UPS（必要）

| 項目 | 規劃 |
|---|---|
| 負載 | Spark ×2（每台實際功耗待量測，保守估 150–240W）+ 2.5GbE 交換器（約 10W）；估計最大約 500W |
| 規格 | **1500VA / ≥900W、純正弦波、在線互動式、USB HID** |
| 參考型號 | CyberPower CP1500PFCLCD（1500VA/1000W）、APC BR1500MS2（1500VA/900W）；台灣可買到 110V 版本 |
| 自動關機 | UPS 的 USB 接 Spark1 → 電池剩 50% 或停電 5 分鐘時，Spark1 經由隔離 LAN 用 SSH 叫 Spark2 關機，再關閉自己 |
| Laptop | 有自己的電池，不接 UPS；Control Plane 偵測兩台 Spark OFFLINE 時把任務標為 `RECOVERING` |
| 驗收 | 拔掉 UPS 市電 → 兩台 Spark 在 10 分鐘內正常關機；復電後自動開機（BIOS 設定 AC power restore），SuperBrain 能恢復任務 |

> 購買前先用插座功率計（約 NT$300–600）量兩台 Spark 在滿載推論時的實際瓦數，確認 900W 有足夠餘裕，通常綽綽有餘。

### 10.2 儲存（現在 → 未來）

| 階段 | 做法 |
|---|---|
| 現在 | 模型放在各 Spark 的本機 SSD；SuperBrain DB 與設定每天備份到 Laptop 外接的 USB SSD（1–2TB） |
| 未來（Gate：模型庫 > 1TB，或需要在兩台 Spark 之間共享） | **2-bay NAS（RAID1，2×8TB）**，放在**隔離 LAN**：做模型倉庫、artifacts 與備份；由 Laptop 推送更新，Spark 只讀取 |
| 備份原則 | 3-2-1：DB 與設定存在 Laptop、USB SSD、NAS（未來）；另外把**加密**的一份放到雲端（Google Drive）；原始測試資料是否上雲由你決定 |

---

## 11. BOM 與成本（台幣為概估，請以實際報價為準）

### 11.1 已有

Laptop Ultra 64GB、Spark ×2、Logi C922 Pro、reSpeaker XVF3800（含外殼）、USB-C 耳機、ChatGPT Plus、Claude Pro。

### 11.2 必要採購（Phase 0–3）

| 品項 | 用途 | 概估 |
|---|---|---|
| UPS 1500VA/900W 純正弦波 | 兩台 Spark + 交換器 | NT$6,000–9,000 |
| 2.5GbE 5-port 非網管交換器 | 隔離 LAN | NT$1,500–2,500 |
| USB-C 2.5GbE 網卡 | Laptop 接隔離 LAN | NT$600–1,000 |
| 有外接電源的 USB-C Hub（含 USB-A ×2 以上） | 接 C922 Pro、XVF3800、耳機、網卡 | NT$1,000–2,000 |
| Cat6 網路線 ×3 | | NT$300 |
| 插座功率計 | 量測 Spark 功耗、UPS sizing | NT$300–600 |
| **小計** | | **約 NT$9,700–15,400** |

> 如果兩台 Spark 實測是 10GbE，而且傳輸模型時確實卡在網路，再升級成 10GbE 交換器；**要先實測，再決定是否升級**。

### 11.3 未來（有 Gate 才買）

| 品項 | Gate | 概估 |
|---|---|---|
| 2-bay NAS + 2×8TB | 模型庫 > 1TB 或需要共享 | NT$20,000–30,000 |
| 10GbE 交換器與網卡 | iperf3 證明 2.5GbE 是瓶頸 | NT$8,000–15,000 |
| ConnectX/QSFP 線材 | 實機確認有 QSFP，且 Heavy Mode benchmark 提升 ≥30% | 未定 |
| 機械手臂（例如影片提到的 Niryo Ned2） | 軟體部分全部驗收完才考慮 | 很高，暫不列入 |

### 11.4 每月費用

| 項目 | 金額 |
|---|---|
| ChatGPT Plus | US$20 |
| Claude Pro | US$20 |
| Gemini（Antigravity 免費額度） | US$0 |
| GPT-Live / 各家 API | **US$0（不啟用）** |
| 電費 | Phase-0 實測後估算：平均瓦數 × 使用時數 / 1000 × 台電電價 |

---

## 12. 施工階段與 Gate

> 規則：每個 Phase 驗收 PASS 之後，才進入下一個 Phase。

| Phase | 內容 | PASS 條件 |
|---|---|---|
| **P0 盤點** | 三台機器的 inventory（§14 清單）；停止接收 Insider build 並凍結；量測功耗 | 三台都能回答「是什麼硬體、什麼 OS、什麼網卡、什麼速度」 |
| **P1 影片同款** | ChatGPT 桌面 Voice + Codex + iPhone Remote（不用 SuperBrain） | T01 用語音建檔、T02 用語音改檔、T03 手機接續 |
| **P2 隔離網路** | 交換器、USB-C 網卡、靜態 IP、Spark 斷網、防火牆、OpenSSH 金鑰 | `ssh spark1 hostname` 100/100 次成功；Spark 無法出網 |
| **P3 UPS** | 安裝 UPS、設定自動關機鏈、AC restore | 斷電演練通過 |
| **P4 Core 骨架** | `C:\SuperBrain`、venv、SQLite schema、`sb` CLI、AGENTS.md、audit | T04/T05：`sb workers` 正確顯示三台 |
| **P5 Spark1 FAST** | 離線供應鏈送入 llama.cpp 與 Qwen 基準模型 → OpenAI 相容 API | T06：用語音派工到 Spark1，並回傳證據 |
| **P6 Golden set** | 100 題 × 雲端 × 本地 → 產出 routing.yaml | 分流表以數據決定 |
| **P7 Spark2 DEEP** | DEEP 候選 benchmark → Verifier | T07 |
| **P8 Queue/Approval/Recovery** | lease、heartbeat、RED 核准、重試、worktree | T08–T16、T19–T24 |
| **P9 收件與視覺** | SFTP 收件區、C922 Pro 工具 | 測試數據自動分析報告；`sb camera snap` |
| **P10 離線語音** | XVF3800 + KWS/VAD/ASR/TTS | 語音 KPI（§6.3）；T17 斷網仍能控制 |
| P11 手機 PWA | Tailscale → Laptop Dashboard | iPhone 可以查看與核准 |
| P12 Heavy Mode | 雙 Spark 叢集 | 只有在 benchmark 證明有效益時才做 |

**在 T01–T08 全部通過之前，禁止導入**：Kubernetes、Redis、NATS、RabbitMQ、PostgreSQL、Grafana、向量資料庫平台、agent swarm 框架、雙 Spark 叢集、GPT-Live API。

### 驗收測試

完整的 T01–T30 與各 Phase Gate 定義在 **[ACCEPTANCE.md](ACCEPTANCE.md)**，本文件不重複列出。

---

## 13. 五個問題的直接回答

### Q1. 影片那種體驗怎麼實現？

分兩步：
1. **今天就能做到影片同款（P1）**：打開 ChatGPT Windows 桌面版，點語音按鈕說話，它會在背景開 Codex 任務去讀檔、改檔、跑程式；中途可以打斷並改指令；手機開 ChatGPT 側邊欄的 **Remote** 配對這台 Laptop，出門也能繼續。前提是 Laptop **保持開機、連網、不睡眠**（電源設定改成插電時永不睡眠）。
2. **擴充到你要的多機調度（P2–P8）**：讓 Codex 不直接動手，而是呼叫 `sb`，由 SuperBrain 把工作派給 Spark1 或 Spark2、排隊、驗證，需要時請你核准，最後用一句話回報。

### Q2. 雲端 AI + 本地 AI 能實現嗎？

可以，而且這就是本藍圖的主架構。
雲端負責**語音前端（ChatGPT Voice）、程式實作（Codex）、架構審查（Claude）、查網路與長文閱讀（Gemini）**；本地負責**批次、隱私資料、測試數據、視覺、驗證、夜間工作**；確定性工作（檔案數量、雜湊、git status、build）不呼叫任何 LLM。
分流依據 golden set 實測：本地達雲端 85% 以上的類別交給本地，這樣雲端額度只花在真正需要的地方。

### Q3. 只用本地 AI 能實現嗎？

**可以做到約 70–85% 的體驗，但有三個缺口**：

| 能力 | 純本地 | 缺口 |
|---|---|---|
| 語音收發 | ✅ XVF3800 + Breeze-ASR + 本地 TTS | 自然程度與插話打斷的流暢度不如 ChatGPT Voice；需要調校 |
| 一般問答、摘要、數據分析 | ✅ Spark 的 30–120B 模型 | 接近雲端 |
| 大型程式開發 Agent | ⚠️ 可以用 Codex CLI 或 Claude Code 接本地模型端點 | 複雜修改的成功率明顯低於雲端前沿模型 |
| Windows 畫面操作（Computer Use） | ⚠️ 本地 VLM 可以做，但不穩定 | 優先改用 API、PowerShell、UI Automation |
| 最新網路資訊 | ❌ | 本質上需要連網 |

所以純本地適合當成 **Offline Mode**（斷網或隱私模式）：和 Hybrid 共用同一套 SuperBrain，只是 Router 把雲端工人標成 OFFLINE。

### Q4. YouTube 完整重點、逐段摘要、可實作 SOP

**影片**：〈ChatGPT Voice Mode 實測，用嘴巴完成所有工作？〉（約 13 分鐘；本地 mp4 是這支影片開頭 0:00–0:52 的螢幕錄影）

**逐段摘要**

| 時間 | 段落 | 重點 |
|---|---|---|
| 00:00–01:16 | 開場 | 用《鋼鐵人 2》Jarvis 的場景引出主題：現在用 ChatGPT **Work 的 Voice Mode** 就能做到類似的事 |
| 01:18–02:22 | 它是什麼 | 內建在**桌面版** ChatGPT；手機首頁的語音只能聊天，桌面版 Voice 會**真的動手操作電腦**。有任務正在跑時，可以按 Start voice chat 無縫接續。任務在背景執行時可以交代新任務，也可以隨時打斷並調整 |
| 02:22–02:52 | 手機遠端 | 電腦保持**開機、連網、不睡眠** → 手機 ChatGPT 側邊欄開 **Remote** 配對 → 手機上的語音指令會由家裡的電腦執行（例如開車時繼續推進專案） |
| 02:58–04:45 | 實測一：整理資料夾 | 點語音 icon 下指令後就可以切去別的視窗；畫面上會留一個 Voice 小圖示，可以隨時說話或查看狀態；它會在後台**開獨立對話串**，掃描 15 個檔案並分類；中途改指令也不會亂 |
| 04:45–08:30 | 實測二：語音寫遊戲 | 口述需求，約 6 分鐘後就在 **Codex 內建瀏覽器**跑出第一版（辦公室打東西遊戲）；一邊試玩一邊口頭提修改（視角、打擊感、加入老闆角色），Agent 會改 code |
| 08:30–10:27 | 手機接續與部署 | 用手機 Remote 接續：畫面是語音介面，**程式其實在電腦上跑**；問進度、請它檢查手機橫向版本，最後叫它**部署上網** |
| 10:27–12:13 | Jarvis 的四個核心 | 大腦（思考）、耳朵與嘴巴（語音）、手（操控設備）、眼睛（看環境）。Voice Mode 已經做到大腦和耳嘴；手和眼的做法是**把機械手臂的 API、相機畫面包成工具**讓 Agent 呼叫（例如 Niryo Ned2）；作者也提醒實體機器人沒這麼簡單 |
| 12:13–13:17 | 作者的用法 | 用 **Typeless 做 Brain Dump**（先把混亂的想法整理好），再交給 AI 做深度工作；**Voice Mode 當即時秘書**，處理瑣事、翻專案檔案、碰撞點子。作者的看法是：把混亂的想法直接丟給語音助理去執行，只會放大混亂 |

**可實作 SOP（影片同款，約 30 分鐘）**
1. 在 Laptop 安裝並登入 ChatGPT Windows 桌面版（Plus 帳號），確認 Work/Codex 可以使用。
2. 電源設定：插電時「永不睡眠」、螢幕可以關閉；Windows Update 的使用時段避開你常用的時間。
3. 建立工作資料夾（例如 `C:\SuperBrain\sandbox`），在 Codex 設定中授權這個資料夾，**不要授權整顆 C 槽**。
4. 點語音按鈕，說：「在 sandbox 建立 VOICE_TEST.md，內容寫今天日期。」→ 用檔案總管確認（T01）。
5. 說：「把第二行改成 Hello SuperBrain。」→ 確認內容（T02）。任務執行中說「等一下，改成英文」，測試打斷功能。
6. iPhone 打開 ChatGPT，進入側邊欄 Remote，掃 QR 配對 Laptop → 在手機用語音問「剛剛做到哪裡？」（T03）。
7. 在 Laptop 寫 `AGENTS.md`（§5.1），規定危險動作要先問你；對外發布或部署一律先問。
8. 養成影片作者的習慣：想法很亂時先 Brain Dump 整理成文字，再交代任務；零碎雜事才直接用語音。

### Q5. 對「本地超級大腦／多電腦語音控制」架構的可用之處

| 影片內容 | 對本架構的價值 | 採用方式 |
|---|---|---|
| 桌面 Voice 會真的動手、在背景開任務 | ⭐⭐⭐ 等於現成的 Voice Adapter 加上 Agent | **Phase A 的語音前端**，零開發成本 |
| 可以隨時打斷並 redirect | ⭐⭐⭐ 本地語音最難做的就是這點 | 先直接用；Phase C 靠 XVF3800 的 AEC 自己做 |
| 手機 Remote，電腦端執行 | ⭐⭐⭐ 就是「手機 = 指令、狀態與核准，不是終端機」 | iPhone 的 MVP 路徑；前提是 Laptop 不睡眠 |
| 背景開獨立對話串 | ⭐⭐ 近似 task 概念 | 但它是 vendor session，**不能當 SSOT**；真正的 task 存在 SQLite |
| Codex 內建瀏覽器驗證成品 | ⭐⭐ 瀏覽器層的驗證工具 | 當作 Verifier 的一環，但仍以 exit code 與測試為主 |
| 一句話就「部署上網」 | ⚠️ 反面教材 | 本架構中「部署、發布」屬於 **RED 動作**，語音只能提出，必須在螢幕上核准 |
| Jarvis = 大腦 + 耳嘴 + 手 + 眼，手眼都是工具 | ⭐⭐⭐ 與「Tool Executor Layer」完全一致 | 眼睛 → C922 Pro 工具（§7）；耳嘴 → XVF3800（§6）；手 → PowerShell、SSH、Worker API（未來才考慮機械手臂） |
| Typeless Brain Dump 與 Voice 秘書分工 | ⭐⭐ 意圖品質決定結果品質 | Intent 層加上「需求不清楚 → 先反問，或先產出計畫給你確認」 |
| 影片沒有提到的部分 | — | 多機、Queue、核准、驗證、離線、隱私分級：這些就是本藍圖要補的 |

---

## 14. Phase-0 盤點清單

**Laptop（已完成一部分，見 §3.2）**，還需要補做：
- [ ] 確認 GPU 切走的 24GB 是否可以在 BIOS 或驅動設定中調整
- [ ] 決定是否停止接收 Insider build，並記錄目前的 build 號碼
- [ ] 查 SSD 型號與剩餘空間：`Get-PhysicalDisk; Get-Volume`
- [ ] 確認 USB-C 是否支援 USB4/Thunderbolt，這會影響 Hub 與網卡的選擇
- [ ] 登入 Tailscale（需要你本人操作）
- [ ] 確認系統沒有 `ANTHROPIC_API_KEY` 與 `OPENAI_API_KEY` 環境變數，避免意外走 API 計費
- [ ] 確認 ChatGPT 桌面版、`codex`、`claude`、`agy` 的版本

**Spark ×2（兩台都要做）**
```powershell
Get-ComputerInfo | Select OsName,OsBuildNumber,CsProcessors
Get-CimInstance Win32_Processor | Select Name,Architecture,NumberOfCores
Get-NetAdapter | Select Name,InterfaceDescription,LinkSpeed,MacAddress   # 找 Ethernet 速度、ConnectX
Get-PnpDevice | Where FriendlyName -match 'Mellanox|ConnectX|QSFP'
Get-PhysicalDisk; Get-Volume
nvidia-smi -q > nvidia.txt
wsl --status; wsl -l -v
powercfg /a
```
```bash
# WSL 內
uname -m; cat /etc/os-release; free -h; df -h; nvidia-smi; docker version
```
- [ ] 用插座功率計量：待機、FAST 推論、DEEP 推論三種狀態的瓦數
- [ ] BIOS：AC power restore = On；關閉睡眠
- [ ] 啟用 OpenSSH Server，建立專用帳號，只允許金鑰登入

**網路**
- [ ] 用 iperf3 量 Laptop ↔ Spark1/2 的頻寬；ping 1,000 次，要求 0% loss
- [ ] Spark 斷網驗收（T25）

---

## 15. 待你決定的事項（不影響 P0–P2 開工）

1. 原始測試資料是否允許（脫敏後）上雲？這決定 `test_data_analysis` 的 fallback 能不能是雲端。
2. 喚醒詞要取什麼名字？（例如「小腦」「Jarvis」）
3. Insider build 要不要換回正式版？（建議換回，至少 Laptop 要凍結）
4. NAS 預算與時程。

---

## 16. 監控與告警（沿用報告 (2)「Monitoring / Alert Conditions」）

第一版不部署 ELK、Prometheus 或 Grafana。只做 SQLite state、JSONL audit、`/health`、`/status`，以及一個最小化的 Dashboard（在 Laptop 的 `127.0.0.1` 上）。語音不唸 Dashboard，只講一句摘要，例如：「三台都正常，一號在分析測試數據，二號空閒，沒有需要你核准的事情。」

| 告警 | 觸發條件 | 動作 |
|---|---|---|
| Worker DEGRADED | 20 秒沒有 heartbeat | 標記 |
| Worker OFFLINE | 30 秒 | 收回 lease、重新派工 |
| Queue 積壓 | 超過 5 個任務或等待超過 10 分鐘 | 通知 |
| 重複失敗 | 2 次 | 停止並通知 |
| OOM | 任何一次 | 通知，並重啟模型服務 |
| RED 等待核准 | 立即 | 手機通知 |
| 認證失敗 | 立即 | `BLOCKED_AUTH` |
| 磁碟剩餘低 | 低於 20% | 通知 |
| Audit 寫入失敗 | 立即 | **停止所有寫入** |
| DB 完整性異常 | 立即 | **停止派工** |
| 偵測到 False-DONE | 立即 | Critical |
| Spark 出現出網流量 | 立即 | Critical，並隔離該 Spark（本藍圖新增） |
| UPS 改由電池供電 | 立即 | 暫停新任務，準備關機（本藍圖新增） |

**Risk Register**：沿用報告 (2)〈Risk Register v1.1〉。本藍圖新增三項：
- Spark 斷網之後供應鏈中斷 → §4.4 維護窗口
- Antigravity 免費額度不穩 → 只當 best-effort
- Laptop 跑 Insider build → 凍結版本

---

## 17. 原有藍圖與資料索引（全部保留，不刪除）

| 檔案 | 定位 | 本藍圖採用的部分 | 被本藍圖覆寫的部分 |
|---|---|---|---|
| [`1_ChatGPT-deep-research-report/deep-research-report (1).md`](../1_ChatGPT-deep-research-report/deep-research-report%20(1).md) | ChatGPT 研究 v1.0：Research → Architecture Decision | Hybrid 決策、Control Plane 拆分、Router 演進、State Schema 初版、T01–T18、施工禁止清單、Rollback SOP、Troubleshooting 決策樹 | 「Codex Python SDK」、Spark 是 DGX/Linux 的假設 |
| [`deep-research-report (2).md`](../1_ChatGPT-deep-research-report/deep-research-report%20(2).md) | ChatGPT 研究 v1.1：Design Freeze Candidate | Windows native Core、SSH→WSL、SQL schema、State Machine、Worker Protocol、Approval digest、T19–T24、Benchmark Matrix、FAST/DEEP Gate、Alert、Risk Register、TTFT 腳本 | Claude Pro US$20 Agent SDK credit（不採用） |
| [`deep-research-report (3).md`](../1_ChatGPT-deep-research-report/deep-research-report%20(3).md) | ChatGPT 研究（第三輪）：權威輸入 Candidate | 五項勘誤、三機 Inventory 表、`subprocess`+`ssh.exe` 降低 ARM64 依賴、RED dialog、Minimal firewall | SQLite ≥3.53.2 的說法（本藍圖改為：先確認 runtime，patched 之前用 rollback journal） |
| `1_ChatGPT-deep-research-report/ScreenRecording_09-24-2026 07-03-57_1(1).mp4` | YouTube 影片開頭 0:00–0:52 的螢幕錄影（Jarvis 場景） | 需求意象 | —（**不上傳 GitHub**：37MB，且含電影片段的版權內容，只保留在本地） |
| YouTube `uflbrOB9ujQ` | ChatGPT Voice Mode 實測 | §13 Q4、Q5 | — |

**查閱規則**：本藍圖只寫「決策」與「差異」。細節（完整 SQL、完整 SOP、腳本）請依上表回原報告查找；如果原報告與本藍圖衝突，**以本藍圖為準**，並在 STATUS.md 的「決策紀錄」記下差異。

---

## 18. 藍圖完整性檢查（2026-09-24，Claude Code Review）

| 面向 | 狀態 | 位置 |
|---|---|---|
| 需求基線 | ✅ | §1 |
| 報告勘誤 | ✅ | §2 |
| 硬體實測與未知項 | ✅ Laptop 已測；⏳ Spark 待 P0 | §3、§14 |
| 網路隔離、升級路徑、離線供應鏈 | ✅ | §4 |
| Control Plane、`sb` CLI、雲端工人、Router | ✅ | §5 |
| 本地模型候選 | ✅（待 benchmark） | §5.4 |
| 語音（A/B/C 三階段、XVF3800） | ✅ | §6 |
| 視覺（C922 Pro） | ✅ | §7 |
| 外部資料收件（SFTP/FTP） | ✅ | §8 |
| 安全、核准、驗證、復原 | ✅（精簡版，細節見報告 (2)） | §9、§17 |
| 電力（UPS）與儲存（NAS） | ✅ | §10 |
| BOM 與成本 | ✅ | §11 |
| Phase 與 Gate | ✅ | §12、ACCEPTANCE.md |
| 驗收標準 | ✅ | ACCEPTANCE.md |
| 監控與告警、Risk | ✅ | §16 |
| 五個問題的回答 | ✅ | §13 |
| 來源索引 | ✅ | §17、§19 |
| **仍缺（刻意延後）** | Worker daemon 的 API 細節 → P8 前補；PWA 設計 → P11 前補；golden set 題目內容 → P6 需要你提供真實工作樣本；Heavy Mode 細節 → P12 | STATUS.md |

---

## 19. 來源

- 本地：`1_ChatGPT-deep-research-report/deep-research-report (1)(2)(3).md`、`ScreenRecording_09-24-2026 07-03-57_1(1).mp4`
- YouTube 字幕：https://youtu.be/uflbrOB9ujQ
- [Surface RTX Spark Dev Box – Microsoft](https://www.microsoft.com/en-us/surface/devices/surface-rtx-spark-dev-box)
- [Tom's Hardware – Surface RTX Spark Dev Box](https://www.tomshardware.com/desktops/mini-pcs/microsoft-debuts-surface-rtx-spark-dev-box-nvidia-powered-mini-pc-helps-devs-get-ready-for-an-agentic-windows)
- [Notebookcheck – Surface Laptop Ultra specs](https://www.notebookcheck.net/Surface-Laptop-Ultra-detailed-specs-upgrades-officially-revealed-A-MacBook-Pro-with-Windows-11.1314391.0.html)
- [Seeed Wiki – reSpeaker XVF3800 USB Mic Array](https://wiki.seeedstudio.com/respeaker_xvf3800_introduction/)
- [GitHub – reSpeaker XVF3800 USB 4MIC ARRAY](https://github.com/respeaker/reSpeaker_XVF3800_USB_4MIC_ARRAY)
- [Gemini CLI – Quotas and pricing](https://geminicli.com/docs/resources/quota-and-pricing/)
- [Antigravity CLI cheat sheet](https://computingforgeeks.com/antigravity-cli-cheat-sheet/)
- [Antigravity 2.0 logins, plans, quota](https://medium.com/google-cloud/unlock-antigravity-2-0-logins-plans-cost-and-quota-9165725685be)
- [sherpa-onnx](https://github.com/k2-fsa/sherpa-onnx)、[Qwen3-ASR in sherpa](https://k2-fsa.github.io/sherpa/onnx/qwen3-asr/index.html)
- [Best local voice-to-text models 2026（Breeze-ASR）](https://everydays.tools/blog/best-local-voice-to-text-models-2026)
- [NVIDIA Forum – Qwen3.8-27B on DGX Spark](https://forums.developer.nvidia.com/t/qwen3-8-27b-at-34-38-tok-s-on-dgx-spark-open-source-one-command-setup-sglang-nvfp4-dspark/380257)
- [llama.cpp on DGX Spark](https://github.com/ggml-org/llama.cpp/discussions/16578)
- [CyberPower CP1500PFCLCD](https://www.cyberpowersystems.com/product/ups/pfc-sinewave/cp1500pfclcd/)
- [Microsoft Learn – Troubleshoot SFTP with OpenSSH](https://learn.microsoft.com/en-us/troubleshoot/windows-server/system-management-components/troubleshoot-sftp-issues-using-openssh)
- [FTP vs SFTP 2026](https://www.integrate.io/blog/sftp-vs-ftp-understanding-the-difference/)
