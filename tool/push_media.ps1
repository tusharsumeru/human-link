# push_media.ps1 — copy a photo/video from this PC into the running Android
# emulator's gallery so image_picker (New Post / New Reel) can select it.
#
# Usage (from the project root, in PowerShell):
#   .\tool\push_media.ps1 "C:\path\to\photo.jpg"
#   .\tool\push_media.ps1 "C:\path\to\clip.mp4"
#   .\tool\push_media.ps1 "C:\folder\of\media"   # pushes every image/video in it
#
# After it runs, open the app → Create → New Post / New Reel → the file is in the
# gallery, ready to pick. (You can also just drag-and-drop a file onto the
# emulator window — this script is the scripted equivalent.)

param(
  [Parameter(Mandatory = $true)]
  [string]$Path
)

$ErrorActionPreference = "Stop"

# Pick the first running emulator.
$devices = @((& adb devices) -split "`n" | Where-Object { $_ -match "emulator-\d+\s+device" })
if ($devices.Count -eq 0) { Write-Error "No running emulator found. Start it first."; exit 1 }
$serial = ($devices[0].Trim() -split "\s+")[0]
Write-Host "Using device: $serial" -ForegroundColor Cyan

# Collect files.
$imageExt = @(".jpg", ".jpeg", ".png", ".gif", ".webp", ".bmp")
$videoExt = @(".mp4", ".mov", ".mkv", ".webm", ".3gp", ".avi")
$files = @()
if (Test-Path $Path -PathType Container) {
  $files = Get-ChildItem -Path $Path -File | Where-Object {
    $imageExt -contains $_.Extension.ToLower() -or $videoExt -contains $_.Extension.ToLower()
  }
} elseif (Test-Path $Path -PathType Leaf) {
  $files = @(Get-Item $Path)
} else {
  Write-Error "Path not found: $Path"; exit 1
}
if (-not $files) { Write-Error "No image/video files found at: $Path"; exit 1 }

foreach ($f in $files) {
  $ext = $f.Extension.ToLower()
  $isVideo = $videoExt -contains $ext
  $destDir = if ($isVideo) { "/sdcard/Movies" } else { "/sdcard/Pictures" }
  $dest = "$destDir/$($f.Name)"

  & adb -s $serial push "$($f.FullName)" $dest | Out-Null
  & adb -s $serial shell "am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file://$dest" | Out-Null
  $kind = if ($isVideo) { "video" } else { "image" }
  Write-Host "  + $($f.Name)  ->  $dest  ($kind)" -ForegroundColor Green
}

Write-Host "Done. Open the app -> Create -> New Post / New Reel to pick it." -ForegroundColor Cyan
