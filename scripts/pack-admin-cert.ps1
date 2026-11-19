$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

# folder name: liangpu admin-cert (kept as code points so this file stays ASCII)
$prefix = ([string][char]0x826F) + ([string][char]0x6251) + '-' +
          ([string][char]0x7BA1) + ([string][char]0x7406) + ([string][char]0x7AEF) +
          ([string][char]0x8BC1) + ([string][char]0x4E66)

$root    = 'D:\code\liangpu'
$src     = Join-Path $root ('dist\' + $prefix)
$zipPath = Join-Path $root ('dist\' + $prefix + '.zip')
if (Test-Path -LiteralPath $zipPath) { Remove-Item -LiteralPath $zipPath -Force }

$archive = [System.IO.Compression.ZipFile]::Open($zipPath, [System.IO.Compression.ZipArchiveMode]::Create)
try {
  $stack = New-Object System.Collections.Stack
  $stack.Push(@($src, ($prefix + '/')))
  while ($stack.Count -gt 0) {
    $item = $stack.Pop()
    $dir = $item[0]
    $namePrefix = $item[1]
    foreach ($child in Get-ChildItem -LiteralPath $dir -Force) {
      $entryName = $namePrefix + $child.Name
      if ($child.PSIsContainer) {
        $stack.Push(@($child.FullName, ($entryName + '/')))
      } else {
        try {
          [void][System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
            $archive, $child.FullName, $entryName, [System.IO.Compression.CompressionLevel]::Optimal)
        } catch {
          Write-Output ('FAILED_ENTRY=' + $entryName)
          Write-Output ('FAILED_SRC=' + $child.FullName)
          throw
        }
      }
    }
  }
} finally {
  $archive.Dispose()
}

Copy-Item -LiteralPath $zipPath -Destination (Join-Path $root 'docker-data\downloads\liangpu-admin-cert.zip') -Force
$info = Get-Item -LiteralPath $zipPath
Write-Output ('OUT=' + $info.FullName)
Write-Output ('SIZE=' + $info.Length)
