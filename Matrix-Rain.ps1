<#
.SYNOPSIS
    "Matrix" digital rain in the console — falling streams of glyphs with
    glowing white heads and fading green trails.

.DESCRIPTION
    Each column is an independent falling stream with its own speed and trail
    length. The head is bright white, the character just behind it green, and
    the rest of the trail persists as green until the tail erases it. Rendering
    uses direct cursor positioning (no Clear-Host) so the rain flows smoothly.

    Requires a real interactive console (Windows Terminal / conhost / pwsh
    window). It will not work with redirected/captured output.

.PARAMETER DurationSec
    Seconds to run. 0 (default) runs until you press a key.

.PARAMETER DelayMs
    Milliseconds between frames. Lower = faster rain. Default 45.

.PARAMETER Density
    Fraction of columns active as rain streams (0.1 - 1.0). Default 0.7.

.EXAMPLE
    .\Matrix-Rain.ps1

.EXAMPLE
    .\Matrix-Rain.ps1 -DurationSec 10 -DelayMs 30 -Density 0.9
#>
[CmdletBinding()]
param(
    [int]$DurationSec = 0,
    [int]$DelayMs     = 45,
    [ValidateRange(0.1, 1.0)][double]$Density = 0.7
)

# --- Build the glyph pool: katakana + digits + a few symbols ------------------
$glyphs = [System.Collections.Generic.List[char]]::new()
0x30A0..0x30FF | ForEach-Object { $glyphs.Add([char]$_) }
'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ#$%&*+=<>?@'.ToCharArray() |
    ForEach-Object { $glyphs.Add($_) }
$rand = [Random]::new()
function Get-Glyph { $glyphs[$rand.Next($glyphs.Count)] }

# --- Console geometry --------------------------------------------------------
try {
    $w = [Console]::WindowWidth  - 1   # leave last column to avoid auto-scroll
    $h = [Console]::WindowHeight - 1
} catch {
    Write-Warning 'Matrix-Rain needs a real interactive console (not redirected output).'
    return
}
if ($w -lt 2 -or $h -lt 2) { Write-Warning 'Console too small.'; return }

# --- Per-column state --------------------------------------------------------
$colY     = New-Object 'double[]' $w   # head position (fractional for sub-step speed)
$colSpeed = New-Object 'double[]' $w   # rows advanced per frame
$colLen   = New-Object 'int[]'    $w   # trail length
$colOn    = New-Object 'bool[]'   $w   # is this column an active stream?

for ($x = 0; $x -lt $w; $x++) {
    $colOn[$x]    = ($rand.NextDouble() -lt $Density)
    $colY[$x]     = -$rand.Next(0, $h)              # stagger start above screen
    $colSpeed[$x] = 0.25 + $rand.NextDouble() * 0.9 # varied fall speeds
    $colLen[$x]   = $rand.Next(4, [Math]::Max(5, $h - 2))
}

# --- Setup terminal ----------------------------------------------------------
$prevCursor = [Console]::CursorVisible
[Console]::CursorVisible = $false
Clear-Host
$startTicks = [Environment]::TickCount

try {
    while ($true) {
        for ($x = 0; $x -lt $w; $x++) {
            if (-not $colOn[$x]) { continue }

            $prevHead = [int][Math]::Floor($colY[$x])
            $colY[$x] += $colSpeed[$x]
            $head      = [int][Math]::Floor($colY[$x])
            if ($head -eq $prevHead) { continue }   # not moved a whole row yet

            # bright white head
            if ($head -ge 0 -and $head -le $h) {
                [Console]::SetCursorPosition($x, $head)
                [Console]::ForegroundColor = 'White'
                [Console]::Write((Get-Glyph))
            }
            # the char just behind the head cools to green
            if ($prevHead -ge 0 -and $prevHead -le $h) {
                [Console]::SetCursorPosition($x, $prevHead)
                [Console]::ForegroundColor = 'Green'
                [Console]::Write((Get-Glyph))
            }
            # erase the tail
            $tail = $head - $colLen[$x]
            if ($tail -ge 0 -and $tail -le $h) {
                [Console]::SetCursorPosition($x, $tail)
                [Console]::Write(' ')
            }
            # recycle the stream once its tail clears the bottom
            if ($tail -gt $h) {
                $colY[$x]     = -$rand.Next(0, [int]($h / 2))
                $colSpeed[$x] = 0.25 + $rand.NextDouble() * 0.9
                $colLen[$x]   = $rand.Next(4, [Math]::Max(5, $h - 2))
            }
        }

        Start-Sleep -Milliseconds $DelayMs

        if ($DurationSec -gt 0 -and
            (([Environment]::TickCount - $startTicks) / 1000) -ge $DurationSec) { break }

        try { if ([Console]::KeyAvailable) { [void][Console]::ReadKey($true); break } } catch { }
    }
}
finally {
    [Console]::ResetColor()
    [Console]::CursorVisible = $prevCursor
    [Console]::SetCursorPosition(0, $h)
    Write-Host "`nWake up, Neo..." -ForegroundColor Green
}