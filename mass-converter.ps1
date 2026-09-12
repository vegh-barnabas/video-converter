# This program finds videos that have not been converted yet,
# stores them in a text file, and converts them one by one.
#
# Requires ffmpeg and ffprobe to be installed.

$source = "F:\Videók\"
$listFile = ".\state\conversion-list.txt"

# Collects and outputs invalid video files into a file
$invalidListFile = ".\state\invalid-files.txt"
$invalidFiles = @()

# List your excluded folders relatively to the $source
# Leave it empty if you would like to convert everything
$excludedFolders = @(
  "NeKonvertald"
  "Filmek\Maradjon"
  "Sorozatok\Kihagyas"
)

$videoExtensions = @(
  ".mp4",
  ".mkv",
  ".avi",
  ".mov",
  ".webm"
)

# [INFO]: Checking files
# [ERROR]: Asd
# [SUCCESS]: Fgh

# ============================================================
# STEP 1 - CHECK FILES
# ============================================================

Write-Host ""
Write-Host "========================================" `
  -BackgroundColor Cyan `
  -ForegroundColor Black

Write-Host "CHECKING FILES" `
  -BackgroundColor Cyan `
  -ForegroundColor Black

Write-Host "========================================" `
  -BackgroundColor Cyan `
  -ForegroundColor Black


$files = @(Get-ChildItem $source -File -Recurse | Where-Object {

    if ($_.Extension.ToLower() -notin $videoExtensions) {
      return $false
    }

    $relativePath = $_.FullName.Substring($source.Length).TrimStart('\')
    $relativeDirectory = Split-Path $relativePath -Parent

    foreach ($excludedFolder in $excludedFolders) {

      if (
        $relativeDirectory -eq $excludedFolder -or
        $relativeDirectory.StartsWith("$excludedFolder\")
      ) {
        return $false
      }
    }

    return $true
  })

$filesToConvert = @()

foreach ($file in $files) {

  $videoCodec = ffprobe -v error `
    -select_streams v:0 `
    -show_entries stream=codec_name `
    -of csv=p=0 `
    "$($file.FullName)" 2>$null

  if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($videoCodec)) {

    Write-Host ""
    Write-Host "INVALID VIDEO:" -ForegroundColor Red
    Write-Host $file.FullName -ForegroundColor Red

    $invalidFiles += $file.FullName

    continue
  }


  $audioCodec = ffprobe -v error `
    -select_streams a:0 `
    -show_entries stream=codec_name `
    -of csv=p=0 `
    "$($file.FullName)" 2>$null

  if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($audioCodec)) {

    Write-Host ""
    Write-Host "INVALID VIDEO / AUDIO:" -ForegroundColor Red
    Write-Host $file.FullName -ForegroundColor Red

    $invalidFiles += $file.FullName

    continue
  }


  if ($videoCodec -ne "hevc" -or $audioCodec -ne "aac") {
    $filesToConvert += $file.FullName
  }
}

if ($invalidFiles.Count -gt 0) {

  $invalidFiles | Set-Content `
    -Path $invalidListFile `
    -Encoding UTF8

  Write-Host ""
  Write-Host "========================================" `
    -BackgroundColor Red `
    -ForegroundColor White

  Write-Host "INVALID VIDEOS: $($invalidFiles.Count)" `
    -BackgroundColor Red `
    -ForegroundColor White

  Write-Host "List saved to: $invalidListFile" `
    -ForegroundColor Red

  Write-Host "========================================" `
    -BackgroundColor Red `
    -ForegroundColor White

}
else {

  Clear-Content `
    -Path $invalidListFile `
    -ErrorAction SilentlyContinue
}


# ============================================================
# STEP 2 - CREATE LIST
# ============================================================

if ($filesToConvert.Count -gt 0) {

  $filesToConvert | Set-Content `
    -Path $listFile `
    -Encoding UTF8

  Write-Host ""
  Write-Host "Files requiring conversion: $($filesToConvert.Count)" `
    -ForegroundColor Yellow

  Write-Host "List saved to: $listFile" `
    -ForegroundColor Gray
}
else {

  # Empty the list if everything is already converted
  Clear-Content `
    -Path $listFile `
    -ErrorAction SilentlyContinue

  Write-Host ""
  Write-Host "All files are already converted." `
    -ForegroundColor Green

  exit
}


# ============================================================
# STEP 3 - CONVERT
# ============================================================

Write-Host ""
Write-Host "========================================" `
  -BackgroundColor Yellow `
  -ForegroundColor Black

Write-Host "STARTING CONVERSION" `
  -BackgroundColor Yellow `
  -ForegroundColor Black

Write-Host "========================================" `
  -BackgroundColor Yellow `
  -ForegroundColor Black


while ($true) {

  # Read current list
  $lines = @(Get-Content $listFile -Encoding UTF8)

  # Remove empty lines
  $lines = @($lines | Where-Object {
      -not [string]::IsNullOrWhiteSpace($_)
    })

  if ($lines.Count -eq 0) {
    break
  }


  # ========================================================
  # Take the LAST item
  # ========================================================

  $input = $lines[-1]

  Write-Host ""
  Write-Host "========================================" `
    -BackgroundColor Yellow `
    -ForegroundColor Black

  Write-Host "Remaining: $($lines.Count)" `
    -BackgroundColor Yellow `
    -ForegroundColor Black

  Write-Host "File:" `
    -BackgroundColor Yellow `
    -ForegroundColor Black

  Write-Host "$input" `
    -ForegroundColor Cyan


  # ========================================================
  # Check that the file still exists
  # ========================================================

  if (-not (Test-Path $input)) {

    Write-Host ""
    Write-Host "ERROR: File does not exist!" `
      -BackgroundColor Red `
      -ForegroundColor White

    Write-Host "Keeping it in the list." `
      -ForegroundColor Yellow

    break
  }


  $inputFile = Get-Item $input


  # ========================================================
  # Output file
  # ========================================================

  $outputFile = Join-Path `
    $inputFile.DirectoryName `
  ($inputFile.BaseName + "-converted.mp4")


  # ========================================================
  # Video duration
  # ========================================================

  $duration = ffprobe -v error `
    -show_entries format=duration `
    -of default=noprint_wrappers=1:nokey=1 `
    "$input"

  $durationTime = [TimeSpan]::FromSeconds(
    [double]$duration
  )


  # ========================================================
  # Audio streams
  # ========================================================

  $audioStreams = @(ffprobe -v error `
      -select_streams a `
      -show_entries stream=index `
      -of csv=p=0 `
      "$input")

  $audioCount = $audioStreams.Count


  Write-Host ""
  Write-Host "Duration: $($durationTime.ToString('hh\:mm\:ss'))" `
    -ForegroundColor Gray

  Write-Host "Audio stream count: $audioCount" `
    -ForegroundColor Gray

  Write-Host "Output: $outputFile" `
    -ForegroundColor Gray


  # ========================================================
  # No audio
  # ========================================================

  if ($audioCount -eq 0) {

    Write-Host ""
    Write-Host "No audio streams, skipping!" `
      -BackgroundColor Red `
      -ForegroundColor White

    break
  }


  # ========================================================
  # Create audio filter
  # ========================================================

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


  Write-Host ""
  Write-Host "Filter: $audioFilter" `
    -ForegroundColor Gray

  Write-Host "Converting..." `
    -BackgroundColor Yellow `
    -ForegroundColor Black


  # ========================================================
  # Convert
  # ========================================================

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


  # ========================================================
  # Check result
  # ========================================================

  if ($LASTEXITCODE -eq 0 -and (Test-Path $outputFile)) {

    Write-Host ""
    Write-Host "DONE!" `
      -BackgroundColor Green `
      -ForegroundColor Black


    # ====================================================
    # Remove successfully converted item from the list
    # ====================================================

    $remainingLines = @(
      $lines | Select-Object -SkipLast 1
    )

    if ($remainingLines.Count -gt 0) {

      $remainingLines |
      Set-Content `
        -Path $listFile `
        -Encoding UTF8

    }
    else {

      Clear-Content `
        -Path $listFile `
        -ErrorAction SilentlyContinue
    }

  }
  else {

    Write-Host ""
    Write-Host "ERROR! Converting has failed." `
      -BackgroundColor Red `
      -ForegroundColor White

    Write-Host ""
    Write-Host "The file remains in the list." `
      -ForegroundColor Yellow

    break
  }
}


# ============================================================
# FINISHED
# ============================================================

$remaining = @(
  Get-Content $listFile -Encoding UTF8 |
  Where-Object {
    -not [string]::IsNullOrWhiteSpace($_)
  }
)

Write-Host ""
Write-Host "========================================" `
  -ForegroundColor DarkGreen

Write-Host "PROCESS FINISHED" `
  -ForegroundColor DarkGreen

Write-Host "Remaining files: $($remaining.Count)" `
  -ForegroundColor $(if ($remaining.Count -eq 0) {
    "Green"
  }
  else {
    "Yellow"
  })

Write-Host "List: $listFile" `
  -ForegroundColor Gray

Write-Host "========================================" `
  -ForegroundColor DarkGreen