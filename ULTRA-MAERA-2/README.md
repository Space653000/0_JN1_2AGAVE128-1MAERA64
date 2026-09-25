# ULTRA-MAERA-2 安裝 SOP

> 對應 BLUEPRINT §3.1（Control Plane / Gateway，原「Laptop Ultra」角色）、§4（隔離網路）、§14（Phase-0 盤點）。
> 這台是**唯一連網**的機器，負責產生金鑰、設定隔離網卡，並在驗證每台 Spark 的 SSH 連線後，
> 由你本人核准 Spark 端執行 `-KeyOnly` 停用密碼登入（RED 動作）。

## 步驟

1. **安裝隔離用的 USB-C 2.5GbE 網卡**，接上 2.5GbE 隔離交換器（不要接家用 Router）。
2. 用系統管理員 PowerShell 執行，把網卡名稱換成 `Get-NetAdapter` 查到的實際名稱：

   ```powershell
   .\scripts\laptop-isolated-nic-setup.ps1 -IsolatedInterfaceAlias "Ethernet 3"
   ```

3. 產生 SSH 金鑰（只做一次，私鑰不進 git）：

   ```powershell
   .\scripts\laptop-generate-ssh-key.ps1
   ```

   輸出的 `%USERPROFILE%\.ssh\superbrain_ed25519.pub` 內容，帶去 SPARK-AGAVE-3 / SPARK-AGAVE-4 那邊。

4. 等每台 Spark 跑完各自的 `spark-bootstrap.ps1`（不含 `-KeyOnly`）並回報 IP 和帳號後，逐台驗證：

   ```powershell
   ssh <帳號>@10.77.0.11 hostname   # SPARK-AGAVE-3
   ssh <帳號>@10.77.0.12 hostname   # SPARK-AGAVE-4
   ```

5. 驗證成功、確認是用金鑰登入（不是密碼）之後，才通知對應的 Spark 執行 `.\spark-bootstrap.ps1 -KeyOnly`。

## 驗收（對應 ACCEPTANCE.md P2 Gate / 網路 Gate）

- [ ] `Get-NetIPInterface | Where Forwarding -eq Enabled` 結果為空（這台沒有轉送封包）
- [ ] 兩台 Spark 各自 `ssh ... hostname` 連續 100 次成功
- [ ] `ping 10.77.0.11` / `ping 10.77.0.12` 各 1000 次，0% loss
- [ ] 已跑過 iperf3 基準（`network-baseline.csv`，見 ACCEPTANCE.md）

## 安全備忘

- 私鑰只在這台機器的 `.ssh\` 目錄，不設 passphrase 是為了無人值守；因此**這台機器本身的帳號登入與磁碟加密要顧好**。
- 這個資料夾裡不會、也不應該出現任何私鑰或已產生的公鑰內容——那是這台機器的本地產物，不是 repo 的一部分。
- 之後若要透過 iPhone 遠端操作（P11），走 Tailscale，只到這台機器，不直接到 Spark（見 BLUEPRINT §4.1 拓撲）。
