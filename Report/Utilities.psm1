function BarGraphZeroToTen ([int] $value) {
    $clnValue = $value
    $clnValue = [math]::Min($clnValue, 10)
    $clnValue = [math]::Max($clnValue, 0)

    for ($i = 0; $i -lt $clnValue; $i++) {
        if ($i -le 3) {
            $color = "Green"
        }
        elseif ($i -le 7) {
            $color = "Yellow"
        }
        else {
            $color = "Red"
        }
        Write-Host -NoNewline -ForegroundColor $color "#"
    }
    for ($i = $clnValue; $i -lt 10; $i++) {
        Write-Host -NoNewline -ForegroundColor DarkGray "#"
    }

    Write-Host -NoNewline " ($($clnValue * 10)%)"
}