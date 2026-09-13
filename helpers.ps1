function Write-Info {
    param (
        [string]$Message
    )

    Write-Host "[INFO]" -ForegroundColor Cyan -NoNewline
    Write-Host " $Message"
}

function Write-Error {
    param (
        [string]$Message
    )

    Write-Host "[ERROR]" -ForegroundColor Red -NoNewline
    Write-Host " $Message"
}

function Write-Success {
    param (
        [string]$Message
    )

    Write-Host "[SUCCESS]" -ForegroundColor Green -NoNewline
    Write-Host " $Message"
}

function Write-Warning {
    param (
        [string]$Message
    )

    Write-Host "[WARNING]" -ForegroundColor DarkYellow -NoNewline
    Write-Host " $Message"
}

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

    Write-Success "Original size:  $([math]::Round($originalSize / 1GB, 2)) GB"
    Write-Success "Converted size: $([math]::Round($convertedSize / 1GB, 2)) GB"
    
    if ($savedBytes -ge 0) {
        Write-Success "Space saved:    $([math]::Round($savedBytes / 1GB, 2)) GB"
    }
    else {
        Write-Warning "Space increased: $([math]::Round([math]::Abs($savedBytes) / 1GB, 2)) GB"
    }
}

function Format-Duration {
    param (
        [int]$hours,
        [int]$minutes,
        [int]$seconds
    )

    $parts = @()

    if ($hours -gt 0) {
        $parts += "$hours hours"
    }

    if ($minutes -gt 0) {
        $parts += "$minutes minutes"
    }

    $parts += "$seconds seconds"

    return $parts -join " "
}