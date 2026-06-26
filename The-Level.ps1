<#
.SYNOPSIS
    DRAMA TV presents -- "THE LEVEL": a haunted prime-time GAME SHOW staged in
    your terminal. A too-smooth host, a sweating contestant, a studio crowd, and
    ONE RULE that blinks in red between every round:

        UNDER NO CIRCUMSTANCES PUT THE LEVEL BACK IN THE LEVEL.

    The contestant clears a round (the crowd claps), clears another (the crowd is
    on its feet)... and then, inevitably, puts THE LEVEL back in THE LEVEL. The
    board folds in on itself -- THE LEVEL inside THE LEVEL inside THE LEVEL,
    boxes within boxes plunging to the vanishing point -- and the room is not
    just FLOORED. It is FLOORED, FLOORED: the meter pins twice, the heads go
    down twice, and somewhere in the recursion the broadcast remembers your name.

.DESCRIPTION
    Each round is directed in beats:
      THIS WEEK ON THE LEVEL ...  ->  THE ONE RULE (flashing red)
      ->  the host poses the board (a single LEVEL box, label on the lid)
      ->  the contestant ANSWERS -- safe answers bank applause, the room rises
      ->  THE TEMPTATION: the prize doubles if they nest it just once more...
      ->  THEY PUT THE LEVEL BACK IN THE LEVEL  ->  RECURSION: nested boxes
          zoom inward to the vanishing point, a falling-pitch siren
      ->  FLOORED, FLOORED -- a double slam; the crowd is levelled, then
          levelled again  ->  TO BE CONTINUED  ->  channel static -> next round.

    AND ONCE THE ROOM HAS BEEN DOUBLE-FLOORED ENOUGH, THE LEVEL LOOKS BACK.
    The set collapses to black, the recursion keeps going where the screen
    can't, and the only rule turns out to have been about you all along:
    "YOU PUT YOURSELF BACK IN THE LEVEL, {VIEWER}." Then it blinks, and the
    next round begins. (Canon with the dread that haunts Drama-TV.ps1.)

    Live mode redraws in place with sound + motion (needs a real console).
    -Storyboard prints a representative montage of frames to stdout instead.

.PARAMETER Rounds      How many rounds before exiting. 0 (default) = forever.
.PARAMETER Silent      Disable the [Console]::Beep sound cues.
.PARAMETER Storyboard  Print a static montage to stdout (no animation / sound).
.PARAMETER Scenes      Storyboard: how many rounds to lay out. Default 1.
.PARAMETER Seed        Fix the RNG for reproducible output. 0 = random.
.PARAMETER Fast        Shorter holds, snappier typing. For the impatient.
.PARAMETER Calm        The show behaves: the rule is kept, nobody breaks it, no haunt.
.PARAMETER Depth       How deep the recursion plunges when the rule breaks. Default 7.
.PARAMETER Haunt       Skip the wait -- THE LEVEL looks back this very round.

.EXAMPLE
    .\The-Level.ps1
.EXAMPLE
    .\The-Level.ps1 -Rounds 3
.EXAMPLE
    .\The-Level.ps1 -Storyboard -Scenes 1 -Seed 42
.EXAMPLE
    .\The-Level.ps1 -Calm                # the rule is kept; a cosy quiz night
.EXAMPLE
    .\The-Level.ps1 -Haunt               # straight to: it looks back
#>
[CmdletBinding()]
param(
    [int]$Rounds = 0,
    [switch]$Silent,
    [switch]$Storyboard,
    [int]$Scenes = 1,
    [int]$Seed   = 0,
    [switch]$Fast,
    [switch]$Calm,
    [int]$Depth  = 7,
    [switch]$Haunt
)

# ============================ RNG ============================================
$seedVal = if ($Seed -gt 0) { $Seed } else { [Environment]::TickCount }
$rng = [Random]::new($seedVal)
function Pick  { param($a) $a[$rng.Next($a.Count)] }
function RNext { param([int]$lo,[int]$hi) $rng.Next($lo,$hi) }
$script:Silent = [bool]$Silent
$script:Calm   = [bool]$Calm
$ms = if ($Fast) { 0.5 } else { 1.0 }                 # global time-scale for holds
function Hold { param([int]$d) Start-Sleep -Milliseconds ([int]($d*$ms)) }

# ============================ Geometry =======================================
$SW = 50; $SH = 15; $TW = 66      # screen content w/h, full TV width
function Pad    { param([string]$s,[int]$w) if ($s.Length -ge $w) { $s.Substring(0,$w) } else { $s + (' ' * ($w-$s.Length)) } }
function Center { param([string]$s,[int]$w)
    if ($s.Length -ge $w) { return $s.Substring(0,$w) }
    $l=[int](($w-$s.Length)/2); (' '*$l)+$s+(' '*($w-$s.Length-$l)) }
function Cell   { param([string]$t,[string]$c) [pscustomobject]@{ Text=$t; Color=$c } }
function Blank  { Cell (' '*$SW) 'Green' }
function LB     { Cell ([string][char]0x2588 * $SW) 'DarkGray' }   # letterbox bar
function Fit    { param($rows)                            # force exactly SH rows of width SW
    $r = @($rows | ForEach-Object { Cell (Pad $_.Text $SW) $_.Color })
    while ($r.Count -lt $SH) { $r += Blank }
    if ($r.Count -gt $SH) { $r = $r[0..($SH-1)] }; ,$r }

# ============================ Word banks =====================================
$Hosts    = @('CHAD STERLING','BIFF MAXWELL','GUY LE GUY','ROD VANTAGE','BRICK HOLLOWAY','TREY GRANDE','LANCE FORTUNE')
$Players  = @('Brenda','Dave','Sharon','Keith','Pam','Geoff','Linda','Trevor','Maureen','Barry','Sandra','Nigel')
$Towns    = @('Slough','Droitwich','Scunthorpe','Basildon','Tring','Diss','Splott','Pity Me','Wetwang','Ugley')
$Jobs     = @('a quantity surveyor','a dental nurse','a retired ferret breeder','a part-time mime',
              'an enthusiastic amateur','a man who owns nine kettles','a competitive whistler','a regional sales rep')
# Safe answers -- things you are allowed to put in THE LEVEL.
$Safe     = @('A SPIRIT LEVEL','A BUBBLE','A SMALL CONFESSION','A SINGLE TEAR','LAST WEEK''S CHAMPION',
              'A DUCK','A REASONABLE AMOUNT OF JAM','THE STUDIO CAT','A WARM RECEIPT','ONE (1) GASP',
              'A LIGHTLY USED PRENUP','AN EVIL TWIN (DECLAWED)','A FORGOTTEN PASSWORD','A POLITE SILENCE')
$Prizes   = @('A CARAVAN','A SPEEDBOAT (NO WATER INCLUDED)','A LIFETIME OF JAM','A SECOND CARAVAN',
              'A CHEQUE FOR SOME MONEY','A SLIGHTLY LARGER CARAVAN','A HOLIDAY TO DROITWICH','A COMMEMORATIVE PLATE',
              'A NORMAL AMOUNT OF GEESE','THE DEEDS TO A RAVINE','A VOUCHER FOR THE VOID')
# Exactly the thing you must never do.
$Forbidden= @('THE LEVEL','THE LEVEL','THE LEVEL','THE LEVEL ITSELF','THIS VERY LEVEL','THE LEVEL (AGAIN)')
$RuleWords= @('UNDER NO CIRCUMSTANCES PUT THE LEVEL BACK IN THE LEVEL',
              'THE ONE RULE: NEVER PUT THE LEVEL BACK IN THE LEVEL',
              'DO NOT -- WE REPEAT -- PUT THE LEVEL BACK IN THE LEVEL',
              'PUT THE LEVEL BACK IN THE LEVEL AND YOU''RE FLOORED, FLOORED')
$HostLines= @('Welcome back to THE LEVEL!','You know the rules, {P}!','It''s ever so simple, {P}!',
              'For {PRIZE}, {P}... what goes in THE LEVEL?','No pressure, {P}, just don''t break THE RULE!',
              'Big money round, {P}! Keep it OUT of itself!','You''re doing brilliantly, {P}!',
              'Studio audience -- isn''t {P} marvellous?')
$SafePlay = @('{P} carefully places {ANS} in THE LEVEL.','{P} pops {ANS} in -- textbook!',
              '{P} lowers {ANS} into THE LEVEL. Clean!','Steady hands! {ANS} goes in. THE RULE holds.',
              '{P} banks {ANS}. The board is happy. For now.')
$Tempters = @('Double it, {P}! Just nest it ONE more time!','The prize TRIPLES if you put THE LEVEL in... you know where.',
              'Go on, {P}... everyone''s thinking it...','One little recursion never hurt anybody, {P}!',
              'For the SUPER JACKPOT, {P} -- put THE LEVEL... back in THE LEVEL?')
$Breaks   = @('{P} puts THE LEVEL back in THE LEVEL.','{P} does it. {P} puts THE LEVEL in THE LEVEL.',
              'And -- oh no -- {P} nests THE LEVEL inside ITSELF.','{P} couldn''t resist. THE LEVEL goes in THE LEVEL.')

# ============================ The LEVEL board (nested boxes) ==================
# A single box with " THE LEVEL " on the lid; nest it and the boxes plunge to a
# vanishing point. $depth = how many boxes deep we have folded.
function Get-LevelGrid { param([int]$depth)
    $rows = $SH - 4
    $grid = @(); for ($y=0;$y -lt $rows;$y++){ $grid += ,((' '*$SW).ToCharArray()) }
    $step = 3
    $maxd = [Math]::Max(1,[Math]::Min($depth, [Math]::Min([int]($rows/2),[int]($SW/(2*$step)))))
    for ($L=0; $L -lt $maxd; $L++){
        $left=$L*$step; $right=$SW-1-$L*$step; $top=$L; $bot=$rows-1-$L
        if (($right-$left) -lt 4 -or ($bot-$top) -lt 2){ $maxd=$L; break }
        for ($x=$left;$x -le $right;$x++){ $grid[$top][$x]='-'; $grid[$bot][$x]='-' }
        for ($y=$top;$y -le $bot;$y++){ $grid[$y][$left]='|'; $grid[$y][$right]='|' }
        $grid[$top][$left]='+'; $grid[$top][$right]='+'; $grid[$bot][$left]='+'; $grid[$bot][$right]='+'
        $lbl=' THE LEVEL '
        if (($right-$left-1) -ge $lbl.Length){
            $st=$left+[int](($right-$left-$lbl.Length)/2)
            for($k=0;$k -lt $lbl.Length;$k++){ $grid[$top][$st+$k]=$lbl[$k] } }
    }
    # at the vanishing point, the innermost cell
    $cy=[int]($rows/2); $cx=[int]($SW/2)
    $heart = if ($depth -gt $maxd) { Pick @('><','oo','::','▓▓','??') } else { '><' }
    if ($cx-1 -ge 0) { $grid[$cy][$cx-1]=$heart[0]; $grid[$cy][$cx]=$heart[1] }
    ,@($grid | ForEach-Object { -join $_ })
}

function Get-LevelShot { param([int]$depth,[string]$caption,[string]$capCol='Cyan')
    $art = Get-LevelGrid $depth
    $rows=@(LB)
    foreach ($ln in $art) { $rows += Cell (Center $ln $SW) 'Cyan' }
    $rows += Cell (Center ($caption.ToUpper()) $SW) $capCol
    $rows += (LB)
    Fit $rows
}

# ============================ Other shot builders ============================
function Wrap2 { param([string]$t,[int]$w)
    $words=$t -split ' '; $lines=@(); $cur=''
    foreach ($wd in $words) { if ($cur -eq ''){$cur=$wd} elseif (($cur.Length+1+$wd.Length)-le $w){$cur+=' '+$wd} else {$lines+=$cur;$cur=$wd} }
    if ($cur -ne ''){$lines+=$cur}; while ($lines.Count -lt 2){$lines+=''}
    @((Center $lines[0] $w),(Center $lines[1] $w)) }

# The host (left) and the contestant (right) at their podiums.
function Get-StageShot { param($round,[string]$caption,[string]$face='(^o^)',[bool]$stormy=$false)
    $rain = { $r=(' '*$SW).ToCharArray(); for($x=0;$x -lt $SW;$x++){ if($rng.Next(100)-lt 12){$r[$x]=(Pick @("'",'/',','))} }; -join $r }
    $hostFace=' \(o_o)/ '; $cont=" $face "
    $names=(' '*$SW).ToCharArray()
    $labels=@{ 13='HOST'; 36=$round.Player.ToUpper() }
    foreach ($c in $labels.Keys) {
        $nm=[string]$labels[$c]; $st=[Math]::Max(0,$c-[int]($nm.Length/2))
        for($k=0;$k -lt $nm.Length -and ($st+$k)-lt $SW;$k++){$names[$st+$k]=$nm[$k]} }
    $w=Wrap2 $caption $SW
    $rows=@(
        (LB),
        (Cell (Center ('<  T H E   L E V E L  >') $SW) 'Yellow'),
        (Cell ('~'*$SW) 'DarkYellow'),
        (Cell ($(if($stormy){& $rain}else{' '*$SW})) 'DarkCyan'),
        (Cell (Pad ('     '+$hostFace+'              '+$cont) $SW) 'Green'),
        (Cell (Pad ('      /|\                /|\ ') $SW) 'Green'),
        (Cell (Pad ('     _/_\_      vs      _/_\_') $SW) 'DarkGreen'),
        (Cell (Pad (-join $names) $SW) 'DarkGreen'),
        (Cell ('='*$SW) 'DarkGray'),
        (Cell $w[0] 'White'),
        (Cell $w[1] 'White'),
        (Blank),
        (Cell (' '+(Center "PLAYING FOR: $($round.Prize)" ($SW-2))+' ') 'Cyan'),
        (Blank),
        (LB) )
    Fit $rows }

function Get-CardShot { param([string]$l1,[string]$l2,[string]$color)
    $rows=@(LB)
    1..4 | ForEach-Object { $rows+=Blank }
    $rows+=Cell (Center ('='*34) $SW) 'DarkGray'
    $rows+=Cell (Center $l1 $SW) $color
    $rows+=Cell (Center $l2 $SW) 'DarkGray'
    $rows+=Cell (Center ('='*34) $SW) 'DarkGray'
    Fit $rows }

function Get-RuleShot { param([string]$rule,[bool]$on)
    $w=Wrap2 $rule $SW
    $rows=@(LB)
    1..3 | ForEach-Object { $rows+=Blank }
    $rows+=Cell (Center '* * *  THE ONE RULE  * * *' $SW) 'DarkRed'
    $rows+=Blank
    $col = if ($on) { 'Red' } else { 'DarkGray' }
    $rows+=Cell $w[0] $col
    $rows+=Cell $w[1] $col
    $rows+=Blank
    $rows+=Cell (Center ('(or you''re FLOORED, FLOORED)') $SW) 'DarkGray'
    $rows+=(LB)
    Fit $rows }

function Get-FlashShot { Fit (1..$SH | ForEach-Object { Cell ([string][char]0x2588 * $SW) 'White' }) }

function Get-StaticShot { param([string]$ch)
    $noise='#%&@*+=:;.,/\|<>~oO0'.ToCharArray(); $rows=@()
    for ($y=0;$y -lt $SH;$y++) {
        $sb=[System.Text.StringBuilder]::new(); for ($x=0;$x -lt $SW;$x++){[void]$sb.Append($noise[$rng.Next($noise.Count)])}
        $row=$sb.ToString(); if ($y -eq 7){ $row=Center (">>  CH $ch  <<") $SW }
        $rows+=Cell $row (Pick @('Gray','DarkGray','White')) }
    Fit $rows }

function Dim { param($cells,[int]$step)
    $map=@{0='White';1='Gray';2='DarkGray';3='Black'}
    @($cells | ForEach-Object { Cell $_.Text $map[$step] }) }

# ============================ The live studio audience =======================
$AUDN = 9
$script:Reaction   = 0.0
$script:SlamFrames = 0
$script:Floored    = 0
function React { param([double]$to,[string]$sting='') if ($to -gt $script:Reaction) { $script:Reaction=[Math]::Min(1.0,$to) }; if ($sting -and $script:Live) { Sting $sting } }
function Get-Mood {
    if ($script:SlamFrames -gt 3) { return 'slam' }
    if ($script:SlamFrames -gt 0) { return 'floor' }
    $r=$script:Reaction
    if ($r -ge 0.82) { 'feet' } elseif ($r -ge 0.60) { 'clap' }
    elseif ($r -ge 0.40) { 'gasp' } elseif ($r -ge 0.18) { 'murmur' } else { 'hush' } }
function Get-AudienceRow {
    $mood=Get-Mood
    $base=@{ hush='(o)'; murmur='(o)'; gasp='(O)'; clap='\o/'; feet='\O/'; floor=' x)'; slam='___' }[$mood]
    $seats=@()
    for ($i=0;$i -lt $AUDN;$i++) {
        $s=$base
        switch ($mood) {
            'murmur'{ if ($rng.Next(100)-lt 25){$s='(o,'} }
            'gasp'  { if ($rng.Next(100)-lt 30){$s='(@)'} }
            'clap'  { if ($rng.Next(100)-lt 40){$s=Pick @('\o/','/o\','\O/')} }
            'feet'  { if ($rng.Next(100)-lt 45){$s=Pick @('\O/','\o/','|O|')} }
            'floor' { $s=Pick @(' x)','(x ','\_ ',' _/','o_o','._.') }
            'slam'  { $s=Pick @('___','_x_',' . ','_ _',' ._') } }
        $seats+=$s }
    $col=@{ hush='DarkGray'; murmur='Gray'; gasp='White'; clap='Yellow'; feet='Yellow'; floor='Red'; slam='Red' }[$mood]
    Cell (Center (($seats -join '  ')) $TW) $col }
function Get-MeterRow {
    $mood=Get-Mood; $r=[Math]::Max(0.0,[Math]::Min(1.0,$script:Reaction))
    $w=14; $fill=[int][Math]::Round($r*$w)
    $bar=([string][char]0x2588*$fill)+([string][char]0x2591*($w-$fill))
    $desc=@{ hush='. . . hushed . . .'; murmur='a murmur ripples'; gasp='the room GASPS';
             clap='APPLAUSE!'; feet='ON ITS FEET!'; floor='*** F L O O R E D ***'; slam='** FLOORED, FLOORED **' }[$mood]
    $txt="APPL-O-METER [$bar] $desc"
    $col = if ($mood -in 'floor','slam') { 'Red' } elseif ($r -ge 0.7) { Pick @('Red','Yellow') }
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
    Row ('|'+(Pad ("   (CH $ch)        ( o )      ( o )        <  THE LEVEL 3000  >  ") ($TW-2))+'|') $body
    Row ('|'+(Pad ("    (O) PWR        VOL        TINT              [|||||||||]       ") ($TW-2))+'|') $body
    Row ("'"+('-'*($TW-2))+"'") $body
    Row (Center '||                                        ||' $TW) $body
    Row (Center '[==]                                    [==]' $TW) $body
    Row (Center 'L I V E   S T U D I O   A U D I E N C E' $TW) 'DarkGray'
    $out.Add((Get-AudienceRow))
    $out.Add((Get-MeterRow))
    ,$out }

# ============================ Sound ==========================================
function Beep { param([int]$f,[int]$ms2) if (-not $script:Silent) { try { [Console]::Beep($f,$ms2) } catch {} } }
function Sting { param([string]$n) switch ($n) {
    'fanfare'   { foreach ($f in 392,523,659,784) { Beep $f 110 } }
    'ding'      { Beep 988 90; Beep 1319 160 }                       # correct!
    'tempt'     { Beep 587 120; Beep 622 120; Beep 659 240 }         # ooooh
    'buzzer'    { Beep 196 300; Beep 165 400 }                       # WRONG
    'recursion' { foreach ($f in 880,740,622,523,440,370,311,262,196,131) { Beep $f 70 } }  # plunge inward
    'slam'      { Beep 150 60; Beep 95 200; Beep 60 320 }
    'ovation'   { 1..20 | ForEach-Object { Beep (RNext 220 920) 15 }; Beep 740 220 }
    'gasp'      { Beep 622 70; Beep 831 80; Beep 1047 150 }
    'thunder'   { 1..3 | ForEach-Object { Beep (RNext 55 95) 110 } }
    'dread'     { 1..5 | ForEach-Object { Beep (RNext 38 62) 90 }; Beep 41 900 } } }

# ============================ THE LEVEL looks back ===========================
$script:Dread = 0.0
function Format-ViewerName { param([string]$raw)
    if (-not $raw) { return '' }
    $n=($raw -split '[\\/@]')[-1]; $n=($n -replace '[^A-Za-z0-9 ]',' ' -replace '\s+',' ').Trim()
    if ($n) { $n.ToUpper() } else { '' } }
function Find-Viewer {
    try { Add-Type -AssemblyName System.DirectoryServices.AccountManagement -ErrorAction Stop
          $dn=Format-ViewerName ([System.DirectoryServices.AccountManagement.UserPrincipal]::Current.DisplayName)
          if ($dn) { return $dn } } catch {}
    try { $n=Format-ViewerName ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name); if ($n){return $n} } catch {}
    try { $n=Format-ViewerName ([Environment]::UserName); if ($n){return $n} } catch {}
    'VIEWER' }
$Viewer = Find-Viewer; if (-not $Viewer) { $Viewer='VIEWER' }

# ============================ Renderers ======================================
function Show-Raw { param($cells,[string]$ch,[bool]$static,[int]$indent=3)
    $tv=Build-Tv $cells $ch $static
    Clear-Host; Write-Host ''
    foreach ($l in $tv) { Write-Host ((' '*$indent)+$l.Text) -ForegroundColor $l.Color } }
function Show-Live { param($cells,[string]$ch,[bool]$static,[int]$indent=3)
    if ($script:SlamFrames -gt 0) { $script:SlamFrames--; $script:Reaction=1.0 }
    else { $script:Reaction=[Math]::Max(0.0,$script:Reaction*0.90-0.012) }
    Show-Raw $cells $ch $static $indent }
function Show-Plain { param($cells,[string]$ch,[bool]$static) (Build-Tv $cells $ch $static) | ForEach-Object { $_.Text } }
function Invoke-Flash { param([string]$ch) 1..2 | ForEach-Object { Show-Live (Get-FlashShot) $ch $false; Beep (RNext 60 90) 70; Hold 55 } }
function Invoke-Shake { param($cells,[string]$ch) foreach ($o in 6,1,5,0,4,2) { Show-Live $cells $ch $false $o; Hold 35 } }

# THE RECURSION -- THE LEVEL plunges into THE LEVEL into THE LEVEL...
function Invoke-Recursion { param([string]$ch,[int]$maxDepth)
    Sting recursion
    for ($d=1; $d -le $maxDepth; $d++) {
        $cap = if ($d -eq 1) { 'the level...' } elseif ($d -lt $maxDepth) { 'the level in the level'+('.'*($d%4)) } else { 'all the way down' }
        Show-Live (Get-LevelShot $d $cap 'Red') $ch $false
        Beep ([Math]::Max(60, 900-$d*90)) 50; Hold ([Math]::Max(40,120-$d*8))
        if (Test-Quit) { throw 'quit' } } }

# THE DOUBLE SLAM -- FLOORED, then FLOORED again.
function Invoke-DoubleSlam { param($cells,[string]$ch)
    foreach ($pass in 1,2) {
        $script:Reaction=1.0; $script:SlamFrames=7; $script:Floored++
        Sting slam; Invoke-Shake $cells $ch; Sting ovation
        $tag = if ($pass -eq 1) { 'F L O O R E D' } else { 'F L O O R E D ,   A G A I N' }
        Show-Live (Get-CardShot $tag '(THE LEVEL WAS IN THE LEVEL)' 'Red') $ch $false; Hold 700
        if (Test-Quit) { throw 'quit' } } }

# THE PAYOFF -- once it has been double-floored enough, THE LEVEL looks back.
function Invoke-Haunt { param([string]$ch)
    $black=@(1..$SH | ForEach-Object { Cell (' '*$SW) 'Black' })
    foreach ($s in 0..3) { Show-Raw (Dim (Get-CardShot ' ' ' ' 'White') $s) $ch $false; Hold 90 }
    Sting dread
    # the recursion keeps going where the screen can't
    foreach ($d in 1..6) {
        $rows=@($black); $rows[6]=Cell (Center ('the level'+(' in the level'*0)) $SW) 'DarkRed'
        $rows[7]=Cell (Center (('  '*$d)+'the level in the level') $SW) 'Red'
        Show-Raw $rows $ch $false; Beep ([Math]::Max(50,400-$d*50)) 60; Hold 120
        if (Test-Quit) { throw 'quit' } }
    $line=(Pick @('YOU PUT YOURSELF BACK IN THE LEVEL, {V}.','THE LEVEL WAS ALWAYS YOU, {V}.',
                  'WHO LET YOU INTO THE LEVEL, {V}?','YOU NEVER LEFT THE LEVEL, {V}.')).Replace('{V}',$Viewer)
    $shown=''
    foreach ($c in $line.ToCharArray()) {
        $shown+=$c; $rows=@($black); $rows[7]=Cell (Center $shown $SW) 'Red'
        Show-Raw $rows $ch $false; Beep (RNext 70 120) 30; Hold 60
        if (Test-Quit) { throw 'quit' } }
    Hold 900; Invoke-Flash $ch
    $rows=@($black); $rows[7]=Cell (Center '. . . the level looks away . . .' $SW) 'DarkGray'
    Show-Raw $rows $ch $false; Beep 60 500; Hold 1200
    $script:Dread=0.0; $script:Floored=0 }
function Maybe-Haunt { param([string]$ch) if (-not $script:Calm -and ($script:ForceHaunt -or $script:Floored -ge 3)) { Invoke-Haunt $ch; $script:ForceHaunt=$false; return $true }; return $false }

# ============================ Round builder ==================================
function New-Round {
    [pscustomobject]@{
        Host   = Pick $Hosts
        Player = Pick $Players
        Town   = Pick $Towns
        Job    = Pick $Jobs
        Prize  = Pick $Prizes
        Rule   = Pick $RuleWords
        Safe   = @($Safe | Sort-Object { $rng.Next() } | Select-Object -First (RNext 2 4))
    } }

# ============================ The director ===================================
function Invoke-Round { param($round)
    $cs='{0:00}' -f $script:ch
    # 1. THIS WEEK ON THE LEVEL
    React 0.35 fanfare
    Show-Live (Get-CardShot 'THIS WEEK ON . . .' 'T H E   L E V E L' 'Yellow') $cs $false; Hold 1000
    if (Test-Quit) { throw 'quit' }
    # meet the contestant
    Show-Live (Get-CardShot "Tonight: $($round.Player) from $($round.Town)" $round.Job 'White') $cs $false; Hold 900
    if (Test-Quit) { throw 'quit' }
    # 2. THE ONE RULE (flashing)
    foreach ($f in 1..6) { Show-Live (Get-RuleShot $round.Rule ($f % 2 -eq 0)) $cs $false; Beep 660 40; Hold 240 }
    if (Test-Quit) { throw 'quit' }
    # 3. safe rounds -- the crowd warms up
    $i=0
    foreach ($ans in $round.Safe) {
        $i++; $hl=(Pick $HostLines).Replace('{P}',$round.Player).Replace('{PRIZE}',$round.Prize)
        Show-Live (Get-StageShot $round $hl '(o_o)') $cs $false; Sting ding; Hold 700
        $play=(Pick $SafePlay).Replace('{P}',$round.Player).Replace('{ANS}',$ans)
        React ([Math]::Min(0.85, 0.45+$i*0.18)) ding
        Show-Live (Get-LevelShot 1 $play 'Green') $cs $false; Sting ding; Hold 800
        if (Test-Quit) { throw 'quit' } }
    if ($script:Calm) {
        # the cosy timeline: the rule is kept, everyone goes home happy
        React 0.95 ovation
        Show-Live (Get-StageShot $round "$($round.Player) keeps it OUT of itself -- and WINS!" '(^o^)') $cs $false; Sting fanfare; Hold 900
        Show-Live (Get-CardShot 'A WINNER!' "$($round.Player) takes home $($round.Prize)" 'Yellow') $cs $false; Hold 1100
        return
    }
    # 4. THE TEMPTATION
    $tempt=(Pick $Tempters).Replace('{P}',$round.Player)
    React 0.5 tempt
    Show-Live (Get-StageShot $round $tempt '(o_O)' $true) $cs $false; Sting tempt; Hold 1000
    # the hush
    $script:Reaction=0.06
    foreach ($h in 1..3) { Beep 80 90; Show-Live (Get-LevelShot 1 'don''t do it...' 'DarkYellow') $cs $false; Hold 260 }
    # 5. THEY DO IT
    $brk=(Pick $Breaks).Replace('{P}',$round.Player)
    Show-Live (Get-StageShot $round $brk '(O_O)' $true) $cs $false; Sting buzzer; Invoke-Flash $cs; Sting thunder; Hold 400
    if (Test-Quit) { throw 'quit' }
    # 6. RECURSION -> DOUBLE SLAM
    Invoke-Recursion $cs $Depth
    Invoke-DoubleSlam (Get-LevelShot $Depth 'all the way down' 'Red') $cs
    if (Maybe-Haunt $cs) { return }
    # 7. TO BE CONTINUED -> static -> next round
    React 0.9 ovation
    $card=Get-CardShot 'TO BE CONTINUED . . .' 'THE LEVEL will return' 'White'
    Show-Live $card $cs $false; Hold 600
    foreach ($s in 0..3) { Show-Live (Dim $card $s) $cs $false; Hold 230 }
    foreach ($s in 1..(RNext 5 8)) {
        $script:ch += RNext 1 4; if ($script:ch -gt 99) { $script:ch=RNext 2 10 }
        Show-Live (Get-StaticShot ('{0:00}' -f $script:ch)) ('{0:00}' -f $script:ch) $true
        Beep (RNext 200 600) 25; Hold 70; if (Test-Quit) { throw 'quit' } } }

# ============================ STORYBOARD =====================================
if ($Storyboard) {
    $ch=RNext 2 10
    for ($e=1; $e -le $Scenes; $e++) {
        $round=New-Round; $script:ch=$ch; $cs='{0:00}' -f $ch
        "##### ROUND $e : THE LEVEL -- $($round.Player) of $($round.Town) for $($round.Prize) #####"; ''
        $script:Reaction=0.35; $script:SlamFrames=0
        '  [ COLD OPEN -- THIS WEEK ON THE LEVEL ]'
        Show-Plain (Get-CardShot 'THIS WEEK ON . . .' 'T H E   L E V E L' 'Yellow') $cs $false; ''
        '  [ THE ONE RULE -- flashing red between every round ]'
        Show-Plain (Get-RuleShot $round.Rule $true) $cs $false; ''
        $script:Reaction=0.62
        '  [ A SAFE ROUND -- the crowd warms up; THE RULE holds ]'
        Show-Plain (Get-LevelShot 1 (($Safe[0])+' goes in. Clean!') 'Green') $cs $false; ''
        $script:Reaction=0.06
        '  [ THE TEMPTATION -- dead silence; do not do it... ]'
        Show-Plain (Get-StageShot $round (($Tempters[0]).Replace('{P}',$round.Player)) '(o_O)' $true) $cs $false; ''
        '  [ *** THEY PUT THE LEVEL BACK IN THE LEVEL *** ]'
        Show-Plain (Get-FlashShot) $cs $false; ''
        '  [ RECURSION -- THE LEVEL in THE LEVEL in THE LEVEL... ]'
        Show-Plain (Get-LevelShot $Depth 'all the way down' 'Red') $cs $false; ''
        $script:SlamFrames=7; $script:Reaction=1.0
        '  [ FLOORED, FLOORED -- the room is levelled, then levelled again ]'
        Show-Plain (Get-CardShot 'F L O O R E D ,   A G A I N' '(THE LEVEL WAS IN THE LEVEL)' 'Red') $cs $false; ''
        $script:SlamFrames=0
        if ($Calm) {
            $script:Reaction=0.95
            '  [ THE COSY TIMELINE -- nobody breaks the rule; a winner! ]'
            Show-Plain (Get-CardShot 'A WINNER!' "$($round.Player) takes home $($round.Prize)" 'Yellow') $cs $false; ''
        } else {
            '  [ *** AND THE LEVEL LOOKS BACK -- it was about you all along *** ]'
            $black=@(1..$SH | ForEach-Object { Cell (' '*$SW) 'Black' })
            $rows=@($black); $rows[7]=Cell (Center "YOU PUT YOURSELF BACK IN THE LEVEL, $Viewer." $SW) 'Red'
            Show-Plain $rows $cs $false; ''
        }
        if ($e -lt $Scenes) { $ch+=RNext 1 4; if ($ch -gt 99){$ch=RNext 2 10}
            $script:ch=$ch
            '  . : .  *kkrrshhh* changing channel  . : .'
            Show-Plain (Get-StaticShot ('{0:00}' -f $ch)) ('{0:00}' -f $ch) $true; '' }
    }
    return
}

# ============================ LIVE ===========================================
try { [void][Console]::WindowWidth } catch {
    Write-Warning 'Live mode needs a real console. Try: .\The-Level.ps1 -Storyboard'; return }
$prevCursor=[Console]::CursorVisible
try { [Console]::CursorVisible=$false } catch {}
$script:ch=RNext 2 10; $played=0; $script:Live=$true
$script:ForceHaunt=[bool]$Haunt
function Test-Quit { try { if ([Console]::KeyAvailable){[void][Console]::ReadKey($true);return $true} } catch {}; return $false }

try {
    while ($true) {
        Invoke-Round (New-Round)
        $played++; if ($Rounds -gt 0 -and $played -ge $Rounds) { break }
    }
}
catch { if ("$_" -notmatch 'quit') { throw } }
finally {
    [Console]::ResetColor(); try { [Console]::CursorVisible=$prevCursor } catch {}
    Write-Host ''; Write-Host '  *click*   ...and that''s THE LEVEL. Goodnight.' -ForegroundColor DarkGray
}
