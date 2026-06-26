<#
.SYNOPSIS
    "FLOORED" -- a late-night ASCII bit where a guy deadpans one devastating
    line straight into the camera, holds the world's longest beat of dead
    silence... and then the audience is FLOORED: jaws drop, hands fly up, the
    APPLAUSE sign detonates, the meter pins, the room loses it, screen shake,
    standing ovation.

.DESCRIPTION
    Each bit is directed in five beats:
      OPEN ON THE GUY  ->  the setup (lower-third subtitle, deadpan face)
      ->  THE PUNCH (typed slow, flat as a pancake, dead into the lens)
      ->  THE BEAT (total silence; just the stare and a ticking timecode)
      ->  FLOORED (cut to the crowd -- applause sting, meter pins, screen
          shake, a giant FLOORED card)  ->  next bit.

    The harder the burn, the harder the room goes: a chuckle, then FLOORED,
    then the room is simply destroyed and a chair gets thrown.

    Live mode redraws in place with sound + motion (needs a real console).
    -Storyboard prints a representative montage of frames to stdout instead.

.PARAMETER Bits        How many one-liners before exiting. 0 (default) = forever.
.PARAMETER Silent      Disable the [Console]::Beep sound cues.
.PARAMETER Storyboard  Print a static montage to stdout (no animation / sound).
.PARAMETER Scenes      Storyboard: how many bits to lay out. Default 1.
.PARAMETER Seed        Fix the RNG for reproducible output. 0 = random.
.PARAMETER Fast        Type faster and shorten the dramatic holds. For the impatient.

.EXAMPLE
    .\Floored.ps1
.EXAMPLE
    .\Floored.ps1 -Bits 5
.EXAMPLE
    .\Floored.ps1 -Storyboard -Scenes 2 -Seed 42
#>
[CmdletBinding()]
param(
    [int]$Bits   = 0,
    [switch]$Silent,
    [switch]$Storyboard,
    [int]$Scenes = 1,
    [int]$Seed   = 0,
    [switch]$Fast
)

# ============================ RNG ============================================
$seedVal = if ($Seed -gt 0) { $Seed } else { [Environment]::TickCount }
$rng = [Random]::new($seedVal)
function Pick  { param($a) $a[$rng.Next($a.Count)] }
function RNext { param([int]$lo,[int]$hi) $rng.Next($lo,$hi) }
$script:Silent = [bool]$Silent

# ============================ Timing =========================================
$TypeMs = if ($Fast) { 9 }   else { 34 }    # ms per character of the punchline
$Beat   = if ($Fast) { 320 } else { 850 }   # short pause
$Hold   = if ($Fast) { 650 } else { 1500 }  # long deadpan hold
$SW     = 56                                 # interior width of the broadcast

# ============================ Helpers ========================================
function Center { param([string]$s,[int]$w)
    if ($s.Length -ge $w) { return $s.Substring(0,$w) }
    $pad=$w-$s.Length; $l=[int]($pad/2); (' '*$l)+$s+(' '*($pad-$l)) }
function PadR { param([string]$s,[int]$w)
    if ($s.Length -ge $w) { return $s.Substring(0,$w) } else { $s+(' '*($w-$s.Length)) } }
function Pause { param([int]$ms) Start-Sleep -Milliseconds $ms }
function Tc { param([System.Diagnostics.Stopwatch]$sw)
    $t=$sw.Elapsed; '{0:00}:{1:00}:{2:00}' -f $t.Hours,$t.Minutes,$t.Seconds }

# ============================ Sound ==========================================
function Beep { param([int]$f,[int]$ms) if (-not $script:Silent) { try { [Console]::Beep($f,$ms) } catch {} } }
function Sting { param([string]$n) switch ($n) {
    'rimshot'  { Beep 330 90; Beep 262 90; Beep 196 220 }                       # ba-dum-tss
    'silence'  { }                                                              # the void
    'laugh'    { 1..6 | ForEach-Object { Beep (RNext 300 520) 50 } }            # the room cracks
    'applause' { 1..14 | ForEach-Object { Beep (RNext 900 2400) 18 } }          # the wave hits
    'floored'  { Beep 523 120; Beep 659 120; Beep 784 360 }                     # the payoff fanfare
    'chair'    { Beep 90 200; Beep 70 320 } } }                                 # a chair gets thrown

# ============================ Word banks =====================================
# Curated deadpan bits -- a setup line and a punch, each tagged with a burn
# level (1 chuckle .. 3 the-room-is-destroyed) that drives the reaction.
$BitPool = @(
  @{ Setup='My therapist told me to set firm boundaries.';
     Punch='So I set one. My salary. I live under it.'; Burn=2 },
  @{ Setup='People ask if I have a five-year plan.';
     Punch='Year one is locating the plan.'; Burn=2 },
  @{ Setup='They put me on the fast track at work.';
     Punch='Turns out it was a treadmill the whole time.'; Burn=3 },
  @{ Setup='I do not have trust issues.';
     Punch='I have an excellent memory.'; Burn=3 },
  @{ Setup='I am not avoiding responsibility.';
     Punch='Responsibility and I agreed to see other people.'; Burn=2 },
  @{ Setup='My bank phoned to check in on me.';
     Punch='It was the bank that needed the support.'; Burn=3 },
  @{ Setup='I told my boss money cannot buy happiness.';
     Punch='He agreed, and used that to explain my raise.'; Burn=3 },
  @{ Setup='I am not lazy.';
     Punch='I am simply running in energy-saving mode.'; Burn=1 },
  @{ Setup='I peaked once, at a meeting.';
     Punch='Nobody in that meeting remembers it. Including me.'; Burn=2 },
  @{ Setup='I started journaling for my mental health.';
     Punch='Day one entry: see previous entry.'; Burn=2 },
  @{ Setup='My calendar says I have free time tomorrow.';
     Punch='My calendar has lied to me before.'; Burn=1 },
  @{ Setup='I told them I work well under pressure.';
     Punch='I do not. I just only work under pressure.'; Burn=3 },
  @{ Setup='I finally hit my step goal today.';
     Punch='Pacing the kitchen wondering where it all went.'; Burn=2 },
  @{ Setup='I do my best thinking in the shower.';
     Punch='Which is concerning, given the results.'; Burn=2 },
  @{ Setup='My plants are thriving this year.';
     Punch='They are plastic. We are all doing our best.'; Burn=3 },
  @{ Setup='I read that comparison is the thief of joy.';
     Punch='So I checked. Everyone else read it too. They are fine.'; Burn=2 },
  @{ Setup='I asked the universe for a sign.';
     Punch='It left me on read. As is tradition.'; Burn=3 },
  @{ Setup='I am the youngest I will ever be, right now.';
     Punch='And somehow this is the best I will look. Good talk.'; Burn=3 },
  @{ Setup='I keep a gratitude list.';
     Punch='It is just the WiFi password and one good nap.'; Burn=2 },
  @{ Setup='They told me to bring my whole self to work.';
     Punch='HR has since revised that policy.'; Burn=3 }
)
function New-Bit { Pick $BitPool }

# Crowd reaction captions, escalating with the burn.
$Reactions = @{
  1 = @('a polite ripple of laughter','someone in row C exhales sharply','a single, respectful "ha"',
        'the front row nods, impressed')
  2 = @('the room CRACKS','jaws hit the floor in unison','a guy spits his drink, clean across aisle 4',
        'a woman stands up just to sit back down')
  3 = @('the AUDIENCE is FLOORED','the room is DESTROYED','total devastation, standing ovation',
        'a chair is thrown. nobody knows whose.','someone yells "I am calling my MOTHER"') }

# ============================ Faces (the guy) ================================
# A flat, unbothered talking head staring dead down the lens. Same deadpan
# every single time -- that is the joke.
$Guy = @(
  '          .-------------------.          ',
  '         /                     \         ',
  '        |    ___         ___    |        ',
  '        |   |   |       |   |   |        ',   # flat, dead eyes
  '        |    ---         ---    |        ',
  '        |             |         |        ',
  '        |          ___|         |        ',   # not even a nose, really
  '        |       ___________     |        ',   # a line for a mouth
  '        |      |___________|    |        ',
  '         \                     /         ',
  '          `-------------------`          ',
  '            | [ o>  MIC ]  |            ',
  '            |_______________|            ' )

# The tighter "into the lens" stare used for the punch + the beat.
$Lens = @(
  '                                         ',
  '            .-----------------.          ',
  '           |   ___       ___   |         ',
  '           |  |   |     |   |  |         ',
  '           |   ---       ---   |         ',
  '           |          |        |         ',
  '           |       _________   |         ',
  '           |      |_________|   |         ',
  '            `-----------------`          ',
  '         [ . . . into the lens . . . ]   ',
  '                                         ' )

# The FLOORED payoff banner.
$FlooredBanner = @(
  ' _____ _    ___   ___  ____  _____ ____  ',
  '|  ___| |  / _ \ / _ \|  _ \| ____|  _ \ ',
  '| |_  | | | | | | | | | |_) |  _| | | | |',
  '|  _| | |_| |_| | |_| |  _ <| |___| |_| |',
  '|_|   |_____\___/ \___/|_| \_\_____|____/' )

# ============================ Crowd ==========================================
# A procedurally-thrown crowd: more arms up + more dropped jaws the higher
# the burn. Rendered as three rows of little people.
$JawDrop = @('(O_O)','(o_o)','(0_0)','(O-O)','(@_@)','(>_<)','(*o*)')
function New-Crowd { param([int]$burn,[int]$cols=9)
    $intensity = @{1=0.30; 2=0.62; 3=0.92}[$burn]
    $head=''; $arm=''; $leg=''
    for ($i=0; $i -lt $cols; $i++) {
        $up = $rng.NextDouble() -lt $intensity
        if ($up) {
            $head += (Center (Pick $JawDrop) 6)
            $arm  += (Center '\o/' 6)
            $leg  += (Center '/ \' 6)
        } else {
            $head += (Center '(--)' 6)
            $arm  += (Center ' o ' 6)
            $leg  += (Center '/ \' 6)
        } }
    @($head,$arm,$leg) }

# ============================ Broadcast chrome ===============================
function Draw { param([string[]]$Picture,[string]$Tag,[bool]$RecOn,[string]$Time,
                      [ConsoleColor]$Color='Yellow',[int]$Shake=0)
    Clear-Host
    $ind = '  ' + (' '*$Shake)
    $bar = '=' * $SW
    Write-Host ($ind+'.'+$bar+'.') -ForegroundColor DarkGray
    $rec  = if ($RecOn) { '(o REC)' } else { '(  REC)' }
    $left = ' '+$rec+'  '+$Tag
    $time = $Time+' '
    $hdr  = (PadR $left ($SW-$time.Length))+$time
    Write-Host ($ind+'|') -NoNewline -ForegroundColor DarkGray
    $idx = if ($RecOn) { $hdr.IndexOf('o') } else { -1 }
    if ($idx -ge 0) {
        Write-Host $hdr.Substring(0,$idx)  -NoNewline -ForegroundColor Gray
        Write-Host 'o'                     -NoNewline -ForegroundColor Red
        Write-Host $hdr.Substring($idx+1)  -NoNewline -ForegroundColor Gray
    } else { Write-Host $hdr -NoNewline -ForegroundColor Gray }
    Write-Host '|' -ForegroundColor DarkGray
    Write-Host ($ind+'|'+('-'*$SW)+'|') -ForegroundColor DarkGray
    foreach ($line in $Picture) {
        Write-Host ($ind+'|') -NoNewline -ForegroundColor DarkGray
        Write-Host (Center $line $SW) -NoNewline -ForegroundColor $Color
        Write-Host '|' -ForegroundColor DarkGray
    }
    Write-Host ($ind+"'"+$bar+"'") -ForegroundColor DarkGray }

# Lower-third caption. Name instant, quote optionally typed out.
function Lower { param([string]$Tag,[string]$Quote,[ConsoleColor]$QColor='White',[bool]$Slow=$false)
    Write-Host ''
    Write-Host ('   '+('_'*($SW-1))) -ForegroundColor DarkGray
    Write-Host '  >> ' -NoNewline -ForegroundColor DarkCyan
    Write-Host $Tag    -ForegroundColor Cyan
    Write-Host '  >> ' -NoNewline -ForegroundColor DarkCyan
    if ($Slow) {
        foreach ($c in $Quote.ToCharArray()) { Write-Host -NoNewline $c -ForegroundColor $QColor; Pause $TypeMs }
        Write-Host ''
    } else { Write-Host $Quote -ForegroundColor $QColor }
    Write-Host ('   '+('~'*($SW-1))) -ForegroundColor DarkGray }

# ============================ Beats ==========================================
function Show-TitleCard {
    Clear-Host; Write-Host ''
    Write-Host '     ____  _____    _    ____  ____   _    _   _ ' -ForegroundColor Cyan
    Write-Host '    |  _ \| ____|  / \  |  _ \|  _ \ / \  | \ | |' -ForegroundColor Cyan
    Write-Host '    | | | |  _|   / _ \ | | | | |_) / _ \ |  \| |' -ForegroundColor Cyan
    Write-Host '    | |_| | |___ / ___ \| |_| |  __/ ___ \| |\  |' -ForegroundColor DarkCyan
    Write-Host '    |____/|_____/_/   \_\____/|_| /_/   \_\_| \_|' -ForegroundColor DarkCyan
    Write-Host ''
    Write-Host '        he says one (1) thing into the camera' -ForegroundColor Yellow
    Write-Host '        --------------------------------------' -ForegroundColor DarkGray
    Write-Host '          the audience is, frankly, FLOORED'    -ForegroundColor DarkGray
    Write-Host ''
    Pause ($Hold+500) }

function Blink-Rec { param([string[]]$Pic,[string]$Tag,[System.Diagnostics.Stopwatch]$Sw,[int]$Times=2)
    for ($i=0;$i -lt $Times;$i++) {
        Draw -Picture $Pic -Tag $Tag -RecOn $true  -Time (Tc $Sw); Pause 260
        Draw -Picture $Pic -Tag $Tag -RecOn $false -Time (Tc $Sw); Pause 200 }
    Draw -Picture $Pic -Tag $Tag -RecOn $true -Time (Tc $Sw) }

# The room going up: applause meter fills, crowd thrown, banner, screen-shake.
function Invoke-Floored { param([int]$burn,[System.Diagnostics.Stopwatch]$Sw)
    # the wave of sound
    Sting laugh; Pause 120
    if ($burn -ge 2) { Sting applause }
    # applause meter pins to the burn
    $cap = @{1=6; 2=11; 3=16}[$burn]
    for ($n=1; $n -le $cap; $n++) {
        $meter = '['+('|'*$n)+(' '*(16-$n))+']'
        $crowd = New-Crowd $burn
        $pic = @('') + $crowd + @('','   APPLAUSE  '+$meter,'')
        $shake = if ($burn -ge 2 -and $n -gt ($cap-5)) { RNext 0 4 } else { 0 }
        Draw -Picture $pic -Tag 'AUDIENCE REACTION' -RecOn $true -Time (Tc $Sw) -Color Green -Shake $shake
        Beep (RNext 700 2200) 14; Pause 45 }
    Pause 200
    # THE CARD
    $col = @{1='White'; 2='Yellow'; 3='Red'}[$burn]
    foreach ($k in 1..($(if($burn -ge 3){6}else{2}))) {
        $shake = if ($burn -ge 2) { RNext 0 ($burn+1) } else { 0 }
        Draw -Picture (@('') + $FlooredBanner + @('','        '+(Pick $Reactions[$burn]))) `
             -Tag 'AUDIENCE: FLOORED' -RecOn $true -Time (Tc $Sw) -Color $col -Shake $shake
        if ($k -eq 1) { Sting floored }
        Pause 110 }
    if ($burn -ge 3) { Sting chair }
    Pause $Hold }

# One full bit, start to finish.
function Invoke-Bit { param($bit,[System.Diagnostics.Stopwatch]$Sw)
    # 1. OPEN ON THE GUY
    Blink-Rec -Pic $Guy -Tag 'OPEN MIC NIGHT' -Sw $Sw -Times 2; Pause $Beat
    # 2. THE SETUP
    Draw -Picture $Guy -Tag 'THE SETUP' -RecOn $true -Time (Tc $Sw)
    Lower -Tag 'HIM' -Quote $bit.Setup; Pause $Hold
    # 3. THE PUNCH -- flat, slow, dead into the lens
    Draw -Picture $Lens -Tag 'DEADPAN' -RecOn $true -Time (Tc $Sw)
    Lower -Tag 'HIM  (deadpan, into camera)' -Quote $bit.Punch -QColor Yellow -Slow $true
    Sting rimshot; Pause 250
    # 4. THE BEAT -- total silence, the stare, a ticking clock
    foreach ($s in 1..3) {
        Draw -Picture $Lens -Tag 'B-ROLL' -RecOn $true -Time (Tc $Sw)
        Write-Host ''
        Write-Host '  >> ' -NoNewline -ForegroundColor DarkCyan
        Write-Host ('[ '+('.'*$s)+' dead silence '+('.'*$s)+' ]') -ForegroundColor DarkGray
        Pause ([int]($Hold*0.55)) }
    # 5. FLOORED
    Invoke-Floored -burn $bit.Burn -Sw $Sw }

function Show-SignOff { param([System.Diagnostics.Stopwatch]$Sw)
    Draw -Picture @(
        '                                  ',
        '       ~  THAT IS THE SHOW  ~      ',
        '                                  ',
        '   he has left the building, and  ',
        '   taken the building with him    ',
        '                                  ',
        '     tip your servers. flatly.    ',
        '                                  ') -Tag 'GOODNIGHT' -RecOn $false -Time (Tc $Sw) -Color Cyan
    Write-Host ''
    Write-Host '  >> ' -NoNewline -ForegroundColor DarkCyan
    Write-Host '[ deadpans one last time, then exits ]' -ForegroundColor DarkGray
    Pause $Hold }

# ============================ STORYBOARD =====================================
if ($Storyboard) {
    for ($e=1; $e -le $Scenes; $e++) {
        $bit = New-Bit
        "##### BIT $e  (burn $($bit.Burn)/3) #####"; ''
        '  [ OPEN ON THE GUY ]'
        ($Guy | ForEach-Object { '   |'+(Center $_ $SW)+'|' }) -join "`n"; ''
        '  [ THE SETUP ]'
        '   >> HIM'
        '   >> '+$bit.Setup; ''
        '  [ THE PUNCH -- deadpan, into the lens ]'
        '   >> HIM  (deadpan, into camera)'
        '   >> '+$bit.Punch; ''
        '  [ . . . dead silence . . . ]'; ''
        '  [ FLOORED ]'
        (New-Crowd $bit.Burn | ForEach-Object { '   |'+(Center $_ $SW)+'|' }) -join "`n"
        ($FlooredBanner | ForEach-Object { '   '+$_ }) -join "`n"
        '        '+(Pick $Reactions[$bit.Burn]); ''
        if ($e -lt $Scenes) { '  . : .  *click* next bit  . : .'; '' }
    }
    return
}

# ============================ LIVE ===========================================
try { [void][Console]::WindowWidth } catch {
    Write-Warning 'Live mode needs a real console. Try: .\Floored.ps1 -Storyboard'; return }
$prevCursor = $true
try { $prevCursor = [Console]::CursorVisible; [Console]::CursorVisible=$false } catch {}

try {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    Show-TitleCard
    $done = 0
    while ($true) {
        Invoke-Bit (New-Bit) $sw
        $done++; if ($Bits -gt 0 -and $done -ge $Bits) { break }
    }
    Show-SignOff $sw
}
finally {
    [Console]::ResetColor(); try { [Console]::CursorVisible=$prevCursor } catch {}
    Write-Host ''
    Write-Host '  *mic drop*   ...and the audience is still on their feet.' -ForegroundColor DarkGray
}
