<#
.SYNOPSIS
    A clapping ASCII seal... and the standing ovation it earns.

.DESCRIPTION
    The seal claps. The crowd notices. An APPLAUSE-O-METER fills, and as the
    hype climbs the show escalates through tiers -- warming up -> BIG APPLAUSE
    -> STANDING OVATION -> *** ENCORE!!! *** -- with rising clap pitch,
    accelerating tempo, colour-cycling, raining confetti, floating crowd
    reactions (BRAVO! / 10/10 / GOAT), and starstruck eyes. Hit the target (or
    peak the meter) and the seal takes a bow under a confetti cannon.

    Everything composites onto a per-cell canvas, so confetti falls *in front
    of* the seal and you can line up a whole clapping chorus (-Seals).

    Live mode needs a real console. -Storyboard prints a representative montage
    of escalating frames to stdout instead (no animation / sound).

.PARAMETER Claps      Claps before the finale. 0 (default) = until you press Q.
.PARAMETER DelayMs    Base ms per frame. Tempo accelerates with hype. Default 300.
.PARAMETER Silent     Suppress the [Console]::Beep applause + fireworks.
.PARAMETER Seals      How many seals in the chorus line (clamped to fit). Default 1.
.PARAMETER NoConfetti Disable the confetti cannon.
.PARAMETER Storyboard Print a static escalation montage to stdout.
.PARAMETER Seed       Fix the RNG for reproducible output. 0 = random.

.EXAMPLE
    .\Clap-Seal.ps1
.EXAMPLE
    .\Clap-Seal.ps1 -Claps 20 -Seals 3
.EXAMPLE
    .\Clap-Seal.ps1 -Storyboard -Seed 7
#>
[CmdletBinding()]
param(
    [int]$Claps    = 0,
    [int]$DelayMs  = 300,
    [switch]$Silent,
    [int]$Seals    = 1,
    [switch]$NoConfetti,
    [switch]$Storyboard,
    [int]$Seed     = 0
)

# ============================ RNG + helpers ==================================
$seedVal = if ($Seed -gt 0) { $Seed } else { [Environment]::TickCount }
$rng = [Random]::new($seedVal)
function Pick { param($a) $a[$rng.Next($a.Count)] }
$script:Silent = [bool]$Silent
function Beep { param([int]$f,[int]$ms) if (-not $script:Silent) { try { [Console]::Beep($f,$ms) } catch {} } }

# ============================ Stage geometry =================================
$W = 70; $H = 22

# ============================ Canvas =========================================
# Per-cell char + colour grid so seal / confetti / meter / reactions composite.
function New-Canvas {
    $ch = [object[]]::new($H); $co = [object[]]::new($H)
    for ($y=0; $y -lt $H; $y++) {
        $ch[$y] = (' ' * $W).ToCharArray()
        $row = [string[]]::new($W)
        for ($x=0; $x -lt $W; $x++) { $row[$x] = 'DarkGray' }
        $co[$y] = $row }
    [pscustomobject]@{ Ch=$ch; Co=$co } }
function Set-Px { param($cv,[int]$x,[int]$y,[char]$c,[string]$col)
    if ($x -lt 0 -or $x -ge $W -or $y -lt 0 -or $y -ge $H) { return }
    $cv.Ch[$y][$x]=$c; $cv.Co[$y][$x]=$col }
function Write-Text { param($cv,[int]$x,[int]$y,[string]$s,[string]$col)
    for ($i=0; $i -lt $s.Length; $i++) { Set-Px $cv ($x+$i) $y $s[$i] $col } }
function Center-X { param([string]$s) [Math]::Max(0,[int](($W-$s.Length)/2)) }
function Stamp { param($cv,[int]$x,[int]$y,[string]$art,[string]$col)   # spaces are transparent
    $lines = $art -split "\r?\n"
    for ($r=0; $r -lt $lines.Count; $r++) {
        $ln=$lines[$r]
        for ($i=0; $i -lt $ln.Length; $i++) { if ($ln[$i] -ne ' ') { Set-Px $cv ($x+$i) ($y+$r) $ln[$i] $col } } } }
function Art-Width { param([string]$art) (($art -split "\r?\n") | Measure-Object -Property Length -Maximum).Maximum }
function Render-Live { param($cv)
    Clear-Host
    for ($y=0; $y -lt $H; $y++) {
        $x=0
        while ($x -lt $W) {                                  # run-length encode each row by colour
            $col=$cv.Co[$y][$x]; $run=''
            while ($x -lt $W -and $cv.Co[$y][$x] -eq $col) { $run += $cv.Ch[$y][$x]; $x++ }
            Write-Host $run -NoNewline -ForegroundColor $col }
        Write-Host '' } }
function Render-Plain { param($cv) for ($y=0; $y -lt $H; $y++) { -join $cv.Ch[$y] } }

# ============================ The seal (eyes templated) ======================
$SealOpen = @'
            .-""""-.
          .'        '.
         /   {E}    {E}   \
        |      __      |
        |     (  )     |
         \    '--'    /
          '.        .'
         _/'-.____.-'\_
        /              \
      _( )            ( )_
     (___)            (___)
'@
$SealClap = @'
            .-""""-.
          .'        '.
         /   {E}    {E}   \
        |      __      |
        |     (  )     |
         \    '--'    /
          '.        .'
         _/'-.____.-'\_
        /              \
        \    ( )( )    /
         '--(___)(___)--'
'@
function Eye-For { param([string]$pose,[string]$tier)        # starstruck at the top
    if ($tier -eq 'ENCORE') { '*' }
    elseif ($pose -eq 'clap') { '^' }                        # squint on the clap
    elseif ($tier -in 'BIG','OVATION') { '^' }
    else { 'o' } }
function Seal-Frame { param([string]$pose,[string]$eye)
    $art = if ($pose -eq 'clap') { $SealClap } else { $SealOpen }
    $art.Replace('{E}',$eye) }

# ============================ Hype tiers =====================================
function Hype-Tier { param([double]$hp)                       # NB: $h would alias $H (case-insensitive!)
    if    ($hp -ge 1.0)  { 'ENCORE'  } elseif ($hp -ge 0.75) { 'OVATION' }
    elseif($hp -ge 0.50) { 'BIG'     } elseif ($hp -ge 0.25) { 'WARM'    } else { 'COLD' } }
$TierInfo = @{
    COLD    = @{ Label='warming up...';        Col='DarkCyan'; Cols=@('DarkCyan','Gray');                          Crowd=@('.','*','clap') }
    WARM    = @{ Label='nice clap!';           Col='Cyan';     Cols=@('Cyan','White','DarkCyan');                  Crowd=@('clap','*clap*','yay','nice') }
    BIG     = @{ Label='BIG APPLAUSE';         Col='Green';    Cols=@('Green','Cyan','White');                     Crowd=@('WOO','nice!','clap clap','yeah') }
    OVATION = @{ Label='STANDING OVATION';     Col='Yellow';   Cols=@('Yellow','White','Cyan','Green');            Crowd=@('BRAVO','WOW','10/10','*cheers*','yes!') }
    ENCORE  = @{ Label='*** ENCORE!!! ***';    Col='Magenta';  Cols=@('Red','Yellow','Green','Cyan','Magenta','White'); Crowd=@('ENCORE','BRAVO!','MORE!','GOAT','LEGEND') }
}

# ============================ Particles ======================================
$script:Conf  = New-Object System.Collections.ArrayList
$script:React = New-Object System.Collections.ArrayList
$ConfChars = @('*','+','.',"'",'o','x','^','"')
function Spawn-Confetti { param([int]$n,$cols)
    for ($i=0; $i -lt $n; $i++) {
        [void]$script:Conf.Add([pscustomobject]@{ X=$rng.Next($W); Y=$rng.Next(0,3); C=(Pick $ConfChars); Col=(Pick $cols) }) } }
function Step-Confetti {
    $keep = New-Object System.Collections.ArrayList
    foreach ($p in $script:Conf) {
        $p.Y += 1; $p.X += $rng.Next(-1,2)
        if ($p.Y -lt ($H-1) -and $p.X -ge 0 -and $p.X -lt $W) { [void]$keep.Add($p) } }
    $script:Conf = $keep }
function Draw-Confetti { param($cv) foreach ($p in $script:Conf) { Set-Px $cv ([int]$p.X) ([int]$p.Y) $p.C $p.Col } }
function Spawn-React { param([string]$word,[string]$col)      # NB: $w would alias $W (case-insensitive!)
    [void]$script:React.Add([pscustomobject]@{ X=$rng.Next(2,[Math]::Max(3,$W-12)); Y=$rng.Next(2,$H-7); T=$rng.Next(3,6); Word=$word; Col=$col }) }
function Step-React {
    $keep = New-Object System.Collections.ArrayList
    foreach ($r in $script:React) { $r.Y -= 1; $r.T -= 1; if ($r.T -gt 0 -and $r.Y -gt 0) { [void]$keep.Add($r) } }
    $script:React = $keep }
function Draw-React { param($cv) foreach ($r in $script:React) { Write-Text $cv ([int]$r.X) ([int]$r.Y) $r.Word $r.Col } }

# ============================ Applause-o-meter ===============================
function Draw-Meter { param($cv,[double]$hp,[string]$tier)
    $info=$TierInfo[$tier]; $barW=34; $fill=[int][Math]::Round($hp*$barW)
    $blk=[char]0x2588
    $bar='['+([string]$blk*$fill)+('-'*($barW-$fill))+']'
    $pct='{0,3}%' -f [int][Math]::Round($hp*100)
    Write-Text $cv 4 ($H-3) ('APPLAUSE-O-METER   '+$info.Label) $info.Col
    Write-Text $cv 4 ($H-2) ($bar+'  '+$pct) $info.Col }

# ============================ Compose a full stage frame =====================
function Compose { param([string]$pose,[double]$hp,[bool]$clapNow,[string]$banner='')
    $tier=Hype-Tier $hp; $info=$TierInfo[$tier]
    $cv=New-Canvas
    Write-Text $cv 0 ($H-1) ('~'*$W) 'DarkBlue'                       # waterline / stage floor
    $title='o  THE SEAL OF APPROVAL  o'
    Write-Text $cv (Center-X $title) 0 $title $info.Col
    Draw-Confetti $cv
    Draw-React $cv
    # seal chorus line, centred
    $eye = Eye-For $pose $tier
    $art = Seal-Frame $pose $eye
    $aw  = Art-Width $art; $gap=2
    $fit = [Math]::Max(1,[int](($W+$gap)/($aw+$gap)))
    $n   = [Math]::Max(1,[Math]::Min([Math]::Min($Seals,3),$fit))
    $total = $n*$aw + ($n-1)*$gap
    $startX = [Math]::Max(0,[int](($W-$total)/2))
    for ($s=0; $s -lt $n; $s++) { Stamp $cv ($startX + $s*($aw+$gap)) 3 $art $info.Col }
    if ($clapNow) {
        $clap = if ($tier -in 'OVATION','ENCORE') { 'CLAP!!' } else { 'CLAP!' }
        Write-Text $cv ([Math]::Min($W-7,$startX+$total+1)) 11 $clap 'White'
        Write-Text $cv ([Math]::Max(0,$startX-5)) 12 (-join (1..2|ForEach-Object{')'})) 'White' }
    if ($banner) { Write-Text $cv (Center-X $banner) ([int]($H/2)) $banner 'Yellow' }
    Draw-Meter $cv $hp $tier
    $cv }

# ============================ Live finale: TAKE A BOW ========================
function Invoke-Finale {
    $banner='*  TAKE A BOW  *'
    for ($i=0; $i -lt 22; $i++) {
        if (-not $NoConfetti) { Spawn-Confetti 16 $TierInfo['ENCORE'].Cols }
        Step-Confetti; Step-React
        $pose = if ($i % 2) { 'clap' } else { 'open' }
        Render-Live (Compose $pose 1.0 ($pose -eq 'clap') $banner)
        Beep (RNext-Fw) 40; Start-Sleep -Milliseconds 110
        if (Test-Quit) { break } }
    Render-Live (Compose 'clap' 1.0 $true ('*  STANDING OVATION  *')) }
function RNext-Fw { 700 + $rng.Next(900) }   # fireworks pitch

# ============================ STORYBOARD =====================================
if ($Storyboard) {
    function Demo { param([double]$hp,[string]$pose,[int]$confAge)
        $tier=Hype-Tier $hp; $info=$TierInfo[$tier]
        $script:Conf  = New-Object System.Collections.ArrayList
        $script:React = New-Object System.Collections.ArrayList
        if (-not $NoConfetti -and $hp -gt 0.3) {
            Spawn-Confetti ([int]($hp*26)) $info.Cols
            1..$confAge | ForEach-Object { Step-Confetti; Spawn-Confetti ([int]($hp*8)) $info.Cols } }
        if ($hp -ge 0.5) { 1..([int]($hp*3)) | ForEach-Object { Spawn-React (Pick $info.Crowd) $info.Col } }
        "  [ $($info.Label)   --   hype $([int]($hp*100))% ]"
        Render-Plain (Compose $pose $hp ($pose -eq 'clap'))
        '' }
    "############  THE SEAL OF APPROVAL  --  applause spectacular  ############"; ''
    Demo 0.10 'clap' 1
    Demo 0.40 'open' 3
    Demo 0.65 'clap' 5
    Demo 0.90 'clap' 6
    Demo 1.00 'open' 7
    "  [ FINALE -- TAKE A BOW ]"
    $script:Conf = New-Object System.Collections.ArrayList
    Spawn-Confetti 60 $TierInfo['ENCORE'].Cols; 1..4 | ForEach-Object { Step-Confetti; Spawn-Confetti 24 $TierInfo['ENCORE'].Cols }
    Render-Plain (Compose 'clap' 1.0 $true '*  TAKE A BOW  *')
    return
}

# ============================ LIVE ===========================================
try { [void][Console]::WindowWidth } catch {
    Write-Warning 'Live mode needs a real console. Try: .\Clap-Seal.ps1 -Storyboard'; return }
$prevCursor = [Console]::CursorVisible
try { [Console]::CursorVisible=$false } catch {}
function Test-Quit {
    try { if ([Console]::KeyAvailable) {
        $k=[Console]::ReadKey($true)
        if ($k.Key -eq 'Q' -or ($k.Modifiers -band [ConsoleModifiers]::Control -and $k.Key -eq 'C')) { return $true } } } catch {}
    return $false }

$script:hype = 0.0; $count = 0; $poses = @('open','clap','open')
try {
    :outer while ($true) {
        foreach ($pose in $poses) {
            $clapNow = ($pose -eq 'clap')
            if ($clapNow) {
                $count++
                $script:hype = [Math]::Min(1.0, $script:hype + 0.085)
                $tier = Hype-Tier $script:hype; $info = $TierInfo[$tier]
                Beep (640 + [int]($script:hype*760)) 70
                if (-not $NoConfetti) { Spawn-Confetti ([int](2 + $script:hype*12)) $info.Cols }
                if ($rng.NextDouble() -lt (0.15 + $script:hype*0.6)) { Spawn-React (Pick $info.Crowd) $info.Col }
            } else {
                $script:hype = [Math]::Max(0.0, $script:hype - 0.012)   # crowd cools a touch between claps
            }
            Step-Confetti; Step-React
            Render-Live (Compose $pose $script:hype $clapNow)
            $delay = [int]($DelayMs * (1 - $script:hype*0.55)); if ($delay -lt 70) { $delay = 70 }
            Start-Sleep -Milliseconds $delay
            if (Test-Quit) { break outer }
            if ($Claps -gt 0 -and $count -ge $Claps) { break outer }
        }
    }
    Invoke-Finale
}
finally {
    [Console]::ResetColor(); try { [Console]::CursorVisible=$prevCursor } catch {}
    Write-Host ''
    Write-Host "   *flap flap*  the seal has left the stage. ($count claps)" -ForegroundColor Yellow
}
