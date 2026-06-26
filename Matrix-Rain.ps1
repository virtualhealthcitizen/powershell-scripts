<#
.SYNOPSIS
    "Matrix" digital rain -- falling glyph streams with bright heads and 256-colour
    fade trails, glyph flicker, colour themes, and hidden messages that decode out
    of the rain ("WAKE UP", "THE MATRIX HAS YOU", ...).

.DESCRIPTION
    Each column is an independent stream with its own speed, length and glyphs.
    The head is bright white; the trail fades through a theme palette to near
    black. Trailing glyphs occasionally mutate, and every so often a stream
    resolves into a readable message before dissolving back into noise.

    Live mode does a flicker-free full-frame ANSI redraw and needs a real
    console. -Storyboard prints frames to stdout (reproducible with -Seed).

.PARAMETER DurationSec Seconds to run live. 0 (default) = until a key is pressed.
.PARAMETER DelayMs     Milliseconds between frames. Lower = faster. Default 55.
.PARAMETER Density     Fraction of columns active (0.1 - 1.0). Default 0.7.
.PARAMETER Theme       green (default) | amber | ice | blood | rainbow.
.PARAMETER NoMessages  Disable the hidden decoded messages.
.PARAMETER NoColor     Render monochrome (for limited terminals).
.PARAMETER Storyboard  Print frames to stdout and exit.
.PARAMETER Frames      Storyboard: how many frames to print. Default 8.
.PARAMETER Seed        Fix the RNG for reproducible output. 0 = random.

.EXAMPLE
    .\Matrix-Rain.ps1
.EXAMPLE
    .\Matrix-Rain.ps1 -Theme amber -Density 0.9 -DelayMs 35
.EXAMPLE
    .\Matrix-Rain.ps1 -Storyboard -Seed 7 -Theme ice
#>
[CmdletBinding()]
param(
    [int]$DurationSec = 0,
    [int]$DelayMs     = 55,
    [ValidateRange(0.1, 1.0)][double]$Density = 0.7,
    [ValidateSet('green','amber','ice','blood','rainbow')][string]$Theme = 'green',
    [switch]$NoMessages,
    [switch]$NoColor,
    [switch]$Storyboard,
    [int]$Frames = 8,
    [int]$Seed   = 0
)

# Enable ANSI / virtual-terminal processing (Windows Terminal already has it).
if (-not $NoColor) {
    try {
        Add-Type -ErrorAction Stop @"
using System;
using System.Runtime.InteropServices;
public static class MRVT {
  [DllImport("kernel32.dll")] static extern IntPtr GetStdHandle(int n);
  [DllImport("kernel32.dll")] static extern bool GetConsoleMode(IntPtr h, out uint m);
  [DllImport("kernel32.dll")] static extern bool SetConsoleMode(IntPtr h, uint m);
  public static void Enable(){ var h=GetStdHandle(-11); uint m; if(GetConsoleMode(h,out m)) SetConsoleMode(h, m|0x0004u); }
}
"@
        [MRVT]::Enable()
    } catch { }
}

# ============================ RNG + glyphs ===================================
$seedVal = if ($Seed -gt 0) { $Seed } else { [Environment]::TickCount }
$rng = [Random]::new($seedVal)
$script:Color = -not $NoColor

$glyphList = [System.Collections.Generic.List[char]]::new()
0x30A0..0x30FF | ForEach-Object { $glyphList.Add([char]$_) }              # katakana
'0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ#$%&*+=<>?@'.ToCharArray() | ForEach-Object { $glyphList.Add($_) }
$Glyphs = $glyphList.ToArray()
function Get-Glyph { $Glyphs[$rng.Next($Glyphs.Length)] }

# 256-colour fade ramps: index 0 = bright head, last = dim tail.
$Ramps = @{
    green = @(231,48,46,40,34,28,22)
    amber = @(231,226,220,214,208,166,94)
    ice   = @(231,159,117,75,39,33,27)
    blood = @(231,224,203,196,160,124,88)
}
$RainbowCols = @(196,202,208,226,46,51,27,93,201,213)

$Messages = @('WAKE UP','THE MATRIX HAS YOU','FOLLOW THE WHITE RABBIT','KNOCK KNOCK',
              'THERE IS NO SPOON','FREE YOUR MIND','SYSTEM FAILURE','HELLO NEO','LOOK CLOSER')

# ============================ Simulation =====================================
function Init-State { param([int]$cols,[int]$rows)
    $st = [pscustomobject]@{
        W=$cols; H=$rows
        On=[bool[]]::new($cols); Y=[double[]]::new($cols); Sp=[double[]]::new($cols)
        Len=[int[]]::new($cols); Hue=[int[]]::new($cols)
        Gly=[object[]]::new($rows)
        Msgs=(New-Object System.Collections.ArrayList) }
    for ($y=0; $y -lt $rows; $y++) { $r=[char[]]::new($cols); for ($x=0;$x -lt $cols;$x++){$r[$x]=' '}; $st.Gly[$y]=$r }
    for ($x=0; $x -lt $cols; $x++) {
        $st.On[$x]  = ($rng.NextDouble() -lt $Density)
        $st.Y[$x]   = -$rng.Next(0,$rows)
        $st.Sp[$x]  = 0.25 + $rng.NextDouble()*0.95
        $st.Len[$x] = $rng.Next(5,[Math]::Max(6,$rows-2))
        $st.Hue[$x] = $RainbowCols[$rng.Next($RainbowCols.Count)] }
    $st }
function Recycle { param($st,[int]$x)
    $st.Y[$x]   = -$rng.Next(0,[int]($st.H/2))
    $st.Sp[$x]  = 0.25 + $rng.NextDouble()*0.95
    $st.Len[$x] = $rng.Next(5,[Math]::Max(6,$st.H-2))
    $st.Hue[$x] = $RainbowCols[$rng.Next($RainbowCols.Count)] }
function Step-Rain { param($st)
    for ($x=0; $x -lt $st.W; $x++) {
        if (-not $st.On[$x]) { continue }
        $prev=[int][Math]::Floor($st.Y[$x]); $st.Y[$x]+=$st.Sp[$x]; $head=[int][Math]::Floor($st.Y[$x])
        if ($head -ne $prev -and $head -ge 0 -and $head -lt $st.H) { $st.Gly[$head][$x] = Get-Glyph }
        if ($rng.NextDouble() -lt 0.12) {                                   # flicker a trailing glyph
            $r = $head - $rng.Next(0,$st.Len[$x]); if ($r -ge 0 -and $r -lt $st.H) { $st.Gly[$r][$x] = Get-Glyph } }
        if (($head - $st.Len[$x]) -gt $st.H) { Recycle $st $x } }
    if (-not $NoMessages -and $rng.NextDouble() -lt 0.045) {                 # a message tries to surface
        $m = $Messages[$rng.Next($Messages.Count)]; $vert = ($rng.Next(2) -eq 0)
        $mx = if ($vert) { $rng.Next(0,$st.W) } else { $rng.Next(0,[Math]::Max(1,$st.W-$m.Length)) }
        $my = if ($vert) { $rng.Next(1,[Math]::Max(2,$st.H-$m.Length-1)) } else { $rng.Next(1,$st.H-1) }
        [void]$st.Msgs.Add([pscustomobject]@{ X=$mx; Y=$my; Text=$m; T=$rng.Next(10,18); Vert=$vert }) }
    $keep = New-Object System.Collections.ArrayList
    foreach ($mm in $st.Msgs) { $mm.T--; if ($mm.T -gt 0) { [void]$keep.Add($mm) } }
    $st.Msgs = $keep }

function Render-Rain { param($st)
    $Ch=[object[]]::new($st.H); $Co=[object[]]::new($st.H)
    for ($y=0;$y -lt $st.H;$y++){ $rc=[char[]]::new($st.W); $cc=[int[]]::new($st.W)
        for ($x=0;$x -lt $st.W;$x++){ $rc[$x]=' '; $cc[$x]=-1 }; $Ch[$y]=$rc; $Co[$y]=$cc }
    $ramp = if ($Theme -eq 'rainbow') { $null } else { $Ramps[$Theme] }
    for ($x=0;$x -lt $st.W;$x++) {
        if (-not $st.On[$x]) { continue }
        $head=[int][Math]::Floor($st.Y[$x]); $len=$st.Len[$x]
        for ($d=0; $d -lt $len; $d++) {
            $r=$head-$d; if ($r -lt 0 -or $r -ge $st.H) { continue }
            $g=$st.Gly[$r][$x]; if ($g -eq ' ') { $g=Get-Glyph; $st.Gly[$r][$x]=$g }
            if ($ramp) { $frac=$d/[Math]::Max(1,$len-1); $col=$ramp[[int][Math]::Round($frac*($ramp.Count-1))] }
            else       { $col = if ($d -eq 0) { 231 } else { $st.Hue[$x] } }
            $Ch[$r][$x]=$g; $Co[$r][$x]=$col } }
    foreach ($m in $st.Msgs) {                                              # decoded messages in bright white
        for ($i=0;$i -lt $m.Text.Length;$i++) {
            $cx = if ($m.Vert) { $m.X } else { $m.X+$i }
            $cy = if ($m.Vert) { $m.Y+$i } else { $m.Y }
            if ($cx -ge 0 -and $cx -lt $st.W -and $cy -ge 0 -and $cy -lt $st.H) { $Ch[$cy][$cx]=$m.Text[$i]; $Co[$cy][$cx]=231 } } }
    [pscustomobject]@{ Ch=$Ch; Co=$Co; W=$st.W; H=$st.H } }

function Frame-Ansi { param($f)
    $e=[char]27; $sb=[System.Text.StringBuilder]::new()
    for ($y=0;$y -lt $f.H;$y++) { $cur=-1
        for ($x=0;$x -lt $f.W;$x++) { $ch=$f.Ch[$y][$x]
            if ($script:Color -and $ch -ne ' ') { $cc=$f.Co[$y][$x]; if ($cc -ne $cur) { [void]$sb.Append("$e[38;5;${cc}m"); $cur=$cc } }
            [void]$sb.Append($ch) }
        if ($script:Color) { [void]$sb.Append("$e[0m"); $cur=-1 }
        if ($y -lt $f.H-1) { [void]$sb.Append("`n") } }
    $sb.ToString() }
function Frame-Plain { param($f) for ($y=0;$y -lt $f.H;$y++) { -join $f.Ch[$y] } }

# ============================ STORYBOARD =====================================
if ($Storyboard) {
    $script:Color = $false
    $st = Init-State 64 22
    1..($st.H+4) | ForEach-Object { Step-Rain $st }                         # warm up so it is raining
    "#####  M A T R I X   R A I N   ($Theme)  #####"; ''
    for ($f=1; $f -le $Frames; $f++) { Step-Rain $st; "  [ frame $f ]"; Frame-Plain (Render-Rain $st); '' }
    return
}

# ============================ LIVE ===========================================
try { $cw=[Console]::WindowWidth; $chh=[Console]::WindowHeight } catch {
    Write-Warning 'Matrix-Rain needs a real console. Try: .\Matrix-Rain.ps1 -Storyboard'; return }
$cols = $cw - 1; $rows = $chh - 1                                           # spare last col/row to avoid scroll
if ($cols -lt 2 -or $rows -lt 2) { Write-Warning 'Console too small.'; return }

$prevCursor = [Console]::CursorVisible
try { [Console]::CursorVisible=$false } catch {}
Clear-Host
$st = Init-State $cols $rows
$startTicks = [Environment]::TickCount
try {
    while ($true) {
        Step-Rain $st
        [Console]::SetCursorPosition(0,0); [Console]::Out.Write((Frame-Ansi (Render-Rain $st)))
        Start-Sleep -Milliseconds $DelayMs
        if ($DurationSec -gt 0 -and ((([Environment]::TickCount-$startTicks)/1000) -ge $DurationSec)) { break }
        try { if ([Console]::KeyAvailable) { [void][Console]::ReadKey($true); break } } catch { }
    }
}
finally {
    if ($script:Color) { [Console]::Out.Write("$([char]27)[0m") }
    [Console]::ResetColor(); try { [Console]::CursorVisible=$prevCursor } catch {}
    try { [Console]::SetCursorPosition(0,$rows) } catch {}
    Write-Host "`nWake up, Neo..." -ForegroundColor Green
}
