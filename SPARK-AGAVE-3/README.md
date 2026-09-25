# SPARK-AGAVE-3 安裝 SOP

> 對應 BLUEPRINT §3.1（FAST 節點，原「Spark1」角色）、§4（隔離網路）、§4.4（離線供應鏈）、§14（Phase-0 盤點）。
> 本資料夾只給 **SPARK-AGAVE-3** 這台機器用；SPARK-AGAVE-4 用同一套腳本、換掉參數即可。
> 依 BLUEPRINT 的安全分級，`spark-bootstrap.ps1`（不含 `-KeyOnly`）屬於 YELLOW（安裝服務、改防火牆、改網卡），
> `-KeyOnly`（停用密碼登入）屬於 **RED**，一定要等 ULTRA-MAERA-2 驗證 SSH 金鑰登入成功後才執行。

## 你要準備的東西

1. 這個 repo（`git clone` 或下載這個資料夾），或用 USB 隨身碟把 `scripts/spark-bootstrap.ps1` 帶過來。
2. ULTRA-MAERA-2 的 SSH 公鑰檔（`superbrain_ed25519.pub`）。**私鑰永遠留在 ULTRA-MAERA-2，不要拷貝到 Spark。**
3. 隔離網卡（接到 2.5GbE 交換器那張）的介面名稱，用 `Get-NetAdapter` 先查（通常是 `Ethernet` 或 `Ethernet 2`）。

## 步驟

0. （建議先做）跑一鍵盤點：`.\scripts\spark-inventory.ps1 -MachineName spark-agave-3`，結果會寫到
   `C:\SuperBrain\baseline\spark-agave-3\inventory.txt`，對應 ACCEPTANCE.md P0 Gate 的證據。
1. **接螢幕鍵盤，完成 Windows 開機設定**，建立本機管理員帳號（記下帳號名稱，稍後要回報）。
2. **暫時**接上網路（家用 Router 或手機分享）：
   - 跑 Windows Update
   - 跑 NVIDIA 驅動更新
   - 執行 `wsl --install`
   - 全部裝完後，準備進入隔離狀態（下一步接回隔離交換器）。
3. 把網路線改接到 **2.5GbE 隔離交換器**（不要接家用 Router），用系統管理員 PowerShell 執行：

   ```powershell
   .\spark-bootstrap.ps1 -Name spark-agave-3 -StaticIP 10.77.0.11 `
       -IsolatedInterfaceAlias "Ethernet 2" `
       -PublicKeyPath C:\temp\superbrain_ed25519.pub
   ```

   - 如果改了電腦名稱，腳本會提示重開機；重開機後**不帶 `-Name`** 再跑一次，完成其餘設定。
   - 腳本結束時會印出這台的 IP 與目前帳號名稱 — 把這兩個告訴負責 ULTRA-MAERA-2 的人（或自己記下）。
   - 這台機器跑完之後應該**連不上網際網路**（沒有 Gateway、沒有 DNS），這是預期行為，對應 BLUEPRINT T25 驗收。

4. 在 **ULTRA-MAERA-2** 端驗證：

   ```powershell
   ssh <帳號>@10.77.0.11 hostname
   ```

   第一次連線會問 host key fingerprint，確認後應該不用密碼、直接用金鑰登入成功。

5. 驗證成功後，回到 **SPARK-AGAVE-3** 這台機器，執行：

   ```powershell
   .\spark-bootstrap.ps1 -KeyOnly
   ```

   這一步會停用密碼登入，只留金鑰登入。**做這步前務必先完成第 4 步的驗證**，不然可能把自己鎖在外面
   （螢幕鍵盤還在，仍可本機登入救援，但會多花時間）。

## 驗收（對應 ACCEPTANCE.md T04 / T25 / P2 Gate）

- [ ] `ssh <帳號>@10.77.0.11 hostname` 連續 100 次成功
- [ ] 在 SPARK-AGAVE-3 上執行 `Test-NetConnection 8.8.8.8` 與 `Resolve-DnsName microsoft.com` **必須失敗**
- [ ] 防火牆只放行 `10.77.0.1`（ULTRA-MAERA-2）的 22、30000-30010，其餘來源看不到這台機器
- [ ] 密碼登入已停用（`-KeyOnly` 執行完成）

出錯就把錯誤訊息整段貼給 Claude Code，不要自己猜著改設定。
