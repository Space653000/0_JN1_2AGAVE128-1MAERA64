#Requires -RunAsAdministrator
<#
  spark-inventory.ps1 — 一鍵盤點 Spark 機器（BLUEPRINT.md §14）
  在 SPARK-AGAVE-3 或 SPARK-AGAVE-4 上，系統管理員 PowerShell 執行：

    .\spark-inventory.ps1 -MachineName spark-agave-3

  結果寫到 C:\SuperBrain\baseline\<MachineName>\，對應 ACCEPTANCE.md P0 Gate 的證據路徑。
  功耗量測（待機／FAST／DEEP 三種狀態）需要插座功率計，本腳本無法自動做，請手動記錄。
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$MachineName
)

$ErrorActionPreference = "Continue"
$OutDir = "C:\SuperBrain\baseline\$MachineName"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$report = Join-Path $OutDir "inventory.txt"

function Add-Section($title, [scriptblock]$block) {
    "`r`n=== $title ===" | Out-File -Append -FilePath $report -Encoding UTF8
    try {
        & $block | Out-File -Append -FilePath $report -Encoding UTF8
    } catch {
        "ERROR: $_" | Out-File -Append -FilePath $report -Encoding UTF8
    }
}

"SuperBrain Spark ($MachineName) Inventory — $(Get-Date -Format o)" | Out-File -FilePath $report -Encoding UTF8

Add-Section "ComputerInfo" { Get-ComputerInfo | Select-Object OsName, OsBuildNumber, CsProcessors }
Add-Section "CPU" { Get-CimInstance Win32_Processor | Select-Object Name, Architecture, NumberOfCores }
Add-Section "NetAdapter（找 Ethernet 速度、ConnectX）" {
    Get-NetAdapter | Select-Object Name, InterfaceDescription, LinkSpeed, MacAddress
}
Add-Section "Mellanox/ConnectX/QSFP（未公開前禁止假設有）" {
    Get-PnpDevice | Where-Object FriendlyName -match 'Mellanox|ConnectX|QSFP'
}
Add-Section "Disk" { Get-PhysicalDisk; Get-Volume }
Add-Section "GPU (nvidia-smi)" { nvidia-smi -q }
Add-Section "WSL" { wsl --status; wsl -l -v }
Add-Section "WSL 內盤點（uname/os-release/free/df/nvidia-smi/docker）" {
    wsl -- bash -lc "uname -m; cat /etc/os-release; free -h; df -h; nvidia-smi; docker version"
}
Add-Section "Power" { powercfg /a }
Add-Section "隔離驗收（T25，跑完 spark-bootstrap.ps1 之後應該都要失敗）" {
    "Test-NetConnection 8.8.8.8:"
    Test-NetConnection 8.8.8.8 -InformationLevel Quiet
    "Resolve-DnsName microsoft.com:"
    try { Resolve-DnsName microsoft.com -ErrorAction Stop } catch { "失敗（預期行為）: $_" }
}

Write-Host "完成，結果在：$report" -ForegroundColor Green
Write-Host "功耗（待機/FAST/DEEP）請用插座功率計手動量測並記錄到同一個資料夾。" -ForegroundColor Yellow
