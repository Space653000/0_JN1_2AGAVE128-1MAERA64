# SPARK-AGAVE-4 安裝 SOP

> 對應 BLUEPRINT §3.1（DEEP 節點，原「Spark2」角色）、§4（隔離網路）、§4.4（離線供應鏈）、§14（Phase-0 盤點）。
> 本資料夾只給 **SPARK-AGAVE-4** 這台機器用；步驟與 SPARK-AGAVE-3 完全相同，只是機器名稱與 IP 不同。
> 依 BLUEPRINT 的安全分級，`spark-bootstrap.ps1`（不含 `-KeyOnly`）屬於 YELLOW（安裝服務、改防火牆、改網卡），
> `-KeyOnly`（停用密碼登入）屬於 **RED**，一定要等 ULTRA-MAERA-2 驗證 SSH 金鑰登入成功後才執行。

## 你要準備的東西

1. 這個 repo（`git clone` 或下載這個資料夾），或用 USB 隨身碟把 `scripts/spark-bootstrap.ps1` 帶過來。
2. ULTRA-MAERA-2 的 SSH 公鑰檔（`superbrain_ed25519.pub`）。**私鑰永遠留在 ULTRA-MAERA-2，不要拷貝到 Spark。**
3. 隔離網卡（接到 2.5GbE 交換器那張）的介面名稱，用 `Get-NetAdapter` 先查。

## 步驟

0. （建議先做）跑一鍵盤點：`.\scripts\spark-inventory.ps1 -MachineName spark-agave-4`，結果會寫到
   `C:\SuperBrain\baseline\spark-agave-4\inventory.txt`，對應 ACCEPTANCE.md P0 Gate 的證據。
1. **接螢幕鍵盤，完成 Windows 開機設定**，建立本機管理員帳號（記下帳號名稱，稍後要回報）。
2. **暫時**接上網路：跑 Windows Update、NVIDIA 驅動更新、執行 `wsl --install`。全部裝完後準備接回隔離交換器。
3. 把網路線改接到 **2.5GbE 隔離交換器**，用系統管理員 PowerShell 執行：

   ```powershell
   .\spark-bootstrap.ps1 -Name spark-agave-4 -StaticIP 10.77.0.12 `
       -IsolatedInterfaceAlias "Ethernet 2" `
       -PublicKeyPath C:\temp\superbrain_ed25519.pub
   ```

   - 改名後依提示重開機，重開機後**不帶 `-Name`** 再跑一次。
   - 結束時印出的 IP 與帳號名稱，告訴負責 ULTRA-MAERA-2 的人。
   - 跑完後這台應該**連不上網際網路**，屬預期行為（T25）。

4. 在 **ULTRA-MAERA-2** 端驗證：

   ```powershell
   ssh <帳號>@10.77.0.12 hostname
   ```

5. 驗證成功後，回到 **SPARK-AGAVE-4**，執行：

   ```powershell
   .\spark-bootstrap.ps1 -KeyOnly
   ```

   停用密碼登入前務必先完成第 4 步驗證。

## 驗收（對應 ACCEPTANCE.md T05 / T25 / P2 Gate）

- [ ] `ssh <帳號>@10.77.0.12 hostname` 連續 100 次成功
- [ ] `Test-NetConnection 8.8.8.8` 與 `Resolve-DnsName microsoft.com` **必須失敗**
- [ ] 防火牆只放行 `10.77.0.1` 的 22、30000-30010
- [ ] 密碼登入已停用

出錯就把錯誤訊息整段貼給 Claude Code，不要自己猜著改設定。

## 先後順序提醒

依 BLUEPRINT §4.4 維護窗口 SOP，**一次只更新一台**：先做完 SPARK-AGAVE-3 並穩定幾天後，再做這台。
不要兩台同時暫時連網做 Windows Update。
