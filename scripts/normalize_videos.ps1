param(
  [string]$InputDir = "assets/videos",
  [string]$OutputDir = "assets/videos_ascii",
  [string]$JsonPath = "assets/mock/videos.json",
  [switch]$UpdateJson,
  [switch]$RenameInPlace
)

function Test-Command {
  param([string]$Name)
  $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

$ffmpegPath = "C:\Users\trae\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-7.0.1-full_build\bin\ffmpeg.exe"

if (-not $RenameInPlace.IsPresent) {
  if (-not (Test-Path $ffmpegPath)) {
    Write-Host "ERROR: ffmpeg.exe not found at specified path: $ffmpegPath" -ForegroundColor Red
    exit 1
  }
}

if (-not (Test-Path $InputDir)) { Write-Host "InputDir not found: $InputDir" -ForegroundColor Red; exit 1 }
New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

function Sanitize-FileName {
  param([string]$Name)
  $safe = ($Name -replace "[^A-Za-z0-9_.-]", "_")
  if ($safe.Length -gt 128) { $safe = $safe.Substring(0,128) }
  return $safe
}

${existing} = Get-ChildItem -Path $OutputDir -Filter *.mp4 -File | Select-Object -ExpandProperty Name

$map = @{}
if ($RenameInPlace.IsPresent) {
  Get-ChildItem -Path $InputDir -Filter *.mp4 -File | ForEach-Object {
    $src = $_.FullName
    $base = Sanitize-FileName $_.BaseName
    $newName = "$base.mp4"
    $i = 1
    while ((Test-Path (Join-Path $InputDir $newName)) -and ($_.Name -ne $newName)) { $newName = "$base`_$i.mp4"; $i++ }
    $map[$_.Name] = $newName
    if ($_.Name -eq $newName) {
      Write-Host "SKIP same name: $newName"
    } else {
      Write-Host "Renaming: $($_.Name) -> $newName"
      Rename-Item -LiteralPath $src -NewName $newName
    }
  }
} else {
  Get-ChildItem -Path $InputDir -Filter *.mp4 -File | ForEach-Object {
    $src = $_.FullName
    $base = Sanitize-FileName $_.BaseName
    $outName = "$base.mp4"
    $i = 1
    while ($existing -contains $outName) { $outName = "$base`_$i.mp4"; $i++ }
    $existing += $outName
    $dst = Join-Path $OutputDir $outName
    $map[$_.Name] = $outName
    if (Test-Path $dst) {
      Write-Host "SKIP existing: $outName"
    } else {
      Write-Host "Transcoding: $($_.Name) -> $outName"
      $ffmpegArgs = @(
          "-i", $src,
          "-c:v", "libx264",
          "-profile:v", "high",
          "-level", "4.1",
          "-pix_fmt", "yuv420p",
          "-c:a", "aac",
          "-b:a", "128k",
          "-movflags", "+faststart",
          "-y",
          $dst
      )
      & $ffmpegPath @ffmpegArgs *> d:\douyin_demo\ffmpeg_log.txt
      if ($LASTEXITCODE -ne 0) { Write-Host "ffmpeg failed for: $($_.Name)" -ForegroundColor Red }
    }
  }
}

if ($UpdateJson.IsPresent -and (Test-Path $JsonPath)) {
  Write-Host "Updating JSON: $JsonPath"
  $json = Get-Content $JsonPath -Encoding UTF8 -Raw | ConvertFrom-Json
  $targetDir = $OutputDir
  if ($RenameInPlace.IsPresent) { $targetDir = $InputDir }
  foreach ($item in $json) {
    $old = Split-Path $item.videoUrl -Leaf
    if ($map.ContainsKey($old)) {
      $item.videoUrl = Join-Path $targetDir $map[$old]
      $item.videoUrl = $item.videoUrl -replace "\\", "/"
    }
  }
  ($json | ConvertTo-Json -Depth 6) | Set-Content $JsonPath -Encoding UTF8
  Write-Host "JSON updated"
}

if ($RenameInPlace.IsPresent) {
  Write-Host "Done. Renamed in place under: $InputDir"
} else {
  Write-Host "Done. Output dir: $OutputDir"
}