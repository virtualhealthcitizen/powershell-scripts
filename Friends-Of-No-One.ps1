<#
.SYNOPSIS
    DRAMA TV presents -- "FRIENDS OF NO ONE": an EMOTIONAL HOSTAGE SITUATION,
    staged in your terminal. Conference Room B. The fluorescent lights flicker.
    Everyone is holding everyone else emotionally hostage, and the demands are
    things like ACKNOWLEDGE MY FEELINGS and CC ME ON EVERYTHING. A weary HR
    negotiator works the room while a spiralling syllogism crawls across the
    screen -- a friend to all is a friend to no one; a friend of no one is a
    friend of everyone -- accelerating until it eats its own tail. Then THE
    REVEAL completes the logic, the room is FLOORED... and the cliffhanger lands:
    it doesn't matter, because they pay you. The meeting is recurring.

.DESCRIPTION
    One episode is directed in beats:
      EMOTIONAL HOSTAGE SITUATION -- CONFERENCE ROOM B
        -> THE STANDOFF (hostages round the table, emotional demands scroll)
        -> ENTER THE NEGOTIATOR (HR, with a clipboard and no remaining hope)
        -> THE PARADOX (the syllogism spirals, faster and faster, on a flicker)
        -> THE REVEAL (...hence: everyone is a friend of no one; no one is a
           friend of everyone; you are all each other's hostage) -- the room
           is FLOORED
        -> ...BUT THEY PAY YOU :3  (a paycheck flutters down; everyone sits
           back down) -> MEETING ADJOURNED... AND RECURRING (fade, then static).

    -Calm resolves it like a functional workplace: feelings acknowledged, meeting
    ends, no recursion. Otherwise the meeting is, of course, recurring.

    Live mode redraws in place with sound + motion (needs a real console).
    -Storyboard prints a representative montage of frames to stdout instead.

.PARAMETER Meetings    How many standoffs before exiting. 0 (default) = forever.
.PARAMETER Silent      Disable the [Console]::Beep sound cues.
.PARAMETER Storyboard  Print a static montage to stdout (no animation / sound).
.PARAMETER Scenes      Storyboard: how many meetings to lay out. Default 1.
.PARAMETER Seed        Fix the RNG for reproducible output. 0 = random.
.PARAMETER Fast        Snappier holds and typing. For the impatient.
.PARAMETER Calm        A functional workplace: feelings acknowledged, no recursion.

.EXAMPLE
    .\Friends-Of-No-One.ps1
.EXAMPLE
    .\Friends-Of-No-One.ps1 -Meetings 2
.EXAMPLE
    .\Friends-Of-No-One.ps1 -Storyboard -Scenes 1 -Seed 42
.EXAMPLE
    .\Friends-Of-No-One.ps1 -Calm           # the meeting actually ends
#>
[CmdletBinding()]
param(
    [int]$Meetings = 0,
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
$Names = @('Brenda','Dave','Sharon','Keith','Pam','Geoff','Linda','Trevor','Maureen','Barry','Sandra','Nigel','Karen','Steve')
$Roles = @('from Accounts','from Marketing','the Regional Lead','the new hire','from IT','who organises the birthdays',
           'who never refills the kettle','from the Tuesday sync','who replied-all','the one with the standing desk')
# The emotional demands -- a hostage situation, but make it open-plan.
$Demands = @('ACKNOWLEDGE MY FEELINGS','CC ME ON EVERYTHING','VALIDATE THIS DECISION','RESPECT MY BOUNDARIES (OR ELSE)',
             'NOBODY LEAVES UNTIL WE ALIGN','SAY YOU''RE SORRY AND MEAN IT','PUT IT IN WRITING','CIRCLE BACK. NOW.',
             'TAKE THIS OFFLINE WITH ME','I NEED THIS BY END OF DAY','MAKE ME FEEL SEEN','ADD IT TO THE PARKING LOT')
$NegoLines = @('Nobody has to get hurt. Let''s just align, okay, {W}?','Talk to me, {W}. What do you NEED?',
               'I hear you. I am HEARING you, {W}.','Let''s use "I" statements, {W}.','Put the agenda DOWN, {W}.',
               'We can circle back on this. We can ALWAYS circle back.','What would make you feel safe, {W}?')
$Actions = @('* {W} slowly slides a calendar invite across the table *','* the fluorescent lights flicker, ominously *',
             '* someone''s phone buzzes. nobody moves. *','* {W} uncaps a dry-erase marker like a weapon *',
             '* a single passive-aggressive sigh echoes *','* the kettle, somewhere, finishes boiling *',
             '* {W} opens a thread three months old *')
# The spiralling syllogism -- the centrepiece. It eats its own tail.
$Syllogism = @(
    'A friend to all is a friend to no one.',
    'So a friend of no one is a friend of everyone.',
    'He said, she said: none-friend = all-friend,',
    'so he said, she said: all-friend = none-friend.',
    'Thus to befriend all is to befriend none,',
    'and to befriend none is, again, to befriend all,',
    'which is none, which is all, which is none,',
    'which is to be, at this point, in a meeting.')
$Hence = @('hence: you are all each other''s hostage, and the door was never locked.',
           'hence: everyone is a friend of no one, and no one will let anyone leave.',
           'hence: the only winning move is to be productive with no one helping you.',
           'hence: a friend of no one is whoever scheduled this, and it is recurring.',
           'hence: nobody is holding the door -- everyone is holding everyone.')
$Punch  = @('...but they pay you. :3','...but it''s salaried, so. :3','...but the benefits are decent. :3',
            '...but payday is Friday, and that''s awesome. :3','...but you''re winning, and that''s awesome. :3')

# ============================ Set-piece art ==================================
# The conference table, seen from above, ringed with little hostage heads.
function Get-TableShot { param([string]$face,[bool]$flicker)
    $heads=@(); for ($i=0;$i -lt 5;$i++){ $heads += Pick @('(o_o)','(>_<)','(T_T)','(-_-)','(O_O)','(;_;)') }
    $top = ' '+($heads[0..1] -join '   ')
    $rows=@(
        (Cell (Center $top $SW) 'Green'),
        (Cell (Center '.--------------------------.' $SW) 'DarkYellow'),
        (Cell (Center "|$(' '*26)|" $SW) 'DarkYellow'),
        (Cell (Center ("| "+(Center 'CONFERENCE ROOM B' 24)+" |") $SW) 'Yellow'),
        (Cell (Center "|$(' '*26)|" $SW) 'DarkYellow'),
        (Cell (Center '.--------------------------.' $SW) 'DarkYellow'),
        (Cell (Center (' '+($heads[2..4] -join '   ')) $SW) 'Green') )
    $rows }

# A paycheck, fluttering down to save everyone from the paradox.
$Check = @('  .------------------------------.',
           '  | PAYROLL        $$$$$.$$  [::] |',
           '  | PAY TO: YOU                  |',
           '  | MEMO: emotional hazard pay   |',
           '  |  ~ ~ signed, The Company ~ ~ |',
           '  ''------------------------------''')

# ============================ Shot builders ==================================
function Get-CardShot { param([string]$l1,[string]$l2,[string]$color)
    $rows=@(LB)
    1..4 | ForEach-Object { $rows+=Blank }
    $rows+=Cell (Center ('='*34) $SW) 'DarkGray'
    $rows+=Cell (Center $l1 $SW) $color
    $rows+=Cell (Center $l2 $SW) 'DarkGray'
    $rows+=Cell (Center ('='*34) $SW) 'DarkGray'
    Fit $rows }

function Get-StandoffShot { param($mtg,[string]$line,[string]$cap,[bool]$flicker,[int]$chy)
    $lights = if ($flicker) { Pick @('*  -  *  -  *  -  *  -  *','-  *  -  *  -  *  -  *  -','*BZZT* . . . *BZZT* . . .') } else { '- - - - - - - - - - - - -' }
    $tbl = Get-TableShot '(o_o)' $flicker
    $w = Wrap2 $line $SW
    $rows=@(
        (LB),
        (Cell (Center ('<  '+$mtg.Title.ToUpper()+'  >') $SW) 'Cyan'),
        (Cell (Center $lights $SW) ($(if($flicker){'White'}else{'DarkGray'}))) )
    $rows += $tbl
    $rows += @(
        (Cell $w[0] 'White'),
        (Cell $w[1] 'White'),
        (Cell (' '+(ChyronWindow $mtg.Chyron $chy ($SW-2))+' ') 'Red'),
        (LB) )
    Fit $rows }

function Get-DemandShot { param([string]$demand,[string]$who)
    $rows=@(LB)
    1..3 | ForEach-Object { $rows+=Blank }
    $rows+=Cell (Center 'THE DEMAND:' $SW) 'DarkRed'
    $rows+=Blank
    $w=Wrap2 ('"'+$demand+'"') $SW
    $rows+=Cell $w[0] 'Red'
    $rows+=Cell $w[1] 'Red'
    $rows+=Blank
    $rows+=Cell (Center ("-- $who") $SW) 'DarkGray'
    $rows+=(LB)
    Fit $rows }

# The paradox spiral: the syllogism stacked, the latest line brightest, the
# whole thing "tightening" as $depth rises (more lines, faster).
function Get-ParadoxShot { param([int]$depth,[bool]$flicker)
    $shown = $Syllogism[0..([Math]::Min($depth,$Syllogism.Count-1))]
    $rows=@(LB)
    $rows+=Cell (Center 'THE PARADOX' $SW) 'Magenta'
    $start=[Math]::Max(0,$shown.Count-10)
    for ($i=$start; $i -lt $shown.Count; $i++) {
        $isLast = ($i -eq $shown.Count-1)
        $col = if ($isLast) { 'White' } elseif ($flicker -and ($rng.Next(2) -eq 0)) { 'DarkMagenta' } else { 'Gray' }
        $rows+=Cell (Center $shown[$i] $SW) $col }
    $rows+=(LB)
    Fit $rows }

function Get-RevealShot { param([string]$hence)
    $w=Wrap2 ("...$hence") $SW
    $rows=@(LB)
    1..2 | ForEach-Object { $rows+=Blank }
    $rows+=Cell (Center 'hence,' $SW) 'DarkGray'
    $rows+=Blank
    $rows+=Cell $w[0] 'White'
    $rows+=Cell $w[1] 'White'
    $rows+=(LB)
    Fit $rows }

function Get-PaycheckShot { param([string]$punch)
    $rows=@(LB)
    $rows+=Blank
    foreach ($l in $Check) { $rows+=Cell (Center $l $SW) 'Green' }
    $rows+=Blank
    $rows+=Cell (Center $punch $SW) 'Yellow'
    $rows+=(LB)
    Fit $rows }

function Get-FlashShot { Fit (1..$SH | ForEach-Object { Cell ([string][char]0x2588 * $SW) 'White' }) }
function Get-StaticShot {
    $noise='#%&@*+=:;.,/\|<>~oO0'.ToCharArray(); $rows=@()
    for ($y=0;$y -lt $SH;$y++) {
        $sb=[System.Text.StringBuilder]::new(); for ($x=0;$x -lt $SW;$x++){[void]$sb.Append($noise[$rng.Next($noise.Count)])}
        $row=$sb.ToString(); if ($y -eq 7){ $row=Center '>>  MEETING RECURRING  <<' $SW }
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
    $txt="TENS-O-METER [$bar] $desc"
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
    Row ('|'+(Pad ("   (CH HR)        ( o )      ( o )        <  FRIENDS OF NO ONE  >  ") ($TW-2))+'|') $body
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
    'intro'     { foreach ($f in 330,294,262) { Beep $f 140 } }          # corporate descending sigh
    'buzz'      { 1..2 | ForEach-Object { Beep 110 120 } }               # fluorescent flicker
    'demand'    { Beep 440 90; Beep 392 200 }
    'reveal'    { Beep 466 150; Beep 466 150; Beep 392 550 }
    'slam'      { Beep 150 60; Beep 95 200; Beep 60 320 }
    'sigh'      { Beep 300 80; Beep 240 300 }
    'cash'      { foreach ($f in 988,1319,1568) { Beep $f 90 }; Beep 2093 200 }   # ka-ching :3
    'ovation'   { 1..18 | ForEach-Object { Beep (RNext 220 920) 15 }; Beep 740 220 } } }

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

# ============================ Meeting builder ================================
function New-Meeting {
    $a=Pick $Names; $b=Pick ($Names | Where-Object { $_ -ne $a })
    [pscustomobject]@{
        Title='FRIENDS OF NO ONE'
        Captor=$a; CaptorRole=(Pick $Roles); Other=$b
        Demand=(Pick $Demands)
        Hence=(Pick $Hence); Punch=(Pick $Punch)
        Chyron=("EMOTIONAL HOSTAGE SITUATION ONGOING   ***   $a $((Pick $Roles)) WILL NOT BE LEFT ON READ   ***   HR EN ROUTE   ***   THE KETTLE IS EMPTY AGAIN   ***   ").ToUpper() } }

# ============================ The director ===================================
function Invoke-Meeting { param($mtg)
    $who = "$($mtg.Captor) $($mtg.CaptorRole)"
    # 1. COLD OPEN
    React 0.3 intro
    Show-Live (Get-CardShot 'EMOTIONAL HOSTAGE SITUATION' 'CONFERENCE ROOM B' 'White') $false; Sting intro; Hold 1100; if (Test-Quit){throw 'quit'}
    # 2. THE STANDOFF (with a fluorescent flicker hitting mid-scene)
    $chy=0
    for ($i=0; $i -lt 2; $i++) {
        $line = if ($i -eq 0) { (Pick $Actions).Replace('{W}',$mtg.Captor) } else { (Pick $NegoLines).Replace('{W}',$mtg.Captor) }
        if ($i -eq 0) { React 0.4 buzz } else { React 0.5 sigh }
        foreach ($f in 1..8) {
            $flicker = ($f % 3 -eq 0)
            Show-Live (Get-StandoffShot $mtg $line ('') $flicker $chy) $false; $chy+=2
            if ($flicker) { Sting buzz }
            Hold 150; if (Test-Quit){throw 'quit'} } }
    # 3. THE DEMAND
    React 0.55 demand
    Show-Live (Get-DemandShot $mtg.Demand $who) $false; Sting demand; Hold 1100; if (Test-Quit){throw 'quit'}
    # 4. THE PARADOX SPIRAL -- the room hushes; the syllogism tightens and speeds up
    $script:Reaction = 0.1
    for ($d=0; $d -lt $Syllogism.Count; $d++) {
        $flicker = ($d -ge 4)
        Show-Live (Get-ParadoxShot $d $flicker) $false
        Beep ([Math]::Max(120, 760-$d*80)) 40                       # pitch climbs as it tightens
        Hold ([Math]::Max(70, 360-$d*36))
        if (Test-Quit){throw 'quit'} }
    # 5. THE REVEAL -> FLOORED
    Show-Live (Get-RevealShot $mtg.Hence) $false; Invoke-Flash; Sting reveal; Hold 500
    Invoke-Slam (Get-RevealShot $mtg.Hence)
    Show-Live (Get-RevealShot $mtg.Hence) $false; Hold 900; if (Test-Quit){throw 'quit'}
    if ($script:Calm) {
        React 0.9 ovation
        Show-Live (Get-CardShot 'FEELINGS: ACKNOWLEDGED' 'meeting adjourned. for real.' 'Green') $false; Sting ovation; Hold 1200
        return
    }
    # 6. ...BUT THEY PAY YOU :3  -- the paycheck flutters down and saves everyone
    foreach ($drop in 0..3) {
        $rows=@(LB); 1..$drop | ForEach-Object { $rows+=Blank }
        foreach ($l in $Check) { $rows+=Cell (Center $l $SW) 'DarkGreen' }
        Show-Live (Fit $rows) $false; Beep (RNext 500 900) 25; Hold 130; if (Test-Quit){throw 'quit'} }
    React 0.85
    Show-Live (Get-PaycheckShot $mtg.Punch) $false; Sting cash; Hold 1300; if (Test-Quit){throw 'quit'}
    # everyone sits back down
    Show-Live (Get-CardShot 'everyone sits back down.' 'the door was never locked.' 'DarkGray') $false; Sting sigh; Hold 1000
    # 7. MEETING ADJOURNED... AND RECURRING -> static
    $card = Get-CardShot 'MEETING ADJOURNED . . .' 'recurring every Tuesday' 'White'
    Show-Live $card $false; Hold 700
    foreach ($s in 0..3){ Show-Live (Dim $card $s) $false; Hold 230 }
    foreach ($s in 1..(RNext 5 8)){ Show-Live (Get-StaticShot) $true; Beep (RNext 200 600) 25; Hold 70; if (Test-Quit){throw 'quit'} } }

# ============================ STORYBOARD =====================================
if ($Storyboard) {
    for ($e=1; $e -le $Scenes; $e++) {
        $mtg=New-Meeting; $who="$($mtg.Captor) $($mtg.CaptorRole)"
        "##### MEETING $e : FRIENDS OF NO ONE -- $($mtg.Captor) vs. everyone #####"; ''
        $script:Reaction=0.35; $script:SlamFrames=0
        '  [ COLD OPEN -- EMOTIONAL HOSTAGE SITUATION, CONFERENCE ROOM B ]'
        Show-Plain (Get-CardShot 'EMOTIONAL HOSTAGE SITUATION' 'CONFERENCE ROOM B' 'White') $false; ''
        $script:Reaction=0.5
        '  [ THE STANDOFF -- the table, the heads, the flickering lights ]'
        Show-Plain (Get-StandoffShot $mtg ((Pick $NegoLines).Replace('{W}',$mtg.Captor)) '' $true 0) $false; ''
        '  [ THE DEMAND ]'
        Show-Plain (Get-DemandShot $mtg.Demand $who) $false; ''
        $script:Reaction=0.1
        '  [ THE PARADOX -- the syllogism spirals and tightens ]'
        Show-Plain (Get-ParadoxShot ($Syllogism.Count-1) $true) $false; ''
        $script:SlamFrames=7; $script:Reaction=1.0
        '  [ THE REVEAL -- ...hence; the room is FLOORED ]'
        Show-Plain (Get-RevealShot $mtg.Hence) $false; ''
        $script:SlamFrames=0
        if ($Calm) {
            $script:Reaction=0.9
            '  [ A FUNCTIONAL WORKPLACE -- feelings acknowledged, meeting actually ends ]'
            Show-Plain (Get-CardShot 'FEELINGS: ACKNOWLEDGED' 'meeting adjourned. for real.' 'Green') $false; ''
        } else {
            '  [ ...BUT THEY PAY YOU :3  -- the paycheck flutters down ]'
            Show-Plain (Get-PaycheckShot $mtg.Punch) $false; ''
            '  [ MEETING ADJOURNED... AND RECURRING ]'
            Show-Plain (Get-StaticShot) $true; ''
        }
    }
    return
}

# ============================ LIVE ===========================================
try { [void][Console]::WindowWidth } catch {
    Write-Warning 'Live mode needs a real console. Try: .\Friends-Of-No-One.ps1 -Storyboard'; return }
$prevCursor=[Console]::CursorVisible
try { [Console]::CursorVisible=$false } catch {}
$script:Live=$true; $held=0
function Test-Quit { try { if ([Console]::KeyAvailable){[void][Console]::ReadKey($true);return $true} } catch {}; return $false }

try {
    while ($true) {
        Invoke-Meeting (New-Meeting)
        $held++; if ($Meetings -gt 0 -and $held -ge $Meetings) { break }
    }
}
catch { if ("$_" -notmatch 'quit') { throw } }
finally {
    [Console]::ResetColor(); try { [Console]::CursorVisible=$prevCursor } catch {}
    Write-Host ''; Write-Host '  *click*   ...meeting ended. (it''s recurring.)' -ForegroundColor DarkGray
}
