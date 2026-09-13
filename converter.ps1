# This program converts all videos from the source directory non-paralell
# and unifies all the audio streams to one.
# You need to either create the source folder manually or run the program once.
# Requires ffmpeg to be installed: https://ffmpeg.org/

. "./helpers.ps1"

$source = ".\source"
$output = ".\converted"

New-Item -ItemType Directory -Force -Path $source | Out-Null
New-Item -ItemType Directory -Force -Path $output | Out-Null

$files = @(Get-ChildItem $source -File -Recurse | Where-Object {
        $_.Extension -in ".mp4", ".mkv", ".avi", ".mov", ".webm"
    })

$totalFiles = $files.Count
$currentFile = 0

$files | ForEach-Object {

    $currentFile++

    $fileInput = $_.FullName

    $outputFile = Join-Path $output ($_.BaseName + "-converted.mp4")

    # Video duration in seconds
    $duration = ffprobe -v error `
        -show_entries format=duration `
        -of default=noprint_wrappers=1:nokey=1 `
        "$fileInput"

    $durationTime = [TimeSpan]::FromSeconds([double]$duration)

    $audioStreams = @(ffprobe -v error `
            -select_streams a `
            -show_entries stream=index `
            -of csv=p=0 `
            "$fileInput")

    $audioCount = $audioStreams.Count

    $durationString = Format-Duration `
        -hours $durationTime.Hours `
        -minutes $durationTime.Minutes `
        -seconds $durationTime.Seconds

    Write-Info "File: $($_.Name)"
    Write-Info "Item: $currentFile / $totalFiles"
    Write-Info "Duration: $durationString"
    Write-Info "Audio stream count: $audioCount"

    if ($audioCount -eq 0) {
        Write-Error "No audio streams, skipping!"

        return
    }

    if ($audioCount -eq 1) {
        $audioFilter = "[0\:a:0]anull[a]"
    }
    else {
        $inputs = ""

        for ($i = 0; $i -lt $audioCount; $i++) {
            $inputs += "[0:a:$i]"
        }

        $audioFilter = "${inputs}amix=inputs=${audioCount}:duration=longest[a]"
    }

    # Write-Info "Filter: $audioFilter"
    Write-Info "Converting..."

    ffmpeg -i "$fileInput" `
        -map 0:v:0 `
        -filter_complex "$audioFilter" `
        -map "[a]" `
        -c:v libx265 `
        -preset medium `
        -crf 28 `
        -c:a aac `
        -b:a 128k `
        "$outputFile"

    if ($LASTEXITCODE -eq 0) {
        Write-Success "File conversion successful!"
    }
    else {
        Write-Error "Converting has failed"
    }
}

if ($LASTEXITCODE -eq 0) {
    Write-Success "All file conversion finished!"
    Show-SpaceSaved -Files $files -OutputDirectory $output
}