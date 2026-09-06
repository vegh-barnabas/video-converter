# This program checks if the video files in a folder have been converted with the converter.
# Requires ffmpeg to be installed: https://ffmpeg.org/

$folder = ".\source"

$videoExtensions = @(
    ".mp4",
    ".mkv",
    ".avi",
    ".mov",
    ".webm"
)

$files = Get-ChildItem $folder -File -Recurse | Where-Object {
    $_.Extension.ToLower() -in $videoExtensions
}

$currentDirectory = ""

$files | ForEach-Object {

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

        # Print directory name only when it changes
        if ($_.DirectoryName -ne $currentDirectory) {
            $currentDirectory = $_.DirectoryName

            Write-Host ""
            Write-Host "========================================" `
                -BackgroundColor Cyan `
                -ForegroundColor Black

            Write-Host "$currentDirectory" `
                -BackgroundColor Cyan `
                -ForegroundColor Black
        }

        # Print only filename
        Write-Host "  $($_.Name)" -ForegroundColor Yellow
    }
}