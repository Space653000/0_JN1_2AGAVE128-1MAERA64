<#
  laptop-generate-ssh-key.ps1 — SuperBrain BLUEPRINT §4.3 / §14
  在 ULTRA-MAERA-2 上執行一次，產生給 SPARK-AGAVE-3 / SPARK-AGAVE-4 用的 SSH 金鑰。
  私鑰只留在這台機器的 %USERPROFILE%\.ssh\，永遠不進 git、不拷貝到任何 Spark。
  依無人值守的需求不設 passphrase；如果你之後想加 passphrase，改用 ssh-agent 即可。
#>

[CmdletBinding()]
param(
    [string]$KeyName = "superbrain_ed25519",
    [string]$SshDir = "$env:USERPROFILE\.ssh"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $SshDir)) {
    New-Item -ItemType Directory -Path $SshDir | Out-Null
}

$keyPath = Join-Path $SshDir $KeyName
if (Test-Path $keyPath) {
    Write-Host "金鑰已存在：$keyPath，不重新產生。若要換一把新的，先手動刪除或改 -KeyName。" -ForegroundColor Yellow
} else {
    ssh-keygen.exe -t ed25519 -f $keyPath -N '""' -C "superbrain-ultra-maera-2"
    Write-Host "已產生：$keyPath（私鑰）與 $keyPath.pub（公鑰）" -ForegroundColor Green
}

Write-Host ""
Write-Host "把下面這個公鑰檔案，用 USB 或 git clone 帶到每台 Spark，交給 spark-bootstrap.ps1 -PublicKeyPath：" -ForegroundColor Cyan
Write-Host "  $keyPath.pub"
Get-Content "$keyPath.pub"
