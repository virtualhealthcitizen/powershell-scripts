<#
.SYNOPSIS
    DRAMA TV presents -- "MAKE A SCENE": a melodrama of public outbursts, staged
    in your terminal. It begins ordinary -- a bistro, a self-checkout, the 8:15 to
    Droitwich. Then something NEBALOSE happens (the soup is cold; the receipt is,
    somehow, WARM) and a perfectly normal person decides, profusely, to MAKE A
    SCENE. The chair SCRAPES. The room turns. RU JEALOSE THAT I'M MAKING A SCENE?
    The SCENE-O-METER climbs, the phones come out, four stars are awarded, and the
    room is FLOORED. Then they storm out (the door does not slam -- it auto-closes)
    and lo: THER WIL BE CONSEQUINCES. The SCENE, however, REMAINS.

    NOTE ON SPELLING: the misspellings are deliberate. NEBALOSE, JEALOSE, NEVORE,
    CONSEQUINCES, AGAN, SCEEENE -- that is the show's voice. On purpose.

.DESCRIPTION
    One episode is directed in beats:
      THE CALM BEFORE (a mundane setting, candlelit and nebalose)
        -> THE TRIGGER (something nebalose: the soup is cold)
        -> THE STANDING UP (the chair SCRAPES; the room half-turns)
        -> THE SCENE (the outburst escalates; the SCENE-O-METER pins)
        -> EVERYONE IS WATCHING (bystanders film it; four stars; a child asks why)
        -> FLOORED -> THE EXIT (storms out; the SCENE REMAINS)
        -> THER WIL BE CONSEQUINCES (a stamp) -> static.

    -Calm: they sit back down, breathe, and DON'T make a scene -- a quiet triumph.

    Live mode redraws in place with sound + motion (needs a real console).
    -Storyboard prints a representative montage of frames to stdout instead.

.PARAMETER Scenes      How many episodes before exiting. 0 (default) = forever.
.PARAMETER Silent      Disable the [Console]::Beep sound cues.
.PARAMETER Storyboard  Print a static montage to stdout (no animation / sound).
.PARAMETER Acts        Storyboard: how many scenes to lay out. Default 1.
.PARAMETER Seed        Fix the RNG for reproducible output. 0 = random.
.PARAMETER Fast        Snappier holds and typing. For the impatient.
.PARAMETER Calm        They keep it together. No scene. A quiet, dignified triumph.

.EXAMPLE
    .\Make-A-Scene.ps1
.EXAMPLE
    .\Make-A-Scene.ps1 -Scenes 2
.EXAMPLE
    .\Make-A-Scene.ps1 -Storyboard -Acts 1 -Seed 42
.EXAMPLE
    .\Make-A-Scene.ps1 -Calm           # for once, nobody makes a scene
#>
[CmdletBinding()]
param(
    [int]$Scenes = 0,
    [switch]$Silent,
    [switch]$Storyboard,
    [int]$Acts   = 1,
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
# The misspellings are DELIBERATE. This is the show's voice. On purpose.
$Names    = @('Brenda','Dave','Sharon','Keith','Pam','Geoff','Linda','Trevor',
              'Maureen','Barry','Sandra','Nigel','Cordelia','Rex','Tammy','Cletus')
$Settings = @('a quiet BISTRO -- candle, linen','the SELF-CHECKOUT, item unexpected','a HUSHED LIBRARY, 2 p.m.',
              'the 8:15 to DROITWICH','a CALM open-plan OFFICE','a GARDEN CENTRE cafe','aisle 7 of a BIG TESCO',
              'a DENTIST''S WAITING ROOM','a yoga class, mid-NAMASTE','a very nice GARDEN PARTY')
$Triggers = @('the soup arrives COLD.','the receipt is, somehow, WARM.','they said "no worries" ONE TOO MANY TIMES.',
              'the wifi asked to LOG IN AGAN.','someone took the LAST good chair.','the QR code would not, WOULD NOT, scan.',
              'they brought the WRONG kind of silence.','the oat milk was, in fact, NORMAL milk.','the napkin was FOLDED wrong.')
$Stand    = @('{P} pushes back the chair. it SCRAPES.','{P} stands. slowly. profusely.','{P} rises. the room half-turns.',
              '{P} sets down the fork. with INTENT.','{P} removes the napkin from the lap. ominously.')
$SceneLn  = @('IS THIS -- is this NEBALOSE TO YOU?!','I WILL NOT be SHUSHED, {V}!','EVERYONE is going to HEAR about the soup.',
              'NO. NO. we are doing this NOW.','I have NEVORE been so -- so SCENE about anything!',
              'RU JEALOSE? RU JEALOSE THAT I''M MAKING A SCENE?','THER WIL be a SCENE. ther wil be CONSEQUINCES.',
              'do you KNOW who I -- no. NO. it doesn''t matter. SCENE.','this is NOT about the soup. (it is about the soup.)')
$Watchers = @('a man at table four films it, silently','the barista freezes, milk still steaming',
              'a child says, loudly, "why is that person"','someone whispers "is this a FLASH MOB?"',
              'it already has FOUR STARS and a review','a woman spills water on her lap and exits',
              '(automobiles, outside, driving by swiftly)','a dog, somewhere, begins to howl in support')
$Exits    = @('{P} storms out. the door does not slam (auto-close).','{P} exits. returns for the coat. exits AGAN.',
              '{P} leaves to a silence so loud it FLOORS the room.','{P} sweeps out. the SCENE, however, REMAINS.')
$Conseq   = @('THER WIL BE CONSEQUINCES.','THE SCENE: MADE.','ONE (1) SCENE, MADE, FOREVER.',
              'CONSEQUINCES (NEBALOSE) TO FOLLOW.','THE SCENE REMAINS. THE SOUP, ALSO, REMAINS.')

# ============================ Set-piece art ==================================
# The scene-maker, arms up, mid-outburst.
function Get-SceneArt { param([string]$face)
    @("      \$face/      ",
      "       /|  |\       ",
      "       _|  |_       ")
}

# ============================ Shot builders ==================================
function Get-CardShot { param([string]$l1,[string]$l2,[string]$color)
    $rows=@(LB)
    1..4 | ForEach-Object { $rows+=Blank }
    $rows+=Cell (Center ('*'+('='*32)+'*') $SW) 'DarkGray'
    $rows+=Cell (Center $l1 $SW) $color
    $rows+=Cell (Center $l2 $SW) 'DarkGray'
    $rows+=Cell (Center ('*'+('='*32)+'*') $SW) 'DarkGray'
    Fit $rows }

# THE CALM BEFORE -- a mundane, candlelit, nebalose setting.
function Get-SettingShot { param([string]$where)
    $rows=@(LB)
    1..2 | ForEach-Object { $rows+=Blank }
    $rows+=Cell (Center 'the calm before . . .' $SW) 'DarkGray'
    $rows+=Blank
    $w=Wrap2 $where $SW
    $rows+=Cell $w[0] 'Gray'
    $rows+=Cell $w[1] 'DarkGray'
    $rows+=Blank
    $rows+=Cell (Center '(nothing is wrong. nothing at all.)' $SW) 'DarkGray'
    $rows+=(LB)
    Fit $rows }

# THE TRIGGER -- something nebalose. a spark.
function Get-TriggerShot { param([string]$line)
    $rows=@(LB)
    1..3 | ForEach-Object { $rows+=Blank }
    $rows+=Cell (Center '. . . and then . . .' $SW) 'DarkYellow'
    $rows+=Blank
    $w=Wrap2 $line $SW
    $rows+=Cell $w[0] 'Yellow'
    $rows+=Cell $w[1] 'Yellow'
    $rows+=(LB)
    Fit $rows }

# THE SCENE -- the scene-maker, mid-outburst, the chyron scrolling.
function Get-SceneShot { param($ep,[string]$line,[int]$chy)
    $face=Pick @('(>_<)','(>O<)','(XoX)','(ToT)','(@_@)')
    $name=(' '*$SW).ToCharArray(); $nm=$ep.Maker.ToUpper(); $st=[Math]::Max(0,25-[int]($nm.Length/2))
    for ($k=0;$k -lt $nm.Length -and ($st+$k)-lt $SW;$k++){ $name[$st+$k]=$nm[$k] }
    $w=Wrap2 $line $SW
    $rows=@(
        (LB),
        (Cell (Center ('<  MAKING A SCENE  >') $SW) 'Cyan'),
        (Cell ('~'*$SW) 'DarkCyan'),
        (Blank))
    foreach ($l in (Get-SceneArt $face)) { $rows+=Cell (Center $l $SW) 'Red' }
    $rows+=Cell (-join $name) 'DarkRed'
    $rows+=Cell $w[0] 'White'
    $rows+=Cell $w[1] 'White'
    $rows+=Cell (' '+(ChyronWindow $ep.Chyron $chy ($SW-2))+' ') 'Red'
    $rows+=(LB)
    Fit $rows }

# EVERYONE IS WATCHING -- bystanders pile up, the meter spikes.
function Get-WatchShot { param([string[]]$stack,[int]$stars)
    $rows=@(LB)
    $rows+=Cell (Center "EVERYONE IS WATCHING  ($stars stars)" $SW) 'Red'
    $rows+=Cell ('-'*$SW) 'DarkGray'
    foreach ($s in ($stack | Select-Object -Last 6)) { $rows+=Cell (Center ("[*] "+$s) $SW) (Pick @('Yellow','DarkYellow','White','Gray')) }
    $rows+=(LB)
    Fit $rows }

# THE EXIT -- through the door (which does not slam).
function Get-ExitShot { param([string]$line)
    $door=@('   .------.   ','   |      |   ','   |  ()  |   ','   |      |   ','   ''------''   ')
    $rows=@(LB)
    foreach ($l in $door) { $rows+=Cell (Center $l $SW) 'DarkCyan' }
    $w=Wrap2 $line $SW
    $rows+=Cell $w[0] 'White'
    $rows+=Cell $w[1] 'White'
    $rows+=(LB)
    Fit $rows }

# THE CONSEQUINCES -- a stamp slams down.
function Get-ConsequenceShot { param([string]$line)
    $rows=@(LB)
    1..2 | ForEach-Object { $rows+=Blank }
    $rows+=Cell (Center '.----------------------------.' $SW) 'Red'
    $rows+=Cell (Center ('|  '+(Center $line 24)+'  |') $SW) 'Red'
    $rows+=Cell (Center "'----------------------------'" $SW) 'Red'
    $rows+=Blank
    $rows+=Cell (Center '(the scene remains, forever)' $SW) 'DarkGray'
    $rows+=(LB)
    Fit $rows }

function Get-FlashShot { Fit (1..$SH | ForEach-Object { Cell ([string][char]0x2588 * $SW) 'White' }) }
function Get-StaticShot { param([string]$banner='>>  SCENE IN PROGRESS  <<')
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
    $desc=@{ hush='. . . a normal day . . .';murmur='a tension gathers';gasp='the room NOTICES';clap='OH, A SCENE!';
             feet='A FULL SCENE!';floor='*** F L O O R E D ***';slam='*** S C E N E   M A D E ***' }[$mood]
    $txt="SCENE-O-METER [$bar] $desc"
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
    $cnt='{0:000}' -f $script:SceneNo
    Row ('|'+(Pad ("   (CH 99)        ( o )      ( o )        <  MAKE A SCENE [#$cnt]  >  ") ($TW-2))+'|') $body
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
    'calm'      { Beep 392 140; Beep 440 200 }                              # a peaceful establishing chord
    'trigger'   { Beep 660 70; Beep 392 160 }                              # the spark
    'scrape'    { 1..4 | ForEach-Object { Beep (RNext 90 150) 35 } }       # the chair, scraping
    'scene'     { 1..5 | ForEach-Object { Beep (RNext 500 820) 35 } }      # the outburst
    'gasp'      { Beep 622 70; Beep 831 80; Beep 1047 150 }
    'shutter'   { Beep 1500 30; Beep 90 60 }                              # a phone takes a photo
    'stars'     { foreach ($f in 988,1319,1568) { Beep $f 70 } }          # four stars, awarded
    'door'      { Beep 300 90; Beep 240 200 }                              # the door (does not slam)
    'slam'      { Beep 150 60; Beep 95 200; Beep 60 320 }
    'stamp'     { Beep 200 60; Beep 90 260 }                              # CONSEQUINCES, stamped
    'sigh'      { Beep 300 80; Beep 240 320 }
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

# ============================ Scene builder ==================================
$script:SceneNo = RNext 12 48          # scenes already made this season
function New-Scene {
    $m=Pick $Names
    [pscustomobject]@{
        Maker=$m; Where=(Pick $Settings); Trigger=(Pick $Triggers); Conseq=(Pick $Conseq)
        Chyron=("MAKE A SCENE   ***   RU JEALOSE THAT I'M MAKING A SCENE   ***   IS THIS NEBALOSE TO YOU   ***   THER WIL BE CONSEQUINCES   ***   ").ToUpper() } }

# ============================ The director ===================================
function Invoke-Scene { param($ep)
    $script:SceneNo++
    # 1. THE CALM BEFORE
    React 0.12 calm
    Show-Live (Get-SettingShot $ep.Where) $false; Sting calm; Hold 1100; if (Test-Quit){throw 'quit'}
    # 2. THE TRIGGER
    React 0.3 trigger
    Show-Live (Get-TriggerShot $ep.Trigger) $false; Sting trigger; Hold 1000; if (Test-Quit){throw 'quit'}
    if ($script:Calm) {
        # the dignified timeline: they breathe, and DON'T make a scene
        React 0.5
        Show-Live (Get-CardShot 'they take a breath.' '. . . and let it go.' 'Green') $false; Sting sigh; Hold 1100
        React 0.85 ovation
        Show-Live (Get-CardShot 'NO SCENE TODAY.' 'a quiet, dignified triumph.' 'Green') $false; Sting ovation; Hold 1200
        return
    }
    # 3. THE STANDING UP
    React 0.45
    Show-Live (Get-CardShot 'THE STANDING UP' ((Pick $Stand).Replace('{P}',$ep.Maker)) 'Yellow') $false; Sting scrape; Hold 950; if (Test-Quit){throw 'quit'}
    # 4. THE SCENE -- escalating outburst
    $chy=0
    foreach ($f in 1..7) {
        $line=(Pick $SceneLn).Replace('{V}',$Viewer)
        React ([Math]::Min(0.9, 0.5+$f*0.07))
        Show-Live (Get-SceneShot $ep $line $chy) $false; $chy+=2
        if ($f % 2 -eq 0) { Sting scene }
        Hold 280; if (Test-Quit){throw 'quit'} }
    # 5. EVERYONE IS WATCHING -- bystanders pile up, stars accrue
    $stack=@(); $stars=1
    foreach ($f in 1..6) {
        $stack += (Pick $Watchers); $stars=[Math]::Min(5,$stars+ (RNext 0 2))
        React ([Math]::Min(0.95, 0.6+$f*0.06))
        Show-Live (Get-WatchShot $stack $stars) $false
        if ($f % 2 -eq 0){ Sting shutter } else { Sting stars }
        Hold ([Math]::Max(150,320-$f*26)); if (Test-Quit){throw 'quit'} }
    # 6. FLOORED
    $script:Reaction=0.2
    Show-Live (Get-CardShot 'THE ROOM IS' 'F L O O R E D' 'Red') $false; Invoke-Flash; Sting gasp; Hold 400
    Invoke-Slam (Get-CardShot 'THE ROOM IS' 'F L O O R E D' 'Red')
    # 7. THE EXIT
    React 0.7
    Show-Live (Get-ExitShot ((Pick $Exits).Replace('{P}',$ep.Maker))) $false; Sting door; Hold 1100; if (Test-Quit){throw 'quit'}
    # 8. THER WIL BE CONSEQUINCES
    React 0.6
    Show-Live (Get-ConsequenceShot $ep.Conseq) $false; Invoke-Flash; Sting stamp; Hold 1200; if (Test-Quit){throw 'quit'}
    $black=@(1..$SH | ForEach-Object { Cell (' '*$SW) 'Black' })
    $rows=@($black); $rows[6]=Cell (Center 'the management names a person of interest:' $SW) 'DarkGray'
    $rows[8]=Cell (Center "$Viewer." $SW) 'Red'
    Show-Raw $rows $false; Beep 200 200; Hold 1100; if (Test-Quit){throw 'quit'}
    # 9. SCENE IN PROGRESS -> static
    foreach ($s in 1..(RNext 5 8)){ Show-Live (Get-StaticShot) $true; Beep (RNext 200 600) 25; Hold 70; if (Test-Quit){throw 'quit'} } }

# ============================ STORYBOARD =====================================
if ($Storyboard) {
    for ($e=1; $e -le $Acts; $e++) {
        $ep=New-Scene
        "##### SCENE $e : MAKE A SCENE -- $($ep.Maker), in $($ep.Where) #####"; ''
        $script:Reaction=0.12; $script:SlamFrames=0
        '  [ THE CALM BEFORE -- a mundane, nebalose setting ]'
        Show-Plain (Get-SettingShot $ep.Where) $false; ''
        '  [ THE TRIGGER -- something nebalose ]'
        Show-Plain (Get-TriggerShot $ep.Trigger) $false; ''
        $script:Reaction=0.45
        '  [ THE STANDING UP -- the chair SCRAPES ]'
        Show-Plain (Get-CardShot 'THE STANDING UP' (($Stand[0]).Replace('{P}',$ep.Maker)) 'Yellow') $false; ''
        $script:Reaction=0.75
        '  [ THE SCENE -- RU JEALOSE THAT I''M MAKING A SCENE? ]'
        Show-Plain (Get-SceneShot $ep 'RU JEALOSE THAT I''M MAKING A SCENE?' 0) $false; ''
        '  [ EVERYONE IS WATCHING -- four stars and a review ]'
        Show-Plain (Get-WatchShot @('a man at table four films it, silently','it already has FOUR STARS and a review','a child says, loudly, "why is that person"') 4) $false; ''
        $script:SlamFrames=7; $script:Reaction=1.0
        '  [ FLOORED -- the room is levelled ]'
        Show-Plain (Get-CardShot 'THE ROOM IS' 'F L O O R E D' 'Red') $false; ''
        $script:SlamFrames=0
        if ($Calm) {
            $script:Reaction=0.85
            '  [ THE DIGNIFIED TIMELINE -- no scene today ]'
            Show-Plain (Get-CardShot 'NO SCENE TODAY.' 'a quiet, dignified triumph.' 'Green') $false; ''
        } else {
            '  [ THE EXIT -- the door does not slam (auto-close) ]'
            Show-Plain (Get-ExitShot (($Exits[0]).Replace('{P}',$ep.Maker))) $false; ''
            '  [ THER WIL BE CONSEQUINCES -- the stamp comes down ]'
            Show-Plain (Get-ConsequenceShot $ep.Conseq) $false; ''
        }
    }
    return
}

# ============================ LIVE ===========================================
try { [void][Console]::WindowWidth } catch {
    Write-Warning 'Live mode needs a real console. Try: .\Make-A-Scene.ps1 -Storyboard'; return }
$prevCursor=[Console]::CursorVisible
try { [Console]::CursorVisible=$false } catch {}
$script:Live=$true; $count=0
function Test-Quit { try { if ([Console]::KeyAvailable){[void][Console]::ReadKey($true);return $true} } catch {}; return $false }

try {
    while ($true) {
        Invoke-Scene (New-Scene)
        $count++; if ($Scenes -gt 0 -and $count -ge $Scenes) { break }
    }
}
catch { if ("$_" -notmatch 'quit') { throw } }
finally {
    [Console]::ResetColor(); try { [Console]::CursorVisible=$prevCursor } catch {}
    Write-Host ''; Write-Host '  *click*   ...the scene is over. the scene REMAINS. (ther wil be consequinces.)' -ForegroundColor DarkGray
}
