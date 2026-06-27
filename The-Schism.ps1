<#
.SYNOPSIS
    DRAMA TV presents -- "THE SCHISM": a late-night televangelist melodrama,
    staged in your terminal. A charismatic founder has had ENOUGH ("that does
    it"), and founds a church: THE CHURCH OF "THAT DOES IT, YOU HAD BETTER NOT
    IMAGINE THAT." From the pulpit comes the threat -- imagine it and ELSE; he
    will imagine what will happen, AFTER you have imagined. Then his friends
    start their own rival churches, including one where they imagine what has
    happened BEFORE you imagined, and the prophecy spirals -- imagining what was
    imagined before it will have been imagined -- until it eats its own tail.
    THE REVEAL: every church was the same church. The congregation is FLOORED.
    And the founder takes two months off. For no reason. It is foretold.

.DESCRIPTION
    One episode is directed in beats:
      THAT DOES IT -- a founder has had enough; the marquee lights up
        -> THE FOUNDING (the church is named; the doors open)
        -> THE FIRST SERMON (the threat: imagine it, or ELSE)
        -> THE SCHISM (friends storm off to found rival churches; signs multiply)
        -> THE PROPHECY (the recursive imagination spirals and tightens)
        -> THE REVEAL (every church was the same church) -- the room is FLOORED
        -> THE TWO-MONTH SABBATICAL (he leaves. for no reason. it is foretold.)
        -> SERVICE CONCLUDED -> fade to a reverent static.

    -Calm gives it an ecumenical ending: the schisms reconcile, the churches
    merge, everyone imagines the same nice thing. Otherwise: the schism is
    eternal, the sabbatical is mandatory, and the prophecy is recurring.

    Live mode redraws in place with sound + motion (needs a real console).
    -Storyboard prints a representative montage of frames to stdout instead.

.PARAMETER Services    How many sermons before exiting. 0 (default) = forever.
.PARAMETER Silent      Disable the [Console]::Beep sound cues.
.PARAMETER Storyboard  Print a static montage to stdout (no animation / sound).
.PARAMETER Scenes      Storyboard: how many services to lay out. Default 1.
.PARAMETER Seed        Fix the RNG for reproducible output. 0 = random.
.PARAMETER Fast        Snappier holds and typing. For the impatient.
.PARAMETER Calm        An ecumenical ending: the schisms reconcile, churches merge.

.EXAMPLE
    .\The-Schism.ps1
.EXAMPLE
    .\The-Schism.ps1 -Services 2
.EXAMPLE
    .\The-Schism.ps1 -Storyboard -Scenes 1 -Seed 42
.EXAMPLE
    .\The-Schism.ps1 -Calm           # the churches reconcile
#>
[CmdletBinding()]
param(
    [int]$Services = 0,
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
function Wrap3 { param([string]$t,[int]$w)
    $words=$t -split ' '; $lines=@(); $cur=''
    foreach ($wd in $words) { if ($cur -eq ''){$cur=$wd} elseif (($cur.Length+1+$wd.Length)-le $w){$cur+=' '+$wd} else {$lines+=$cur;$cur=$wd} }
    if ($cur -ne ''){$lines+=$cur}; while ($lines.Count -lt 3){$lines+=''}
    @((Center $lines[0] $w),(Center $lines[1] $w),(Center $lines[2] $w)) }
function ChyronWindow { param([string]$s,[int]$off,[int]$w)
    while ($s.Length -lt ($w*2)) { $s += $s }; ($s+$s).Substring($off % $s.Length, $w) }

# ============================ Word banks =====================================
$Titles  = @('Reverend','Pastor','Bishop','Brother','Sister','Most Reverend','Televangelist','The Honourable Prophet')
$Names   = @('Cyrus','Delphine','Marv','Tammy','Esau','Lurlene','Cornelius','Bobbie','Ezekiel','Mahalia','Cletus','Drusilla')
# The founding church -- named verbatim, as foretold.
$FoundingChurch = 'THAT DOES IT, YOU HAD BETTER NOT IMAGINE THAT'
# Rival churches the friends storm off to found.
$RivalChurches = @('WHAT HAPPENED BEFORE YOU IMAGINED','WHAT WILL HAPPEN AFTER YOU IMAGINED',
                   'THE REVERSE GASP','THE SECOND SABBATICAL','THE HOLY CIRCLE-BACK','NO ONE IN PARTICULAR',
                   'WHAT YOU IMAGINED I IMAGINED','THE PRE-EMPTIVE REVELATION','THE CONGREGATION OF NONE',
                   'IMAGINING, BUT WORSE','THE EXACT SAME THING BUT TUESDAYS')
$Sermons = @('You had BETTER not imagine that. Or ELSE.','I will imagine what will happen -- AFTER you have imagined!',
             'That does it. That. DOES. IT.','Tithe, and ye shall imagine!','The collection plate is ALSO a mirror!',
             'My friends will start their OWN churches, and lo, they did!','Have you, brothers and sisters, imagined? You SHOULDN''T HAVE.',
             'I foresaw this sermon. I also foresaw you not listening.','Two months. For no reason. It is FORETOLD.')
$Schisms = @('{F} storms out to found THE CHURCH OF {C}!','And lo, {F} schisms! Behold: THE CHURCH OF {C}!',
             '{F} cannot abide it -- a NEW church is born: {C}!','{F} founds THE CHURCH OF {C}, out of spite, mostly!')
$Reveals = @('every church was the same church, {W}.','you founded the church that founded you, {W}.',
             'the prophecy was imagining ITSELF the whole time, {W}.','everyone imagined everyone, and no one was left to attend, {W}.',
             'the congregation of no one is standing-room only, {W}.','you were the schism, {W}. you were always the schism.')
$Sabbatical = @('and then he left. for two months. for no reason.','the founder takes a two-month sabbatical. it is foretold.',
                'gone. two months. the marquee just says "BRB".','he imagined a holiday, and so it came to pass.')
# The recursive prophecy -- the centrepiece. It eats its own tail.
$Prophecy = @(
    'I imagine what will happen.',
    'I imagine what happens after you imagined.',
    'You imagine what I imagined would happen.',
    'They imagine what happened before you imagined,',
    'before you imagined it had, after they imagined,',
    'which is what happens before it will have happened,',
    'which is what you imagined you had not yet imagined,',
    'which is, at this point, a church.')

# ============================ Set-piece art ==================================
# The pulpit + a stained-glass window behind the preacher.
function Get-PulpitArt { param([string]$face)
    @('      .-^-.      ',
      "     /|\ /|\     ",
      "    (-+-+-+-)    ",
      "     \|/_\|/     ",
      "   preacher:     ",
      "     $face       ",
      "      /|\        ",
      '    __|||__      ')   # the pulpit
}
# A church signboard (used for the founding church and the rival cascade).
function Get-SignLines { param([string]$name)
    $w=Wrap2 $name 24
    @(' .--------------------------. ',
      ' |   T H E   C H U R C H    | ',
      ' |        O F . . .         | ',
      (' | '+(Center $w[0] 24)+' | '),
      (' | '+(Center $w[1] 24)+' | '),
      " '--------------------------' ")
}

# ============================ Shot builders ==================================
function Get-CardShot { param([string]$l1,[string]$l2,[string]$color)
    $rows=@(LB)
    1..4 | ForEach-Object { $rows+=Blank }
    $rows+=Cell (Center ('+'+('='*32)+'+') $SW) 'DarkGray'
    $rows+=Cell (Center $l1 $SW) $color
    $rows+=Cell (Center $l2 $SW) 'DarkGray'
    $rows+=Cell (Center ('+'+('='*32)+'+') $SW) 'DarkGray'
    Fit $rows }

# The founding: the big signboard for the named church.
function Get-FoundingShot { param([string]$name,[string]$caption)
    $rows=@(LB)
    foreach ($l in (Get-SignLines $name)) { $rows+=Cell (Center $l $SW) 'Yellow' }
    $w=Wrap2 $caption $SW
    $rows+=Cell $w[0] 'White'
    $rows+=Cell $w[1] 'White'
    $rows+=(LB)
    Fit $rows }

# The sermon: preacher at the pulpit, congregation below, a threat lower-third.
function Get-SermonShot { param($svc,[string]$line,[int]$chy,[bool]$glow)
    $face = Pick @('(O_O)','(>_<)','(o_o)','(^o^)','(0_0)')
    $pews = '  n   n   n   n   n   n  '       # bowed heads in the pews
    $art = Get-PulpitArt $face
    $rows=@(
        (LB),
        (Cell (Center ('<  '+$svc.Title.ToUpper()+'  >') $SW) 'Cyan'),
        (Cell (Center ($(if($glow){'* * *  HALLELUJAH  * * *'}else{'- - - - - - - - - - - -'})) $SW) ($(if($glow){'Yellow'}else{'DarkGray'}))) )
    foreach ($l in $art[0..3]) { $rows+=Cell (Center $l $SW) 'DarkCyan' }
    $rows+=Cell (Center $art[5] $SW) 'Green'
    $rows+=Cell (Center $pews $SW) 'DarkGray'
    $w=Wrap2 ("$($svc.Preacher): `"$line`"") $SW
    $rows+=Cell $w[0] 'White'
    $rows+=Cell $w[1] 'White'
    $rows+=Cell (' '+(ChyronWindow $svc.Chyron $chy ($SW-2))+' ') 'Red'
    $rows+=(LB)
    Fit $rows }

# The schism cascade: rival church signs piling up, smaller and smaller.
function Get-SchismShot { param([string[]]$names,[string]$caption)
    $rows=@(LB)
    $rows+=Cell (Center 'T H E   S C H I S M' $SW) 'Magenta'
    foreach ($nm in ($names | Select-Object -First 5)) {
        $rows+=Cell (Center ("+-- THE CHURCH OF $nm") $SW) (Pick @('Yellow','DarkYellow','White','Gray')) }
    $rows+=Blank
    $w=Wrap2 $caption $SW
    $rows+=Cell $w[0] 'White'
    $rows+=Cell $w[1] 'White'
    $rows+=(LB)
    Fit $rows }

# The prophecy spiral: imagination stacked, the latest line brightest, tightening.
function Get-ProphecyShot { param([int]$depth,[bool]$glow)
    $shown=$Prophecy[0..([Math]::Min($depth,$Prophecy.Count-1))]
    $rows=@(LB)
    $rows+=Cell (Center 'T H E   P R O P H E C Y' $SW) 'Magenta'
    $start=[Math]::Max(0,$shown.Count-10)
    for ($i=$start; $i -lt $shown.Count; $i++) {
        $isLast=($i -eq $shown.Count-1)
        $col= if ($isLast){'White'} elseif ($glow -and ($rng.Next(2)-eq 0)){'DarkMagenta'} else {'Gray'}
        $rows+=Cell (Center $shown[$i] $SW) $col }
    $rows+=(LB)
    Fit $rows }

function Get-RevealShot { param([string]$hence)
    $w=Wrap3 ("...$hence") $SW
    $rows=@(LB)
    1..2 | ForEach-Object { $rows+=Blank }
    $rows+=Cell (Center 'and lo, it was revealed:' $SW) 'DarkGray'
    $rows+=Blank
    foreach ($ln in $w) { $rows+=Cell $ln 'White' }
    $rows+=(LB)
    Fit $rows }

function Get-FlashShot { Fit (1..$SH | ForEach-Object { Cell ([string][char]0x2588 * $SW) 'White' }) }
function Get-StaticShot { param([string]$banner='>>  SERVICE CONCLUDED  <<')
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
    $desc=@{ hush='. . . hushed . . .';murmur='a murmur ripples';gasp='the flock GASPS';clap='HALLELUJAH!';
             feet='ON ITS FEET!';floor='*** F L O O R E D ***';slam='*** S L A M M E D ***' }[$mood]
    $txt="FAITH-O-METER [$bar] $desc"
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
    Row ('|'+(Pad ("   (CH 07)        ( o )      ( o )        <  T H E   S C H I S M  >  ") ($TW-2))+'|') $body
    Row ('|'+(Pad ("    (O) PWR        VOL        TINT              [|||||||||]       ") ($TW-2))+'|') $body
    Row ("'"+('-'*($TW-2))+"'") $body
    Row (Center '||                                        ||' $TW) $body
    Row (Center '[==]                                    [==]' $TW) $body
    Row (Center 'L I V E   C O N G R E G A T I O N' $TW) 'DarkGray'
    $out.Add((Get-AudienceRow)); $out.Add((Get-MeterRow))
    ,$out }

# ============================ Sound ==========================================
function Beep { param([int]$f,[int]$ms) if (-not $script:Silent) { try { [Console]::Beep($f,$ms) } catch {} } }
function Sting { param([string]$n) switch ($n) {
    'organ'     { foreach ($f in 262,330,392,523) { Beep $f 160 } }        # the church organ
    'bell'      { Beep 880 200; Beep 660 300 }                             # a tolling bell
    'amen'      { foreach ($f in 392,440,523) { Beep $f 120 }; Beep 392 300 }
    'schism'    { foreach ($f in 523,494,440,392,349) { Beep $f 90 } }     # a chord splitting apart
    'reveal'    { Beep 466 150; Beep 466 150; Beep 392 550 }
    'slam'      { Beep 150 60; Beep 95 200; Beep 60 320 }
    'sigh'      { Beep 300 80; Beep 240 320 }
    'doors'     { Beep 196 250; Beep 147 350 }                             # the doors open
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

# ============================ Service builder ================================
function New-Service {
    $a=Pick $Names; $title=Pick $Titles
    $friends=@($Names | Where-Object { $_ -ne $a } | Sort-Object { $rng.Next() } | Select-Object -First 4)
    $rivals=@($RivalChurches | Sort-Object { $rng.Next() } | Select-Object -First 4)
    $schismLines=@()
    for ($i=0; $i -lt $friends.Count; $i++) {
        $schismLines += (Pick $Schisms).Replace('{F}',$friends[$i]).Replace('{C}',$rivals[$i]) }
    [pscustomobject]@{
        Title="THE CHURCH OF $FoundingChurch"; Preacher="$title $a"; Founder=$a
        FoundingName=$FoundingChurch; Rivals=$rivals; SchismLines=$schismLines
        Reveal=((Pick $Reveals).Replace('{W}',$a)); Sabbatical=(Pick $Sabbatical)
        Chyron=("BREAKING: $title $a HAS HAD ENOUGH   ***   THAT DOES IT   ***   FOUR FRIENDS, FOUR NEW CHURCHES   ***   DO NOT IMAGINE THAT   ***   ").ToUpper() } }

# ============================ The director ===================================
function Invoke-Service { param($svc)
    # 1. THAT DOES IT
    React 0.35 organ
    Show-Live (Get-CardShot 'THAT DOES IT.' 'a founder has had enough' 'White') $false; Sting organ; Hold 1100; if (Test-Quit){throw 'quit'}
    # 2. THE FOUNDING -- the church is named, verbatim
    React 0.5 doors
    foreach ($f in 1..4) { Show-Live (Get-FoundingShot $svc.FoundingName 'the doors open. the marquee blazes.') $false; if ($f -eq 1){Sting doors}; Hold 380; if (Test-Quit){throw 'quit'} }
    # 3. THE FIRST SERMON (with a HALLELUJAH glow mid-scene)
    $chy=0
    foreach ($f in 1..10) {
        $line = if ($f -le 5) { 'You had BETTER not imagine that. Or ELSE.' } else { 'I will imagine what will happen -- AFTER you have imagined!' }
        $glow = ($f % 4 -eq 0)
        Show-Live (Get-SermonShot $svc $line $chy $glow) $false; $chy+=2
        if ($glow) { React 0.6 amen } elseif ($f -eq 1) { Sting bell }
        Hold 150; if (Test-Quit){throw 'quit'} }
    # 4. THE SCHISM -- friends storm off to found rival churches
    React 0.55 schism
    $built=@()
    foreach ($i in 0..($svc.SchismLines.Count-1)) {
        $built += "$($svc.Rivals[$i])"
        Show-Live (Get-SchismShot $built $svc.SchismLines[$i]) $false; Sting schism; Hold 700; if (Test-Quit){throw 'quit'} }
    # 5. THE PROPHECY -- the recursive imagination spirals and tightens
    $script:Reaction=0.1
    for ($d=0; $d -lt $Prophecy.Count; $d++) {
        $glow=($d -ge 4)
        Show-Live (Get-ProphecyShot $d $glow) $false
        Beep ([Math]::Max(120, 740-$d*80)) 40
        Hold ([Math]::Max(70, 360-$d*36)); if (Test-Quit){throw 'quit'} }
    # 6. THE REVEAL -> FLOORED
    Show-Live (Get-RevealShot $svc.Reveal) $false; Invoke-Flash; Sting reveal; Hold 500
    Invoke-Slam (Get-RevealShot $svc.Reveal)
    Show-Live (Get-RevealShot $svc.Reveal) $false; Hold 900; if (Test-Quit){throw 'quit'}
    if ($script:Calm) {
        React 0.95 ovation
        Show-Live (Get-CardShot 'AND THEY RECONCILED' 'all churches merged. one nice imagining.' 'Green') $false; Sting amen; Hold 1200
        return
    }
    # 7. THE TWO-MONTH SABBATICAL -- he leaves. for no reason. it is foretold.
    React 0.4
    Show-Live (Get-CardShot 'ORDER OF SERVICE, FINAL ITEM:' $svc.Sabbatical 'White') $false; Sting sigh; Hold 1200; if (Test-Quit){throw 'quit'}
    $black=@(1..$SH | ForEach-Object { Cell (' '*$SW) 'Black' })
    $rows=@($black); $rows[6]=Cell (Center "the prophecy names a founding member:" $SW) 'DarkGray'
    $rows[8]=Cell (Center "$Viewer." $SW) 'White'
    Show-Raw $rows $false; Beep 523 120; Hold 1100; if (Test-Quit){throw 'quit'}
    $rows=@($black); $rows[7]=Cell (Center 'the marquee just says "BRB. 2 MONTHS."' $SW) 'DarkGray'; Show-Raw $rows $false; Sting bell; Hold 1200
    # 8. SERVICE CONCLUDED -> static
    foreach ($s in 1..(RNext 5 8)){ Show-Live (Get-StaticShot) $true; Beep (RNext 200 600) 25; Hold 70; if (Test-Quit){throw 'quit'} } }

# ============================ STORYBOARD =====================================
if ($Storyboard) {
    for ($e=1; $e -le $Scenes; $e++) {
        $svc=New-Service
        "##### SERVICE $e : THE SCHISM -- $($svc.Preacher) founds a church #####"; ''
        $script:Reaction=0.35; $script:SlamFrames=0
        '  [ COLD OPEN -- THAT DOES IT ]'
        Show-Plain (Get-CardShot 'THAT DOES IT.' 'a founder has had enough' 'White') $false; ''
        '  [ THE FOUNDING -- the church is named, verbatim ]'
        Show-Plain (Get-FoundingShot $svc.FoundingName 'the doors open. the marquee blazes.') $false; ''
        $script:Reaction=0.55
        '  [ THE FIRST SERMON -- the threat from the pulpit ]'
        Show-Plain (Get-SermonShot $svc 'You had BETTER not imagine that. Or ELSE.' 0 $true) $false; ''
        '  [ THE SCHISM -- friends storm off to found rival churches ]'
        Show-Plain (Get-SchismShot $svc.Rivals $svc.SchismLines[0]) $false; ''
        $script:Reaction=0.1
        '  [ THE PROPHECY -- the recursive imagination spirals and tightens ]'
        Show-Plain (Get-ProphecyShot ($Prophecy.Count-1) $true) $false; ''
        $script:SlamFrames=7; $script:Reaction=1.0
        '  [ THE REVEAL -- every church was the same church; the room is FLOORED ]'
        Show-Plain (Get-RevealShot $svc.Reveal) $false; ''
        $script:SlamFrames=0
        if ($Calm) {
            $script:Reaction=0.95
            '  [ AN ECUMENICAL ENDING -- the schisms reconcile, churches merge ]'
            Show-Plain (Get-CardShot 'AND THEY RECONCILED' 'all churches merged. one nice imagining.' 'Green') $false; ''
        } else {
            '  [ THE TWO-MONTH SABBATICAL -- he leaves, for no reason, foretold ]'
            $black=@(1..$SH | ForEach-Object { Cell (' '*$SW) 'Black' })
            $rows=@($black); $rows[6]=Cell (Center 'the prophecy names a founding member:' $SW) 'DarkGray'
            $rows[8]=Cell (Center "$Viewer." $SW) 'White'
            Show-Plain $rows $false; ''
            '  [ SERVICE CONCLUDED -> reverent static ]'
            Show-Plain (Get-StaticShot) $true; ''
        }
    }
    return
}

# ============================ LIVE ===========================================
try { [void][Console]::WindowWidth } catch {
    Write-Warning 'Live mode needs a real console. Try: .\The-Schism.ps1 -Storyboard'; return }
$prevCursor=[Console]::CursorVisible
try { [Console]::CursorVisible=$false } catch {}
$script:Live=$true; $count=0
function Test-Quit { try { if ([Console]::KeyAvailable){[void][Console]::ReadKey($true);return $true} } catch {}; return $false }

try {
    while ($true) {
        Invoke-Service (New-Service)
        $count++; if ($Services -gt 0 -and $count -ge $Services) { break }
    }
}
catch { if ("$_" -notmatch 'quit') { throw } }
finally {
    [Console]::ResetColor(); try { [Console]::CursorVisible=$prevCursor } catch {}
    Write-Host ''; Write-Host '  *click*   ...service concluded. (he''ll be back in two months.)' -ForegroundColor DarkGray
}
