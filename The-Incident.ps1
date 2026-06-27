<#
.SYNOPSIS
    DRAMA TV presents -- "THE INCIDENT": a melodrama of nebalose incidents,
    staged in your terminal. THERE WAS AN INCIDENT. It was NEBALOSE. Nobody will
    say what happened -- the report is all redacted bars. Everyone accuses
    everyone: RU JEALOSE? RU JEALOSE THAT I'M NERVOSE? A nervose narrator sweats
    under the lights as the incidents cascade -- ANOTHER INCIDENT, ANOTHER ONE --
    the counter ticking ever upward. Then THE REVEAL (the nature of which remains
    NEBALOSE), the room is FLOORED, and lo: THER WIL BE CONSEQUINCES.

    NOTE ON SPELLING: the misspellings are deliberate. NEBALOSE, JEALOSE,
    NERVOSE, CONSEQUINCES, NEVORE, AGAN -- that is the show's voice. On purpose.

.DESCRIPTION
    One episode is directed in beats:
      THERE WAS AN INCIDENT
        -> THE REPORT (nebalose; every field redacted to black bars)
        -> THE ACCUSATION (RU JEALOSE THAT I'M NERVOSE?)
        -> THE NERVES (a narrator sweats; the NERVOSE-O-METER climbs)
        -> THE CASCADE (ANOTHER INCIDENT. ANOTHER ONE. the counter spikes)
        -> THE REVEAL (the nature of the incident -- still NEBALOSE) -- FLOORED
        -> THER WIL BE CONSEQUINCES (a stamp comes down) -> PENDING... -> static.

    -Calm files it cleanly: the incident is resolved, logged, and closed, with
    no further incidents and, for once, no consequinces. Otherwise: another one.

    Live mode redraws in place with sound + motion (needs a real console).
    -Storyboard prints a representative montage of frames to stdout instead.

.PARAMETER Incidents    How many episodes before exiting. 0 (default) = forever.
.PARAMETER Silent       Disable the [Console]::Beep sound cues.
.PARAMETER Storyboard   Print a static montage to stdout (no animation / sound).
.PARAMETER Scenes       Storyboard: how many incidents to lay out. Default 1.
.PARAMETER Seed         Fix the RNG for reproducible output. 0 = random.
.PARAMETER Fast         Snappier holds and typing. For the impatient.
.PARAMETER Calm         File it cleanly: resolved, logged, closed. No consequinces.

.EXAMPLE
    .\The-Incident.ps1
.EXAMPLE
    .\The-Incident.ps1 -Incidents 2
.EXAMPLE
    .\The-Incident.ps1 -Storyboard -Scenes 1 -Seed 42
.EXAMPLE
    .\The-Incident.ps1 -Calm           # the incident is, for once, resolved
#>
[CmdletBinding()]
param(
    [int]$Incidents = 0,
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
# Redact a string to solid bars (the incident, being nebalose, cannot be shown).
function Redact { param([int]$len) ([string][char]0x2588) * $len }
function RedactWord { param([string]$s) -join ($s.ToCharArray() | ForEach-Object { if ($_ -eq ' ') { ' ' } else { [char]0x2588 } }) }

# ============================ Word banks =====================================
# The misspellings are DELIBERATE. This is the show's voice. On purpose.
$Names    = @('Brad','Vanessa','Dimitri','Esmeralda','Chad','Bianca','Rex','Cordelia',
              'Lance','Seraphina','Brock','Ophelia','Roderick','Genevieve','Tammy','Cletus')
$Natures  = @('an INCIDENT','a SITUATION','an OCCURRENCE','an EVENT, of sorts','a MATTER','a DEVELOPMENT',
              'a THING THAT HAPPENED','an UNPLEASANTNESS','a REGRETTABLE NEBALOSITY')
$Fields   = @('NATURE OF INCIDENT','PARTIES INVOLVED','TIME OF INCIDENT','LOCATION','WITNESSES','WHAT WAS SAID','WHO STARTED IT')
$Accuse   = @('RU JEALOSE?','RU JEALOSE THAT I''M NERVOSE?','I SAW WHAT YOU DID. (it was an incident.)',
              'YOU''RE JUST JEALOSE, {O}!','DON''T MAKE ME NERVOSE, {O}!','THIS IS NEBALOSE AND YOU KNOW IT!',
              'I AM NOT NERVOSE. RU NERVOSE?','WHO TOLD YOU ABOUT THE INCIDENT, {O}?!')
$Nerves   = @('I''m NERVOSE. I''m so NERVOSE.','why is everyone looking at me','it was NEBALOSE, I SWEAR',
              'I wasn''t even THERE for the incident','*sweating* define "incident"','I have NEVORE been so NERVOSE',
              'there was an incident and I am NERVOSE about it')
$Cascade  = @('ANOTHER INCIDENT.','ANOTHER ONE.','and ANOTHER.','INCIDENT.','ANOTHER INCIDENT, ANOTHER ONE.','...ANOTHER ONE.')
$Reveals  = @('the nature of the incident is, and remains, NEBALOSE, {W}.','it was YOU. it was the incident. it was NEBALOSE, {W}.',
              'there was NEVORE just one incident, {W}.','everyone was JEALOSE. everyone was NERVOSE. {W}.',
              'the incident was being NERVOSE about the incident, {W}.','you were the incident all along, {W}.')
$Conseq   = @('THER WIL BE CONSEQUINCES.','CONSEQUINCES: PENDING.','CONSEQUINCES (NEBALOSE) TO FOLLOW.',
              'THER WIL BE CONSEQUINCES. ANOTHER ONE.','CONSEQUINCES WIL BE NERVOSE.')
# --- PROFOUND WONDERS (bonus surreal interstitials; the spellings stay deliberate) ---
$Wonders  = @('(automobiles driving by swiftly)','a woman spills water on her lap and exits',
              '(a distant car alarm, never addressed)','a man nods slowly, knowing nothing',
              '(automobiles -- still -- driving by, swiftly)','someone''s pomeranian wanders across the set',
              'a woman returns, spills water AGAN, exits AGAN','(*jazz trombone messing with u*)')
$Demand2  = @('IF THER IS NOT ANOTHER, I AM GOING TO BE SO, FUCKING, PISSED.','THER HAD BETTER BE ANOTHER.',
              'GIVE ME ANOTHER OR I SWEAR ON THE INCIDINT --')
$Prosper  = @('YOU CAN''T SAY THAT! OR U DON''T GET RICH, HALLELUJAH!','SAY IT RIGHT OR THE BLESSINGS DRY UP, HALLELUJAH!',
              'RICHES, HALLELUJAH -- BUT ONLY IF U DON''T SAY THAT!')
$Insults  = @('you''re such a LOW-TEMPERATURE KNOW-YOUR-HISTORY PERSON','at PC PENNES. at HOM HEPOT. it does. it does. IT DOESS.',
              'xD jood one. THAT IS ABSOLUTELY CORRECT.','a real truth-tellore, huh. wull.')
$AdLines  = @('why dontcha tell ''em the truth...','...in SPRINJ BOOT...','...for $5.')
$Monopole = @('''member that Monopole game?','with the CUWPS?','at MCDONOLDS?')
$Savior   = @('im sory but u half too feign for urself. im not ur savor.','i cannot save u from the incident. nobod can.',
              'feign for urself now. im not ur savor.')

# ============================ Set-piece art ==================================
# The redacted incident report -- a form where every value is a black bar.
function Get-ReportLines { param([int]$caseNo)
    $rows=@(' .--------------------------. ',
            (' |  INCIDINT REPORT  #'+('{0:000}' -f $caseNo)+'  | '),
            ' |--------------------------| ')
    foreach ($f in (@($Fields | Sort-Object { $rng.Next() } | Select-Object -First 3))) {
        $label=$f.Substring(0,[Math]::Min(14,$f.Length))
        $bar=Redact (RNext 6 12)
        $rows += (' | '+(Pad $label 14)+' '+(Pad $bar 8)+' | ') }
    $rows += " '--------------------------' "
    $rows }

# A nervose figure, sweating under the lights.
function Get-NervousArt { param([string]$face)
    @("     '   '      ",        # sweat
      "   ( $face )    ",
      "    /| | |\     ",
      "   ' /   \ '    ")        # more sweat
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

# THE REPORT -- nebalose; redacted bars where the facts should be.
function Get-ReportShot { param($inc,[string]$caption)
    $rows=@(LB)
    foreach ($l in (Get-ReportLines $inc.CaseNo)) { $rows+=Cell (Center $l $SW) 'DarkCyan' }
    $w=Wrap2 $caption $SW
    $rows+=Cell $w[0] 'White'
    $rows+=Cell $w[1] 'White'
    $rows+=(LB)
    Fit $rows }

# THE ACCUSATION -- two parties, one nervose, one jealose.
function Get-AccuseShot { param($inc,[string]$line,[int]$chy)
    $f1=Pick @('(>_<)','(o_O)','(O_O)','(-_-)'); $f2=Pick @('(;_;)','(o_o)','(T_T)','(@_@)')
    $names=(' '*$SW).ToCharArray()
    $a=$inc.Cast[0].ToUpper(); $b=$inc.Cast[1].ToUpper()
    foreach ($pair in @{15=$a;34=$b}.GetEnumerator()) {
        $nm=$pair.Value; $st=[Math]::Max(0,$pair.Key-[int]($nm.Length/2))
        for ($k=0;$k -lt $nm.Length -and ($st+$k)-lt $SW;$k++){ $names[$st+$k]=$nm[$k] } }
    $w=Wrap2 $line $SW
    $rows=@(
        (LB),
        (Cell (Center ('<  THE INCIDENT  >') $SW) 'Cyan'),
        (Cell ('~'*$SW) 'DarkCyan'),
        (Blank),
        (Cell (Pad ('        '+$f1+'              '+$f2) $SW) 'Green'),
        (Cell (Pad ('        /|\              /|\ ') $SW) 'Green'),
        (Cell (Pad (-join $names) $SW) 'DarkGreen'),
        (Blank),
        (Cell $w[0] 'White'),
        (Cell $w[1] 'White'),
        (Blank),
        (Cell (' '+(ChyronWindow $inc.Chyron $chy ($SW-2))+' ') 'Red'),
        (LB) )
    Fit $rows }

# THE NERVES -- a sweating narrator, the nervose lower-third.
function Get-NervousShot { param([string]$caption)
    $face=Pick @('o_o','O_O','o.o','._.','>_>')
    $rows=@(LB)
    $rows+=Cell (Center 'THE WITNESS' $SW) 'Yellow'
    foreach ($l in (Get-NervousArt $face)) { $rows+=Cell (Center $l $SW) 'Green' }
    $w=Wrap2 ('"'+$caption+'"') $SW
    $rows+=Cell $w[0] 'White'
    $rows+=Cell $w[1] 'White'
    $rows+=(LB)
    Fit $rows }

# THE CASCADE -- incidents piling up, the counter spiking.
function Get-CascadeShot { param([string[]]$stack,[int]$count)
    $rows=@(LB)
    $rows+=Cell (Center "INCIDINTS THIS SEASON: $count" $SW) 'Red'
    $rows+=Cell ('-'*$SW) 'DarkGray'
    foreach ($s in ($stack | Select-Object -Last 6)) { $rows+=Cell (Center ("[!] "+$s) $SW) (Pick @('Yellow','DarkYellow','White','Red')) }
    $rows+=(LB)
    Fit $rows }

# THE REVEAL.
function Get-RevealShot { param([string]$hence)
    $w=Wrap2 ("...$hence") $SW
    $rows=@(LB)
    1..2 | ForEach-Object { $rows+=Blank }
    $rows+=Cell (Center 'the findings of the inquiry:' $SW) 'DarkGray'
    $rows+=Blank
    $rows+=Cell $w[0] 'White'
    $rows+=Cell $w[1] 'White'
    $rows+=(LB)
    Fit $rows }

# THE CONSEQUINCES -- a stamp slams down on the file.
function Get-ConsequenceShot { param([string]$line)
    $rows=@(LB)
    1..2 | ForEach-Object { $rows+=Blank }
    $rows+=Cell (Center '.----------------------------.' $SW) 'Red'
    $rows+=Cell (Center ('|  '+(Center $line 24)+'  |') $SW) 'Red'
    $rows+=Cell (Center "'----------------------------'" $SW) 'Red'
    $rows+=Blank
    $rows+=Cell (Center '(stamped, in red, forever)' $SW) 'DarkGray'
    $rows+=(LB)
    Fit $rows }

# A PROFOUND WONDER drifts across the broadcast (a stage direction, made flesh).
function Get-WonderShot { param([string]$line)
    $rows=@(LB)
    1..4 | ForEach-Object { $rows+=Blank }
    $w=Wrap2 $line $SW
    $rows+=Cell $w[0] 'Gray'
    $rows+=Cell $w[1] 'DarkGray'
    1..2 | ForEach-Object { $rows+=Blank }
    $rows+=Cell (Center '. . .' $SW) 'DarkGray'
    $rows+=(LB)
    Fit $rows }

# SMASH CUT to -- THE LEVEL. (a crossover. it is, frankly, clevore.)
function Get-LevelCutShot { param([string]$caption)
    $box=@('+------------------------+',
           '|  +------------------+  |',
           '|  |    THE LEVEL     |  |',
           '|  |  +------------+  |  |',
           '|  |  | THE LEVEL  |  |  |',
           '|  |  +-----><-----+  |  |',
           '|  +------------------+  |',
           '+------------------------+')
    $rows=@(LB)
    foreach ($l in $box) { $rows+=Cell (Center $l $SW) 'Cyan' }
    $rows+=Cell (Center $caption $SW) 'White'
    $rows+=(LB)
    Fit $rows }

# A WORD FROM OUR SPONSOR. the truth. in SPRINJ BOOT. for $5.
function Get-AdShot { param([string]$line)
    $rows=@(LB)
    1..3 | ForEach-Object { $rows+=Blank }
    $rows+=Cell (Center '* * *  A WORD FROM OUR SPONSOR  * * *' $SW) 'DarkYellow'
    $rows+=Blank
    $w=Wrap2 $line $SW
    $rows+=Cell $w[0] 'Yellow'
    $rows+=Cell $w[1] 'Yellow'
    $rows+=Blank
    $rows+=Cell (Center 'SPRINJ BOOT -- $5 -- THE TRUTH' $SW) 'Green'
    $rows+=(LB)
    Fit $rows }

function Get-FlashShot { Fit (1..$SH | ForEach-Object { Cell ([string][char]0x2588 * $SW) 'White' }) }
function Get-StaticShot { param([string]$banner='>>  PENDING INVESTIGATION  <<')
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
    $desc=@{ hush='. . . hushed . . .';murmur='a murmur ripples';gasp='the room GASPS';clap='UPROAR!';
             feet='ON ITS FEET!';floor='*** F L O O R E D ***';slam='*** S L A M M E D ***' }[$mood]
    $txt="NERVOSE-O-METER [$bar] $desc"
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
    $cnt='{0:000}' -f $script:IncCount
    Row ('|'+(Pad ("   (CH 99)        ( o )      ( o )        <  THE INCIDENT [#$cnt]  >  ") ($TW-2))+'|') $body
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
    'alarm'     { 1..3 | ForEach-Object { Beep 740 90; Beep 587 90 } }       # incident klaxon
    'redact'    { 1..4 | ForEach-Object { Beep (RNext 90 140) 30 } }         # the marker squeaks
    'accuse'    { Beep 466 120; Beep 392 200 }
    'nervose'   { 1..5 | ForEach-Object { Beep (RNext 500 760) 35 } }        # a fluttering, anxious trill
    'another'   { Beep 660 70; Beep 880 110 }                                # ANOTHER ONE
    'trombone'  { Beep 311 130; Beep 294 150; Beep 277 180; Beep 233 460 }   # sad jazz trombone, messing with u
    'hallelujah'{ foreach ($f in 392,494,587,784) { Beep $f 120 } }          # u don't get rich otherwise
    'cars'      { 1..3 | ForEach-Object { Beep (RNext 200 420) 40 } }        # automobiles, swiftly
    'spill'     { Beep 880 60; Beep 440 130 }                                # a woman spills water
    'smash'     { Beep 1200 40; Beep 90 220 }                                # SMASH CUT
    'cash'      { foreach ($f in 988,1319,1568) { Beep $f 80 }; Beep 2093 200 }   # for $5
    'reveal'    { Beep 466 150; Beep 466 150; Beep 392 550 }
    'slam'      { Beep 150 60; Beep 95 200; Beep 60 320 }
    'stamp'     { Beep 200 60; Beep 90 260 }                                 # CONSEQUINCES, stamped
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

# ============================ Incident builder ===============================
$script:IncCount = RNext 12 48          # incidents already on the books this season
function New-Incident {
    $a=Pick $Names; $b=Pick ($Names | Where-Object { $_ -ne $a })
    [pscustomobject]@{
        Cast=@($a,$b); CaseNo=(RNext 100 999); Nature=(Pick $Natures)
        Reveal=((Pick $Reveals).Replace('{W}',$a)); Conseq=(Pick $Conseq)
        Chyron=("THERE WAS AN INCIDENT   ***   IT WAS NEBALOSE   ***   RU JEALOSE THAT I'M NERVOSE   ***   ANOTHER INCIDENT ANOTHER ONE   ***   THER WIL BE CONSEQUINCES   ***   ").ToUpper() } }

# ============================ The director ===================================
function Invoke-Incident { param($inc)
    $script:IncCount++
    # 1. THERE WAS AN INCIDENT
    React 0.4 alarm
    Show-Live (Get-CardShot 'THERE WAS AN INCIDENT.' "it was $($inc.Nature)" 'Red') $false; Sting alarm; Hold 1100; if (Test-Quit){throw 'quit'}
    # 2. THE REPORT -- nebalose; everything redacted
    React 0.45 redact
    foreach ($f in 1..4) { Show-Live (Get-ReportShot $inc 'the report is, regrettably, NEBALOSE.') $false; if ($f -eq 1){Sting redact}; Hold 360; if (Test-Quit){throw 'quit'} }
    # 3. THE ACCUSATION -- RU JEALOSE THAT I'M NERVOSE?
    $chy=0
    foreach ($f in 1..8) {
        $line=(Pick $Accuse).Replace('{O}',$inc.Cast[1])
        React 0.6
        Show-Live (Get-AccuseShot $inc $line $chy) $false; $chy+=2
        if ($f % 3 -eq 0) { Sting accuse }
        Hold 180; if (Test-Quit){throw 'quit'} }
    # 4. THE NERVES -- the witness sweats
    foreach ($f in 1..5) { React 0.55; Show-Live (Get-NervousShot (Pick $Nerves)) $false; Sting nervose; Hold 420; if (Test-Quit){throw 'quit'} }
    # 5. THE CASCADE -- ANOTHER INCIDENT. ANOTHER ONE.
    $stack=@()
    foreach ($f in 1..6) {
        $script:IncCount++; $stack += (Pick $Cascade)
        React ([Math]::Min(0.9, 0.5+$f*0.08))
        Show-Live (Get-CascadeShot $stack $script:IncCount) $false; Sting another; Hold ([Math]::Max(120,300-$f*28)); if (Test-Quit){throw 'quit'} }
    # 5b. PROFOUND WONDERS -- the demand, another, the wonders, the smash cut, the sponsor
    React 0.75
    Show-Live (Get-CardShot (Pick $Demand2) 'or so help me' 'Red') $false; Sting accuse; Hold 1100; if (Test-Quit){throw 'quit'}
    $script:IncCount++
    React 0.85
    Show-Live (Get-CardShot 'THERE WAS ANOTHER.' "incidint #$($script:IncCount)" 'Yellow') $false; Sting another; Hold 950; if (Test-Quit){throw 'quit'}
    # a few profound wonders drift past
    foreach ($wb in (@($Wonders | Sort-Object { $rng.Next() } | Select-Object -First 4))) {
        $st = if ($wb -match 'automobile|car alarm') { 'cars' } elseif ($wb -match 'water') { 'spill' } elseif ($wb -match 'trombone') { 'trombone' } else { 'sigh' }
        Show-Live (Get-WonderShot $wb) $false; Sting $st; Hold 700; if (Test-Quit){throw 'quit'} }
    # the prosperity gospel, hollered across the aisle
    React 0.7
    Show-Live (Get-AccuseShot $inc (Pick $Prosper) 0) $false; Sting hallelujah; Hold 1000; if (Test-Quit){throw 'quit'}
    # an insult. a jood one.
    Show-Live (Get-NervousShot (Pick $Insults)) $false; Sting trombone; Hold 1000; if (Test-Quit){throw 'quit'}
    # SMASH CUT to -- THE LEVEL
    Invoke-Flash; Sting smash
    Show-Live (Get-LevelCutShot 'clevore.............. >_>') $false; Hold 850; if (Test-Quit){throw 'quit'}
    Show-Live (Get-LevelCutShot 'truth tellore huh.... wull....') $false; Sting trombone; Hold 850; if (Test-Quit){throw 'quit'}
    # a word from our sponsor: the truth, in SPRINJ BOOT, for $5
    foreach ($ad in $AdLines) { Show-Live (Get-AdShot $ad) $false; Sting cash; Hold 650; if (Test-Quit){throw 'quit'} }
    Show-Live (Get-CardShot 'THAT IS ABSOLUTELY CORRECT.' '(*jazz trombone messing with u*)' 'White') $false; Sting trombone; Hold 1100; if (Test-Quit){throw 'quit'}
    # 'member that Monopole game? with the CUWPS? at MCDONOLDS?
    foreach ($mb in $Monopole) { Show-Live (Get-WonderShot $mb) $false; Beep (RNext 400 700) 60; Hold 600; if (Test-Quit){throw 'quit'} }
    # 6. THE REVEAL -> FLOORED
    $script:Reaction=0.1
    Show-Live (Get-RevealShot $inc.Reveal) $false; Invoke-Flash; Sting reveal; Hold 500
    Invoke-Slam (Get-RevealShot $inc.Reveal)
    Show-Live (Get-RevealShot $inc.Reveal) $false; Hold 900; if (Test-Quit){throw 'quit'}
    if ($script:Calm) {
        React 0.9 ovation
        Show-Live (Get-CardShot 'INCIDENT: RESOLVED' 'logged, closed. no consequinces.' 'Green') $false; Sting sigh; Hold 1200
        return
    }
    # 7. THER WIL BE CONSEQUINCES -- the stamp comes down
    React 0.6
    Show-Live (Get-ConsequenceShot $inc.Conseq) $false; Invoke-Flash; Sting stamp; Hold 1200; if (Test-Quit){throw 'quit'}
    $black=@(1..$SH | ForEach-Object { Cell (' '*$SW) 'Black' })
    $rows=@($black); $rows[6]=Cell (Center 'the inquiry names a person of interest:' $SW) 'DarkGray'
    $rows[8]=Cell (Center "$Viewer." $SW) 'Red'
    Show-Raw $rows $false; Beep 200 200; Hold 1100; if (Test-Quit){throw 'quit'}
    $rows=@($black); $rows[7]=Cell (Center 'ANOTHER INCIDENT. ANOTHER ONE.' $SW) 'DarkGray'; Show-Raw $rows $false; Sting another; Hold 1100
    # ...and the broadcast reminds you: you are on your own now
    Show-Live (Get-CardShot 'IM NOT UR SAVOR.' (Pick $Savior) 'DarkGray') $false; Sting trombone; Hold 1200; if (Test-Quit){throw 'quit'}
    # 8. PENDING INVESTIGATION -> static
    foreach ($s in 1..(RNext 5 8)){ Show-Live (Get-StaticShot) $true; Beep (RNext 200 600) 25; Hold 70; if (Test-Quit){throw 'quit'} } }

# ============================ STORYBOARD =====================================
if ($Storyboard) {
    for ($e=1; $e -le $Scenes; $e++) {
        $inc=New-Incident
        "##### INCIDINT $e : THE INCIDENT -- $($inc.Cast[0]) vs. $($inc.Cast[1]) (it was NEBALOSE) #####"; ''
        $script:Reaction=0.4; $script:SlamFrames=0
        '  [ COLD OPEN -- THERE WAS AN INCIDENT ]'
        Show-Plain (Get-CardShot 'THERE WAS AN INCIDENT.' "it was $($inc.Nature)" 'Red') $false; ''
        '  [ THE REPORT -- nebalose; every field redacted ]'
        Show-Plain (Get-ReportShot $inc 'the report is, regrettably, NEBALOSE.') $false; ''
        $script:Reaction=0.6
        '  [ THE ACCUSATION -- RU JEALOSE THAT I''M NERVOSE? ]'
        Show-Plain (Get-AccuseShot $inc 'RU JEALOSE THAT I''M NERVOSE?' 0) $false; ''
        $script:Reaction=0.55
        '  [ THE NERVES -- the witness sweats ]'
        Show-Plain (Get-NervousShot 'I''m NERVOSE. I''m so NERVOSE.') $false; ''
        '  [ THE CASCADE -- ANOTHER INCIDENT. ANOTHER ONE. ]'
        Show-Plain (Get-CascadeShot @('ANOTHER INCIDENT.','ANOTHER ONE.','and ANOTHER.','INCIDENT.','...ANOTHER ONE.') ($script:IncCount+5)) $false; ''
        $script:Reaction=0.75
        '  [ THE DEMAND -- if ther is not another... ]'
        Show-Plain (Get-CardShot 'IF THER IS NOT ANOTHER, I AM GOING' 'TO BE SO, FUCKING, PISSED.' 'Red') $false; ''
        '  [ PROFOUND WONDER -- a stage direction, made flesh ]'
        Show-Plain (Get-WonderShot 'a woman spills water on her lap and exits') $false; ''
        '  [ SMASH CUT to -- THE LEVEL ]'
        Show-Plain (Get-LevelCutShot 'clevore.............. >_>') $false; ''
        '  [ A WORD FROM OUR SPONSOR -- the truth, in SPRINJ BOOT, for $5 ]'
        Show-Plain (Get-AdShot '...in SPRINJ BOOT... for $5.') $false; ''
        $script:SlamFrames=7; $script:Reaction=1.0
        '  [ THE REVEAL -- the nature of the incident (still NEBALOSE); FLOORED ]'
        Show-Plain (Get-RevealShot $inc.Reveal) $false; ''
        $script:SlamFrames=0
        if ($Calm) {
            $script:Reaction=0.9
            '  [ RESOLVED -- logged, closed, no consequinces ]'
            Show-Plain (Get-CardShot 'INCIDENT: RESOLVED' 'logged, closed. no consequinces.' 'Green') $false; ''
        } else {
            '  [ THER WIL BE CONSEQUINCES -- the stamp comes down ]'
            Show-Plain (Get-ConsequenceShot $inc.Conseq) $false; ''
            '  [ PERSON OF INTEREST -> pending investigation ]'
            $black=@(1..$SH | ForEach-Object { Cell (' '*$SW) 'Black' })
            $rows=@($black); $rows[6]=Cell (Center 'the inquiry names a person of interest:' $SW) 'DarkGray'
            $rows[8]=Cell (Center "$Viewer." $SW) 'Red'
            Show-Plain $rows $false; ''
        }
    }
    return
}

# ============================ LIVE ===========================================
try { [void][Console]::WindowWidth } catch {
    Write-Warning 'Live mode needs a real console. Try: .\The-Incident.ps1 -Storyboard'; return }
$prevCursor=[Console]::CursorVisible
try { [Console]::CursorVisible=$false } catch {}
$script:Live=$true; $count=0
function Test-Quit { try { if ([Console]::KeyAvailable){[void][Console]::ReadKey($true);return $true} } catch {}; return $false }

try {
    while ($true) {
        Invoke-Incident (New-Incident)
        $count++; if ($Incidents -gt 0 -and $count -ge $Incidents) { break }
    }
}
catch { if ("$_" -notmatch 'quit') { throw } }
finally {
    [Console]::ResetColor(); try { [Console]::CursorVisible=$prevCursor } catch {}
    Write-Host ''; Write-Host '  *click*   ...this matter is NEBALOSE. (ther wil be consequinces.)' -ForegroundColor DarkGray
}
