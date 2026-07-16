# scripts/move_wallpapers.ps1
# Recurse through STEAL folder, find all images/videos, and move them to STEAL/WALLPAPER

$targetDir = "d:\WebProjects\icarus-ui\STEAL\WALLPAPER"
if (-not (Test-Path $targetDir)) {
    New-Item -ItemType Directory -Path $targetDir | Out-Null
}

$extensions = @("*.jpg", "*.jpeg", "*.png", "*.gif", "*.mp4", "*.webm")
$files = Get-ChildItem -Path "d:\WebProjects\icarus-ui\STEAL" -Recurse -File -Include $extensions

$movedCount = 0
foreach ($file in $files) {
    # Skip if file is already inside the target WALLPAPER directory
    if ($file.FullName.StartsWith($targetDir)) {
        continue
    }

    $destPath = Join-Path $targetDir $file.Name
    $count = 1
    $baseName = $file.BaseName
    $ext = $file.Extension

    # Solve filename collisions by appending index
    while (Test-Path $destPath) {
        $destPath = Join-Path $targetDir "${baseName}_${count}${ext}"
        $count++
    }

    try {
        Move-Item -Path $file.FullName -Destination $destPath -Force -ErrorAction Stop
        $movedCount++
    } catch {
        Write-Warning "Failed to move: $($file.FullName) -> $_"
    }
}

Write-Output "Successfully moved $movedCount wallpaper files to STEAL/WALLPAPER"
