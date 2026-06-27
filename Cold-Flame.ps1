<#
.SYNOPSIS
    DRAMA TV presents -- "COLD FLAME": a 3 a.m. DRIVE-THRU TRAGEDY, staged in
    your terminal. BURGER MAJESTY, off the interstate. One lonely night-shift
    employee. An empty dining room humming under dead fluorescents. A single
    burger going cold beneath a heat lamp that burned out weeks ago. He confesses
    everything to the drive-thru speaker; only static answers back. The shake
    machine is, of course, down. Then THE REVEAL: the flame-broiler sputters
    once in the dark... and the order comes up for YOU -- but no one is coming.

.DESCRIPTION
    One episode is directed in beats:
      3:00 A.M. -- BURGER MAJESTY, OFF THE INTERSTATE
        -> THE LONELY SHIFT (one employee, an empty room, the freezer hum)
        -> THE COLD BURGER (a confession to a burger under a dead heat lamp)
        -> THE DRIVE-THRU CONFESSIONAL (he speaks; the speaker answers in static)
        -> THE SHAKE MACHINE IS DOWN (it is always down)
        -> THE REVEAL (the flame-broiler sputters; a truth about low temperature
           and lonely people) -- the room is FLOORED
        -> ORDER UP FOR {VIEWER} (...but no one comes to the counter)
        -> NOW SERVING: NO ONE -> fade to a cold, greasy static.

    -Calm gives it a warmer ending: the flame catches, a late customer arrives,
    the burger is remade hot. Otherwise the flame stays low, and so do we.

    Live mode redraws in place with sound + motion (needs a real console).
    -Storyboard prints a representative montage of frames to stdout instead.

.PARAMETER Shifts      How many tragedies before exiting. 0 (default) = forever.
.PARAMETER Silent      Disable the [Console]::Beep sound cues.
.PARAMETER Storyboard  Print a static montage to stdout (no animation / sound).
.PARAMETER Scenes      Storyboard: how many shifts to lay out. Default 1.
.PARAMETER Seed        Fix the RNG for reproducible output. 0 = random.
.PARAMETER Fast        Snappier holds and typing. For the impatient.
.PARAMETER Calm        A warmer ending: the flame catches, a customer arrives.

.EXAMPLE
    .\Cold-Flame.ps1
.EXAMPLE
    .\Cold-Flame.ps1 -Shifts 2
.EXAMPLE
    .\Cold-Flame.ps1 -Storyboard -Scenes 1 -Seed 42
.EXAMPLE
    .\Cold-Flame.ps1 -Calm           # the flame catches; someone comes
#>
[CmdletBinding()]
param(
    [int]$Shifts = 0,
    [switch]$Silent,
    [switch]$Storyboard,
    [int]$Scenes = 1,
    [int]$Seed   = 0,
    [switch]$Fast,
    [switch]$Calm
)

# ============================ RNG ============================================
$seedVal = if ($Seed -gt 0) { $Seed } else { [Environment]::TickCount }
$rng = [Random]::new($seedVal)
function Pick  { param($a) $a[$rng.Next($a.Count)] }
function RNext { param([int]$lo,[int]$hi) $rng.Next($lo,$hi) }
$script:Silent = [bool]$Silent
$script:Calm   = [bool]$Calm
$tscale = if ($Fast) { 0.5 } else { 1.0 }
function Hold { param([int]$d) Start-Sleep -Milliseconds ([int]($d*$tscale)) }

# ============================ Geometry =======================================
$SW = 50; $SH = 15; $TW = 66
function Pad    { param([string]$s,[int]$w) if ($s.Length -ge $w) { $s.Substring(0,$w) } else { $s + (' ' * ($w-$s.Length)) } }
function Center { param([string]$s,[int]$w)
    if ($s.Length -ge $w) { return $s.Substring(0,$w) }
    $l=[int](($w-$s.Length)/2); (' '*$l)+$s+(' '*($w-$s.Length-$l)) }
function Cell   { param([string]$t,[string]$c) [pscustomobject]@{ Text=$t; Color=$c } }
function Blank  { Cell (' '*$SW) 'Green' }
function LB     { Cell ([string][char]0x2588 * $SW) 'DarkGray' }
function Fit    { param($rows)
    $r = @($rows | ForEach-Object { Cell (Pad $_.Text $SW) $_.Color })
    while ($r.Count -lt $SH) { $r += Blank }
    if ($r.Count -gt $SH) { $r = $r[0..($SH-1)] }; ,$r }
function Wrap2 { param([string]$t,[int]$w)
    $words=$t -split ' '; $lines=@(); $cur=''
    foreach ($wd in $words) { if ($cur -eq ''){$cur=$wd} elseif (($cur.Length+1+$wd.Length)-le $w){$cur+=' '+$wd} else {$lines+=$cur;$cur=$wd} }
    if ($cur -ne ''){$lines+=$cur}; while ($lines.Count -lt 2){$lines+=''}
    @((Center $lines[0] $w),(Center $lines[1] $w)) }
function ChyronWindow { param([string]$s,[int]$off,[int]$w)
    while ($s.Length -lt ($w*2)) { $s += $s }; ($s+$s).Substring($off % $s.Length, $w) }

# ============================ Word banks =====================================
$Names = @('Wayne','Dale','Marv','Stan','Lou','Gus','Earl','Cal','Norm','Dot','Rae','Sal','Burt','Hank')
# Tragic confessions, delivered to inanimate fast-food objects.
$Confess = @('I always wanted to be the breakfast shift, you know?','She left on a Tuesday. We were out of pickles that day too.',
             'Forty years of flame-broiling and what do I have? A name tag.','I talk to the soda fountain now. It listens better than most.',
             'The heat lamp went out the same week she did.','I keep the lobby spotless. Nobody ever sees it.',
             'I gave this place my best years and a deposit on a sedan.','Every burger I make, I make for one. It''s always for one.',
             'I memorised the whole menu. There''s no one left to recite it to.')
$Speaker = @('* the drive-thru speaker crackles with static *','* a moth taps the menu board, then leaves *',
             '* the fryer beeps for a basket no one ordered *','* the ice machine drops a single cube, alone *',
             '* the floor mop leans against the wall like a friend *','* the headset hums an empty channel *',
             '* the bell DINGs. nobody is at the door. *')
$ShakeGag = @('THE SHAKE MACHINE IS DOWN.','THE SHAKE MACHINE IS, AS EVER, DOWN.','THE SHAKE MACHINE HAS ALWAYS BEEN DOWN.',
              'THE SHAKE MACHINE WAS NEVER UP.','OUT OF SHAKES. OUT OF EVERYTHING, REALLY.')
$Reveals = @('the flame was never coming back, {W}.','you were the low-temperature one all along, {W}.',
             'the lobby was empty because YOU never left, {W}.','there was no night shift. there was only the night, {W}.',
             'the order was for you, {W}. it was always for you.','nobody is coming to the counter, {W}. nobody ever was.',
             'the burger was cold because the cook was, {W}.')
$Punch  = @('order up... for no one.','now serving: no one.','your table is ready. you are the only table.',
            'fresh, hot, and for absolutely nobody.','have it your way. there is only your way.')

# ============================ Set-piece art ==================================
# A burger. Cold. The steam lines are blank because the heat lamp is dead.
function Get-BurgerArt { param([bool]$hot)
    $steam = if ($hot) { @('   ( ( (   ',"    ) ) )   ",'   ( ( (   ') } else { @('           ','           ','           ') }
    $b = @('   .-"""""-.   ',
           '  /  . . .  \  ',
           ' ( ~ ~ ~ ~ ~ ) ',
           '  )=========(  ',
           ' ( @ @ @ @ @ ) ',
           '  \  _____  /  ',
           '   ''-.....-''   ')
    ,@($steam + $b) }

# The dead heat lamp over the holding station.
$HeatLamp = @('  ___________  ',
              ' [___________] ',
              '  \         /  ',
              '   \  ( )  /   ',     # ( ) = the bulb, dark
              '    \_____/    ')

# The drive-thru speaker / order box.
$SpeakerBox = @(' .-----------. ',
                ' | . . . . . | ',
                ' | . [MENU] . | ',
                ' | . . . . . | ',
                ' ''--[SPEAK]--'' ')

# ============================ Shot builders ==================================
function Get-CardShot { param([string]$l1,[string]$l2,[string]$color)
    $rows=@(LB)
    1..4 | ForEach-Object { $rows+=Blank }
    $rows+=Cell (Center ('-'*34) $SW) 'DarkGray'
    $rows+=Cell (Center $l1 $SW) $color
    $rows+=Cell (Center $l2 $SW) 'DarkGray'
    $rows+=Cell (Center ('-'*34) $SW) 'DarkGray'
    Fit $rows }

# The empty dining room: one worker behind the counter, rows of empty tables.
function Get-LobbyShot { param($shift,[string]$line,[int]$chy,[bool]$buzz)
    $lights = if ($buzz) { Pick @('- - *bzzt* - - - - - - -','- - - - - - *flick* - - -','- - - - - - - - - - - - -') } else { '- - - - - - - - - - - - -' }
    $worker = Pick @('(._.)','(-_-)','(u_u)','(._. )')
    $tables = ' o   o   o   o   o '       # empty two-tops
    $rows=@(
        (LB),
        (Cell (Center ('<  '+$shift.Title.ToUpper()+'  >') $SW) 'Cyan'),
        (Cell (Center $lights $SW) ($(if($buzz){'White'}else{'DarkGray'}))),
        (Cell (Center '.----------------------------.' $SW) 'DarkYellow'),
        (Cell (Center ("| BURGER MAJESTY   $worker  |") $SW) 'Yellow'),
        (Cell (Center '|  [====] counter  [open?]   |' $SW) 'DarkYellow'),
        (Cell (Center "'----------------------------'" $SW) 'DarkYellow'),
        (Cell (Center $tables $SW) 'DarkGray'),
        (Cell (Center $tables $SW) 'DarkGray') )
    $w=Wrap2 $line $SW
    $rows += @(
        (Cell $w[0] 'White'),
        (Cell $w[1] 'White'),
        (Cell (' '+(ChyronWindow $shift.Chyron $chy ($SW-2))+' ') 'Red'),
        (LB) )
    Fit $rows }

# The cold burger under the dead lamp, with a confession lower-third.
function Get-BurgerShot { param([string]$caption,[bool]$hot)
    $art = Get-BurgerArt $hot
    $rows=@(LB)
    foreach ($l in $HeatLamp[0..1]) { $rows+=Cell (Center $l $SW) 'DarkGray' }
    foreach ($l in $art) { $rows+=Cell (Center $l $SW) ($(if($hot){'Yellow'}else{'DarkYellow'})) }
    $w=Wrap2 $caption $SW
    $rows+=Cell $w[0] 'White'
    $rows+=Cell $w[1] 'White'
    $rows+=(LB)
    Fit $rows }

# The drive-thru confessional: the speaker box, and what it says back (static).
function Get-SpeakerShot { param([string]$said,[string]$reply)
    $rows=@(LB)
    foreach ($l in $SpeakerBox) { $rows+=Cell (Center $l $SW) 'DarkCyan' }
    $w=Wrap2 $said $SW
    $rows+=Cell $w[0] 'White'
    $rows+=Cell $w[1] 'White'
    $rows+=Cell (Center $reply $SW) 'DarkGray'
    $rows+=(LB)
    Fit $rows }

function Get-RevealShot { param([string]$hence,[bool]$hot)
    $flame = if ($hot) { Pick @(') ( )','( ) (','){ }(') } else { Pick @('. . .',' .   ','  .  ') }
    $w=Wrap2 ("...$hence") $SW
    $rows=@(LB)
    1..1 | ForEach-Object { $rows+=Blank }
    $rows+=Cell (Center $flame $SW) ($(if($hot){'Yellow'}else{'DarkGray'}))
    $rows+=Cell (Center '\\|//' $SW) ($(if($hot){'DarkYellow'}else{'DarkGray'}))   # the broiler
    $rows+=Cell (Center '=====' $SW) 'DarkGray'
    $rows+=Blank
    $rows+=Cell $w[0] 'White'
    $rows+=Cell $w[1] 'White'
    $rows+=(LB)
    Fit $rows }

function Get-FlashShot { Fit (1..$SH | ForEach-Object { Cell ([string][char]0x2588 * $SW) 'White' }) }
function Get-StaticShot { param([string]$banner='>>  NOW SERVING: NO ONE  <<')
    $noise='#%&@*+=:;.,/\|<>~oO0'.ToCharArray(); $rows=@()
    for ($y=0;$y -lt $SH;$y++) {
        $sb=[System.Text.StringBuilder]::new(); for ($x=0;$x -lt $SW;$x++){[void]$sb.Append($noise[$rng.Next($noise.Count)])}
        $row=$sb.ToString(); if ($y -eq 7){ $row=Center $banner $SW }
        $rows+=Cell $row (Pick @('Gray','DarkGray','White')) }
    Fit $rows }
function Dim { param($cells,[int]$step) $map=@{0='White';1='Gray';2='DarkGray';3='Black'}; @($cells | ForEach-Object { Cell $_.Text $map[$step] }) }

# ============================ Audience + meter ===============================
$AUDN=9; $script:Reaction=0.0; $script:SlamFrames=0
function React { param([double]$to,[string]$sting='') if ($to -gt $script:Reaction){$script:Reaction=[Math]::Min(1.0,$to)}; if ($sting -and $script:Live){Sting $sting} }
function Get-Mood {
    if ($script:SlamFrames -gt 3){return 'slam'}; if ($script:SlamFrames -gt 0){return 'floor'}
    $r=$script:Reaction
    if ($r -ge 0.82){'feet'} elseif ($r -ge 0.60){'clap'} elseif ($r -ge 0.40){'gasp'} elseif ($r -ge 0.18){'murmur'} else {'hush'} }
function Get-AudienceRow {
    $mood=Get-Mood
    $base=@{ hush='(o)';murmur='(o)';gasp='(O)';clap='\o/';feet='\O/';floor=' x)';slam='___' }[$mood]
    $seats=@(); for ($i=0;$i -lt $AUDN;$i++){ $s=$base
        switch ($mood) {
            'murmur'{ if ($rng.Next(100)-lt 25){$s='(o,'} }
            'gasp'  { if ($rng.Next(100)-lt 30){$s='(@)'} }
            'clap'  { if ($rng.Next(100)-lt 40){$s=Pick @('\o/','/o\','\O/')} }
            'feet'  { if ($rng.Next(100)-lt 45){$s=Pick @('\O/','\o/','|O|')} }
            'floor' { $s=Pick @(' x)','(x ','\_ ',' _/','o_o','._.') }
            'slam'  { $s=Pick @('___','_x_',' . ','_ _',' ._') } }
        $seats+=$s }
    $col=@{ hush='DarkGray';murmur='Gray';gasp='White';clap='Yellow';feet='Yellow';floor='Red';slam='Red' }[$mood]
    Cell (Center (($seats -join '  ')) $TW) $col }
function Get-MeterRow {
    $mood=Get-Mood; $r=[Math]::Max(0.0,[Math]::Min(1.0,$script:Reaction))
    $w=14; $fill=[int][Math]::Round($r*$w); $bar=([string][char]0x2588*$fill)+([string][char]0x2591*($w-$fill))
    $desc=@{ hush='. . . hushed . . .';murmur='a murmur ripples';gasp='the room GASPS';clap='APPLAUSE!';
             feet='ON ITS FEET!';floor='*** F L O O R E D ***';slam='*** S L A M M E D ***' }[$mood]
    $txt="SADNESS-O-METER [$bar] $desc"
    $col= if ($mood -in 'floor','slam'){'Red'} elseif ($r -ge 0.7){Pick @('Red','Yellow')} elseif ($r -ge 0.4){'Yellow'} elseif ($r -ge 0.18){'White'} else {'DarkGray'}
    Cell (Center $txt $TW) $col }

# ============================ TV chrome ======================================
function Build-Tv { param($cells,[bool]$static)
    $out=New-Object 'System.Collections.Generic.List[object]'
    function Row { param($t,$c) $out.Add((Cell $t $c)) }
    $body='DarkGray'; $frame='DarkCyan'
    if ($static) { Row (Center '.   *      .       *   .' $TW) 'Yellow' } else { Row (' '*$TW) $body }
    Row (Center '\                 /' $TW) $body
    Row (Center '  \             /  ' $TW) $body
    Row (Center '   \____ ___ ___/  ' $TW) $body
    Row ('.'+('-'*($TW-2))+'.') $body
    Row ('|'+(' '*($TW-2))+'|') $body
    Row ('|'+(' '*5)+'.'+('-'*($SW+2))+'.'+(' '*5)+'|') $frame
    foreach ($c in $cells) { Row ('|'+(' '*5)+'| '+(Pad $c.Text $SW)+' |'+(' '*5)+'|') $c.Color }
    Row ('|'+(' '*5)+"'"+('-'*($SW+2))+"'"+(' '*5)+'|') $frame
    Row ('|'+(' '*($TW-2))+'|') $body
    Row ('|'+(Pad ("   (CH 86)        ( o )      ( o )        <  C O L D   F L A M E  >  ") ($TW-2))+'|') $body
    Row ('|'+(Pad ("    (O) PWR        VOL        TINT              [|||||||||]       ") ($TW-2))+'|') $body
    Row ("'"+('-'*($TW-2))+"'") $body
    Row (Center '||                                        ||' $TW) $body
    Row (Center '[==]                                    [==]' $TW) $body
    Row (Center 'L I V E   S T U D I O   A U D I E N C E' $TW) 'DarkGray'
    $out.Add((Get-AudienceRow)); $out.Add((Get-MeterRow))
    ,$out }

# ============================ Sound ==========================================
function Beep { param([int]$f,[int]$ms) if (-not $script:Silent) { try { [Console]::Beep($f,$ms) } catch {} } }
function Sting { param([string]$n) switch ($n) {
    'open'      { foreach ($f in 294,262,247) { Beep $f 150 } }            # lonely descending
    'buzz'      { 1..2 | ForEach-Object { Beep 110 100 } }                 # fluorescent flicker
    'fryer'     { Beep 880 60; Beep 660 60 }                               # a basket nobody ordered
    'static'    { 1..3 | ForEach-Object { Beep (RNext 1200 2600) 18 } }    # the speaker
    'reveal'    { Beep 392 150; Beep 330 150; Beep 247 600 }
    'slam'      { Beep 150 60; Beep 95 200; Beep 60 320 }
    'sigh'      { Beep 300 80; Beep 240 320 }
    'ding'      { Beep 1047 120 }                                          # order up (for no one)
    'flame'     { foreach ($f in 196,262,330,392,523) { Beep $f 70 } }     # the flame catches (calm only)
    'ovation'   { 1..16 | ForEach-Object { Beep (RNext 220 920) 15 }; Beep 740 220 } } }

# ============================ Renderers ======================================
function Show-Raw  { param($cells,[bool]$static,[int]$indent=3) $tv=Build-Tv $cells $static; Clear-Host; Write-Host ''; foreach ($l in $tv){ Write-Host ((' '*$indent)+$l.Text) -ForegroundColor $l.Color } }
function Show-Live { param($cells,[bool]$static,[int]$indent=3)
    if ($script:SlamFrames -gt 0){$script:SlamFrames--; $script:Reaction=1.0} else {$script:Reaction=[Math]::Max(0.0,$script:Reaction*0.90-0.012)}
    Show-Raw $cells $static $indent }
function Show-Plain{ param($cells,[bool]$static) (Build-Tv $cells $static) | ForEach-Object { $_.Text } }
function Invoke-Flash { 1..2 | ForEach-Object { Show-Live (Get-FlashShot) $false; Beep (RNext 60 90) 70; Hold 55 } }
function Invoke-Shake { param($cells) foreach ($o in 6,1,5,0,4,2){ Show-Live $cells $false $o; Hold 35 } }
function Invoke-Slam { param($cells) $script:Reaction=1.0; $script:SlamFrames=7; Sting slam; Invoke-Shake $cells; Sting ovation }

# ============================ Viewer name ====================================
function Format-ViewerName { param([string]$raw)
    if (-not $raw) { return '' }
    $n=($raw -split '[\\/@]')[-1]; $n=($n -replace '[^A-Za-z0-9 ]',' ' -replace '\s+',' ').Trim()
    if ($n){$n.ToUpper()}else{''} }
function Find-Viewer {
    try { Add-Type -AssemblyName System.DirectoryServices.AccountManagement -ErrorAction Stop
          $dn=Format-ViewerName ([System.DirectoryServices.AccountManagement.UserPrincipal]::Current.DisplayName); if ($dn){return $dn} } catch {}
    try { $n=Format-ViewerName ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name); if ($n){return $n} } catch {}
    try { $n=Format-ViewerName ([Environment]::UserName); if ($n){return $n} } catch {}
    'VIEWER' }
$Viewer = Find-Viewer; if (-not $Viewer){$Viewer='VIEWER'}

# ============================ Shift builder ==================================
function New-Shift {
    $a=Pick $Names
    [pscustomobject]@{
        Title='COLD FLAME'; Cook=$a
        Confess=(Pick $Confess); Speaker=(Pick $Speaker); Shake=(Pick $ShakeGag)
        Reveal=((Pick $Reveals).Replace('{W}',$a)); Punch=(Pick $Punch)
        Chyron=("FLAME-BROILER OFFLINE SINCE TUESDAY   ***   SHAKE MACHINE STILL DOWN   ***   $a WORKS ANOTHER DOUBLE   ***   LOBBY: EMPTY   ***   ").ToUpper() } }

# ============================ The director ===================================
function Invoke-Shift { param($shift)
    # 1. COLD OPEN
    React 0.3 open
    Show-Live (Get-CardShot '3:00 A.M. -- BURGER MAJESTY' 'off the interstate' 'White') $false; Sting open; Hold 1100; if (Test-Quit){throw 'quit'}
    # 2. THE LONELY SHIFT (lights buzz mid-scene)
    $chy=0
    foreach ($f in 1..10) {
        $buzz = ($f % 4 -eq 0)
        Show-Live (Get-LobbyShot $shift (Pick $Speaker) $chy $buzz) $false; $chy+=2
        if ($buzz) { Sting buzz } elseif ($f -eq 6) { Sting fryer }
        Hold 150; if (Test-Quit){throw 'quit'} }
    # 3. THE COLD BURGER -- a confession to a burger under a dead lamp
    React 0.45 sigh
    foreach ($f in 1..6) { Show-Live (Get-BurgerShot $shift.Confess $false) $false; if ($f -eq 1){Sting sigh}; Hold 320; if (Test-Quit){throw 'quit'} }
    # 4. THE DRIVE-THRU CONFESSIONAL
    React 0.5
    foreach ($reply in '* static *','* ...static... *','* a long, kind static *') {
        Show-Live (Get-SpeakerShot ("$($shift.Cook): `"$($shift.Confess)`"") $reply) $false; Sting static; Hold 700; if (Test-Quit){throw 'quit'} }
    # 5. THE SHAKE MACHINE IS DOWN
    Show-Live (Get-CardShot 'WE ARE SORRY TO INFORM YOU' $shift.Shake 'Red') $false; Beep 196 300; Hold 1100; if (Test-Quit){throw 'quit'}
    # 6. THE REVEAL -- the broiler sputters; the truth; FLOORED
    $script:Reaction=0.08
    foreach ($h in 1..3) { Beep 90 90; Show-Live (Get-RevealShot 'the truth is...' $false) $false; Hold 260 }
    Show-Live (Get-RevealShot $shift.Reveal $false) $false; Invoke-Flash; Sting reveal; Hold 500
    Invoke-Slam (Get-RevealShot $shift.Reveal $false)
    Show-Live (Get-RevealShot $shift.Reveal $false) $false; Hold 900; if (Test-Quit){throw 'quit'}
    if ($script:Calm) {
        # the warmer timeline: the flame catches, someone actually comes in
        React 0.85 flame
        foreach ($f in 1..4) { Show-Live (Get-BurgerShot 'the flame catches. a car pulls in.' $true) $false; Beep (RNext 300 700) 60; Hold 280 }
        React 0.95 ovation
        Show-Live (Get-CardShot 'ORDER UP -- HOT' 'a late customer, a remade burger' 'Yellow') $false; Sting ovation; Hold 1200
        return
    }
    # 7. ORDER UP FOR {VIEWER} -- but no one comes
    React 0.4
    Show-Live (Get-CardShot ("ORDER UP FOR $Viewer") 'now serving at the counter...' 'White') $false; Sting ding; Hold 1000; if (Test-Quit){throw 'quit'}
    $black=@(1..$SH | ForEach-Object { Cell (' '*$SW) 'Black' })
    foreach ($wait in 0..3) { $rows=@($black); $rows[7]=Cell (Center ('. . .'+('.'*$wait)) $SW) 'DarkGray'; Show-Raw $rows $false; Beep 70 80; Hold 500; if (Test-Quit){throw 'quit'} }
    $rows=@($black); $rows[7]=Cell (Center 'but no one comes to the counter.' $SW) 'DarkGray'; Show-Raw $rows $false; Sting sigh; Hold 1300
    Show-Live (Get-CardShot $shift.Punch.ToUpper() 'COLD FLAME' 'DarkGray') $false; Hold 1000
    # 8. NOW SERVING: NO ONE -> static
    foreach ($s in 1..(RNext 5 8)){ Show-Live (Get-StaticShot) $true; Beep (RNext 200 600) 25; Hold 70; if (Test-Quit){throw 'quit'} } }

# ============================ STORYBOARD =====================================
if ($Storyboard) {
    for ($e=1; $e -le $Scenes; $e++) {
        $shift=New-Shift
        "##### SHIFT $e : COLD FLAME -- $($shift.Cook), alone, 3 a.m. #####"; ''
        $script:Reaction=0.3; $script:SlamFrames=0
        '  [ COLD OPEN -- 3:00 A.M., BURGER MAJESTY, OFF THE INTERSTATE ]'
        Show-Plain (Get-CardShot '3:00 A.M. -- BURGER MAJESTY' 'off the interstate' 'White') $false; ''
        $script:Reaction=0.4
        '  [ THE LONELY SHIFT -- one worker, an empty dining room ]'
        Show-Plain (Get-LobbyShot $shift (Pick $Speaker) 0 $true) $false; ''
        $script:Reaction=0.45
        '  [ THE COLD BURGER -- a confession under a dead heat lamp ]'
        Show-Plain (Get-BurgerShot $shift.Confess $false) $false; ''
        '  [ THE DRIVE-THRU CONFESSIONAL -- the speaker answers in static ]'
        Show-Plain (Get-SpeakerShot ("$($shift.Cook): `"$($shift.Confess)`"") '* static *') $false; ''
        '  [ THE SHAKE MACHINE IS DOWN ]'
        Show-Plain (Get-CardShot 'WE ARE SORRY TO INFORM YOU' $shift.Shake 'Red') $false; ''
        $script:SlamFrames=7; $script:Reaction=1.0
        '  [ THE REVEAL -- the broiler sputters; the room is FLOORED ]'
        Show-Plain (Get-RevealShot $shift.Reveal $false) $false; ''
        $script:SlamFrames=0
        if ($Calm) {
            $script:Reaction=0.95
            '  [ A WARMER ENDING -- the flame catches, a customer arrives ]'
            Show-Plain (Get-BurgerShot 'the flame catches. a car pulls in.' $true) $false; ''
        } else {
            '  [ ORDER UP FOR YOU -- but no one comes to the counter ]'
            $black=@(1..$SH | ForEach-Object { Cell (' '*$SW) 'Black' })
            $rows=@($black); $rows[6]=Cell (Center "ORDER UP FOR $Viewer" $SW) 'White'
            $rows[8]=Cell (Center 'but no one comes to the counter.' $SW) 'DarkGray'
            Show-Plain $rows $false; ''
            '  [ NOW SERVING: NO ONE -> cold, greasy static ]'
            Show-Plain (Get-StaticShot) $true; ''
        }
    }
    return
}

# ============================ LIVE ===========================================
try { [void][Console]::WindowWidth } catch {
    Write-Warning 'Live mode needs a real console. Try: .\Cold-Flame.ps1 -Storyboard'; return }
$prevCursor=[Console]::CursorVisible
try { [Console]::CursorVisible=$false } catch {}
$script:Live=$true; $done=0
function Test-Quit { try { if ([Console]::KeyAvailable){[void][Console]::ReadKey($true);return $true} } catch {}; return $false }

try {
    while ($true) {
        Invoke-Shift (New-Shift)
        $done++; if ($Shifts -gt 0 -and $done -ge $Shifts) { break }
    }
}
catch { if ("$_" -notmatch 'quit') { throw } }
finally {
    [Console]::ResetColor(); try { [Console]::CursorVisible=$prevCursor } catch {}
    Write-Host ''; Write-Host '  *click*   ...lobby closed. drive safe.' -ForegroundColor DarkGray
}
