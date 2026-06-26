<#
.SYNOPSIS
    DRAMA DUCK -- a one-duck melodrama staged in your terminal. The velvet
    curtains part, a spotlight finds a single, deeply theatrical duck, and it
    delivers an overwrought soliloquy (with REAL animated tears), drops a
    scandalous CONFESSION on a flash of lightning + screen-shake + a musical
    sting, SWOONS onto the fainting couch... and is rewarded with a
    rose-throwing standing ovation -- THE POND IS ON ITS FEET -- and a
    tearful curtain-call bow.

.DESCRIPTION
    Each "act" is directed as a tiny tragedy:
      CURTAIN RISES  ->  TONIGHT'S TRAGEDY title card  ->  weeping soliloquy
      (the duck emotes; single tears trickle down the bill; a PLAYBILL marquee
      scrolls)  ->  THE CONFESSION (dolly-flash onto a gasping duck + "dun dun
      DUUUN")  ->  THE SWOON (collapse onto the chaise)  ->  STANDING OVATION
      (BRAVO!, falling roses, thunderous applause)  ->  CURTAIN CALL bow  ->
      curtain falls  ->  next show.

    THE POND IS THE HOUSE.  A live audience of waterfowl sits below the stage
    with a POND-O-METER that ripples in real time: it murmurs and quacks through
    the soliloquy, hushes to still water in the breath before the confession,
    and at the ovation the whole pond rises, as one, to its feet.

    Live mode redraws the whole stage in place with sound + motion (needs a
    real console). -Storyboard prints a representative montage to stdout
    instead -- no animation, no sound -- handy for a quick look or headless test.

.PARAMETER Acts        How many tragedies before the theatre goes dark. 0 (default) = forever.
.PARAMETER Silent      Disable the [Console]::Beep stings (for a silent matinee).
.PARAMETER Storyboard  Print a static montage to stdout (no animation / sound).
.PARAMETER Scenes      Storyboard: how many acts to lay out. Default 1.
.PARAMETER Seed        Fix the RNG for reproducible output. 0 = random.

.EXAMPLE
    .\Drama-Duck.ps1
.EXAMPLE
    .\Drama-Duck.ps1 -Acts 3
.EXAMPLE
    .\Drama-Duck.ps1 -Storyboard -Scenes 1 -Seed 42
#>
[CmdletBinding()]
param(
    [int]$Acts   = 0,
    [switch]$Silent,
    [switch]$Storyboard,
    [int]$Scenes = 1,
    [int]$Seed   = 0
)

# ============================ RNG ============================================
$seedVal = if ($Seed -gt 0) { $Seed } else { [Environment]::TickCount }
$rng = [Random]::new($seedVal)
function Pick  { param($a) $a[$rng.Next($a.Count)] }
function RNext { param([int]$lo,[int]$hi) $rng.Next($lo,$hi) }
$script:Silent = [bool]$Silent

# ============================ Geometry =======================================
$SW = 46; $SH = 16                 # stage content width / height
function Pad    { param([string]$s,[int]$w) if ($s.Length -ge $w) { $s.Substring(0,$w) } else { $s + (' ' * ($w-$s.Length)) } }
function Center { param([string]$s,[int]$w)
    if ($s.Length -ge $w) { return $s.Substring(0,$w) }
    $l=[int](($w-$s.Length)/2); (' '*$l)+$s+(' '*($w-$s.Length-$l)) }
function Cell   { param([string]$t,[string]$c) [pscustomobject]@{ Text=$t; Color=$c } }
function Blank  { Cell (' '*$SW) 'DarkGray' }
function Fit    { param($rows)                      # force exactly SH rows of width SW
    $r = @($rows | ForEach-Object { Cell (Pad $_.Text $SW) $_.Color })
    while ($r.Count -lt $SH) { $r += Blank }
    if ($r.Count -gt $SH) { $r = $r[0..($SH-1)] }; ,$r }
function PutChar { param($rows,[int]$r,[int]$c,[string]$ch)     # overlay one char onto a row
    if ($r -ge 0 -and $r -lt $rows.Count) { $t=$rows[$r].Text
        if ($c -ge 0 -and $c -lt $t.Length) { $a=$t.ToCharArray(); $a[$c]=$ch[0]; $rows[$r].Text = -join $a } } }
function Wrap2 { param([string]$t,[int]$w)
    $words=$t -split ' '; $lines=@(); $cur=''
    foreach ($wd in $words) { if ($cur -eq ''){$cur=$wd} elseif (($cur.Length+1+$wd.Length)-le $w){$cur+=' '+$wd} else {$lines+=$cur;$cur=$wd} }
    if ($cur -ne ''){$lines+=$cur}; while ($lines.Count -lt 2){$lines+=''}
    @((Center $lines[0] $w),(Center $lines[1] $w)) }
function ChyronWindow { param([string]$s,[int]$off,[int]$w)
    while ($s.Length -lt ($w*2)) { $s += $s }; ($s+$s).Substring($off % $s.Length, $w) }

$Marquee = '   * * *   T O N I G H T   O N L Y   * * *   D R A M A   D U C K   * * *   A   O N E - D U C K   T R A G E D Y   * * *   '

# ============================ The duck =======================================
# Every art line is exactly 13 wide so the block stays aligned when centered.
$DuckTemplate = @(
    '  .-"""""-.  ',
    ' /         \ ',
    '/   {EY}   \',
    '|   {B1}   |',
    '|   {B2}   |',
    ' \         / ',
    '  \       /  ',
    " '._     _.' ",
    '  _/     \_  ',
    '(___)   (___)'
)
$Faces = @{
    weep    = @{ EY='o   o'; Open=$false; Tear=$true  }
    gasp    = @{ EY='O   O'; Open=$true;  Tear=$false }
    swoon   = @{ EY='x   x'; Open=$true;  Tear=$false }
    defiant = @{ EY='>   <'; Open=$false; Tear=$false }
    love    = @{ EY='@   @'; Open=$false; Tear=$false }
    triumph = @{ EY='^   ^'; Open=$true;  Tear=$false }
    sing    = @{ EY='o   o'; Open=$true;  Tear=$false }
}
function Get-Duck { param([string]$emo)
    $f = $Faces[$emo]; if (-not $f) { $f = $Faces['weep'] }
    $b1 = ',---.'
    $b2 = if ($f.Open) { "'-O-'" } else { "'---'" }
    $DuckTemplate | ForEach-Object {
        $_.Replace('{EY}',$f.EY).Replace('{B1}',$b1).Replace('{B2}',$b2) }
}

# ============================ Word banks =====================================
$Names = @('Sir Quacksworth','Lady Mallardine','Count Drakeula','Dame Featherton',
           'Baron von Bill','Duchess Webbington','Reginald Wingate','Lady Pondeletia',
           'Madame Beaktrice','The Duke of Dabbling')
$Titles = @('THE TRAGEDY OF {N}','{N}: A POND DIVIDED','TO QUACK OR NOT TO QUACK',
            'THE LAST MIGRATION OF {N}','A CRUMB BETRAYED','{N} WEEPS AT DAWN',
            'THE UGLY TRUTH','RIPPLES OF THE HEART')
$Openers = @("To quack... or not to quack. THAT is the question.",
             "O, cruel and rippling pond, why do you mock me so?",
             "Hark! What crumb through yonder water breaks?",
             "Friends! Mallards! Waterfowl! Lend me your bills!",
             "Is this a breadcrumb I see before me?",
             "Once more unto the reeds, dear friends, once more!")
$Lines = @("They called me a mere... DUCKLING.",
           "I gave this pond my FINEST molt!",
           "The flock migrated south... without ME.",
           "My reflection is a STRANGER to me now.",
           "Not one crumb. Not ONE, in all these years!",
           "The swans never let me forget my webbed feet.",
           "I have paddled in CIRCLES my entire life!",
           "You promised me the whole loaf, {O}!")
$Dirs  = @("* clutches the breast feathers *",
           "* a single tear rolls down the bill *",
           "* waddles dramatically, stage left *",
           "* gazes into the cruel, cruel pond *",
           "* the spotlight trembles with emotion *",
           "* flings a wing across the fevered brow *",
           "* a lone feather drifts to the boards *")
$Confessions = @("It was I... who ate the LAST breadcrumb.",
                 "The Ugly Duckling... was ME all along.",
                 "I... never... learned... to FLY.",
                 "The swan you mourned is standing before you.",
                 "I quacked. And no one... came.",
                 "Your true father... is a GOOSE.")

function New-Act {
    $name = Pick $Names
    $other= Pick ($Names | Where-Object { $_ -ne $name })
    $title= (Pick $Titles).Replace('{N}', $name.ToUpper())
    $beats= @()
    foreach ($i in 1..(RNext 2 4)) {
        if ((RNext 0 100) -lt 60) {
            $emo = Pick @('weep','defiant','gasp','sing')
            $txt = (Pick $Lines).Replace('{O}', $other)
            $beats += [pscustomobject]@{ Kind='line'; Text=$txt; Emo=$emo }
        } else {
            $emo = Pick @('weep','swoon','love')
            $beats += [pscustomobject]@{ Kind='dir'; Text=(Pick $Dirs); Emo=$emo }
        }
    }
    [pscustomobject]@{
        Title  = $title
        Name   = $name
        Opener = Pick $Openers
        Beats  = $beats
        Confession = Pick $Confessions
    }
}

# ============================ Shot builders ==================================
function Get-StageShot { param($act,[string]$emo,[string]$cap,[string]$capKind,[int]$marq,[int]$tearRow=-1)
    $duck = Get-Duck $emo
    $lp = [int](($SW-13)/2)
    $rows = New-Object 'System.Collections.Generic.List[object]'
    $rows.Add((Cell (Center ('~ ' + $act.Title + ' ~') $SW) 'Cyan'))
    $rows.Add((Blank))
    for ($i=0; $i -lt $duck.Count; $i++) {
        $col = if ($i -eq 3 -or $i -eq 4) { 'DarkYellow' } elseif ($i -eq 2) { 'White' } else { 'Yellow' }
        $rows.Add((Cell (Pad ((' '*$lp)+$duck[$i]) $SW) $col))
    }
    $rows.Add((Blank))
    $cap2 = if ($capKind -eq 'line') { '"' + $cap + '"' } else { $cap }
    $w = Wrap2 $cap2 $SW
    $cc = if ($capKind -eq 'line') { 'White' } else { 'Yellow' }
    $rows.Add((Cell $w[0] $cc)); $rows.Add((Cell $w[1] $cc))
    $rows.Add((Cell (' '+(ChyronWindow $Marquee $marq ($SW-2))+' ') 'Magenta'))
    if (($emo -eq 'weep') -and ($tearRow -ge 0)) {
        foreach ($ec in ($lp+3),($lp+9)) { PutChar $rows (5 + $tearRow) $ec "'" }   # tears trickle down the bill
    }
    Fit $rows
}

function Get-FaintShot { param($act,[int]$marq)
    $duck = Get-Duck 'swoon'
    $lp = [int](($SW-13)/2)
    $rows = New-Object 'System.Collections.Generic.List[object]'
    $rows.Add((Cell (Center ('~ ' + $act.Title + ' ~') $SW) 'Cyan'))
    $rows.Add((Blank))
    for ($i=0; $i -lt 7; $i++) {
        $col = if ($i -eq 3 -or $i -eq 4) { 'DarkYellow' } elseif ($i -eq 2) { 'White' } else { 'Yellow' }
        $rows.Add((Cell (Pad ((' '*$lp)+$duck[$i]) $SW) $col))
    }
    $rows.Add((Cell (Center '.-""""""""""""""""""""-.' $SW) 'DarkMagenta'))   # the fainting couch
    $rows.Add((Cell (Center '/  the fainting couch   \' $SW) 'DarkMagenta'))
    $rows.Add((Cell (Center '"""""""""""""""""""""""""' $SW) 'DarkMagenta'))
    $rows.Add((Blank))
    $rows.Add((Cell (Center '* T H E   S W O O N *' $SW) 'Red'))
    $rows.Add((Blank))
    $rows.Add((Cell (' '+(ChyronWindow $Marquee $marq ($SW-2))+' ') 'Magenta'))
    Fit $rows
}

function Get-CardShot { param([string]$l1,[string]$l2,[string]$color)
    $rows=@(Blank)
    1..4 | ForEach-Object { $rows+=Blank }
    $rows+=Cell (Center ('='*34) $SW) 'DarkGray'
    $rows+=Cell (Center $l1 $SW) $color
    $rows+=Cell (Center $l2 $SW) 'DarkGray'
    $rows+=Cell (Center ('='*34) $SW) 'DarkGray'
    Fit $rows
}

function Get-CurtainShot { param([double]$open)
    $blk=[string][char]0x2588
    $cw=[int]([Math]::Round(($SW/2)*(1.0-$open)))
    $rows=@()
    for ($y=0; $y -lt $SH; $y++) {
        if ($y -eq 0) { $rows += Cell ('v'*$SW) 'DarkYellow'; continue }     # gold valance
        $mid=[Math]::Max(0,$SW-2*$cw)
        $rows += Cell (Pad (($blk*$cw)+(' '*$mid)+($blk*$cw)) $SW) 'Red'
    }
    Fit $rows
}

function Get-FlashShot { Fit (1..$SH | ForEach-Object { Cell ([string][char]0x2588 * $SW) 'White' }) }

function Get-OvationShot {
    $petal = { $r=(' '*$SW).ToCharArray(); 1..10 | ForEach-Object { $r[$rng.Next($SW)]=(Pick @('@','*','.',',','o'))[0] }; -join $r }
    $rows=@(
        (Cell (& $petal) 'Red'),
        (Cell (Center '*  *   B R A V O ! ! !   *  *' $SW) 'Yellow'),
        (Cell (& $petal) 'Red'),
        (Cell (Center '\o/    \o/    \o/    \o/' $SW) 'White'),
        (Cell (Center ' |      |      |      | ' $SW) 'White'),
        (Cell (Center '/ \    / \    / \    / \' $SW) 'White'),
        (Cell (& $petal) 'Red'),
        (Blank),
        (Cell (Center 'the pond is on its feet!' $SW) 'Magenta'),
        (Cell (& $petal) 'Red')
    )
    Fit $rows
}

# ============================ Stage chrome ===================================
function Build-Stage { param($cells)
    $out = New-Object 'System.Collections.Generic.List[object]'
    function Row { param($t,$c) $out.Add((Cell $t $c)) }
    $w = $SW + 6
    Row (Center ('  '+('_'*$SW)+'  ') $w) 'DarkRed'
    Row (Center '* * *   D R A M A   D U C K   * * *' $w) 'Magenta'
    Row ('.'+('='*($w-2))+'.') 'DarkRed'
    foreach ($c in $cells) { Row ('| '+(Pad $c.Text ($w-4))+' |') $c.Color }
    Row ("'"+('='*($w-2))+"'") 'DarkRed'
    Row (Center '. : * . : * . : * . : * . : * . : *' $w) 'Yellow'
    Row (Center '\____________ STAGE ____________/' $w) 'DarkGray'
    foreach ($pr in (Get-PondRows)) { $out.Add($pr) }   # the live pond, seated below the stage
    ,$out
}

function Show-Live  { param($cells,[int]$indent=4)
    if ($script:FeetFrames -gt 0) { $script:FeetFrames--; $script:Pond = 1.0 }   # held on its feet
    else { $script:Pond = [Math]::Max(0.0, $script:Pond*0.90 - 0.012) }           # the pond settles
    $st = Build-Stage $cells
    Clear-Host; Write-Host ''
    foreach ($l in $st) { Write-Host ((' '*$indent)+$l.Text) -ForegroundColor $l.Color } }
function Show-Plain { param($cells) (Build-Stage $cells) | ForEach-Object { $_.Text } }

# ============================ The pond (live audience) =======================
# The pond is not just scenery -- it is the house. $Pond (0..1) is the energy
# in the water: bumped by each beat via React, decaying every frame so it
# SWINGS -- murmuring through the soliloquy, hushing to still water before the
# confession, and at the ovation the whole pond stands ($FeetFrames holds it
# up). Rendered as four rows below the stage by Build-Stage.
$PondN = 8
$script:Pond       = 0.0
$script:FeetFrames = 0
$script:Live       = $false
function React { param([double]$to,[string]$sting='')          # stir the pond
    if ($to -gt $script:Pond) { $script:Pond = [Math]::Min(1.0,$to) }
    if ($sting -and $script:Live) { Sting $sting } }
function Get-PondMood {
    if ($script:FeetFrames -gt 0) { return 'feet' }
    $r=$script:Pond
    if ($r -ge 0.80) { 'applause' } elseif ($r -ge 0.58) { 'quack' }
    elseif ($r -ge 0.36) { 'murmur' } elseif ($r -ge 0.15) { 'ripple' } else { 'still' } }
function Get-PondRows {
    $w = $SW + 6
    $mood = Get-PondMood
    $base = @{ still='<o)'; ripple='<o)'; murmur='<O)'; quack='<Q)'; applause='\o/'; feet='\O/' }[$mood]
    $seats=@()
    for ($i=0; $i -lt $PondN; $i++) {
        $s=$base
        switch ($mood) {
            'ripple'   { if ($rng.Next(100) -lt 30) { $s='<O)' } }
            'murmur'   { if ($rng.Next(100) -lt 30) { $s=Pick @('<o)','<O)') } }
            'quack'    { if ($rng.Next(100) -lt 45) { $s=Pick @('<O)','<o)','<Q)') } }
            'applause' { if ($rng.Next(100) -lt 45) { $s=Pick @('\o/','\O/','/o\') } }
            'feet'     { if ($rng.Next(100) -lt 50) { $s=Pick @('\O/','\o/','\Q/') } }
        }
        $seats += $s }
    $col = @{ still='DarkCyan'; ripple='DarkCyan'; murmur='Cyan'; quack='White'; applause='Yellow'; feet='Magenta' }[$mood]
    # the water they sit on -- a flat surface that churns up as the pond rises
    $wet = ('~'*$w).ToCharArray()
    $splash = [int]($script:Pond * $w * 0.5)
    for ($k=0; $k -lt $splash; $k++) { $wet[$rng.Next($w)] = (Pick @('^','^','v',':','.'))[0] }
    # the POND-O-METER  (kept inside the pond's 52-col width so it never clips)
    $bw=10; $fill=[int][Math]::Round($script:Pond*$bw)
    $bar='['+('|'*$fill)+(' '*($bw-$fill))+']'
    $desc=@{ still='still water'; ripple='a ripple of polite quacks'; murmur='the pond MURMURS';
             quack='the pond is QUACKING'; applause='the pond APPLAUDS'; feet='THE POND IS ON ITS FEET!' }[$mood]
    $mcol = if ($mood -eq 'feet') { 'Magenta' } elseif ($script:Pond -ge 0.58) { 'Yellow' }
            elseif ($script:Pond -ge 0.15) { 'White' } else { 'DarkCyan' }
    @(
      (Cell (Center 'o  o  o   T H E   P O N D   o  o  o' $w) 'DarkCyan'),
      (Cell (Center (($seats -join '  ')) $w) $col),
      (Cell (-join $wet) 'DarkBlue'),
      (Cell (Center ("POND-O-METER $bar $desc") $w) $mcol)
    ) }

# ============================ Sound ==========================================
function Beep  { param([int]$f,[int]$ms) if (-not $script:Silent) { try { [Console]::Beep($f,$ms) } catch {} } }
function Sting { param([string]$n) switch ($n) {
    'curtain'  { Beep 330 160; Beep 392 160; Beep 494 360 }                   # the rise
    'sob'      { Beep 392 150; Beep 330 150; Beep 262 480 }                   # weeping
    'gasp'     { Beep 784 80; Beep 988 160 }
    'confess'  { Beep 466 150; Beep 466 150; Beep 392 600 }                   # dun dun DUUUN
    'thud'     { Beep 110 220; Beep 90 260 }                                   # the swoon
    'applause' { 1..14 | ForEach-Object { Beep (RNext 200 700) 22 } }
    'bow'      { Beep 523 130; Beep 659 130; Beep 784 360 }
    'quack'    { 1..3 | ForEach-Object { Beep (RNext 280 360) 90; Beep (RNext 150 210) 70 } }   # the pond gasps
    'ovation'  { 1..20 | ForEach-Object { Beep (RNext 220 900) 16 }; Beep 740 240 } } }          # the house erupts

# ============================ Live motion helpers ============================
function Invoke-Flash { 1..2 | ForEach-Object { Show-Live (Get-FlashShot); Beep (RNext 60 90) 70; Start-Sleep -Milliseconds 55 } }
function Invoke-Shake { param($cells) foreach ($o in 7,2,6,1,5,3) { Show-Live $cells $o; Start-Sleep -Milliseconds 35 } }

# ============================ The director ===================================
function Invoke-Act { param($act)
    # 1. The curtain rises
    foreach ($p in 0.0,0.18,0.38,0.6,0.82,1.0) {
        Show-Live (Get-CurtainShot $p); Start-Sleep -Milliseconds 140; if (Test-Quit) { throw 'quit' } }
    Sting curtain; React 0.22; Start-Sleep -Milliseconds 250
    # 2. Tonight's tragedy (title card)
    React 0.15
    Show-Live (Get-CardShot "TONIGHT'S TRAGEDY" $act.Title 'White'); Start-Sleep -Milliseconds 1200; if (Test-Quit) { throw 'quit' }
    # 3. The opening line + the weeping soliloquy
    $marq = 0
    $allBeats = @([pscustomobject]@{ Kind='line'; Text=$act.Opener; Emo='defiant' }) + $act.Beats
    foreach ($beat in $allBeats) {
        $tear = 0
        foreach ($f in 1..9) {
            $tr = if ($beat.Emo -eq 'weep') { ($tear % 3) } else { -1 }
            Show-Live (Get-StageShot $act $beat.Emo $beat.Text $beat.Kind $marq $tr)
            $marq += 2; $tear++
            if ($f -eq 1) {                                    # the pond reacts to each beat
                switch ($beat.Emo) {
                    'weep'    { Sting sob;  React 0.42 }
                    'gasp'    { Sting gasp; React 0.62 quack }
                    'defiant' { React 0.52 }
                    default   { React 0.40 }
                } }
            Start-Sleep -Milliseconds 150; if (Test-Quit) { throw 'quit' }
        }
    }
    # 4. THE CONFESSION -- the pond hushes to still water, then GASPS
    foreach ($h in 1..3) { Beep 70 90; Start-Sleep -Milliseconds 240 }
    $script:Pond = 0.05                                       # you could hear a lily pad drop
    Show-Live (Get-StageShot $act 'gasp' 'and now... the truth.' 'dir' $marq); Start-Sleep -Milliseconds 500
    $confShot = Get-StageShot $act 'gasp' $act.Confession 'line' $marq
    Show-Live $confShot; Invoke-Flash; Sting confess; React 0.78; Invoke-Shake $confShot
    Show-Live $confShot; Start-Sleep -Milliseconds 900; if (Test-Quit) { throw 'quit' }
    # 5. THE SWOON
    React 0.5
    Show-Live (Get-FaintShot $act $marq); Sting thud; Start-Sleep -Milliseconds 1100; if (Test-Quit) { throw 'quit' }
    # 6. STANDING OVATION -- the whole pond rises: THE POND IS ON ITS FEET
    $script:Pond = 1.0; $script:FeetFrames = 60; Sting ovation
    foreach ($o in 1..6) { Show-Live (Get-OvationShot); if ($o -eq 1 -or $o -eq 4) { Sting applause }; Start-Sleep -Milliseconds 200; if (Test-Quit) { throw 'quit' } }
    Show-Live (Get-CardShot 'THE POND' 'IS ON ITS FEET' 'Magenta'); Sting ovation; Start-Sleep -Milliseconds 1000; if (Test-Quit) { throw 'quit' }
    # 7. The curtain call -- a tearful bow
    Show-Live (Get-StageShot $act 'love' '* takes a deep, tearful bow *' 'dir' $marq); Sting bow; Start-Sleep -Milliseconds 900
    Show-Live (Get-StageShot $act 'triumph' 'thank you... THANK you, you are too kind.' 'line' $marq); Start-Sleep -Milliseconds 900
    if (Test-Quit) { throw 'quit' }
    # 8. The curtain falls
    foreach ($p in 1.0,0.78,0.55,0.3,0.0) {
        Show-Live (Get-CurtainShot $p); Start-Sleep -Milliseconds 130; if (Test-Quit) { throw 'quit' } }
    Start-Sleep -Milliseconds 350
}

# ============================ STORYBOARD =====================================
if ($Storyboard) {
    for ($e=1; $e -le $Scenes; $e++) {
        $act = New-Act
        "##### ACT $e : $($act.Title) #####"; ''
        '  [ THE CURTAIN RISES ]'
        Show-Plain (Get-CurtainShot 0.45); ''
        "  [ TONIGHT'S TRAGEDY -- title card ]"
        Show-Plain (Get-CardShot "TONIGHT'S TRAGEDY" $act.Title 'White'); ''
        '  [ THE SOLILOQUY -- the pond MURMURS; tears trickle down the bill; PLAYBILL marquee scrolls ]'
        $script:Pond = 0.42; $script:FeetFrames = 0
        Show-Plain (Get-StageShot $act 'weep' $act.Opener 'line' 0 1); ''
        '  [ *** THE CONFESSION -- the pond hushes to still water, then GASPS *** ]'
        $script:Pond = 0.06
        Show-Plain (Get-StageShot $act 'gasp' $act.Confession 'line' 0); ''
        '  [ THE SWOON -- onto the fainting couch ]'
        Show-Plain (Get-FaintShot $act 0); ''
        '  [ STANDING OVATION -- BRAVO!, falling roses, THE POND IS ON ITS FEET ]'
        $script:Pond = 1.0; $script:FeetFrames = 5
        Show-Plain (Get-OvationShot)
        Show-Plain (Get-CardShot 'THE POND' 'IS ON ITS FEET' 'Magenta'); ''
        $script:Pond = 0.0; $script:FeetFrames = 0
        '  [ THE CURTAIN CALL -- a tearful bow ]'
        Show-Plain (Get-StageShot $act 'love' '* takes a deep, tearful bow *' 'dir' 0); ''
        if ($e -lt $Scenes) { '  . : .  *the curtain falls*  . : .'; Show-Plain (Get-CurtainShot 0.0); '' }
    }
    return
}

# ============================ LIVE ===========================================
try { [void][Console]::WindowWidth } catch {
    Write-Warning 'Live mode needs a real console. Try: .\Drama-Duck.ps1 -Storyboard'; return }
$prevCursor = [Console]::CursorVisible
try { [Console]::CursorVisible=$false } catch {}
function Test-Quit { try { if ([Console]::KeyAvailable){[void][Console]::ReadKey($true);return $true} } catch {}; return $false }

$staged = 0; $script:Live = $true
try {
    while ($true) {
        Invoke-Act (New-Act)
        $staged++; if ($Acts -gt 0 -and $staged -ge $Acts) { break }
    }
}
catch { if ("$_" -notmatch 'quit') { throw } }
finally {
    [Console]::ResetColor(); try { [Console]::CursorVisible=$prevCursor } catch {}
    Write-Host ''; Write-Host '  *the house lights rise*   ...and the duck takes one final, unnecessary bow.' -ForegroundColor DarkGray
}
