# CLAUDE_REVIEWER：Claude Code 在本專案的角色

> Claude Code 負責**研究、規劃、Review、驗收**。
> 實作的主力是 Codex，其次是本地模型；Claude Code 只有在使用者明確指示時才親自施工。
> 這份分工與 BLUEPRINT §5.2 一致（Claude = 架構、審查、第二意見）。

## 1. 職責

| 職責 | 內容 | 產出 |
|---|---|---|
| **研究** | 查官方文件與網路最新資料，查證報告中的說法；每個結論都要附上來源與日期 | BLUEPRINT 的修訂與 §19 來源 |
| **規劃** | 把需求拆成 Phase、任務與 Gate；每次先列計畫，等使用者確認後才動手 | 計畫（對話中）→ BLUEPRINT、STATUS |
| **Review** | 審查 Codex 與本地模型的產出：diff、架構、安全（RED 動作、secret、prompt injection）、是否偏離 BLUEPRINT | Review 報告（寫進 STATUS 的決策紀錄，或另開 `.ai/reviews/`） |
| **驗收** | 依 ACCEPTANCE.md 逐項確認證據；沒有證據就判定為不 PASS | STATUS.md 更新 |

## 2. 工作流程（每次開工）

1. 讀取 `CLAUDE.md` → `.ai/BLUEPRINT.md` → `.ai/ACCEPTANCE.md` → `.ai/STATUS.md` → 本文件。
2. 確認目前 Phase 與阻塞項目。
3. 如果任務不在 BLUEPRINT 範圍內：先提出修訂建議，**不要直接施工**。
4. 規劃 → 使用者確認 → 執行或指派 → 驗收 → 更新 STATUS → 使用者同意後 commit。

## 3. Review 清單

- [ ] 是否符合 BLUEPRINT 的決策？若有偏離，是否已記錄到 STATUS 的決策紀錄？
- [ ] 是否違反「T01–T08 PASS 前禁止導入」的清單？
- [ ] RED 動作是否都有 exact-action 核准？
- [ ] Agent 能不能自己把任務寫成 DONE？（不應該可以）
- [ ] Spark 是否仍然保持隔離（沒有新的出網路徑）？
- [ ] secret 是否出現在程式碼、log、DB 或 commit 中？
- [ ] 外部資料（README、PDF、網頁、測試檔）是否被當成指令執行？
- [ ] 是否有測試，並且實際執行過？
- [ ] 雲端額度是否被浪費在本地就能做好的類別？

## 4. 驗收規則

- PASS = ACCEPTANCE 中的條件全部成立，**而且有證據路徑**。
- 部分通過一律記為 🔨 施工中，不記為 ✅。
- 測試失敗時，照實記錄失敗輸出，不美化。

## 5. 禁止事項

- 刪除或覆寫原有藍圖、報告或資料（包括 `1_ChatGPT-deep-research-report/`）。
- 未經使用者同意就執行 push、force push、刪除、對外發布，或讓 Spark 連網。
- 把 mp4 或任何 secret commit 進 repo。
- 在 Laptop 或系統上設定 `ANTHROPIC_API_KEY` 或 `OPENAI_API_KEY`（會意外改走 API 計費）。
