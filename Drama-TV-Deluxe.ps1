<#
.SYNOPSIS
    DRAMA TV DELUXE -- "THE DRAMMYS": the channel's red-carpet, gold-plated
    SEASON FINALE awards special, staged in your terminal. The whole universe
    shows up at once: a spotlight-swept red carpet, a PREVIOUSLY-ON-EVERYTHING
    recap, the nominees for Best Betrayal, a golden envelope and a drumroll, the
    WINNER reveal under a confetti cannon, an overwrought acceptance speech that
    gets struck by lightning... and then the finale crashes the ceremony: the
    crowd is FLOORED, the duck takes the stage, and THE LEVEL gives out one last
    award -- to YOU, by name. Then the credits roll in gold.

.DESCRIPTION
    One DELUXE special is directed as a gala in seven acts:
      1. RED CARPET        -- spotlights sweep, gossip chyron, the stars arrive
      2. PREVIOUSLY, ON EVERYTHING -- a lightning recap of the whole canon
      3. THE NOMINEES      -- the category, and five gloriously petty nominees
      4. THE ENVELOPE      -- a golden envelope, a drumroll, a held breath
      5. AND THE DRAMMY GOES TO... -- the WINNER, trophy, CONFETTI CANNON,
                              a standing ovation that FLOORS the room
      6. THE SPEECH        -- a tearful, overwrought speech; lightning; a twist
      7. THE FINALE        -- the duck takes the stage; THE LEVEL presents its
                              final award to YOU by name; then GOLD credits roll.

    -Calm keeps it a classy, un-haunted gala (a winner, an ovation, credits).
    Otherwise the finale goes full canon: the duck, and THE LEVEL looking back.

    Live mode redraws in place with sound + motion (needs a real console).
    -Storyboard prints a representative montage of frames to stdout instead.

.PARAMETER Specials    How many full ceremonies before exiting. 0 (default)=forever.
.PARAMETER Silent      Disable the [Console]::Beep sound cues.
.PARAMETER Storyboard  Print a static montage to stdout (no animation / sound).
.PARAMETER Scenes      Storyboard: how many ceremonies to lay out. Default 1.
.PARAMETER Seed        Fix the RNG for reproducible output. 0 = random.
.PARAMETER Fast        Snappier typing and shorter holds. For the impatient.
.PARAMETER Calm        A classy gala: a winner, an ovation, credits -- no haunting.

.EXAMPLE
    .\Drama-TV-Deluxe.ps1
.EXAMPLE
    .\Drama-TV-Deluxe.ps1 -Specials 1
.EXAMPLE
    .\Drama-TV-Deluxe.ps1 -Storyboard -Scenes 1 -Seed 42
.EXAMPLE
    .\Drama-TV-Deluxe.ps1 -Calm                # the red carpet, minus the dread
#>
[CmdletBinding()]
param(
    [int]$Specials = 0,
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
function GLB    { Cell (-join (1..$SW | ForEach-Object { Pick @([char]0x2588,[char]0x2593,'*','.') })) 'DarkYellow' }  # gilded letterbox
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
function Sparkle { param([int]$pct=18)
    $g='*+.,`''^:o'.ToCharArray(); -join (1..$SW | ForEach-Object { if ($rng.Next(100) -lt $pct) { $g[$rng.Next($g.Count)] } else { ' ' } }) }

# ============================ Word banks =====================================
$Names   = @('Brad','Vanessa','Dimitri','Esmeralda','Chad','Bianca','Rex','Cordelia',
             'Lance','Seraphina','Brock','Tristan','Ophelia','Roderick','Genevieve','Blaze')
$Shows   = @('As the Void Turns','Days of Our Doom','Passions of Ravenshollow','The Bold and the Unspeakable',
             'General Madness','Crestfall After Dark','The Young and the Eldritch','THE LEVEL','Drama Duck: The Soliloquy')
$Categories = @('BEST BETRAYAL','OUTSTANDING SLAP','BEST FAKED DEATH','MOST EVIL TWIN',
                'BEST PUSH OFF A BALCONY','OUTSTANDING GASP','BEST WEDDING RUINED','LIFETIME ACHIEVEMENT IN SCANDAL')
$Nominees = @('"How COULD you, {O}?!" -- {W}','The Slap Heard Round {PLACE}','{W}''s Triumphant Return From The Dead',
              '{O}, As The Evil Twin Nobody Asked For','The Will-Reading That Ended Everything','{W} vs. The Rose Garden Evidence',
              'The Wedding Where The Prenup Burned','{O}''s Soul-Selling, Season-Long Arc','One (1) Devastating Single Tear',
              'The Coma That Was, In Fact, A Lie','{W} Dangling {O} Over The {FALL}')
$Speeches = @('I would like to thank my evil twin...','I never thought I''d win for faking my OWN death!',
              'This is for everyone I pushed off a {FALL}!','I couldn''t have done it without betraying {O}!',
              'They said a single tear couldn''t carry a season. They were WRONG!',
              'I''d like to thank the Academy, and the rose garden where I buried the evidence!')
$Twists   = @('{W} reveals the trophy is HOLLOW... and so is the marriage!','The envelope was switched -- the REAL winner is {O}!',
              '{W} confesses the whole season was a dream!','{O} bursts in -- ALIVE -- to claim the award!',
              'The orchestra plays {W} off... straight off the {FALL}!')
$Places  = @('Ravenshollow','Maplewood','Sunset Bay','Crestfall','Bel-Aire','Thornwood','Carcosa','Innsmouth')
$Falls   = @('balcony','yacht','lighthouse','penthouse ledge','clocktower','grand staircase','opera box','ski lift')

# ============================ Set-piece art ==================================
$Trophy = @(@'
    .-=========-.
    \  D R A M  /
     \  M Y !  /
      )       (
     (    Y    )
      \   |   /
       )  |  (
      (___|___)
       \_____/
      .'WINNER'.
     '-_______-'
'@ -split "\r?\n" | Where-Object { $_ -ne '' })
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

# ============================ Shot builders ==================================
function Get-TitleShot {
    $art=@('  D R A M A   T V','     D E L U X E','  *  THE DRAMMYS  *')
    $rows=@((GLB),(Cell (Sparkle 22) 'Yellow'))
    1..1 | ForEach-Object { $rows+=Blank }
    foreach ($l in $art) { $rows+=Cell (Center $l $SW) 'Yellow' }
    $rows+=Blank
    $rows+=Cell (Center 'the season finale, gala edition' $SW) 'DarkYellow'
    $rows+=Cell (Sparkle 22) 'Yellow'
    $rows+=(GLB)
    Fit $rows }

function Get-RedCarpetShot { param([string]$caption,[int]$sweep,[int]$chy,[string]$chyron)
    $beam=(' '*$SW).ToCharArray()
    foreach ($s in @($sweep, ($SW-1-$sweep))) { for ($d=-2;$d -le 2;$d++){ $x=$s+$d; if ($x -ge 0 -and $x -lt $SW){ $beam[$x]=(Pick @('\','/','|')) } } }
    $carpet=('#'*$SW)
    $rows=@(
        (GLB),
        (Cell (Center 'R E D   C A R P E T   L I V E' $SW) 'Yellow'),
        (Cell (-join $beam) 'White'),
        (Cell (Sparkle 14) 'DarkYellow'),
        (Cell (Center '\o/   \o/      *FLASH*      \o/   \o/' $SW) 'White'),
        (Cell (Center ' |     |      ( @ )         |     | ' $SW) 'Gray'),
        (Cell (Center '/ \   / \                  / \   / \' $SW) 'DarkGray'),
        (Cell $carpet 'DarkRed'),
        (Cell $carpet 'Red'),
        (Blank),
        ((Wrap2 $caption $SW | ForEach-Object { Cell $_ 'White' })),
        (Cell (' '+(ChyronWindow $chyron $chy ($SW-2))+' ') 'Yellow'),
        (GLB) )
    Fit ($rows | ForEach-Object { $_ }) }

function Get-CardShot { param([string]$l1,[string]$l2,[string]$color)
    $rows=@(GLB)
    1..3 | ForEach-Object { $rows+=Blank }
    $rows+=Cell (Center ('* '*17) $SW) 'DarkYellow'
    $rows+=Cell (Center $l1 $SW) $color
    $rows+=Cell (Center $l2 $SW) 'DarkYellow'
    $rows+=Cell (Center ('* '*17) $SW) 'DarkYellow'
    $rows+=(GLB)
    Fit $rows }

function Get-NomineesShot { param($award)
    $rows=@(GLB)
    $rows+=Cell (Center "NOMINEES -- $($award.Category)" $SW) 'Yellow'
    $rows+=Cell ('-'*$SW) 'DarkYellow'
    foreach ($n in $award.Nominees) { $rows+=Cell (Center ("> "+$n) $SW) 'White' }
    $rows+=(GLB)
    Fit $rows }

function Get-EnvelopeShot { param([string]$caption,[string]$col='Yellow')
    $env=@('   ._______________.',
           '   |\             /|',
           '   | \           / |',
           '   |  \  D T V  /  |',
           '   |   \       /   |',
           '   |    \_____/    |',
           '   |_______________|')
    $rows=@(GLB)
    foreach ($l in $env) { $rows+=Cell (Center $l $SW) $col }
    $rows+=Cell (Center $caption.ToUpper() $SW) 'White'
    $rows+=(GLB)
    Fit $rows }

function Get-WinnerShot { param($award,[bool]$confetti)
    $rows=@(GLB)
    $rows+=Cell ($(if($confetti){Sparkle 30}else{' '*$SW})) (Pick @('Yellow','Magenta','Cyan','White'))
    foreach ($l in $Trophy) { $rows+=Cell (Center $l $SW) 'Yellow' }
    $rows+=Cell (Center ("*** $($award.Winner) ***") $SW) 'White'
    $rows+=Cell (Center "for $($award.Show)" $SW) 'DarkYellow'
    $rows+=Cell ($(if($confetti){Sparkle 30}else{' '*$SW})) (Pick @('Yellow','Magenta','Cyan','White'))
    $rows+=(GLB)
    Fit $rows }

function Get-SpeechShot { param($award,[string]$face,[bool]$stormy)
    $rain = { -join (1..$SW | ForEach-Object { if ($rng.Next(100)-lt 14){ Pick @("'",'/',',') } else { ' ' } }) }
    $w=Wrap2 ("$($award.Winner): `"$($award.Speech)`"") $SW
    $rows=@(
        (GLB),
        (Cell (Center 'THE ACCEPTANCE SPEECH' $SW) 'Yellow'),
        (Cell ($(if($stormy){& $rain}else{Sparkle 8})) 'DarkCyan'),
        (Blank),
        (Cell (Center " $face " $SW) 'Green'),
        (Cell (Center ' /|\ ' $SW) 'Green'),
        (Cell (Center '_/ \_' $SW) 'DarkGreen'),
        (Blank),
        (Cell $w[0] 'White'),
        (Cell $w[1] 'White'),
        (Cell ($(if($stormy){& $rain}else{' '*$SW})) 'DarkCyan'),
        (Blank),
        (GLB) )
    Fit $rows }

function Get-CreditsShot { param([string[]]$window)
    $rows=@(GLB)
    foreach ($l in $window) { $rows+=Cell (Center $l $SW) 'DarkYellow' }
    $rows+=(GLB)
    Fit $rows }

function Get-FlashShot { Fit (1..$SH | ForEach-Object { Cell ([string][char]0x2588 * $SW) 'White' }) }
function Get-DuckShot { param([string]$caption)
    $rows=@(GLB); 1..1 | ForEach-Object { $rows+=Blank }
    foreach ($l in $DuckCam) { $rows+=Cell (Center $l $SW) 'Yellow' }
    $rows+=Cell (Center $caption.ToUpper() $SW) 'DarkYellow'; $rows+=(GLB)
    Fit $rows }
function Dim { param($cells,[int]$step) $map=@{0='White';1='Gray';2='DarkGray';3='Black'}; @($cells | ForEach-Object { Cell $_.Text $map[$step] }) }

# ============================ Audience + meter ===============================
$AUDN=9; $script:Reaction=0.0; $script:SlamFrames=0; $script:Floored=0
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
             feet='STANDING OVATION!';floor='*** F L O O R E D ***';slam='*** S L A M M E D ***' }[$mood]
    $txt="APPL-O-METER [$bar] $desc"
    $col= if ($mood -in 'floor','slam'){'Red'} elseif ($r -ge 0.7){Pick @('Red','Yellow')} elseif ($r -ge 0.4){'Yellow'} elseif ($r -ge 0.18){'White'} else {'DarkGray'}
    Cell (Center $txt $TW) $col }

# ============================ TV chrome ======================================
function Build-Tv { param($cells,[bool]$gala=$true)
    $out=New-Object 'System.Collections.Generic.List[object]'
    function Row { param($t,$c) $out.Add((Cell $t $c)) }
    $body='DarkGray'; $frame='DarkYellow'
    Row (Center '.   *      .       *   .' $TW) 'Yellow'
    Row (Center '\                 /' $TW) $body
    Row (Center '  \             /  ' $TW) $body
    Row (Center '   \____ ___ ___/  ' $TW) $body
    Row ('.'+('-'*($TW-2))+'.') $body
    Row ('|'+(' '*($TW-2))+'|') $body
    Row ('|'+(' '*5)+'.'+('-'*($SW+2))+'.'+(' '*5)+'|') $frame
    foreach ($c in $cells) { Row ('|'+(' '*5)+'| '+(Pad $c.Text $SW)+' |'+(' '*5)+'|') $c.Color }
    Row ('|'+(' '*5)+"'"+('-'*($SW+2))+"'"+(' '*5)+'|') $frame
    Row ('|'+(' '*($TW-2))+'|') $body
    Row ('|'+(Pad ("   (CH 01)        ( o )      ( o )        <  DRAMA TV DELUXE  >  ") ($TW-2))+'|') $frame
    Row ('|'+(Pad ("    (O) PWR        VOL        TINT              [|||||||||]       ") ($TW-2))+'|') $body
    Row ("'"+('-'*($TW-2))+"'") $body
    Row (Center '||                                        ||' $TW) $body
    Row (Center '[==]                                    [==]' $TW) $body
    Row (Center 'L I V E   G A L A   A U D I E N C E' $TW) 'DarkYellow'
    $out.Add((Get-AudienceRow)); $out.Add((Get-MeterRow))
    ,$out }

# ============================ Sound ==========================================
function Beep { param([int]$f,[int]$ms) if (-not $script:Silent) { try { [Console]::Beep($f,$ms) } catch {} } }
function Sting { param([string]$n) switch ($n) {
    'fanfare'   { foreach ($f in 392,523,659,784,1047) { Beep $f 120 } }
    'redcarpet' { foreach ($f in 523,587,659,698,784) { Beep $f 90 } }
    'drumroll'  { 1..18 | ForEach-Object { Beep (RNext 90 140) 22 } }
    'reveal'    { Beep 466 150; Beep 466 150; Beep 392 550 }
    'confetti'  { 1..16 | ForEach-Object { Beep (RNext 700 1500) 18 } }
    'ovation'   { 1..24 | ForEach-Object { Beep (RNext 220 920) 14 }; Beep 880 240 }
    'slam'      { Beep 150 60; Beep 95 200; Beep 60 320 }
    'thunder'   { 1..3 | ForEach-Object { Beep (RNext 55 95) 110 } }
    'gasp'      { Beep 622 70; Beep 831 80; Beep 1047 150 }
    'orchestra' { foreach ($f in 784,659,523,392,330,262) { Beep $f 110 } }   # played off-stage
    'quack'     { 1..4 | ForEach-Object { Beep (RNext 300 380) 110; Beep (RNext 150 210) 80 } }
    'dread'     { 1..5 | ForEach-Object { Beep (RNext 38 62) 90 }; Beep 41 900 } } }

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

# ============================ Renderers ======================================
function Show-Raw  { param($cells,[int]$indent=3) $tv=Build-Tv $cells; Clear-Host; Write-Host ''; foreach ($l in $tv){ Write-Host ((' '*$indent)+$l.Text) -ForegroundColor $l.Color } }
function Show-Live { param($cells,[int]$indent=3)
    if ($script:SlamFrames -gt 0){$script:SlamFrames--; $script:Reaction=1.0} else {$script:Reaction=[Math]::Max(0.0,$script:Reaction*0.90-0.012)}
    Show-Raw $cells $indent }
function Show-Plain{ param($cells) (Build-Tv $cells) | ForEach-Object { $_.Text } }
function Invoke-Flash { 1..2 | ForEach-Object { Show-Live (Get-FlashShot); Beep (RNext 60 90) 70; Hold 55 } }
function Invoke-Shake { param($cells) foreach ($o in 6,1,5,0,4,2){ Show-Live $cells $o; Hold 35 } }
function Invoke-Confetti { param($award) foreach ($f in 1..6){ Show-Live (Get-WinnerShot $award $true); Beep (RNext 700 1500) 20; Hold 90 } }

function Invoke-Slam { param($cells)
    $script:Reaction=1.0; $script:SlamFrames=7; $script:Floored++
    Sting slam; Invoke-Shake $cells; Sting ovation }

# THE FINALE PAYOFF -- the duck takes the stage, then THE LEVEL's final award.
function Invoke-Finale {
    $black=@(1..$SH | ForEach-Object { Cell (' '*$SW) 'Black' })
    # the duck takes the stage
    Sting quack
    Show-Live (Get-DuckShot 'a special presenter takes the stage') ; Hold 800; if (Test-Quit){throw 'quit'}
    Show-Live (Get-DuckShot 'and the duck has an envelope') ; Sting quack; Hold 800; if (Test-Quit){throw 'quit'}
    # THE LEVEL presents the final award -- to you
    foreach ($s in 0..3){ Show-Raw (Dim (Get-CardShot 'AND THE FINAL DRAMMY' 'goes to . . .' 'White') $s); Hold 110 }
    Sting dread
    $line=(Pick @('THE DRAMMY FOR BEST VIEWER GOES TO {V}.','{V}, YOU WIN. YOU ALWAYS WIN.',
                  'A LIFETIME ACHIEVEMENT AWARD FOR {V}.','THE LEVEL THANKS YOU FOR WATCHING, {V}.')).Replace('{V}',$Viewer)
    $shown=''
    foreach ($c in $line.ToCharArray()){ $shown+=$c; $rows=@($black); $rows[7]=Cell (Center $shown $SW) 'Yellow'
        Show-Raw $rows; Beep (RNext 300 520) 28; Hold 55; if (Test-Quit){throw 'quit'} }
    Hold 900; Sting quack; Invoke-Flash
    $rows=@($black); $rows[7]=Cell (Center 'Q U A C K .' $SW) 'DarkYellow'; Show-Raw $rows; Beep 120 600; Hold 1200
    $script:Floored=0 }

# ============================ Award builder ==================================
function New-Award {
    $a=Pick $Names; $b=Pick ($Names | Where-Object { $_ -ne $a }); $place=Pick $Places; $fall=Pick $Falls
    $sub={ param($t) ($t).Replace('{W}',$a).Replace('{O}',$b).Replace('{PLACE}',$place).Replace('{FALL}',$fall) }
    [pscustomobject]@{
        Category=(Pick $Categories); Show=(Pick $Shows); Winner=$a.ToUpper()
        Nominees=@($Nominees | Sort-Object { $rng.Next() } | Select-Object -First 5 | ForEach-Object { & $sub $_ })
        Speech=(& $sub (Pick $Speeches)); Twist=(& $sub (Pick $Twists))
        Chyron=("THE DRAMMYS LIVE   ***   $a WORE VINTAGE $place   ***   $b ARRIVED FASHIONABLY UNDEAD   ***   WHO WILL WIN $((Pick $Categories))?   ***   ").ToUpper() } }

# ============================ The director ===================================
function Invoke-Special { param($award)
    # 1. TITLE + RED CARPET
    React 0.3 fanfare
    Show-Live (Get-TitleShot); Sting fanfare; Hold 1200; if (Test-Quit){throw 'quit'}
    React 0.4 redcarpet
    $chy=0
    foreach ($f in 0..9){ Show-Live (Get-RedCarpetShot 'The stars arrive at the DRAMMYS gala!' ($f % $SW) $chy $award.Chyron); $chy+=2
        if ($f -eq 5){ React 0.6 gasp; Beep 1047 120 }; Hold 150; if (Test-Quit){throw 'quit'} }
    # 2. PREVIOUSLY, ON EVERYTHING
    Show-Live (Get-CardShot 'PREVIOUSLY, ON . . .' 'E V E R Y T H I N G' 'Yellow'); Sting orchestra; Hold 1000
    foreach ($r in @('A wedding RUINED.','A twin REVEALED.','A balcony SURVIVED (barely).','A duck, WEEPING.','THE LEVEL, WATCHING.')) {
        Show-Live (Get-CardShot '. . . recap . . .' $r 'White'); Beep (RNext 300 700) 60; Hold 420; if (Test-Quit){throw 'quit'} }
    # 3. THE NOMINEES
    React 0.5 gasp
    Show-Live (Get-CardShot 'AND THE NOMINEES ARE' $award.Category 'Yellow'); Sting gasp; Hold 800
    foreach ($f in 1..6){ Show-Live (Get-NomineesShot $award); Hold 360; if (Test-Quit){throw 'quit'} }
    # 4. THE ENVELOPE + DRUMROLL (the hush)
    $script:Reaction=0.06
    Show-Live (Get-EnvelopeShot 'the envelope, please...'); Hold 700
    Sting drumroll
    foreach ($f in 1..8){ Show-Live (Get-EnvelopeShot ('...'+('.'*($f%4))) (Pick @('Yellow','White','DarkYellow'))); Beep (RNext 90 140) 30; Hold 120; if (Test-Quit){throw 'quit'} }
    # 5. AND THE DRAMMY GOES TO... -- WINNER, confetti, FLOORED ovation
    Show-Live (Get-CardShot 'AND THE DRAMMY GOES TO' $award.Winner 'White'); Invoke-Flash; Sting reveal; Hold 500
    React 0.95
    Invoke-Confetti $award; Sting confetti
    Invoke-Slam (Get-WinnerShot $award $true)
    Show-Live (Get-WinnerShot $award $true); Hold 900; if (Test-Quit){throw 'quit'}
    # 6. THE SPEECH (struck by lightning) + TWIST
    foreach ($f in 1..6){ $stormy=($f -ge 4); Show-Live (Get-SpeechShot $award '(T_T)' $stormy)
        if ($f -eq 4){ React 0.7 gasp; Invoke-Flash; Sting thunder; Invoke-Shake (Get-SpeechShot $award '(O_O)' $true) }; Hold 300; if (Test-Quit){throw 'quit'} }
    Show-Live (Get-CardShot 'BUT WAIT --' $award.Twist 'Red'); Sting gasp; Hold 1100; if (Test-Quit){throw 'quit'}
    if (-not $script:Calm) { Invoke-Finale }
    # 7. CREDITS roll in gold
    React 0.9 ovation
    $credits=@('','D R A M A   T V   D E L U X E','','THE DRAMMYS','','Best Betrayal ......... '+$award.Winner,
               'Most Tears ............ EVERYONE','Best Duck ............. THE DUCK','Presented By .......... THE LEVEL',
               'For Your Consideration','','a virtualhealthcitizen production','','* * *','THANK YOU FOR WATCHING','',
               'and remember:','never put THE LEVEL','back in THE LEVEL','','* * *','')
    for ($i=0; $i -lt ($credits.Count-3); $i++){ Show-Live (Get-CreditsShot $credits[$i..($i+2)]); Beep 523 20; Hold 240; if (Test-Quit){throw 'quit'} }
    foreach ($s in 0..3){ Show-Live (Dim (Get-CardShot 'GOODNIGHT' 'DRAMA TV DELUXE' 'Yellow') $s); Hold 250 } }

# ============================ STORYBOARD =====================================
if ($Storyboard) {
    for ($e=1; $e -le $Scenes; $e++) {
        $award=New-Award
        "##### DELUXE SPECIAL $e : THE DRAMMYS -- $($award.Category) #####"; ''
        $script:Reaction=0.4; $script:SlamFrames=0
        '  [ TITLE CARD -- the gilded opening ]'
        Show-Plain (Get-TitleShot); ''
        '  [ RED CARPET LIVE -- spotlights sweep, the stars arrive ]'
        Show-Plain (Get-RedCarpetShot 'The stars arrive at the DRAMMYS gala!' 6 0 $award.Chyron); ''
        '  [ PREVIOUSLY, ON EVERYTHING -- the lightning recap ]'
        Show-Plain (Get-CardShot '. . . recap . . .' 'THE LEVEL, WATCHING.' 'White'); ''
        '  [ THE NOMINEES ]'
        Show-Plain (Get-NomineesShot $award); ''
        $script:Reaction=0.06
        '  [ THE ENVELOPE -- a hush, a drumroll ]'
        Show-Plain (Get-EnvelopeShot 'the envelope, please...'); ''
        $script:SlamFrames=7; $script:Reaction=1.0
        '  [ AND THE DRAMMY GOES TO... -- WINNER, CONFETTI, the room is FLOORED ]'
        Show-Plain (Get-WinnerShot $award $true); ''
        $script:SlamFrames=0; $script:Reaction=0.5
        '  [ THE ACCEPTANCE SPEECH -- struck by lightning ]'
        Show-Plain (Get-SpeechShot $award '(T_T)' $true); ''
        '  [ BUT WAIT -- the twist ]'
        Show-Plain (Get-CardShot 'BUT WAIT --' $award.Twist 'Red'); ''
        if ($Calm) {
            $script:Reaction=0.95
            '  [ A CLASSY FINISH -- gold credits roll ]'
            Show-Plain (Get-CreditsShot @('THE DRAMMYS','','THANK YOU FOR WATCHING')); ''
        } else {
            '  [ THE FINALE -- the duck presents THE LEVEL''s final award... to YOU ]'
            $black=@(1..$SH | ForEach-Object { Cell (' '*$SW) 'Black' })
            $rows=@($black); $rows[6]=Cell (Center 'THE DRAMMY FOR BEST VIEWER GOES TO' $SW) 'DarkYellow'
            $rows[8]=Cell (Center "$Viewer." $SW) 'Yellow'
            Show-Plain $rows; ''
            '  [ GOLD CREDITS -- never put THE LEVEL back in THE LEVEL ]'
            Show-Plain (Get-CreditsShot @('never put THE LEVEL','back in THE LEVEL','* * *')); ''
        }
    }
    return
}

# ============================ LIVE ===========================================
try { [void][Console]::WindowWidth } catch {
    Write-Warning 'Live mode needs a real console. Try: .\Drama-TV-Deluxe.ps1 -Storyboard'; return }
$prevCursor=[Console]::CursorVisible
try { [Console]::CursorVisible=$false } catch {}
$script:Live=$true; $shown=0
function Test-Quit { try { if ([Console]::KeyAvailable){[void][Console]::ReadKey($true);return $true} } catch {}; return $false }

try {
    while ($true) {
        Invoke-Special (New-Award)
        $shown++; if ($Specials -gt 0 -and $shown -ge $Specials) { break }
    }
}
catch { if ("$_" -notmatch 'quit') { throw } }
finally {
    [Console]::ResetColor(); try { [Console]::CursorVisible=$prevCursor } catch {}
    Write-Host ''; Write-Host '  *click*   ...and that''s a wrap on the DRAMMYS. Goodnight, gala.' -ForegroundColor DarkYellow
}
