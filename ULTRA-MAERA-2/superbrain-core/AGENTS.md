# SuperBrain 規則（給 Codex）

> 來源：BLUEPRINT.md §5.1。此檔要放在 `C:\SuperBrain\AGENTS.md`，讓 ChatGPT 桌面版 Voice 的後端（Codex）知道該呼叫 `sb`。

- 任何涉及 SPARK-AGAVE-3、SPARK-AGAVE-4、多機、長任務、測試數據分析的需求：一律執行 `sb submit "<原話>"`，不要自己 SSH。
- 使用者問「現在在幹嘛／進度」：執行 `sb status`，用一句中文唸出結果。
- 不得執行 `sb approve`。核准只能由使用者在 Dashboard 或手機上點選。
- `sb` 回傳 WAITING_APPROVAL 時，把 approval 內容原文唸給使用者。
