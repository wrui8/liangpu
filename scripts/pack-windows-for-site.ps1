$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

# 良扑 = 良(U+826F) 扑(U+6251), kept as code points so this file stays ASCII
$liang = [string][char]0x826F
$pu    = [string][char]0x6251
# 使用说明.txt = 使(U+4F7F) 用(U+7528) 说(U+8BF4) 明(U+660E)
$note  = ([string][char]0x4F7F) + ([string][char]0x7528) + ([string][char]0x8BF4) + ([string][char]0x660E) + '.txt'

$root   = 'D:\code\liangpu'
$src    = Join-Path $root ('dist\' + $liang + $pu + '-Windows-0.1.0\' + $liang + $pu + '-0.1.0')
$outDir = Join-Path $root 'docker-data\downloads'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$zipPath = Join-Path $outDir 'liangpu-windows-0.1.0.zip'
if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force }

if (-not (Test-Path -LiteralPath $src)) { throw "source not found: $src" }

$archive = [System.IO.Compression.ZipFile]::Open($zipPath, [System.IO.Compression.ZipArchiveMode]::Create)
try {
  $stack = New-Object System.Collections.Stack
  $stack.Push(@($src, ''))
  while ($stack.Count -gt 0) {
    $item = $stack.Pop()
    $dir = $item[0]
    $prefix = $item[1]
    foreach ($child in Get-ChildItem -LiteralPath $dir -Force) {
      $name = $prefix + $child.Name
      if ($child.PSIsContainer) {
        $stack.Push(@($child.FullName, ($name + '/')))
      } else {
        if ($child.Name -eq $note) { continue }
        [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
          $archive, $child.FullName, $name, [System.IO.Compression.CompressionLevel]::Optimal)
      }
    }
  }
} finally {
  $archive.Dispose()
}

$info = Get-Item -LiteralPath $zipPath
Write-Output ('OUT=' + $info.FullName)
Write-Output ('SIZE=' + $info.Length)
