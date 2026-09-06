# This program converts all videos from the source directory non-paralell
# and unifies all the audio streams to one.
# You need to either create the source folder manually or run the program once.
# Requires ffmpeg to be installed: https://ffmpeg.org/

. "./helpers.ps1"

$source = ".\source"
$output = ".\converted"

New-Item -ItemType Directory -Force -Path $source | Out-Null
New-Item -ItemType Directory -Force -Path $output | Out-Null

$files = @(Get-ChildItem $source -File | Where-Object {
    $_.Extension -in ".mp4", ".mkv", ".avi", ".mov", ".webm"
})

$totalFiles = $files.Count
$currentFile = 0

$files | ForEach-Object {

    $currentFile++

    $input = $_.FullName
    $outputFile = Join-Path $output ($_.BaseName + "-converted.mp4")

    # Video duration in seconds
    $duration = ffprobe -v error `
        -show_entries format=duration `
        -of default=noprint_wrappers=1:nokey=1 `
        "$input"

    $durationTime = [TimeSpan]::FromSeconds([double]$duration)

    $audioStreams = @(ffprobe -v error `
        -select_streams a `
        -show_entries stream=index `
        -of csv=p=0 `
        "$input")

    $audioCount = $audioStreams.Count

    Write-Host ""
    Write-Host "========================================" -BackgroundColor Yellow -ForegroundColor Black
    Write-Host "File: $($_.Name)" -BackgroundColor Yellow -ForegroundColor Black
    Write-Host "Item: $currentFile / $totalFiles" -BackgroundColor Yellow -ForegroundColor Black
    Write-Host "Duration: $($durationTime.ToString('hh\:mm\:ss'))" -BackgroundColor Yellow -ForegroundColor Black
    Write-Host "Audio stream count: $audioCount" -BackgroundColor Yellow -ForegroundColor Black

    if ($audioCount -eq 0) {
        Write-Host "No audio streams, skipping!" -BackgroundColor Red -ForegroundColor White
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

    Write-Host "Filter: $audioFilter" -BackgroundColor Yellow -ForegroundColor Black
    Write-Host "Converting..." -BackgroundColor Yellow -ForegroundColor Black

    ffmpeg -i "$input" `
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
        Write-Host "Done!" -BackgroundColor Yellow
    }
    else {
        Write-Host "ERROR! Converting has failed." -BackgroundColor Red -ForegroundColor White
    }
}

Show-SpaceSaved -Files $files -OutputDirectory $output