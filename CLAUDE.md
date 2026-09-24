# CLAUDE.md：SuperBrain 專案入口

本專案是「語音多機調度的混合式 AI 系統」，由 Laptop Ultra（控制與連網）加上兩台 Surface RTX Spark（隔離、本地 AI）組成。

## 每次工作前必讀（依序）

1. [.ai/BLUEPRINT.md](.ai/BLUEPRINT.md)：**唯一藍圖依據**；與其他資料衝突時，以它為準
2. [.ai/ACCEPTANCE.md](.ai/ACCEPTANCE.md)：驗收標準，定義什麼算完成
3. [.ai/STATUS.md](.ai/STATUS.md)：已完成、施工中、未完成與阻塞項目
4. [.ai/CLAUDE_REVIEWER.md](.ai/CLAUDE_REVIEWER.md)：Claude Code 的角色（研究、規劃、Review、驗收）與禁止事項

讀完之後，先用 2–3 句話回報「目前 Phase、下一步、有哪些阻塞」，再開始工作。

## 專案規則

- 語言：繁體中文（程式碼、指令、技術名詞保留英文）；commit 訊息用英文。
- 先規劃、使用者確認後再動手；破壞性操作一律先徵求同意。
- **不要刪除** `1_ChatGPT-deep-research-report/` 或任何原有藍圖與資料。
- 大型媒體（`*.mp4` 等）不進 git，見 `.gitignore`。
- 每完成一個階段，就更新 `.ai/STATUS.md`，並把證據路徑寫進去。
- 這是 **public repo**：禁止 commit secret、內網帳號密碼、客戶資料或原始測試數據。

## 目錄

```text
CLAUDE.md                        ← 本檔（入口）
README.md                        ← 專案簡介與索引
.ai/
  BLUEPRINT.md                   ← 唯一藍圖
  ACCEPTANCE.md                  ← 驗收標準
  STATUS.md                      ← 進度
  CLAUDE_REVIEWER.md             ← Claude Code 職責
1_ChatGPT-deep-research-report/  ← 原始研究（保留，只讀）
```
