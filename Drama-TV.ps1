<#
.SYNOPSIS
    A procedurally-generated ASCII television that channel-surfs through
    overwrought, cinematic prime-time dramas -- letterboxed shots, a scrolling
    BREAKING NEWS chyron, lightning + thunder, screen-shake, a dolly-zoom REVEAL
    with a musical sting, and TO BE CONTINUED cliffhangers.

.DESCRIPTION
    Each "channel" is directed as a tiny episode:
      PREVIOUSLY ON ...  ->  stormy dialogue (rain, chyron, thunder/flash/shake)
      ->  THE REVEAL (dolly-zoom onto a giant emoting face + "dun dun DUUUN")
      ->  TO BE CONTINUED ...  (fade to black)  ->  channel static  -> next show.

    Live mode redraws in place with sound + motion (needs a real console).
    -Storyboard prints a representative montage of frames to stdout instead.

.PARAMETER Channels   How many episodes before exiting. 0 (default) = forever.
.PARAMETER Silent     Disable the [Console]::Beep sound cues.
.PARAMETER Storyboard Print a static montage to stdout (no animation / sound).
.PARAMETER Scenes     Storyboard: how many episodes to lay out. Default 1.
.PARAMETER Seed       Fix the RNG for reproducible output. 0 = random.

.EXAMPLE
    .\Drama-TV.ps1
.EXAMPLE
    .\Drama-TV.ps1 -Channels 4
.EXAMPLE
    .\Drama-TV.ps1 -Storyboard -Scenes 1 -Seed 42
#>
[CmdletBinding()]
param(
    [int]$Channels = 0,
    [switch]$Silent,
    [switch]$Storyboard,
    [int]$Scenes   = 1,
    [int]$Seed     = 0
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
    soap=@('You kissed my {REL}?!','I am leaving you forever!','This wedding is OFF!')
    hospital=@('Stat! We are losing {O}!','The charts were switched!','The transplant was sabotaged!')
    court=@('Objection, Your Honor!','The real culprit is {O}!','I confess... it was me!')
    crime=@('Freeze! It is over, {O}!','The killer left one last clue...','You have the wrong suspect!') }
$Actions = @{
    any=@('* thunder crashes outside *','* {W} faints onto the floor *','* a single dramatic tear falls *',
          '* {W} slaps {O} across the face *','* the organ music swells *','* {W} storms out, sobbing *')
    hospital=@('* the heart monitor flatlines *','* {W} sprints down the corridor *')
    court=@('* the gallery gasps loudly *','* the gavel slams down *')
    crime=@('* tires screech offscreen *','* {W} draws a sealed envelope *') }
$Reveals = @('{O} is your long-lost {REL}!','{W} faked the entire death!','The baby was switched at birth!',
             '{O} has been alive the WHOLE time!','It was {W} behind the mask!','The will names {O} as sole heir!',
             '{W} and {O} were secretly married!','{O} pushed {W} off the balcony!')

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
$Big       = @{ horror=$FaceHorror; rage=$FaceRage; tears=$FaceTears }
$SmallFace = @{ horror='(O_O)';     rage='(>_<)';   tears='(T_T)' }

# ============================ Procedural show ================================
function New-Show {
    $genre = Pick @('soap','soap','soap','hospital','court','crime')
    $place = Pick $Places; $adj1 = Pick $Adjs; $adj2 = Pick ($Adjs | Where-Object { $_ -ne $adj1 })
    $a = Pick $Names; $b = Pick ($Names | Where-Object { $_ -ne $a }); $rel = Pick $Rels
    $title = switch ($genre) {
        'soap'     { Pick @("The $adj1 and the $adj2","$place Hearts","Passions of $place","Days of $place","$place After Dark") }
        'hospital' { Pick @("General $place","$place Memorial","Code: $adj1") }
        'court'    { Pick @("$place Court","Order in $place","The $adj1 Verdict") }
        'crime'    { Pick @("$place P.D.","$place Homicide","$adj1 Streets") } }
    $beats = @()
    foreach ($i in 1..(RNext 2 4)) {
        $kind = Pick @('line','line','action'); $sp = Pick @($a,$b); $ot = if ($sp -eq $a) { $b } else { $a }
        $pool = if ($kind -eq 'line') { $Dialogue.any + $(if ($Dialogue.ContainsKey($genre)){$Dialogue[$genre]}else{@()}) }
                else                  { $Actions.any  + $(if ($Actions.ContainsKey($genre)) {$Actions[$genre]} else{@()}) }
        $txt = (Pick $pool).Replace('{W}',$sp).Replace('{O}',$ot).Replace('{REL}',$rel)
        $beats += [pscustomobject]@{ Kind=$kind; Speaker=$sp; Text=$txt; Emo1=(Pick $Emotions); Emo2=(Pick $Emotions) } }
    $reveal = (Pick $Reveals).Replace('{W}',$a).Replace('{O}',$b).Replace('{REL}',$rel)
    $chyron = ("BREAKING: $a SEEN FLEEING $place MANSION   ***   $b VOWS REVENGE   ***   IS THE $rel REALLY DEAD?   ***   ").ToUpper()
    [pscustomobject]@{ Title=$title; Genre=$genre; Cast=@($a,$b); Beats=$beats
                       Reveal=$reveal; RevealExpr=(Pick @('horror','horror','rage','tears')); Chyron=$chyron }
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
    Row ('|'+(Pad ("   (CH $ch)        ( o )      ( o )        <  DRAMATRON 3000  >  ") ($TW-2))+'|') $body
    Row ('|'+(Pad ("    (O) PWR        VOL        TINT              [|||||||||]       ") ($TW-2))+'|') $body
    Row ("'"+('-'*($TW-2))+"'") $body
    Row (Center '||                                        ||' $TW) $body
    Row (Center '[==]                                    [==]' $TW) $body
    ,$out }

# ============================ Sound + live renderers =========================
function Beep { param([int]$f,[int]$ms) if (-not $script:Silent) { try { [Console]::Beep($f,$ms) } catch {} } }
function Sting { param([string]$n) switch ($n) {
    'reveal'     { Beep 466 150; Beep 466 150; Beep 392 550 }                 # dun dun DUUUN
    'thunder'    { 1..3 | ForEach-Object { Beep (RNext 55 95) 110 } }
    'heartbeat'  { Beep 80 90; Beep 70 90 }
    'cliffhanger'{ Beep 392 220; Beep 330 220; Beep 247 650 }
    'organ'      { Beep 262 120; Beep 330 120; Beep 392 220 } } }

function Show-Live { param($cells,[string]$ch,[bool]$static,[int]$indent=3)
    $tv = Build-Tv $cells $ch $static
    Clear-Host; Write-Host ''
    foreach ($l in $tv) { Write-Host ((' '*$indent)+$l.Text) -ForegroundColor $l.Color } }
function Show-Plain { param($cells,[string]$ch,[bool]$static)
    (Build-Tv $cells $ch $static) | ForEach-Object { $_.Text } }

function Invoke-Flash { param([string]$ch) 1..2 | ForEach-Object { Show-Live (Get-FlashShot) $ch $false; Beep (RNext 60 90) 70; Start-Sleep -Milliseconds 55 } }
function Invoke-Shake { param($cells,[string]$ch) foreach ($o in 6,1,5,0,4,2) { Show-Live $cells $ch $false $o; Start-Sleep -Milliseconds 35 } }

# ============================ The director ===================================
function Invoke-Episode { param($show)
    # 1. PREVIOUSLY ON
    Show-Live (Get-CardShot 'PREVIOUSLY,  ON . . .' $show.Title.ToUpper() 'White') ('{0:00}' -f $script:ch) $false
    Sting organ; Start-Sleep -Milliseconds 1100; if (Test-Quit) { throw 'quit' }
    # 2. Establishing dialogue (with a storm hitting mid-scene)
    $n = [Math]::Min($show.Beats.Count, 2)
    for ($i=0; $i -lt $n; $i++) {
        $beat=$show.Beats[$i]; $stormy = ($rng.Next(100) -lt 60)
        $chy=0
        foreach ($f in 1..10) {
            Show-Live (Get-DialogueShot $show $beat $stormy $chy) ('{0:00}' -f $script:ch) $false
            $chy += 2
            if ($stormy -and $f -eq 5) { Invoke-Flash ('{0:00}' -f $script:ch); Sting thunder; Invoke-Shake (Get-DialogueShot $show $beat $stormy $chy) ('{0:00}' -f $script:ch) }
            Start-Sleep -Milliseconds 130; if (Test-Quit) { throw 'quit' }
        }
    }
    # 3. THE REVEAL  -- heartbeat builds, dolly-zoom snaps onto the face, sting + flash + shake
    foreach ($h in 1..3) { Sting heartbeat; Start-Sleep -Milliseconds 260 }
    Show-Live (Get-ZoomShot $show 'small' 'the truth is...') ('{0:00}' -f $script:ch) $false; Beep 330 120; Start-Sleep -Milliseconds 360
    Show-Live (Get-ZoomShot $show 'big'   $show.Reveal)      ('{0:00}' -f $script:ch) $false
    Invoke-Flash ('{0:00}' -f $script:ch); Sting reveal
    Invoke-Shake (Get-ZoomShot $show 'big' $show.Reveal) ('{0:00}' -f $script:ch)
    Show-Live (Get-ZoomShot $show 'big' $show.Reveal) ('{0:00}' -f $script:ch) $false; Start-Sleep -Milliseconds 800
    if (Test-Quit) { throw 'quit' }
    # 4. TO BE CONTINUED -> fade to black
    $card = Get-CardShot 'TO BE CONTINUED . . .' ("next week on $($show.Title)") 'White'
    Show-Live $card ('{0:00}' -f $script:ch) $false; Sting cliffhanger; Start-Sleep -Milliseconds 600
    foreach ($s in 0..3) { Show-Live (Dim $card $s) ('{0:00}' -f $script:ch) $false; Start-Sleep -Milliseconds 230 }
    # 5. Channel static -> next show
    foreach ($s in 1..(RNext 5 8)) {
        $script:ch += RNext 1 4; if ($script:ch -gt 99) { $script:ch = RNext 2 10 }
        Show-Live (Get-StaticShot ('{0:00}' -f $script:ch)) ('{0:00}' -f $script:ch) $true
        Beep (RNext 200 600) 25; Start-Sleep -Milliseconds 70; if (Test-Quit) { throw 'quit' }
    } }

# ============================ STORYBOARD =====================================
if ($Storyboard) {
    $ch = RNext 2 10
    for ($e=1; $e -le $Scenes; $e++) {
        $show = New-Show; $cs='{0:00}' -f $ch
        "##### EPISODE $e : $($show.Title) #####"; ''
        '  [ COLD OPEN -- PREVIOUSLY ON ]'
        Show-Plain (Get-CardShot 'PREVIOUSLY,  ON . . .' $show.Title.ToUpper() 'White') $cs $false; ''
        '  [ ACT ONE -- storm rolls in: rain, BREAKING NEWS chyron, dialogue ]'
        Show-Plain (Get-DialogueShot $show $show.Beats[0] $true 0) $cs $false; ''
        '  [ *** LIGHTNING + THUNDER + SCREEN SHAKE *** ]'
        Show-Plain (Get-FlashShot) $cs $false; ''
        '  [ THE REVEAL -- dolly-zoom + "dun dun DUUUN" ]'
        Show-Plain (Get-ZoomShot $show 'big' $show.Reveal) $cs $false; ''
        '  [ CLIFFHANGER -- fade to black ]'
        Show-Plain (Get-CardShot 'TO BE CONTINUED . . .' ("next week on $($show.Title)") 'White') $cs $false; ''
        if ($e -lt $Scenes) { $ch += RNext 1 4; if ($ch -gt 99){$ch=RNext 2 10}
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
$script:ch = RNext 2 10; $surfed = 0
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
