#Requires -RunAsAdministrator
<#
  spark-bootstrap.ps1 — SuperBrain BLUEPRINT §4.2 / §4.4 / §14
  在 SPARK-AGAVE-3 / SPARK-AGAVE-4 上執行。依藍圖的隔離 LAN 設計：
    - 只允許 ULTRA-MAERA-2（10.77.0.1）連入 SSH（22）與模型 API（30000-30010）
    - 不設 Default Gateway、不設 DNS（讓 Spark 保持斷網，符合 T25 驗收）
    - 先用密碼登入驗證成功，再用 -KeyOnly 停用密碼登入（RED 動作，需你本人核准後才執行）

  用法：
    .\spark-bootstrap.ps1 -Name spark-agave-3 -StaticIP 10.77.0.11 `
        -IsolatedInterfaceAlias "Ethernet 2" -PublicKeyPath C:\temp\superbrain_ed25519.pub

    # 從 ULTRA-MAERA-2 驗證 `ssh <帳號>@10.77.0.11 hostname` 成功後，再執行：
    .\spark-bootstrap.ps1 -KeyOnly
#>

[CmdletBinding()]
param(
    [string]$Name,
    [string]$StaticIP,
    [string]$IsolatedInterfaceAlias,
    [string]$PublicKeyPath,
    [switch]$KeyOnly
)

$ErrorActionPreference = "Stop"
$LaptopIP = "10.77.0.1"   # ULTRA-MAERA-2，唯一允許連入這台 Spark 的來源

function Write-Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }
function Write-Warn2($msg) { Write-Host "!! $msg" -ForegroundColor Yellow }

# ---------------------------------------------------------------------------
# -KeyOnly：只做「停用密碼登入」這一件事，前提是你已經在 ULTRA-MAERA-2
# 用密碼成功 SSH 進來過，不然會把自己鎖在外面。
# ---------------------------------------------------------------------------
if ($KeyOnly) {
    Write-Step "停用 SSH 密碼登入，只留金鑰登入"
    $sshdConfig = "$env:ProgramData\ssh\sshd_config"
    if (-not (Test-Path $sshdConfig)) {
        throw "找不到 $sshdConfig，OpenSSH Server 似乎還沒安裝，請先不帶 -KeyOnly 跑一次。"
    }

    $content = Get-Content $sshdConfig
    $content = $content -replace '^#?\s*PasswordAuthentication\s+.*', 'PasswordAuthentication no'
    $content = $content -replace '^#?\s*PubkeyAuthentication\s+.*', 'PubkeyAuthentication yes'
    if ($content -notmatch '^PasswordAuthentication\s+no') {
        $content += "PasswordAuthentication no"
    }
    if ($content -notmatch '^PubkeyAuthentication\s+yes') {
        $content += "PubkeyAuthentication yes"
    }
    Set-Content -Path $sshdConfig -Value $content -Encoding ASCII

    Restart-Service sshd
    Write-Host "完成。密碼登入已停用，只能用金鑰登入這台機器。" -ForegroundColor Green
    exit 0
}

# ---------------------------------------------------------------------------
# 1. 可選：改電腦名稱（會要求重開機，重開機後不要帶 -Name 再跑一次）
# ---------------------------------------------------------------------------
if ($Name -and $env:COMPUTERNAME -ne $Name) {
    Write-Step "改電腦名稱為 $Name（需要重開機）"
    Rename-Computer -NewName $Name -Force
    Write-Warn2 "電腦名稱已排入變更，請重新開機後、不帶 -Name 參數再執行一次本腳本，完成其餘設定。"
    exit 0
}

# ---------------------------------------------------------------------------
# 2. 安裝並啟動 OpenSSH Server
# ---------------------------------------------------------------------------
Write-Step "安裝並啟動 OpenSSH Server"
$capability = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'
if ($capability.State -ne 'Installed') {
    Add-WindowsCapability -Online -Name $capability.Name
}
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic

# ---------------------------------------------------------------------------
# 3. 防火牆：只允許 ULTRA-MAERA-2（10.77.0.1）連入 SSH 與模型 API
# ---------------------------------------------------------------------------
Write-Step "設定防火牆，只允許 $LaptopIP 連入 22、30000-30010"

Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue |
    Disable-NetFirewallRule -ErrorAction SilentlyContinue

$ruleName = 'SuperBrain-SSH-From-Laptop'
if (-not (Get-NetFirewallRule -Name $ruleName -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -Name $ruleName -DisplayName $ruleName `
        -Direction Inbound -Protocol TCP -LocalPort 22 `
        -RemoteAddress $LaptopIP -Action Allow | Out-Null
}

$apiRuleName = 'SuperBrain-ModelAPI-From-Laptop'
if (-not (Get-NetFirewallRule -Name $apiRuleName -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -Name $apiRuleName -DisplayName $apiRuleName `
        -Direction Inbound -Protocol TCP -LocalPort 30000-30010 `
        -RemoteAddress $LaptopIP -Action Allow | Out-Null
}

# ---------------------------------------------------------------------------
# 4. 隔離網卡：靜態 IP，不設 Gateway、不設 DNS（符合 T25：Spark 不能出網）
# ---------------------------------------------------------------------------
if ($StaticIP -and $IsolatedInterfaceAlias) {
    Write-Step "設定隔離網卡 [$IsolatedInterfaceAlias] 為 $StaticIP/24，無 Gateway、無 DNS"
    $existing = Get-NetIPAddress -InterfaceAlias $IsolatedInterfaceAlias -AddressFamily IPv4 -ErrorAction SilentlyContinue
    $existing | Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
    New-NetIPAddress -InterfaceAlias $IsolatedInterfaceAlias -IPAddress $StaticIP -PrefixLength 24 | Out-Null
    Set-DnsClientServerAddress -InterfaceAlias $IsolatedInterfaceAlias -ResetServerAddresses
    Set-DnsClient -InterfaceAlias $IsolatedInterfaceAlias -RegisterThisConnectionsAddress $false
} else {
    Write-Warn2 "沒有帶 -StaticIP / -IsolatedInterfaceAlias，略過網卡設定，請自行依 BLUEPRINT §4.1 手動設定。"
}

# ---------------------------------------------------------------------------
# 5. 放入 ULTRA-MAERA-2 的公鑰（管理員帳號用 administrators_authorized_keys）
# ---------------------------------------------------------------------------
if ($PublicKeyPath) {
    Write-Step "放入公鑰：$PublicKeyPath"
    if (-not (Test-Path $PublicKeyPath)) {
        throw "找不到公鑰檔案：$PublicKeyPath"
    }
    $authKeysPath = "$env:ProgramData\ssh\administrators_authorized_keys"
    Copy-Item $PublicKeyPath $authKeysPath -Force
    # 依 Microsoft OpenSSH 文件鎖權限，只留 SYSTEM 與 Administrators
    icacls.exe $authKeysPath /inheritance:r | Out-Null
    icacls.exe $authKeysPath /grant "SYSTEM:F" "Administrators:F" | Out-Null
} else {
    Write-Warn2 "沒有帶 -PublicKeyPath，請手動把 ULTRA-MAERA-2 的公鑰放進 administrators_authorized_keys。"
}

Restart-Service sshd

# ---------------------------------------------------------------------------
# 6. 印出結果
# ---------------------------------------------------------------------------
Write-Step "完成。以下資訊請回報給 ULTRA-MAERA-2 那邊："
Write-Host "  電腦名稱   : $env:COMPUTERNAME"
Write-Host "  目前帳號   : $env:USERDOMAIN\$env:USERNAME"
if ($StaticIP) { Write-Host "  隔離網 IP  : $StaticIP" }
Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '127.*' } |
    Format-Table InterfaceAlias, IPAddress -AutoSize

Write-Warn2 "下一步：在 ULTRA-MAERA-2 執行 `ssh <帳號>@<IP> hostname` 驗證成功後，回來這台跑 .\spark-bootstrap.ps1 -KeyOnly 停用密碼登入。"
