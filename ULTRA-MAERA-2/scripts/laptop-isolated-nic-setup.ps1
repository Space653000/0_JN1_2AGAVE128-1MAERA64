#Requires -RunAsAdministrator
<#
  laptop-isolated-nic-setup.ps1 — SuperBrain BLUEPRINT §4.1 / §4.2
  在 ULTRA-MAERA-2 上執行，把接到隔離交換器的那張 USB-C 2.5GbE 網卡設成
  10.77.0.1/24、無 Gateway，並確認這台機器沒有把封包從一張網卡轉送到另一張
  （不能變成 Spark 的跳板）。
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$IsolatedInterfaceAlias
)

$ErrorActionPreference = "Stop"
$LaptopIsolatedIP = "10.77.0.1"

function Write-Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }

Write-Step "設定 [$IsolatedInterfaceAlias] 為 $LaptopIsolatedIP/24，不設 Gateway"
Get-NetIPAddress -InterfaceAlias $IsolatedInterfaceAlias -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue
New-NetIPAddress -InterfaceAlias $IsolatedInterfaceAlias -IPAddress $LaptopIsolatedIP -PrefixLength 24 | Out-Null
Set-DnsClientServerAddress -InterfaceAlias $IsolatedInterfaceAlias -ResetServerAddresses

Write-Step "確認 Internet Connection Sharing 沒有把這張卡當跳板"
Write-Host "請手動檢查『網路連線』設定裡，這張卡的內容 -> 共用 分頁，確保『允許其他網路使用者透過本電腦連線』未勾選。"

Write-Step "驗證：目前所有網卡的 IP Forwarding 狀態（BLUEPRINT 要求全部為 Disabled）"
Get-NetIPInterface | Where-Object Forwarding -eq 'Enabled' | Format-Table -AutoSize
Write-Host "上面若有任何一列輸出，代表有轉送風險，需要處理（正常應該是空的）。" -ForegroundColor Yellow

Write-Step "完成。下一步：在這台機器跑 .\laptop-generate-ssh-key.ps1，再把公鑰帶去各台 Spark。"
