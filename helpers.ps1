function Show-SpaceSaved {
    param (
        [array]$Files,
        [string]$OutputDirectory
    )

    $originalSize = 0
    $convertedSize = 0

    foreach ($file in $Files) {
        $originalSize += $file.Length

        $convertedFile = Join-Path $OutputDirectory ($file.BaseName + "-converted.mp4")

        if (Test-Path $convertedFile) {
            $convertedSize += (Get-Item $convertedFile).Length
        }
    }

    $savedBytes = $originalSize - $convertedSize

    Write-Host ""
    Write-Host "========================================" -BackgroundColor Green -ForegroundColor Black
    Write-Host "CONVERSION FINISHED" -BackgroundColor Green -ForegroundColor Black
    Write-Host "Original size:  $([math]::Round($originalSize / 1GB, 2)) GB" -BackgroundColor Green -ForegroundColor Black
    Write-Host "Converted size: $([math]::Round($convertedSize / 1GB, 2)) GB" -BackgroundColor Green -ForegroundColor Black

    if ($savedBytes -ge 0) {
        Write-Host "Space saved:    $([math]::Round($savedBytes / 1GB, 2)) GB" -BackgroundColor Green -ForegroundColor Black
    }
    else {
        Write-Host "Space increased: $([math]::Round([math]::Abs($savedBytes) / 1GB, 2)) GB" -BackgroundColor Red -ForegroundColor White
    }
}