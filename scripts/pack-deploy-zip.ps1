$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$liang = [string][char]0x826F
$pu    = [string][char]0x6251
$svc   = ([string][char]0x670D) + ([string][char]0x52A1) + ([string][char]0x7AEF)
$note  = ([string][char]0x90E8) + ([string][char]0x7F72) + ([string][char]0x8BF4) + ([string][char]0x660E) + '.txt'

$root = 'D:\code\liangpu'
$outDir = Join-Path $root 'dist'
$zipPath = Join-Path $outDir ($liang + $pu + '-' + $svc + '-Docker-0.1.0.zip')
if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force }

$archive = [System.IO.Compression.ZipFile]::Open($zipPath, [System.IO.Compression.ZipArchiveMode]::Create)

function Add-Entry([string]$rel) {
  $full = Join-Path $root ($rel -replace '/', '\')
  if (-not (Test-Path -LiteralPath $full)) {
    Write-Output ('MISSING ' + $rel)
    return
  }
  [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
    $archive, $full, $rel, [System.IO.Compression.CompressionLevel]::Optimal)
}

function Add-Tree([string]$rel, [string]$full) {
  foreach ($child in Get-ChildItem -LiteralPath $full -Force) {
    if ($child.PSIsContainer) {
      if ($child.Name -eq 'node_modules') { continue }
      if ($child.Name -eq 'dist' -and ($rel -eq 'admin' -or $rel -eq 'server')) { continue }
      if ($child.Name -eq 'data' -and $rel -eq 'server') { continue }
      Add-Tree ($rel + '/' + $child.Name) $child.FullName
    } else {
      Add-Entry ($rel + '/' + $child.Name)
    }
  }
}

try {
  Add-Entry '.dockerignore'
  Add-Entry 'Dockerfile'
  Add-Entry 'compose.yaml'
  Add-Entry '.env.example'
  Add-Entry 'docker-entrypoint.sh'
  Add-Entry 'README.md'
  Add-Entry $note
  Add-Tree 'admin' (Join-Path $root 'admin')
  Add-Tree 'docs' (Join-Path $root 'docs')
  Add-Tree 'scripts' (Join-Path $root 'scripts')
  Add-Tree 'server' (Join-Path $root 'server')
} finally {
  $archive.Dispose()
}

$info = Get-Item -LiteralPath $zipPath
Write-Output ('OUT=' + $info.FullName)
Write-Output ('SIZE=' + $info.Length)
