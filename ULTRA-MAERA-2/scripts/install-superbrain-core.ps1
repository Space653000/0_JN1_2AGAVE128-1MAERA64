#Requires -RunAsAdministrator
<#
  install-superbrain-core.ps1 — 一鍵安裝 SuperBrain Core（P4 骨架）
  在 ULTRA-MAERA-2 上，系統管理員 PowerShell 執行，不需要額外步驟：

    .\install-superbrain-core.ps1

  它會：建立 C:\SuperBrain、建立 venv、裝依賴、初始化 SQLite（種入三台機器）、
  跑一次 pytest 自我驗證、印出 `sb workers`。
  來源程式碼從這個 repo 的 ULTRA-MAERA-2\superbrain-core 複製過來；
  用 git clone 這個 repo 到本機，或用 USB 把整個 ULTRA-MAERA-2 資料夾帶過來即可。
#>

[CmdletBinding()]
param(
    [string]$InstallRoot = "C:\SuperBrain",
    [string]$SourceDir = (Join-Path $PSScriptRoot "..\superbrain-core")
)

$ErrorActionPreference = "Stop"
function Write-Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }

if (-not (Test-Path $SourceDir)) {
    throw "找不到原始碼資料夾：$SourceDir。請確認整個 ULTRA-MAERA-2 資料夾（含 superbrain-core）都在本機上。"
}

Write-Step "檢查 Python"
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
    throw "找不到 python，請先安裝 Python 3.12（ARM64），並確認在 PATH 中。"
}

Write-Step "建立 $InstallRoot 並複製原始碼"
New-Item -ItemType Directory -Force -Path $InstallRoot | Out-Null
$coreDir = Join-Path $InstallRoot "superbrain-core"
Copy-Item -Path $SourceDir -Destination $coreDir -Recurse -Force

Write-Step "建立 venv"
$venvDir = Join-Path $InstallRoot "venv"
if (-not (Test-Path $venvDir)) {
    python -m venv $venvDir
}
$venvPython = Join-Path $venvDir "Scripts\python.exe"

Write-Step "安裝依賴"
& $venvPython -m pip install --quiet --upgrade pip
& $venvPython -m pip install --quiet -r (Join-Path $coreDir "requirements.txt")

Write-Step "初始化 SQLite（種入 ultra-maera-2 / spark-agave-3 / spark-agave-4）並自我驗證（pytest）"
Push-Location $coreDir
try {
    & $venvPython -m pytest -q
    if ($LASTEXITCODE -ne 0) {
        throw "pytest 沒有全數通過，請把上面的輸出貼給 Claude Code。"
    }

    $env:SUPERBRAIN_DB = Join-Path $InstallRoot "state.db"
    $env:SUPERBRAIN_AUDIT_LOG = Join-Path $InstallRoot "audit.jsonl"
    & $venvPython -m sb.cli workers
} finally {
    Pop-Location
}

Write-Step "完成。之後執行 sb 指令範例："
Write-Host "  `$env:SUPERBRAIN_DB = '$InstallRoot\state.db'"
Write-Host "  `$env:SUPERBRAIN_AUDIT_LOG = '$InstallRoot\audit.jsonl'"
Write-Host "  $venvPython -m sb.cli status"
