# This program checks if the files in a folder has been converted with the converter.
# Requires ffmpeg to be installed: https://ffmpeg.org/

$folder = ".\source"

Get-ChildItem $folder -File -Recurse | ForEach-Object {

    $file = $_.FullName

    $videoCodec = ffprobe -v error `
        -select_streams v:0 `
        -show_entries stream=codec_name `
        -of csv=p=0 `
        "$file"

    $audioCodec = ffprobe -v error `
        -select_streams a:0 `
        -show_entries stream=codec_name `
        -of csv=p=0 `
        "$file"

    if ($videoCodec -ne "hevc" -or $audioCodec -ne "aac") {
        $sizeMB = [math]::Round($_.Length / 1MB, 2)

        Write-Host "$($_.FullName)" -BackgroundColor Yellow  -ForegroundColor Black
        Write-Host "  Size: ${sizeMB} MB" -BackgroundColor Yellow  -ForegroundColor Black
        Write-Host "  Video: $videoCodec" -BackgroundColor Yellow  -ForegroundColor Black
        Write-Host "  Audio: $audioCodec" -BackgroundColor Yellow  -ForegroundColor Black
        Write-Host ""
    }
}