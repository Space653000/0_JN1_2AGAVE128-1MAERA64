#Requires -RunAsAdministrator
<#
  laptop-inventory.ps1 — 一鍵盤點 ULTRA-MAERA-2（BLUEPRINT.md §14）
  下載後直接在系統管理員 PowerShell 執行：

    .\laptop-inventory.ps1

  結果會寫到 C:\SuperBrain\baseline\ultra-maera-2\，對應 ACCEPTANCE.md P0 Gate 的證據路徑。
#>

[CmdletBinding()]
param(
    [string]$OutDir = "C:\SuperBrain\baseline\ultra-maera-2"
)

$ErrorActionPreference = "Continue"
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

"SuperBrain Laptop (ULTRA-MAERA-2) Inventory — $(Get-Date -Format o)" | Out-File -FilePath $report -Encoding UTF8

Add-Section "ComputerInfo" { Get-ComputerInfo | Select-Object OsName, OsBuildNumber, CsProcessors, CsSystemType }
Add-Section "CPU" { Get-CimInstance Win32_Processor | Select-Object Name, Architecture, NumberOfCores }
Add-Section "GPU (nvidia-smi)" { nvidia-smi -q }
Add-Section "Memory" { Get-CimInstance Win32_ComputerSystem | Select-Object TotalPhysicalMemory }
Add-Section "Disk" { Get-PhysicalDisk; Get-Volume }
Add-Section "USB Controllers" { Get-PnpDevice | Where-Object FriendlyName -match 'USB4|Thunderbolt' }
Add-Section "NetAdapter" { Get-NetAdapter | Select-Object Name, InterfaceDescription, LinkSpeed, MacAddress }
Add-Section "WSL" { wsl --status; wsl -l -v }
Add-Section "SQLite runtime (if sqlite3.exe on PATH)" { sqlite3 --version }
Add-Section "CLI versions" {
    "python: $(python --version 2>&1)"
    "node:   $(node --version 2>&1)"
    "gh:     $(gh --version 2>&1)"
    "codex:  $(codex --version 2>&1)"
    "claude: $(claude --version 2>&1)"
    "agy:    $(agy --version 2>&1)"
}
Add-Section "危險環境變數檢查（不應該存在，避免意外走 API 計費）" {
    "ANTHROPIC_API_KEY set: $([bool]$env:ANTHROPIC_API_KEY)"
    "OPENAI_API_KEY set:    $([bool]$env:OPENAI_API_KEY)"
}
Add-Section "Tailscale" { tailscale status }
Add-Section "IP Forwarding（BLUEPRINT §4.2 要求必須為空）" {
    Get-NetIPInterface | Where-Object Forwarding -eq 'Enabled'
}
Add-Section "Power" { powercfg /a }

Write-Host "完成，結果在：$report" -ForegroundColor Green
Write-Host "請把這個檔案的內容回報，或直接把整個 $OutDir 資料夾附上。" -ForegroundColor Cyan
