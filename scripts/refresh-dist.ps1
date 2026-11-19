$ErrorActionPreference = 'Stop'

# 良扑 = 良(U+826F) 扑(U+6251); all names kept as code points so this file stays ASCII
$liang = [string][char]0x826F
$pu    = [string][char]0x6251
$lp    = $liang + $pu
# 使用说明.txt
$noteWin = ([string][char]0x4F7F) + ([string][char]0x7528) + ([string][char]0x8BF4) + ([string][char]0x660E) + '.txt'
# 安装说明.txt
$noteApk = ([string][char]0x5B89) + ([string][char]0x88C5) + ([string][char]0x8BF4) + ([string][char]0x660E) + '.txt'

$root = 'D:\code\liangpu'
$dist = Join-Path $root 'dist'

# ---------- Windows ----------
$rel = Join-Path $root 'app\build\windows\x64\runner\Release'
$winDir = Join-Path $dist ($lp + '-Windows-0.1.0')
$winApp = Join-Path $winDir ($lp + '-0.1.0')
if (-not (Test-Path -LiteralPath $rel)) { throw "release not found: $rel" }

New-Item -ItemType Directory -Force -Path $winApp | Out-Null
Get-ChildItem -LiteralPath $winApp -Force | Where-Object { $_.Name -ne $noteWin } | Remove-Item -Force -Recurse
Copy-Item -Path (Join-Path $rel '*') -Destination $winApp -Recurse -Force
Rename-Item -LiteralPath (Join-Path $winApp 'liangpu_app.exe') -NewName ($lp + '.exe')
Write-Output ('WIN_EXE=' + (Get-Item -LiteralPath (Join-Path $winApp ($lp + '.exe'))).Length)

$winZip = Join-Path $dist ($lp + '-Windows-0.1.0.zip')
if (Test-Path -LiteralPath $winZip) { Remove-Item -LiteralPath $winZip -Force }
Compress-Archive -Path (Join-Path $winDir '*') -DestinationPath $winZip -CompressionLevel Optimal
Write-Output ('WIN_ZIP=' + (Get-Item -LiteralPath $winZip).Length)

# ---------- Android ----------
$apkSrc = Join-Path $root 'app\build\app\outputs\flutter-apk'
$abis = @('arm64-v8a', 'armeabi-v7a', 'x86_64')
$apkPaths = @()
foreach ($abi in $abis) {
  $src = Join-Path $apkSrc ('app-' + $abi + '-release.apk')
  if (-not (Test-Path -LiteralPath $src)) { throw "apk not found: $src" }
  $dst = Join-Path $dist ($lp + '-0.1.0-' + $abi + '.apk')
  Copy-Item -LiteralPath $src -Destination $dst -Force
  $apkPaths += $dst
  Write-Output ('APK_' + $abi + '=' + (Get-Item -LiteralPath $dst).Length)
}

$apkZip = Join-Path $dist ($lp + '-Android-0.1.0.zip')
if (Test-Path -LiteralPath $apkZip) { Remove-Item -LiteralPath $apkZip -Force }
$items = @()
foreach ($p in $apkPaths) { $items += $p }
$items += (Join-Path $dist $noteApk)
Compress-Archive -Path $items -DestinationPath $apkZip -CompressionLevel Optimal
Write-Output ('APK_ZIP=' + (Get-Item -LiteralPath $apkZip).Length)

# ---------- 站点 Windows 包 ----------
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $root 'scripts\pack-windows-for-site.ps1')

# ---------- 站点 Android 包（用 ASCII 文件名，避免下载链接需要 URL 编码） ----------
$siteDl = Join-Path $root 'docker-data\downloads'
New-Item -ItemType Directory -Force -Path $siteDl | Out-Null
Copy-Item -LiteralPath (Join-Path $dist ($lp + '-0.1.0-arm64-v8a.apk')) -Destination (Join-Path $siteDl 'liangpu-android-arm64-v8a-0.1.0.apk') -Force
Copy-Item -LiteralPath $apkZip -Destination (Join-Path $siteDl 'liangpu-android-0.1.0.zip') -Force
Write-Output ('SITE_APK=' + (Get-Item -LiteralPath (Join-Path $siteDl 'liangpu-android-arm64-v8a-0.1.0.apk')).Length)
Write-Output ('SITE_APK_ZIP=' + (Get-Item -LiteralPath (Join-Path $siteDl 'liangpu-android-0.1.0.zip')).Length)
