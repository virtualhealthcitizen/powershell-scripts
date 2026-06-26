<#
.SYNOPSIS
    Animated ASCII-art seal that claps its flippers.

.DESCRIPTION
    Renders two alternating frames in the console so a happy seal claps.
    The eyes squint and a "CLAP!" pops up on every clap (with an optional beep).

.PARAMETER Claps
    Number of claps to perform. 0 (default) loops forever until you press Q or Ctrl+C.

.PARAMETER DelayMs
    Milliseconds each frame is held. Smaller = faster clapping. Default 300.

.PARAMETER Silent
    Suppress the beep on each clap.

.EXAMPLE
    .\Clap-Seal.ps1

.EXAMPLE
    .\Clap-Seal.ps1 -Claps 8 -DelayMs 200 -Silent
#>
[CmdletBinding()]
param(
    [int]$Claps   = 0,
    [int]$DelayMs = 300,
    [switch]$Silent
)

# --- Frame 1: flippers OUT (eyes open) ---------------------------------------
$open = @'
            .-""""-.
          .'        '.
         /   o    o   \
        |      __      |
        |     (  )     |
         \    '--'    /
          '.        .'
         _/'-.____.-'\_
        /              \
      _( )            ( )_
     (___)            (___)
'@

# --- Frame 2: flippers IN, mid-clap (eyes squint) ----------------------------
$closed = @'
            .-""""-.
          .'        '.
         /   ^    ^   \
        |      __      |
        |     (  )     |
         \    '--'    /
          '.        .'
         _/'-.____.-'\_
        /              \
        \    ( )( )    /     CLAP!
         '--(___)(___)--'
'@

function Show-Frame {
    param([string]$Art)
    Clear-Host
    Write-Host ''
    Write-Host $Art -ForegroundColor Cyan
    Write-Host ''
    Write-Host '   ~ press Q to stop ~' -ForegroundColor DarkGray
}

# Hide the cursor for a cleaner animation; restore it on the way out.
$prevCursor = [Console]::CursorVisible
try { [Console]::CursorVisible = $false } catch { }

$count = 0
try {
    while ($true) {
        Show-Frame $open
        Start-Sleep -Milliseconds $DelayMs

        Show-Frame $closed
        if (-not $Silent) { [Console]::Beep(880, 80) }
        Start-Sleep -Milliseconds $DelayMs

        $count++
        if ($Claps -gt 0 -and $count -ge $Claps) { break }

        # Non-blocking quit check.
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            if ($key.Key -eq 'Q' -or
                ($key.Modifiers -band [ConsoleModifiers]::Control -and $key.Key -eq 'C')) {
                break
            }
        }
    }
}
finally {
    try { [Console]::CursorVisible = $prevCursor } catch { }
    Write-Host ''
    Write-Host "   That's all, folks. ($count claps)" -ForegroundColor Yellow
}