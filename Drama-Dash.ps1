<#
.SYNOPSIS
    DRAMA DASH -- a cinematic ASCII endless-runner. You are a soap-opera star
    sprinting away from your scandal. JUMP the wedding cakes & tombstones, DUCK
    the thrown vases & paparazzi drones. Lightning splits a day/night sky, the
    pace climbs, and a crash ends in "TO BE CONTINUED..." with your distance.

.DESCRIPTION
    A real-time terminal game: non-blocking input, jump physics with gravity,
    parallax scenery, day/night cycle with thunderstorms, and flicker-free
    full-frame redraw (ANSI 256-colour). High score persists to %TEMP%.

    Controls:  SPACE / UP / W = jump    DOWN / S = duck    R = restart    Q = quit

.PARAMETER NoColor     Render without ANSI colour (for limited terminals).
.PARAMETER Silent      Disable sound cues ([Console]::Beep).
.PARAMETER Storyboard  Print representative frames to stdout and exit (no loop).
.PARAMETER Demo        Run N frames on autopilot and print sample frames (headless test).
.PARAMETER Seed        Fix the RNG for reproducible output. 0 = random.

.EXAMPLE
    .\Drama-Dash.ps1
.EXAMPLE
    .\Drama-Dash.ps1 -NoColor
.EXAMPLE
    .\Drama-Dash.ps1 -Storyboard -Seed 7
#>
[CmdletBinding()]
param(
    [switch]$NoColor,
    [switch]$Silent,
    [switch]$Storyboard,
    [int]$Demo = 0,
    [int]$Seed = 0
)

# Enable ANSI / virtual-terminal processing on Windows consoles (Win Terminal already does).
if (-not $NoColor) {
    try {
        Add-Type -ErrorAction Stop @"
using System;
using System.Runtime.InteropServices;
public static class DDVT {
  [DllImport("kernel32.dll")] static extern IntPtr GetStdHandle(int n);
  [DllImport("kernel32.dll")] static extern bool GetConsoleMode(IntPtr h, out uint m);
  [DllImport("kernel32.dll")] static extern bool SetConsoleMode(IntPtr h, uint m);
  public static void Enable(){ var h=GetStdHandle(-11); uint m; if(GetConsoleMode(h,out m)) SetConsoleMode(h, m|0x0004u); }
}
"@
        [DDVT]::Enable()
    } catch { }
}

# ============================ RNG / constants ================================
$seedVal = if ($Seed -gt 0) { $Seed } else { [Environment]::TickCount }
$rng = [Random]::new($seedVal)
function RNext { param([int]$lo,[int]$hi) $rng.Next($lo,$hi) }
function Pick  { param($a) $a[$rng.Next($a.Count)] }
$script:Silent = [bool]$Silent
$script:Color  = -not $NoColor

$W = 70; $H = 18; $SURFACE = 14; $PX = 8        # playfield, ground row, player column
$GRAV = 0.35; $JUMP_V = 2.0; $DUCK_FRAMES = 6
$HISCORE_FILE = Join-Path $env:TEMP 'drama-dash-highscore.txt'

# 256-colour palette
$C = @{ star=252; moon=231; cloud=251; hill=240; ground=100; dirt=94; grass=70
        run=220; jump=213; duck=223; gObs=196; aObs=201; hud=231; title=226
        bolt=231; flash=231; dead=196; tag=244 }

# ============================ Sprites ========================================
$RUN_A  = @(' o ','/|\','/ \')
$RUN_B  = @(' o ','/|\','| |')
$JUMP_S = @(' o ','\|/','/ \')                  # arms flung up, very dramatic
$DUCK_A = @('___','o_\')
$DUCK_B = @('___','o_/')

# Ground obstacles (JUMP these) -- bottom sits on the surface row
$GROUND = @(
    ,@('[#]','[#]')          # wedding cake
    ,@('.-.','|R|')          # tombstone
    ,@('/=\','|_|')          # overturned chair
    ,@('_/\_')               # banana peel (short hop)
)
# Air obstacles (DUCK these) -- fly at head height
$AIR = @(
    ,@('<O>',' V ')          # paparazzi drone
    ,@('\_/','(_)')          # hurled vase
    ,@('~v~','~^~')          # tabloid bird
)

# ============================ Buffers / drawing ==============================
function New-Buffers {
    $g=@(); $c=@()
    for ($y=0; $y -lt $H; $y++) { $g += ,((' ' * $W).ToCharArray()); $c += ,(New-Object 'int[]' $W) }
    @{ G=$g; C=$c } }
function Put { param($b,[int]$x,[int]$y,[char]$ch,[int]$col)
    if ($y -ge 0 -and $y -lt $H -and $x -ge 0 -and $x -lt $W) { $b.G[$y][$x]=$ch; $b.C[$y][$x]=$col } }
function Draw-Sprite { param($b,$art,[int]$topRow,[int]$x,[int]$col)
    for ($r=0; $r -lt $art.Count; $r++) { $ln=$art[$r]
        for ($c2=0; $c2 -lt $ln.Length; $c2++) { if ($ln[$c2] -ne ' ') { Put $b ($x+$c2) ($topRow+$r) $ln[$c2] $col } } } }
function Sprite-Cells { param($art,[int]$topRow,[int]$x)
    $set=@{}; for ($r=0; $r -lt $art.Count; $r++) { $ln=$art[$r]
        for ($c2=0; $c2 -lt $ln.Length; $c2++) { if ($ln[$c2] -ne ' ') { $set[(($topRow+$r)*1000)+($x+$c2)]=$true } } }
    $set }

# ============================ Game state =====================================
function Get-Hi { if (Test-Path $HISCORE_FILE) { try { [int](Get-Content $HISCORE_FILE -First 1) } catch { 0 } } else { 0 } }
function Set-Hi { param([int]$v) try { $v | Set-Content $HISCORE_FILE } catch { } }

function New-Game {
    @{ y=0.0; vy=0.0; grounded=$true; duck=0; frame=0; traveled=0.0
       speed=1.2; score=0.0; obs=(New-Object 'System.Collections.Generic.List[object]')
       lastSpawn=-22.0; gap=22.0; night=$false; flash=0; boltX=0; hi=(Get-Hi); screen='title' } }

function Player-Sprite { param($g)
    if ($g.duck -gt 0 -and $g.grounded) {
        @{ art=$(if (($g.frame % 4) -lt 2) { $DUCK_A } else { $DUCK_B }); top=($SURFACE-1); col=$C.duck }
    } elseif (-not $g.grounded) {
        $feet = $SURFACE - [int][Math]::Round($g.y); @{ art=$JUMP_S; top=($feet-2); col=$C.jump }
    } else {
        @{ art=$(if (($g.frame % 4) -lt 2) { $RUN_A } else { $RUN_B }); top=($SURFACE-2); col=$C.run } } }

function Spawn-Obstacle { param($g)
    if ($rng.Next(100) -lt 58) { $art = Pick $GROUND; $kind='ground' }
    else                       { $art = Pick $AIR;    $kind='air' }
    $ow = ($art | Measure-Object -Property Length -Maximum).Maximum
    $top = if ($kind -eq 'ground') { $SURFACE - ($art.Count-1) } else { $SURFACE - 3 }
    $g.obs.Add(@{ x=([double]$W); art=$art; top=$top; w=$ow; kind=$kind }) }

function Step-Game { param($g)
    $g.frame++
    $g.speed = [Math]::Min(3.0, 1.2 + $g.frame * 0.0006)
    $g.traveled += $g.speed
    $g.score   += $g.speed * 0.5
    $g.night = ([Math]::Floor($g.frame / 700) % 2) -eq 1
    if ($g.flash -gt 0) { $g.flash-- }
    elseif ($g.night -and $rng.Next(1000) -lt 9) { $g.flash=2; $g.boltX=(RNext 12 ($W-6)); Sound thunder }

    # physics
    if (-not $g.grounded) { $g.y += $g.vy; $g.vy -= $GRAV; if ($g.y -le 0) { $g.y=0; $g.vy=0; $g.grounded=$true } }
    if ($g.duck -gt 0) { $g.duck-- }

    # obstacles: move, spawn, despawn
    foreach ($o in $g.obs) { $o.x -= $g.speed }
    for ($i=$g.obs.Count-1; $i -ge 0; $i--) { if (($g.obs[$i].x + $g.obs[$i].w) -lt 0) { $g.obs.RemoveAt($i) } }
    if (($g.traveled - $g.lastSpawn) -ge $g.gap) {
        Spawn-Obstacle $g; $g.lastSpawn=$g.traveled
        $g.gap = RNext ([int](16 + $g.speed*5)) ([int](30 + $g.speed*7)) }
}

function Hit? { param($g)
    $ps = Player-Sprite $g
    $pc = Sprite-Cells $ps.art $ps.top $PX
    foreach ($o in $g.obs) {
        $oc = Sprite-Cells $o.art $o.top ([int][Math]::Round($o.x))
        foreach ($k in $oc.Keys) { if ($pc.ContainsKey($k)) { return $true } } }
    return $false }

# ============================ Scenery + compose ==============================
function Render { param($g)
    $b = New-Buffers
    $t = [int]$g.traveled

    # sky: stars (night) or clouds (day), with parallax
    if ($g.night) {
        Put $b ($W-6) 1 ([char]'C') $C.moon; Put $b ($W-5) 1 ([char]')') $C.moon
        for ($i=0; $i -lt 26; $i++) {
            $sx = (($i*37 + 5) - [int]($t/3)) % $W; if ($sx -lt 0) { $sx += $W }
            $sy = ($i*7 + 2) % 7 + 1
            if ((($i*13 + $g.frame) % 17) -lt 12) { Put $b $sx $sy ([char]'.') $C.star } }
    } else {
        for ($i=0; $i -lt 4; $i++) {
            $cx = (($i*23 + 10) - [int]($t/4)) % ($W+10); if ($cx -lt 0) { $cx += ($W+10) }
            Draw-Sprite $b @('(~~~)') (2 + ($i % 3)) ($cx-5) $C.cloud } }

    # distant hills (slow parallax) just above the play band
    for ($x=0; $x -lt $W; $x++) {
        $hgt = [int](2 * [Math]::Abs([Math]::Sin(($x + $t/4) * 0.18)))
        Put $b $x ($SURFACE-4-$hgt) ([char]'^') $C.hill }

    # ground surface (scrolling texture) + dirt
    for ($x=0; $x -lt $W; $x++) {
        $ch = switch ((($x + $t) % 7)) { 0 {'_'} 3 {'.'} default {'='} }
        Put $b $x $SURFACE ([char]$ch) $C.grass
        for ($y=$SURFACE+1; $y -lt $H; $y++) {
            $d = (($x*7 + $y*13 + $t) % 11); if ($d -eq 0) { Put $b $x $y ([char]',') $C.dirt }
            elseif ($d -eq 5) { Put $b $x $y ([char]'.') $C.dirt } } }

    # lightning bolt
    if ($g.flash -gt 0) {
        $bx=$g.boltX; for ($y=1; $y -lt $SURFACE-3; $y++) { Put $b $bx $y ([char]'#') $C.bolt; $bx += (($y % 2)*2 - 1) } }

    # obstacles
    foreach ($o in $g.obs) { Draw-Sprite $b $o.art $o.top ([int][Math]::Round($o.x)) $(if ($o.kind -eq 'ground') { $C.gObs } else { $C.aObs }) }

    # player (+ speed streamers)
    if ($g.grounded -and $g.duck -le 0) { Put $b ($PX-2) ($SURFACE-1) ([char]'~') $C.tag; Put $b ($PX-1) $SURFACE ([char]'-') $C.tag }
    $ps = Player-Sprite $g; Draw-Sprite $b $ps.art $ps.top $PX $ps.col

    # HUD
    $title = ' DRAMA DASH '
    for ($i=0; $i -lt $title.Length; $i++) { Put $b ($i+1) 0 $title[$i] $C.title }
    $dist = "DIST {0,5}m" -f [int]$g.score
    for ($i=0; $i -lt $dist.Length; $i++) { Put $b ($W-2-$dist.Length+$i) 0 $dist[$i] $C.hud }
    $hi = "HI {0}" -f ([Math]::Max($g.hi,[int]$g.score))
    for ($i=0; $i -lt $hi.Length; $i++) { Put $b (28+$i) 0 $hi[$i] $C.hud }

    # overlays
    if ($g.screen -eq 'title') {
        Overlay $b @(
            '=================================',
            '         D R A M A   D A S H         ',
            '   flee your scandal. mind the cake. ',
            '',
            '  SPACE/UP = leap over disaster',
            '  DOWN     = duck the paparazzi',
            '',
            '     >> press SPACE to flee <<       ',
            '=================================') $C.title
    } elseif ($g.screen -eq 'dead') {
        Overlay $b @(
            '===================================',
            '        T O   B E   C O N T I N U E D . . .',
            '',
            ("   You fled {0}m from your past." -f [int]$g.score),
            ("   Best escape: {0}m" -f [Math]::Max($g.hi,[int]$g.score)),
            '',
            '   R = run again      Q = quit') $C.dead }

    Build-Frame $b }

function Overlay { param($b,$lines,[int]$col)
    $maxw = (($lines | Measure-Object -Property Length -Maximum).Maximum) + 4
    $x0 = [int](($W - $maxw)/2); $top = [int](($H - $lines.Count)/2)
    foreach ($ln in $lines) {
        $lead = [int](($maxw - $ln.Length)/2)
        $padded = (' '*$lead) + $ln + (' '*($maxw - $ln.Length - $lead))   # clear a clean card rectangle
        for ($i=0; $i -lt $padded.Length; $i++) { Put $b ($x0+$i) $top $padded[$i] $col }
        $top++ } }

function Build-Frame { param($b)
    $e=[char]27; $sb=[System.Text.StringBuilder]::new()
    for ($y=0; $y -lt $H; $y++) {
        $cur=-1
        for ($x=0; $x -lt $W; $x++) {
            if ($script:Color) { $cc=$b.C[$y][$x]; if ($b.G[$y][$x] -ne ' ' -and $cc -ne $cur) { [void]$sb.Append("$e[38;5;${cc}m"); $cur=$cc } }
            [void]$sb.Append($b.G[$y][$x]) }
        if ($script:Color) { [void]$sb.Append("$e[0m"); $cur=-1 }
        if ($y -lt $H-1) { [void]$sb.Append("`n") } }
    $sb.ToString() }

# ============================ Sound ==========================================
function Sound { param([string]$n) if ($script:Silent) { return }
    try { switch ($n) {
        'jump'    { [Console]::Beep(660,40) }
        'duck'    { [Console]::Beep(330,40) }
        'thunder' { [Console]::Beep(70,120) }
        'crash'   { [Console]::Beep(180,120); [Console]::Beep(120,160); [Console]::Beep(90,260) }
        'point'   { [Console]::Beep(880,30) } } } catch { } }

# ============================ STORYBOARD =====================================
if ($Storyboard) {
    $script:Color = $false
    function Show { param($label,$g) "  $label"; (Render $g); '' }
    $g = New-Game; $g.screen='title'; Show '[ TITLE SCREEN ]' $g
    # mid-run: a ground obstacle approaching + an air obstacle further out
    $g = New-Game; $g.screen='play'; $g.score=312
    $g.obs.Add(@{ x=20.0; art=$GROUND[0]; top=($SURFACE-1); w=3; kind='ground' })
    $g.obs.Add(@{ x=44.0; art=$AIR[0];    top=($SURFACE-3); w=3; kind='air' })
    Show '[ ACT ONE -- running; cake ahead, drone beyond ]' $g
    # jumping the cake
    $g.y=4.0; $g.grounded=$false; $g.obs[0].x=9.0; Show '[ THE LEAP -- clearing the wedding cake ]' $g
    # ducking the drone
    $g.y=0.0; $g.grounded=$true; $g.duck=4; $g.obs.Clear(); $g.night=$true
    $g.obs.Add(@{ x=9.0; art=$AIR[0]; top=($SURFACE-3); w=3; kind='air' }); $g.flash=2; $g.boltX=50
    Show '[ THE DUCK -- under the paparazzi drone, lightning strikes ]' $g
    # game over
    $g2 = New-Game; $g2.screen='dead'; $g2.score=1280; $g2.night=$true; Show '[ CRASH -- TO BE CONTINUED ]' $g2
    return
}

# ============================ DEMO (headless autopilot) ======================
if ($Demo -gt 0) {
    $script:Color = $false; $g = New-Game; $g.screen='play'
    for ($f=0; $f -lt $Demo; $f++) {
        # autopilot: jump nearest ground obstacle, duck nearest air obstacle
        $jump=$false; $duck=$false
        foreach ($o in $g.obs) { $d=[int][Math]::Round($o.x)-$PX
            if ($d -ge 0 -and $d -le 9) { if ($o.kind -eq 'ground') { $jump=$true } else { $duck=$true } } }
        if ($jump -and $g.grounded) { $g.vy=$JUMP_V; $g.grounded=$false }
        if ($duck -and $g.grounded) { $g.duck=$DUCK_FRAMES }
        Step-Game $g
        if (Hit? $g) { "  [demo] crashed at frame $f, ~$([int]$g.score)m, obstacles cleared"; break }
        if ($f % 30 -eq 0) { "  ---- frame $f  (dist $([int]$g.score)m, speed $([Math]::Round($g.speed,2))) ----"; Render $g; '' }
    }
    "  [demo] survived/ended at ~$([int]$g.score)m"
    return
}

# ============================ LIVE ===========================================
try { $cw=[Console]::WindowWidth; $ch2=[Console]::WindowHeight } catch {
    Write-Warning 'Drama-Dash needs a real console. Try: .\Drama-Dash.ps1 -Storyboard'; return }
if ($cw -lt $W -or $ch2 -lt ($H+1)) {
    Write-Warning ("Console too small. Need at least {0}x{1}; have {2}x{3}." -f $W,($H+1),$cw,$ch2); return }

$prevCursor = [Console]::CursorVisible
try { [Console]::CursorVisible=$false } catch {}
Clear-Host
$g = New-Game
$frameMs = 55
$lastMilestone = 0

try {
    while ($true) {
        $jump=$false; $duck=$false; $restart=$false; $quit=$false
        while ([Console]::KeyAvailable) {
            $k=[Console]::ReadKey($true).Key
            switch ($k) {
                'Spacebar' { $jump=$true } 'UpArrow' { $jump=$true } 'W' { $jump=$true }
                'DownArrow' { $duck=$true } 'S' { $duck=$true }
                'R' { $restart=$true } 'Q' { $quit=$true } 'Escape' { $quit=$true } } }
        if ($quit) { break }

        switch ($g.screen) {
            'title' { if ($jump) { $g = New-Game; $g.screen='play' } }
            'play'  {
                if ($jump -and $g.grounded) { $g.vy=$JUMP_V; $g.grounded=$false; Sound jump }
                if ($duck -and $g.grounded) { $g.duck=$DUCK_FRAMES; Sound duck }
                Step-Game $g
                $mid=[int]([int]$g.score/100); if ($mid -gt $lastMilestone) { $lastMilestone=$mid; Sound point }
                if (Hit? $g) {
                    Sound crash
                    foreach ($o in 6,2,5,1,4,0) {                 # death shake
                        [Console]::SetCursorPosition($o,0); [Console]::Out.Write((Render $g)); Start-Sleep -Milliseconds 45 }
                    if ([int]$g.score -gt $g.hi) { $g.hi=[int]$g.score; Set-Hi $g.hi }
                    $g.screen='dead'
                } }
            'dead'  { if ($restart) { $hi=$g.hi; $g = New-Game; $g.hi=$hi; $g.screen='play' } }
        }

        [Console]::SetCursorPosition(0,0); [Console]::Out.Write((Render $g))
        Start-Sleep -Milliseconds $frameMs
    }
}
finally {
    if ($script:Color) { [Console]::Out.Write(("{0}[0m" -f [char]27)) }
    [Console]::ResetColor(); try { [Console]::CursorVisible=$prevCursor } catch {}
    try { [Console]::SetCursorPosition(0,$H) } catch {}
    Write-Host ''; Write-Host '  *click*  ...and we are off the air.' -ForegroundColor DarkGray
}
