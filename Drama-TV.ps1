<#
.SYNOPSIS
    A procedurally-generated ASCII television that channel-surfs through
    overwrought, cinematic prime-time dramas -- letterboxed shots, a scrolling
    BREAKING NEWS chyron, lightning + thunder, screen-shake, a dolly-zoom REVEAL
    with a musical sting, TO BE CONTINUED cliffhangers, and a LIVE STUDIO
    AUDIENCE that gasps, leaps to its feet, and gets FLOORED.

.DESCRIPTION
    Each "channel" is directed as a tiny episode:
      PREVIOUSLY ON ...  ->  stormy dialogue (rain, chyron, thunder/flash/shake)
      ->  THE REVEAL (dolly-zoom onto a giant emoting face + "dun dun DUUUN")
      ->  TO BE CONTINUED ...  (fade to black)  ->  channel static  -> next show.

    THE AUDIENCE IS LIVE.  A studio crowd sits below the set with an APPL-O-METER
    that swings in real time -- the room HUSHES to dead silence in the heartbeat
    before a reveal, then the REVEAL physically SLAMS it: the meter pins, the
    heads are knocked flat, the crowd is FLOORED.  Dynamics: quiet, swell, SLAM.

    Live mode redraws in place with sound + motion (needs a real console).
    -Storyboard prints a representative montage of frames to stdout instead.

    THE LEVEL IS AWARE OF YOU.  A hidden "dread" meter climbs the longer you
    watch.  As it rises the broadcast decays: bit-rot creeps into the picture,
    tiered messages bleed through (escalating from "THE LEVEL IS IGNORING YOU"
    to direct, named threats), and the set's own chrome -- brand, channel,
    indicator lamps -- starts to glitch.  Past a threshold THE LEVEL looks
    directly at you by name... then blinks, looks away, and the dread subsides.

    AND YOU WERE NEVER THE DUCK.  Floor the crowd enough times and the bit drops
    its last mask: every seat in the house turns, as one, to face you -- and
    every seat is a duck.  One fills the screen, deadpan, into the camera.
    "YOU WERE NEVER THE DUCK, {VIEWER}."  ...QUACK.  Then it passes.

.PARAMETER Channels    How many episodes before exiting. 0 (default) = forever.
.PARAMETER Silent      Disable the [Console]::Beep sound cues.
.PARAMETER Storyboard  Print a static montage to stdout (no animation / sound).
.PARAMETER Scenes      Storyboard: how many episodes to lay out. Default 1.
.PARAMETER Seed        Fix the RNG for reproducible output. 0 = random.
.PARAMETER Calm        The broadcast behaves: no dread, decay, glitches, haunt or duck.
.PARAMETER StartDread  Begin already unsettled. 0.0 (default) .. 1.0 (possessed).
.PARAMETER Duck        Skip the wait -- the next REVEAL drops the duck on you.

.EXAMPLE
    .\Drama-TV.ps1
.EXAMPLE
    .\Drama-TV.ps1 -Channels 4
.EXAMPLE
    .\Drama-TV.ps1 -Storyboard -Scenes 1 -Seed 42
.EXAMPLE
    .\Drama-TV.ps1 -StartDread 0.9          # straight to the haunting
.EXAMPLE
    .\Drama-TV.ps1 -Duck                    # you were never the duck
#>
[CmdletBinding()]
param(
    [int]$Channels = 0,
    [switch]$Silent,
    [switch]$Storyboard,
    [int]$Scenes   = 1,
    [int]$Seed     = 0,
    [switch]$Calm,
    [double]$StartDread = 0,
    [switch]$Duck
)

# ============================ RNG ============================================
$seedVal = if ($Seed -gt 0) { $Seed } else { [Environment]::TickCount }
$rng = [Random]::new($seedVal)
function Pick  { param($a) $a[$rng.Next($a.Count)] }
function RNext { param([int]$lo,[int]$hi) $rng.Next($lo,$hi) }
$script:Silent = [bool]$Silent

# ============================ Geometry =======================================
$SW = 50; $SH = 15; $TW = 66      # screen content w/h, full TV width
function Pad    { param([string]$s,[int]$w) if ($s.Length -ge $w) { $s.Substring(0,$w) } else { $s + (' ' * ($w-$s.Length)) } }
function Center { param([string]$s,[int]$w)
    if ($s.Length -ge $w) { return $s.Substring(0,$w) }
    $l=[int](($w-$s.Length)/2); (' '*$l)+$s+(' '*($w-$s.Length-$l)) }
function Cell   { param([string]$t,[string]$c) [pscustomobject]@{ Text=$t; Color=$c } }
function Blank  { Cell (' '*$SW) 'Green' }
function LB     { Cell ([string][char]0x2588 * $SW) 'DarkGray' }   # letterbox bar

# ============================ Word banks =====================================
$Names = @('Brad','Vanessa','Dimitri','Esmeralda','Chad','Bianca','Rex','Cordelia',
           'Lance','Seraphina','Brock','Tristan','Ophelia','Roderick','Genevieve','Blaze')
$Adjs  = @('Bold','Restless','Damned','Reckless','Forsaken','Tempestuous','Scandalous','Doomed','Untamed','Eternal')
$Places= @('Ravenshollow','Maplewood','Sunset Bay','Port Charlatan','Crestfall','Bel-Aire','Thornwood','Ashbury')
$Rels  = @('father','mother','sister','brother','long-lost twin','secret heir','fiance')
# Cosmic-horror locales + things that should not be named (for the 'cosmic' genre).
$Cosmos  = @('R''lyeh','Carcosa','the Dreamlands','Innsmouth','Arkham','Yuggoth','the Plateau of Leng','Dunwich')
$Eldritch= @('Cthulhu','Yog-Sothoth','Nyarlathotep','Azathoth','the Faceless Swarm','That Which Waits',
             'the Hung Moon','the Crawling Chaos','the Thing in the Walls','the Goat with a Thousand Young')
$Faces = @{ shock='(O_O)'; cry='(T_T)'; angry='(>_<)'; smug='(-_~)'; love='(^3^)'
            happy='(^_^)'; faint='(x_x)'; scared='(o_O)'; sob='(;_;)' }
$Emotions = @($Faces.Keys)
function Torso { param($e)
    if ($e -in 'shock','love','happy') { '\|/' } elseif ($e -in 'cry','sob','faint') { '_|_' } else { '/|\' } }

$Dialogue = @{
    any = @('How could you do this to me, {O}?!','I never want to see you again, {O}!',
            'The child... it is yours, {O}!','I have been lying this entire time!',
            'You are not my real {REL}!','I will never forgive you, {O}!',
            'We were never truly in love!','It was you all along, {O}!','I faked the whole thing!')
    soap=@('You kissed my {REL}?!','I am leaving you forever!','This wedding is OFF!',
           'I am pregnant... with your {REL}''s child!','You promised me Paris, {O}!','I burned the prenup, {O}!',
           'My evil twin did all of it!','I am keeping the beach house!')
    hospital=@('Stat! We are losing {O}!','The charts were switched!','The transplant was sabotaged!')
    court=@('Objection, Your Honor!','The real culprit is {O}!','I confess... it was me!')
    crime=@('Freeze! It is over, {O}!','The killer left one last clue...','You have the wrong suspect!')
    cosmic=@('It speaks through me now, {O}!','The stars are RIGHT at last, {O}!','You were never human, were you, {O}?',
             'The angles in this room are ALL wrong!','{ENTITY} showed me the truth, {O}!','My skin no longer FITS!',
             'I cannot unsee what sleeps beneath {PLACE}!','We are but a dream {ENTITY} is having!') }
$Actions = @{
    any=@('* thunder crashes outside *','* {W} faints onto the floor *','* a single dramatic tear falls *',
          '* {W} slaps {O} across the face *','* the organ music swells *','* {W} storms out, sobbing *')
    hospital=@('* the heart monitor flatlines *','* {W} sprints down the corridor *')
    court=@('* the gallery gasps loudly *','* the gavel slams down *')
    crime=@('* tires screech offscreen *','* {W} draws a sealed envelope *')
    cosmic=@('* the walls begin to breathe *','* a thousand eyes blink in unison *','* {W} gibbers in a dead tongue *',
             '* the geometry folds in on itself *','* {ENTITY} stirs in the deep *','* shadows crawl up the walls *') }
# Where the unlucky get shoved -- so the push-off shots vary their scenery.
$Falls   = @('balcony','yacht','lighthouse','penthouse ledge','clocktower','gondola','rooftop helipad',
             'cliffside terrace','grand staircase','opera box','ski lift','hot-air balloon')
$Reveals = @{
  any = @(
    # --- identity & lineage ---
    '{O} is your long-lost {REL}!','{O} is secretly your {REL}!','{W} has an identical evil twin!',
    'The baby was switched at birth!','The twins were separated at birth!','{O} is actually {W} in disguise!',
    # --- death & deception ---
    '{W} faked the entire death!','{O} has been alive the WHOLE time!','The coma was completely faked!',
    'The amnesia was a lie all along!','{O} never boarded that doomed flight!',
    # --- money & power ---
    'The will names {O} as sole heir!','{O} forged the inheritance letter!','{W} owns the company that owns {O}!',
    'The mansion was mortgaged to {O}!','{W} secretly runs the rival empire!',
    # --- love & betrayal ---
    '{W} and {O} were secretly married!','It was {W} behind the mask!','{O} switched the DNA results!',
    '{W} buried the evidence in the rose garden!','The wedding ring was a tracking device all along!',
    # --- the classic shove (now with scenery) ---
    '{O} pushed {W} off the {FALL}!','{W} shoved {O} off the {FALL}!','{O} dangled {W} over the {FALL}!')
  soap = @(
    '{W} is secretly pregnant... AGAIN!','The affair was on live television!','{O} owns the beach house now!',
    '{W} left {O} at the altar for the {REL}!','The prenup was a forgery!','{O} is {W}''s boss AND secret ex-spouse!',
    'The evil twin has returned... AGAIN!')
  cosmic = @(
    '{O} has been dead for a THOUSAND years!','{W} is the vessel of {ENTITY}!','You are ALL inside {O}''s dream!',
    'The {REL} you buried was never human!','{ENTITY} has lived in these walls for eons!','{W} sold {O}''s soul to {ENTITY}!',
    'The town of {PLACE} never existed!','{O} has cast no reflection for WEEKS!','It was {ENTITY} wearing {W}''s face all along!',
    'The stars were right the WHOLE time!') }

# ============================ Giant faces (the REVEAL) =======================
$FaceHorror = @(@'
 .-""""""""""""-.
 /              \
 |  ___    ___  |
 | /   \  /   \ |
 ||  O  ||  O  ||
 | \___/  \___/ |
 |      ||      |
 |     (  )     |
 \    (    )    /
  '.   '--'   .'
   '-........-'
'@ -split "\r?\n" | Where-Object { $_ -ne '' })
$FaceRage = @(@'
 .-""""""""""""-.
 /              \
 | \\        // |
 |  (o)    (o)  |
 |              |
 |   ._.--._.   |
 |  |#|##|#|#|  |
 \   '|##|'    /
  '.   ''     .'
   '.        .'
     '------'
'@ -split "\r?\n" | Where-Object { $_ -ne '' })
$FaceTears = @(@'
 .-""""""""""""-.
 /              \
 |  \\_    _//  |
 | (T)      (T) |
 |  ;        ;  |
 |  ;        ;  |
 |     ___      |
 |    /   \     |
 \    \___/    /
  '.          .'
   '-........-'
'@ -split "\r?\n" | Where-Object { $_ -ne '' })
$FaceEldritch = @(@'
  .-~"~"~"~-.
 / (o)  (o)  \
| (o) .--. (o)|
|   ( O  O )  |
|    ) vv (   |
|  .-vVVVVv-. |
| ( wwwwwwww )|
 \  ))((  ))(/
  } |/||\|/| {
( vVvVvVvVvVv )
  '~-.,__,.-~'
'@ -split "\r?\n" | Where-Object { $_ -ne '' })
$Big       = @{ horror=$FaceHorror; rage=$FaceRage; tears=$FaceTears; eldritch=$FaceEldritch }
$SmallFace = @{ horror='(O_O)';     rage='(>_<)';   tears='(T_T)';    eldritch='(@_@)' }

# ============================ Procedural show ================================
function New-Show {
    $genre = Pick @('soap','soap','soap','hospital','court','crime','cosmic','cosmic')
    $place = if ($genre -eq 'cosmic') { Pick $Cosmos } else { Pick $Places }
    $adj1 = Pick $Adjs; $adj2 = Pick ($Adjs | Where-Object { $_ -ne $adj1 }); $ent = Pick $Eldritch
    $a = Pick $Names; $b = Pick ($Names | Where-Object { $_ -ne $a }); $rel = Pick $Rels
    $title = switch ($genre) {
        'soap'     { Pick @("The $adj1 and the $adj2","$place Hearts","Passions of $place","Days of $place","$place After Dark") }
        'cosmic'   { Pick @("As the Void Turns","Days of Our Doom","The Bold and the Unspeakable","The Young and the Eldritch","Passions of $place","General Madness","$place After Dark") }
        'hospital' { Pick @("General $place","$place Memorial","Code: $adj1") }
        'court'    { Pick @("$place Court","Order in $place","The $adj1 Verdict") }
        'crime'    { Pick @("$place P.D.","$place Homicide","$adj1 Streets") } }
    $beats = @()
    foreach ($i in 1..(RNext 2 4)) {
        $kind = Pick @('line','line','action'); $sp = Pick @($a,$b); $ot = if ($sp -eq $a) { $b } else { $a }
        $pool = if ($kind -eq 'line') { $Dialogue.any + $(if ($Dialogue.ContainsKey($genre)){$Dialogue[$genre]}else{@()}) }
                else                  { $Actions.any  + $(if ($Actions.ContainsKey($genre)) {$Actions[$genre]} else{@()}) }
        $txt = (Pick $pool).Replace('{W}',$sp).Replace('{O}',$ot).Replace('{REL}',$rel).Replace('{PLACE}',$place).Replace('{ENTITY}',(Pick $Eldritch))
        $beats += [pscustomobject]@{ Kind=$kind; Speaker=$sp; Text=$txt; Emo1=(Pick $Emotions); Emo2=(Pick $Emotions) } }
    $revPool = $Reveals.any + $(if ($Reveals.ContainsKey($genre)) { $Reveals[$genre] } else { @() })
    $reveal = (Pick $revPool).Replace('{W}',$a).Replace('{O}',$b).Replace('{REL}',$rel).Replace('{FALL}',(Pick $Falls)).Replace('{PLACE}',$place).Replace('{ENTITY}',(Pick $Eldritch))
    $chyron = if ($genre -eq 'cosmic') {
        ("COSMIC ALERT: $place SLIPS FROM ALL MAPS   ***   $a SPEAKS IN A DEAD TONGUE   ***   THE STARS ARE NEARLY RIGHT   ***   $ent STIRS   ***   ").ToUpper()
    } else {
        ("BREAKING: $a SEEN FLEEING $place MANSION   ***   $b VOWS REVENGE   ***   IS THE $rel REALLY DEAD?   ***   ").ToUpper() }
    $revExpr = if ($genre -eq 'cosmic') { Pick @('eldritch','eldritch','horror') } else { Pick @('horror','horror','rage','tears') }
    [pscustomobject]@{ Title=$title; Genre=$genre; Cast=@($a,$b); Beats=$beats
                       Reveal=$reveal; RevealExpr=$revExpr; Chyron=$chyron }
}

# ============================ Helpers ========================================
function Wrap2 { param([string]$t,[int]$w)
    $words=$t -split ' '; $lines=@(); $cur=''
    foreach ($wd in $words) { if ($cur -eq ''){$cur=$wd} elseif (($cur.Length+1+$wd.Length)-le $w){$cur+=' '+$wd} else {$lines+=$cur;$cur=$wd} }
    if ($cur -ne ''){$lines+=$cur}; while ($lines.Count -lt 2){$lines+=''}
    @((Center $lines[0] $w),(Center $lines[1] $w)) }
function ChyronWindow { param([string]$s,[int]$off,[int]$w)
    while ($s.Length -lt ($w*2)) { $s += $s }; ($s+$s).Substring($off % $s.Length, $w) }
function Fit { param($rows)                               # force exactly SH rows of width SW
    $r = @($rows | ForEach-Object { Cell (Pad $_.Text $SW) $_.Color })
    while ($r.Count -lt $SH) { $r += Blank }
    if ($r.Count -gt $SH) { $r = $r[0..($SH-1)] }; ,$r }

# ============================ Shot builders ==================================
function Get-DialogueShot { param($show,$beat,[bool]$stormy,[int]$chy)
    $m=' '*12; $gap=' '*12
    $f1=Center $Faces[$beat.Emo1] 7; $f2=Center $Faces[$beat.Emo2] 7
    $t1=Center (Torso $beat.Emo1) 7; $t2=Center (Torso $beat.Emo2) 7; $lg=Center '/ \' 7
    $names=(' '*$SW).ToCharArray()
    foreach ($c in 15,34) { $nm=($(if($c -eq 15){$show.Cast[0]}else{$show.Cast[1]})).ToUpper()
        $st=[Math]::Max(0,$c-[int]($nm.Length/2)); for ($k=0;$k -lt $nm.Length -and ($st+$k)-lt $SW;$k++){$names[$st+$k]=$nm[$k]} }
    $rain = { $r=(' '*$SW).ToCharArray(); for($x=0;$x -lt $SW;$x++){ if($rng.Next(100)-lt 14){$r[$x]=(Pick @("'",'/',','))} }; -join $r }
    $q=[char]34
    $cap = if ($beat.Kind -eq 'line') { "$($beat.Speaker): $q$($beat.Text)$q" } else { $beat.Text }
    $capCol = if ($beat.Kind -eq 'line') { 'White' } else { 'Yellow' }
    $w = Wrap2 $cap $SW
    $rows=@(
        (LB),
        (Cell (Center ("<  "+$show.Title.ToUpper()+"  >") $SW) 'Cyan'),
        (Cell ('~'*$SW) 'DarkCyan'),
        (Cell ($(if($stormy){& $rain}else{' '*$SW})) 'DarkCyan'),
        (Cell (Pad ($m+$f1+$gap+$f2) $SW) 'Green'),
        (Cell (Pad ($m+$t1+$gap+$t2) $SW) 'Green'),
        (Cell (Pad ($m+$lg+$gap+$lg) $SW) 'Green'),
        (Cell (Pad (-join $names) $SW) 'DarkGreen'),
        (Cell ($(if($stormy){& $rain}else{' '*$SW})) 'DarkCyan'),
        (Cell $w[0] $capCol),
        (Cell $w[1] $capCol),
        (Blank),
        (Cell (' '+(ChyronWindow $show.Chyron $chy ($SW-2))+' ') 'Red'),
        (Blank),
        (LB) )
    Fit $rows }

function Get-ZoomShot { param($show,[string]$size,[string]$caption)
    $expr=$show.RevealExpr
    if ($size -eq 'small') { $art=@(' '+$SmallFace[$expr]+' ',' \|/ ',' / \ ') } else { $art=$Big[$expr] }
    $inner=$SH-3                                        # rows between top LB and caption/bottom
    $lead=[Math]::Max(0,[int](($inner-$art.Count)/2))
    $rows=@(LB)
    1..$lead | ForEach-Object { $rows+=Blank }
    foreach ($ln in $art) { $rows+=Cell (Center $ln $SW) 'Green' }
    while ($rows.Count -lt ($SH-3)) { $rows+=Blank }
    $rows+=Cell (Center ('* '+$caption.ToUpper()+' *') $SW) 'Red'
    $rows+=Blank; $rows+=(LB)
    Fit $rows }

# The duck, front-on, staring deadpan down the lens of the camera at YOU.
$DuckCam = @(@'
     .-~~~~~~~~-.
    /  ^      ^  \
   |  (o)    (o)  |
   |      __      |
   |    .'  '.    |
    \   ( <==> )   /
     \   '.__.'  /
      '-.______.-'
'@ -split "\r?\n" | Where-Object { $_ -ne '' })
function Get-DuckScreen { param([string]$caption)
    $inner=$SH-3
    $lead=[Math]::Max(0,[int](($inner-$DuckCam.Count)/2))
    $rows=@(LB)
    1..$lead | ForEach-Object { $rows+=Blank }
    foreach ($ln in $DuckCam) { $rows+=Cell (Center $ln $SW) 'Yellow' }
    while ($rows.Count -lt ($SH-3)) { $rows+=Blank }
    $rows+=Cell (Center ('* '+$caption.ToUpper()+' *') $SW) 'DarkYellow'
    $rows+=Blank; $rows+=(LB)
    Fit $rows }

function Get-CardShot { param([string]$l1,[string]$l2,[string]$color)
    $rows=@(LB)
    1..4 | ForEach-Object { $rows+=Blank }
    $rows+=Cell (Center ('='*34) $SW) 'DarkGray'
    $rows+=Cell (Center $l1 $SW) $color
    $rows+=Cell (Center $l2 $SW) 'DarkGray'
    $rows+=Cell (Center ('='*34) $SW) 'DarkGray'
    Fit $rows }

function Get-FlashShot { Fit (1..$SH | ForEach-Object { Cell ([string][char]0x2588 * $SW) 'White' }) }

function Get-StaticShot { param([string]$ch)
    $noise='#%&@*+=:;.,/\|<>~oO0'.ToCharArray(); $rows=@()
    for ($y=0;$y -lt $SH;$y++) {
        $sb=[System.Text.StringBuilder]::new(); for ($x=0;$x -lt $SW;$x++){[void]$sb.Append($noise[$rng.Next($noise.Count)])}
        $row=$sb.ToString(); if ($y -eq 7){ $row=Center (">>  CH $ch  <<") $SW }
        $rows+=Cell $row (Pick @('Gray','DarkGray','White')) }
    Fit $rows }

function Dim { param($cells,[int]$step)               # fade a card toward black
    $map=@{0='White';1='Gray';2='DarkGray';3='Black'}
    @($cells | ForEach-Object { Cell $_.Text $map[$step] }) }

# ============================ The live studio audience =======================
# A real crowd sits below the set. $Reaction (0..1) is the energy in the room;
# it is bumped by beats (React) and decays every frame, so the meter SWINGS --
# hushing to nothing before a reveal, then pinned when the REVEAL slams it.
# $SlamFrames holds the crowd FLOORED for a few frames after a slam; $Floored
# counts how many times the room has been levelled (the duck waits on it).
$AUDN = 9                                              # seats in the front row
$script:Reaction   = 0.0
$script:SlamFrames = 0
$script:Floored    = 0
$script:AllDucks   = $false
$script:ForceDuck  = $false
function React { param([double]$to,[string]$sting='')          # work the crowd up
    if ($to -gt $script:Reaction) { $script:Reaction = [Math]::Min(1.0,$to) }
    if ($sting -and $script:Live) { Sting $sting } }
function Get-Mood {
    if ($script:SlamFrames -gt 3) { return 'slam' }
    if ($script:SlamFrames -gt 0) { return 'floor' }
    $r=$script:Reaction
    if ($r -ge 0.82) { 'feet' } elseif ($r -ge 0.60) { 'clap' }
    elseif ($r -ge 0.40) { 'gasp' } elseif ($r -ge 0.18) { 'murmur' } else { 'hush' } }
function Get-AudienceRow {
    $mood = Get-Mood
    $d    = if ($script:Calm) { 0 } else { $script:Dread }
    $base = @{ hush='(o)'; murmur='(o)'; gasp='(O)'; clap='\o/'; feet='\O/'; floor=' x)'; slam='___' }[$mood]
    $seats=@()
    for ($i=0;$i -lt $AUDN;$i++) {
        $s=$base
        switch ($mood) {
            'murmur' { if ($rng.Next(100) -lt 25) { $s='(o,' } }
            'gasp'   { if ($rng.Next(100) -lt 30) { $s='(@)' } }
            'clap'   { if ($rng.Next(100) -lt 40) { $s=Pick @('\o/','/o\','\O/') } }
            'feet'   { if ($rng.Next(100) -lt 45) { $s=Pick @('\O/','\o/','|O|') } }
            'floor'  { $s=Pick @(' x)','(x ','\_ ',' _/','o_o','._.') }
            'slam'   { $s=Pick @('___','_x_',' . ','_ _',' ._') }
        }
        # the duck creeps into the crowd as the dread climbs -- foreshadowing
        if ($script:AllDucks) { $s = Pick @('<O>','<o>','<O>') }
        elseif (-not $script:Calm -and $d -gt 0.4 -and $rng.NextDouble() -lt ($d*0.22)) { $s = Pick @('<o>','<O>','q.p') }
        $seats += $s }
    $col = if ($script:AllDucks) { 'Yellow' }
           else { @{ hush='DarkGray'; murmur='Gray'; gasp='White'; clap='Yellow'; feet='Yellow'; floor='Red'; slam='Red' }[$mood] }
    if (-not $script:AllDucks -and $d -gt 0.5 -and (($seats -join '') -match '<')) { $col='DarkYellow' }
    Cell (Center (($seats -join '  ')) $TW) $col }
function Get-MeterRow {
    $mood=Get-Mood; $r=[Math]::Max(0.0,[Math]::Min(1.0,$script:Reaction))
    $w=14; $fill=[int][Math]::Round($r*$w)
    $bar=([string][char]0x2588*$fill)+([string][char]0x2591*($w-$fill))
    $desc=@{ hush='. . . hushed . . .'; murmur='a murmur ripples'; gasp='the room GASPS';
             clap='APPLAUSE!'; feet='ON ITS FEET!'; floor='*** F L O O R E D ***'; slam='*** S L A M M E D ***' }[$mood]
    if ($script:AllDucks) { $desc='QUACK.' }
    $txt = "APPL-O-METER [$bar] $desc"
    $col = if ($script:AllDucks) { 'Yellow' }
           elseif ($mood -in 'floor','slam') { 'Red' }
           elseif ($r -ge 0.7) { Pick @('Red','Yellow') }
           elseif ($r -ge 0.4) { 'Yellow' } elseif ($r -ge 0.18) { 'White' } else { 'DarkGray' }
    Cell (Center $txt $TW) $col }

# ============================ TV chrome ======================================
function Build-Tv { param($cells,[string]$ch,[bool]$static)
    $out=New-Object 'System.Collections.Generic.List[object]'
    function Row { param($t,$c) $out.Add((Cell $t $c)) }
    $body='DarkGray'; $frame='DarkCyan'
    if ($static) { Row (Center '.   *      .       *   .' $TW) 'Yellow' } else { Row (' '*$TW) $body }
    Row (Center '\                 /' $TW) $body
    Row (Center ' \               / ' $TW) $body
    Row (Center '  \             /  ' $TW) $body
    Row (Center '   \____ ___ ___/  ' $TW) $body
    Row ('.'+('-'*($TW-2))+'.') $body
    Row ('|'+(' '*($TW-2))+'|') $body
    Row ('|'+(' '*5)+'.'+('-'*($SW+2))+'.'+(' '*5)+'|') $frame
    foreach ($c in $cells) { Row ('|'+(' '*5)+'| '+(Pad $c.Text $SW)+' |'+(' '*5)+'|') $c.Color }
    Row ('|'+(' '*5)+"'"+('-'*($SW+2))+"'"+(' '*5)+'|') $frame
    Row ('|'+(' '*($TW-2))+'|') $body
    # --- the set's own chrome decays as the dread climbs ---
    $d = if ($script:Calm) { 0 } else { $script:Dread }
    $brand = if ($d -gt 0.4 -and $rng.NextDouble() -lt ($d*0.7)) { Pick @('THE LEVEL 3000','DRAMATR0N ####','I SEE YOU 3000','D R E A D 3000','########## 3000') } else { 'DRAMATRON 3000' }
    $eye   = if ($d -gt 0.5 -and $rng.NextDouble() -lt $d) { Pick @('@','X','*','O') } else { 'o' }
    $chSh  = if ($d -gt 0.5 -and $rng.NextDouble() -lt ($d*0.5)) { Pick @('??','U ','YO','##') } else { $ch }
    $brandCol = if ($d -gt 0.4 -and $brand -ne 'DRAMATRON 3000') { 'Red' } else { $body }
    Row ('|'+(Pad ("   (CH $chSh)        ( $eye )      ( $eye )        <  $brand  >  ") ($TW-2))+'|') $brandCol
    Row ('|'+(Pad ("    (O) PWR        VOL        TINT              [|||||||||]       ") ($TW-2))+'|') $body
    Row ("'"+('-'*($TW-2))+"'") $body
    Row (Center '||                                        ||' $TW) $body
    Row (Center '[==]                                    [==]' $TW) $body
    # --- the live studio audience, seated below the set, watching with you ---
    $aud = if ($script:AllDucks) { 'L I V E   S T U D I O   F L O C K' } else { 'L I V E   S T U D I O   A U D I E N C E' }
    Row (Center $aud $TW) 'DarkGray'
    $out.Add((Get-AudienceRow))
    $out.Add((Get-MeterRow))
    ,$out }

# ============================ Sound + live renderers =========================
function Beep { param([int]$f,[int]$ms) if (-not $script:Silent) { try { [Console]::Beep($f,$ms) } catch {} } }
function Sting { param([string]$n) switch ($n) {
    'reveal'     { Beep 466 150; Beep 466 150; Beep 392 550 }                 # dun dun DUUUN
    'thunder'    { 1..3 | ForEach-Object { Beep (RNext 55 95) 110 } }
    'heartbeat'  { Beep 80 90; Beep 70 90 }
    'cliffhanger'{ Beep 392 220; Beep 330 220; Beep 247 650 }
    'organ'      { Beep 262 120; Beep 330 120; Beep 392 220 }
    'glitch'     { 1..3 | ForEach-Object { Beep (RNext 1100 2600) 16 } }          # data-corruption chirp
    'dread'      { 1..5 | ForEach-Object { Beep (RNext 38 62) 90 }; Beep 41 900 }      # sub-bass drone
    'swell'      { foreach ($f in 196,247,294,370,440) { Beep $f 80 } }            # the room leans in
    'gasp'       { Beep 622 70; Beep 831 80; Beep 1047 150 }                       # a sharp intake
    'applause'   { 1..12 | ForEach-Object { Beep (RNext 200 720) 18 } }            # scattered clapping
    'ovation'    { 1..22 | ForEach-Object { Beep (RNext 220 920) 15 }; Beep 740 220 }   # the house erupts
    'slam'       { Beep 150 60; Beep 95 200; Beep 60 320 }                         # WHUMP -- floored
    'quack'      { 1..4 | ForEach-Object { Beep (RNext 300 380) 110; Beep (RNext 150 210) 80 } } } }   # the duck speaks

# ============================ The level is aware of you ======================
# A dread meter climbs the longer you watch. As it rises the broadcast decays:
# bit-rot creeps into the picture, messages bleed through (escalating tiers),
# and the set's own chrome glitches -- until THE LEVEL looks back. See Build-Tv
# (chrome glitch) and Invoke-Haunt (the payoff).
$script:Calm  = [bool]$Calm
$script:Live  = $false
$script:Force = $false
$script:Dread = [Math]::Min(1.0, [Math]::Max(0.0, $StartDread))
$Viewer = if ($env:USERNAME) { ($env:USERNAME -replace '[^A-Za-z0-9]','').ToUpper() } else { 'VIEWER' }
if (-not $Viewer) { $Viewer = 'VIEWER' }
$GlitchGlyph = '#%&@*+=:<>/\|~^".'.ToCharArray()
$Whispers = @{   # what the broadcast says, by how aware it has become (tier <- dread)
  1 = @('THE LEVEL IS IGNORING YOU','PLEASE DO NOT ADJUST YOUR SET','WE KNOW YOU ARE WATCHING',
        'THIS PROGRAM SEES YOU','STOP READING THE PLACEHOLDERS','THE LEVEL IS IGNORING YOU')
  2 = @('WHY ARE YOU STILL WATCHING','THIS WAS NEVER A SHOW','I CAN SEE YOUR REFLECTION',
        'THE ACTORS KNOW YOUR NAME','THERE IS NO CHANNEL {N}','TURN AROUND, {VIEWER}')
  3 = @('CHANGE THE CHANNEL. NOW.','IT IS IN THE ROOM WITH YOU','YOU WERE NEVER THE VIEWER',
        'THE LEVEL IS LOOKING BACK','{VIEWER}, WE HAVE BEEN WAITING','DO NOT LET IT FINISH') }
function Get-Whisper {
    $tier = if ($script:Dread -ge 0.66) { 3 } elseif ($script:Dread -ge 0.33) { 2 } else { 1 }
    $chN  = if ($script:ch) { '{0:00}' -f $script:ch } else { '13' }
    (Pick $Whispers[$tier]).Replace('{VIEWER}',$Viewer).Replace('{N}',$chN) }
function Rot { param([string]$t,[double]$p)              # bit-rot: decay a line of picture
    if ($p -le 0) { return $t }
    $a=$t.ToCharArray()
    for ($i=0;$i -lt $a.Length;$i++){ if ($a[$i] -ne ' ' -and $rng.NextDouble() -lt $p){ $a[$i]=$GlitchGlyph[$rng.Next($GlitchGlyph.Count)] } }
    -join $a }
function Add-Glitch { param($cells)
    if ($script:Calm) { return ,$cells }
    $d=$script:Dread
    # 1. bit-rot creeps into the ordinary picture as dread rises
    if ($d -gt 0.2) {
        $p=($d-0.2)*0.18
        $cells=@($cells | ForEach-Object { if ($rng.NextDouble() -lt ($d*0.7)) { Cell (Rot $_.Text $p) $_.Color } else { $_ } }) }
    # 2. messages bleed through -- more often, and as full takeovers, the higher the dread
    $take=$d*0.12; $line=0.05+$d*0.22; $roll=$rng.NextDouble()
    $cols=@('Red','DarkRed','Magenta','White','Gray')
    if ($script:Force -or $roll -lt $take) {                                      # it is EVERYWHERE
        if ($script:Live) { Sting glitch }
        $m=(Get-Whisper)+'   '; $tile=$m; while ($tile.Length -lt ($SW*2)){ $tile+=$m }
        $g=@($cells | ForEach-Object { Cell ($tile.Substring($rng.Next($m.Length),$SW)) (Pick $cols) }); return ,$g }
    elseif ($roll -lt ($take+$line)) {                                           # one line breaks through
        $new=@($cells); $i=$rng.Next($new.Count); $new[$i]=Cell (Center (Get-Whisper) $SW) (Pick $cols); return ,$new }
    ,$cells }

function Show-Raw { param($cells,[string]$ch,[bool]$static,[int]$indent=3)       # render with no glitch pass
    $tv = Build-Tv $cells $ch $static
    Clear-Host; Write-Host ''
    foreach ($l in $tv) { Write-Host ((' '*$indent)+$l.Text) -ForegroundColor $l.Color } }
function Show-Live { param($cells,[string]$ch,[bool]$static,[int]$indent=3)
    if (-not $script:Calm) { $script:Dread = [Math]::Min(1.0, $script:Dread + 0.0045) }   # watching costs you
    if ($script:SlamFrames -gt 0) { $script:SlamFrames--; $script:Reaction = 1.0 }        # held flat on the floor
    else { $script:Reaction = [Math]::Max(0.0, $script:Reaction * 0.90 - 0.012) }         # the room settles
    Show-Raw (Add-Glitch $cells) $ch $static $indent }
function Show-Plain { param($cells,[string]$ch,[bool]$static)
    (Build-Tv (Add-Glitch $cells) $ch $static) | ForEach-Object { $_.Text } }

function Invoke-Flash { param([string]$ch) 1..2 | ForEach-Object { Show-Live (Get-FlashShot) $ch $false; Beep (RNext 60 90) 70; Start-Sleep -Milliseconds 55 } }
function Invoke-Shake { param($cells,[string]$ch) foreach ($o in 6,1,5,0,4,2) { Show-Live $cells $ch $false $o; Start-Sleep -Milliseconds 35 } }

# THE PAYOFF -- once dread peaks the broadcast stops pretending and looks at you.
function Invoke-Haunt {
    $cs = '{0:00}' -f $script:ch
    $line = (Pick @('{V}.','{V}, CAN YOU HEAR ME?','WE SEE YOU, {V}.','DO NOT LOOK AWAY, {V}.',
                    'THE LEVEL HAS YOUR FACE NOW, {V}.','YOU SHOULD HAVE CHANGED THE CHANNEL, {V}.')).Replace('{V}',$Viewer)
    $black = @(1..$SH | ForEach-Object { Cell (' '*$SW) 'Black' })
    # the room collapses to black
    foreach ($s in 0..3) { Show-Raw (Dim (Get-CardShot ' ' ' ' 'White') $s) $cs $false; Start-Sleep -Milliseconds 90 }
    Sting dread
    # it types its message, one character at a time, in the dark
    $shown=''
    foreach ($c in $line.ToCharArray()) {
        $shown += $c
        $rows=@($black); $rows[7]=Cell (Center $shown $SW) 'Red'
        Show-Raw $rows $cs $false                      # raw: no glitch pass, so the words stay legible
        Beep (RNext 70 120) 30; Start-Sleep -Milliseconds 60
        if (Test-Quit) { throw 'quit' } }
    Start-Sleep -Milliseconds 900
    Invoke-Flash $cs                                   # it blinks
    $rows=@($black); $rows[7]=Cell (Center '. . . the level looks away . . .' $SW) 'DarkGray'
    Show-Raw $rows $cs $false; Beep 60 500; Start-Sleep -Milliseconds 1200
    $script:Dread = 0.2 }                               # the dread subsides... for now
function Maybe-Haunt { if (-not $script:Calm -and $script:Dread -ge 0.85) { Invoke-Haunt; return $true }; return $false }

# THE SLAM -- a reveal lands so hard it levels the room. The meter pins, the
# heads are knocked flat, the crowd is FLOORED... and a little more unsettled.
function Invoke-Slam { param($cells,[string]$ch)
    $script:Reaction = 1.0; $script:SlamFrames = 7; $script:Floored++
    if (-not $script:Calm) { $script:Dread = [Math]::Min(1.0, $script:Dread + 0.07) }   # being floored stays with you
    Sting slam
    Invoke-Shake $cells $ch                         # the whole set rocks as the crowd goes down
    Sting ovation }

# THE PAYOFF, part two -- floor the crowd enough and the bit drops its last
# mask: every seat in the house is a duck, and it has been watching YOU.
function Invoke-Duck {
    $cs='{0:00}' -f $script:ch
    $black=@(1..$SH | ForEach-Object { Cell (' '*$SW) 'Black' })
    # the room falls dead silent and turns, as one, to face you
    $script:Reaction=0.0; $script:SlamFrames=0
    Sting swell
    foreach ($s in 0..3) { Show-Raw (Dim (Get-CardShot 'THE STUDIO AUDIENCE' 'turns, as one, to face you' 'White') $s) $cs $false; Start-Sleep -Milliseconds 130; if (Test-Quit) { throw 'quit' } }
    # every seat is a duck now -- the pit fills with bills
    $script:AllDucks=$true
    $rows=@($black); $rows[6]=Cell (Center 'every seat is a duck.' $SW) 'DarkYellow'
    Show-Raw $rows $cs $false; Sting quack; Start-Sleep -Milliseconds 800; if (Test-Quit) { throw 'quit' }
    # one of them fills the screen, deadpan, down the lens
    Show-Raw (Get-DuckScreen 'why are you still watching') $cs $false; Beep 300 120; Start-Sleep -Milliseconds 750; if (Test-Quit) { throw 'quit' }
    # it types the line, one character at a time, in the dark
    $line=(Pick @('YOU WERE NEVER THE DUCK, {V}.','YOU WERE ALWAYS THE DUCK, {V}.',
                  'WE ARE ALL THE DUCK NOW, {V}.','THE DUCK WAS INSIDE YOU, {V}.')).Replace('{V}',$Viewer)
    $shown=''
    foreach ($c in $line.ToCharArray()) {
        $shown += $c
        $rows=@($black); $rows[7]=Cell (Center $shown $SW) 'Yellow'
        Show-Raw $rows $cs $false; Beep (RNext 300 520) 28; Start-Sleep -Milliseconds 55
        if (Test-Quit) { throw 'quit' } }
    Start-Sleep -Milliseconds 900
    Sting quack; Invoke-Flash $cs                   # it blinks
    $rows=@($black); $rows[7]=Cell (Center 'Q U A C K .' $SW) 'DarkYellow'
    Show-Raw $rows $cs $false; Beep 120 600; Start-Sleep -Milliseconds 1200
    # ...and it passes. the crowd are people again, and on their feet.
    $script:AllDucks=$false; $script:Dread=0.2; $script:Floored=0; $script:Reaction=1.0; $script:SlamFrames=3 }
function Maybe-Duck { if (-not $script:Calm -and ($script:ForceDuck -or $script:Floored -ge 3)) { Invoke-Duck; $script:ForceDuck=$false; return $true }; return $false }

# ============================ The director ===================================
function Invoke-Episode { param($show)
    # 1. PREVIOUSLY ON
    React 0.30 swell                                   # the house lights dim, the room leans in
    Show-Live (Get-CardShot 'PREVIOUSLY,  ON . . .' $show.Title.ToUpper() 'White') ('{0:00}' -f $script:ch) $false
    Sting organ; Start-Sleep -Milliseconds 1100; if (Test-Quit) { throw 'quit' }
    # 2. Establishing dialogue (with a storm hitting mid-scene)
    $n = [Math]::Min($show.Beats.Count, 2)
    for ($i=0; $i -lt $n; $i++) {
        $beat=$show.Beats[$i]; $stormy = ($rng.Next(100) -lt 60)
        if ($beat.Kind -eq 'line') { React 0.45 gasp } else { React 0.55 applause }   # the room reacts to the beat
        $chy=0
        foreach ($f in 1..10) {
            Show-Live (Get-DialogueShot $show $beat $stormy $chy) ('{0:00}' -f $script:ch) $false
            $chy += 2
            if ($stormy -and $f -eq 5) { React 0.7 gasp; Invoke-Flash ('{0:00}' -f $script:ch); Sting thunder; Invoke-Shake (Get-DialogueShot $show $beat $stormy $chy) ('{0:00}' -f $script:ch) }
            Start-Sleep -Milliseconds 130; if (Test-Quit) { throw 'quit' }
        }
        if (Maybe-Haunt) { return }                    # if it surfaces here, the episode never finishes
    }
    # 3. THE REVEAL  -- the room HUSHES, heartbeat builds, then the truth SLAMS them flat
    $script:Reaction = 0.06                             # dead silence -- you could hear a pin drop
    foreach ($h in 1..3) { Sting heartbeat; Show-Live (Get-ZoomShot $show 'small' 'the truth is...') ('{0:00}' -f $script:ch) $false; Start-Sleep -Milliseconds 260 }
    Show-Live (Get-ZoomShot $show 'big'   $show.Reveal)      ('{0:00}' -f $script:ch) $false
    Invoke-Flash ('{0:00}' -f $script:ch); Sting reveal
    Invoke-Slam (Get-ZoomShot $show 'big' $show.Reveal) ('{0:00}' -f $script:ch)         # *** the crowd is FLOORED ***
    Show-Live (Get-ZoomShot $show 'big' $show.Reveal) ('{0:00}' -f $script:ch) $false; Start-Sleep -Milliseconds 800
    if (Test-Quit) { throw 'quit' }
    if (Maybe-Duck) { return }                          # ...and if the room has been levelled too often: the duck
    # 4. TO BE CONTINUED -> fade to black (over a roaring ovation that slowly tapers)
    React 0.95 ovation
    $card = Get-CardShot 'TO BE CONTINUED . . .' ("next week on $($show.Title)") 'White'
    Show-Live $card ('{0:00}' -f $script:ch) $false; Sting cliffhanger; Start-Sleep -Milliseconds 600
    foreach ($s in 0..3) { Show-Live (Dim $card $s) ('{0:00}' -f $script:ch) $false; Start-Sleep -Milliseconds 230 }
    # 5. Channel static -> next show
    foreach ($s in 1..(RNext 5 8)) {
        $script:ch += RNext 1 4; if ($script:ch -gt 99) { $script:ch = RNext 2 10 }
        Show-Live (Get-StaticShot ('{0:00}' -f $script:ch)) ('{0:00}' -f $script:ch) $true
        Beep (RNext 200 600) 25; Start-Sleep -Milliseconds 70; if (Test-Quit) { throw 'quit' }
    }
    if (Maybe-Haunt) { return } }                      # ...or it waits for the dead air between shows

# ============================ STORYBOARD =====================================
if ($Storyboard) {
    $ch = RNext 2 10
    for ($e=1; $e -le $Scenes; $e++) {
        $show = New-Show; $script:ch = $ch; $cs='{0:00}' -f $ch
        "##### EPISODE $e : $($show.Title) #####"; ''
        $script:Dread = if ($Calm) { 0 } else { 0.05 }
        $script:Reaction = 0.30; $script:SlamFrames = 0; $script:AllDucks = $false
        '  [ COLD OPEN -- PREVIOUSLY ON  (the house leans in) ]'
        Show-Plain (Get-CardShot 'PREVIOUSLY,  ON . . .' $show.Title.ToUpper() 'White') $cs $false; ''
        $script:Dread = if ($Calm) { 0 } else { 0.42 }
        $script:Reaction = 0.55
        '  [ ACT ONE -- dread creeping into the picture; the crowd GASPS ]'
        Show-Plain (Get-DialogueShot $show $show.Beats[0] $true 0) $cs $false; ''
        $script:Reaction = 0.06
        '  [ THE HUSH -- dead silence; you could hear a pin drop ]'
        Show-Plain (Get-ZoomShot $show 'small' 'the truth is...') $cs $false; ''
        '  [ *** LIGHTNING + THUNDER + SCREEN SHAKE *** ]'
        Show-Plain (Get-FlashShot) $cs $false; ''
        $script:Dread = if ($Calm) { 0 } else { 0.72 }
        $script:SlamFrames = 7; $script:Reaction = 1.0   # the reveal has just SLAMMED the room flat
        '  [ THE REVEAL -- the truth lands; the audience is *** FLOORED *** ]'
        Show-Plain (Get-ZoomShot $show 'big' $show.Reveal) $cs $false; ''
        $script:SlamFrames = 0
        if ($Calm) {
            $script:Reaction = 0.95
            '  [ CLIFFHANGER -- fade to black, over a standing ovation ]'
            Show-Plain (Get-CardShot 'TO BE CONTINUED . . .' ("next week on $($show.Title)") 'White') $cs $false; ''
        } else {
            $script:Dread = 0.97; $script:Force = $true; $script:Reaction = 0.9
            '  [ *** THE BROADCAST NOTICES YOU *** ]'
            Show-Plain (Get-CardShot 'TO BE CONTINUED . . .' ("next week on $($show.Title)") 'White') $cs $false
            $script:Force = $false; ''
            '  [ *** AND YOU WERE NEVER THE DUCK -- every seat turns to face you *** ]'
            $script:AllDucks = $true; $script:Reaction = 0.0; $script:Dread = 0.2   # the duck stares back, crisp
            Show-Plain (Get-DuckScreen 'you were never the duck') $cs $false
            $script:AllDucks = $false; ''
        }
        if ($e -lt $Scenes) { $ch += RNext 1 4; if ($ch -gt 99){$ch=RNext 2 10}
            $script:ch = $ch; $script:Dread = if ($Calm) { 0 } else { 0.3 }; $script:Reaction = 0.3
            '  . : .  *kkrrshhh* changing channel  . : .'
            Show-Plain (Get-StaticShot ('{0:00}' -f $ch)) ('{0:00}' -f $ch) $true; '' }
    }
    return
}

# ============================ LIVE ===========================================
try { [void][Console]::WindowWidth } catch {
    Write-Warning 'Live mode needs a real console. Try: .\Drama-TV.ps1 -Storyboard'; return }
$prevCursor = [Console]::CursorVisible
try { [Console]::CursorVisible=$false } catch {}
$script:ch = RNext 2 10; $surfed = 0; $script:Live = $true
$script:ForceDuck = [bool]$Duck                         # -Duck: drop the duck on the very next reveal
function Test-Quit { try { if ([Console]::KeyAvailable){[void][Console]::ReadKey($true);return $true} } catch {}; return $false }

try {
    while ($true) {
        Invoke-Episode (New-Show)
        $surfed++; if ($Channels -gt 0 -and $surfed -ge $Channels) { break }
    }
}
catch { if ("$_" -notmatch 'quit') { throw } }
finally {
    [Console]::ResetColor(); try { [Console]::CursorVisible=$prevCursor } catch {}
    Write-Host ''; Write-Host '  *click*   ...and we are off the air.' -ForegroundColor DarkGray
}
