<#
.SYNOPSIS
    "THE OPEN PLAN" - an ASCII office mockumentary that plays in your terminal.

.DESCRIPTION
    A fake TV broadcast: blinking REC light, running timecode, lower-third
    subtitles, and "talking head" confessional cutaways where the staff
    deadpan directly into the camera roughly every ten seconds. Snark included
    at no extra charge.

.PARAMETER Fast
    Type subtitles quickly and shorten the dramatic pauses. For the impatient.

.PARAMETER Forever
    Loop the episode until you press Ctrl+C. Like real corporate life.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\scripts\haha\Show-OfficeMockumentary.ps1

.EXAMPLE
    .\scripts\haha\Show-OfficeMockumentary.ps1 -Fast -Forever
#>
[CmdletBinding()]
param(
    [switch]$Fast,
    [switch]$Forever
)

$ErrorActionPreference = 'Stop'

# ----- timing knobs ---------------------------------------------------------
$TypeMs  = if ($Fast) { 8 }   else { 26 }   # ms per character of subtitle
$Beat    = if ($Fast) { 350 } else { 900 }  # short pause (ms)
$Hold    = if ($Fast) { 700 } else { 1700 } # long deadpan hold (ms)
$InnerW  = 54                               # interior width of the "TV"

# ----- low-level helpers ----------------------------------------------------
function Center([string]$s, [int]$w) {
    if ($s.Length -ge $w) { return $s.Substring(0, $w) }
    $pad = $w - $s.Length
    $l = [math]::Floor($pad / 2); $r = $pad - $l
    (' ' * $l) + $s + (' ' * $r)
}

function PadR([string]$s, [int]$w) {
    if ($s.Length -ge $w) { return $s.Substring(0, $w) }
    $s + (' ' * ($w - $s.Length))
}

function Tc([System.Diagnostics.Stopwatch]$sw) {
    $t = $sw.Elapsed
    '{0:00}:{1:00}:{2:00}' -f $t.Hours, $t.Minutes, $t.Seconds
}

function Pause([int]$ms) { Start-Sleep -Milliseconds $ms }

# Typewriter a line of subtitle text, char by char.
function Write-Slow([string]$text, [ConsoleColor]$color = 'White') {
    foreach ($ch in $text.ToCharArray()) {
        Write-Host -NoNewline $ch -ForegroundColor $color
        Pause $TypeMs
    }
    Write-Host ''
}

# Draw the television: top chrome (REC + timecode), the picture, bottom chrome.
function Draw-Tv {
    param(
        [string[]]$Picture,
        [string]$Tag,
        [bool]$RecOn,
        [string]$Time
    )
    Clear-Host
    $w = $InnerW
    $bar = '=' * $w
    Write-Host ("  ." + $bar + ".") -ForegroundColor DarkGray

    $rec = if ($RecOn) { '(o REC)' } else { '(  REC)' }
    $left = ' ' + $rec + '  ' + $Tag
    $time = $Time + ' '
    $header = (PadR $left ($w - $time.Length)) + $time

    Write-Host '  |' -NoNewline -ForegroundColor DarkGray
    # color the REC dot red, the rest dim
    $idx = $header.IndexOf('o')
    if ($RecOn -and $idx -ge 0) {
        Write-Host $header.Substring(0, $idx) -NoNewline -ForegroundColor Gray
        Write-Host 'o' -NoNewline -ForegroundColor Red
        Write-Host $header.Substring($idx + 1) -NoNewline -ForegroundColor Gray
    } else {
        Write-Host $header -NoNewline -ForegroundColor Gray
    }
    Write-Host '|' -ForegroundColor DarkGray
    Write-Host ("  |" + ('-' * $w) + "|") -ForegroundColor DarkGray

    foreach ($line in $Picture) {
        Write-Host '  |' -NoNewline -ForegroundColor DarkGray
        Write-Host (Center $line $w) -NoNewline -ForegroundColor Yellow
        Write-Host '|' -ForegroundColor DarkGray
    }

    Write-Host ("  '" + $bar + "'") -ForegroundColor DarkGray
}

# Lower-third caption block. Name printed instantly, quote typed out.
function Lower-Third {
    param([string]$Name, [string]$Title, [string]$Quote, [ConsoleColor]$QColor = 'White')
    $w = $InnerW
    Write-Host ''
    Write-Host ("   " + ('_' * ($w - 1))) -ForegroundColor DarkGray
    Write-Host '  >> ' -NoNewline -ForegroundColor DarkCyan
    Write-Host $Name -NoNewline -ForegroundColor Cyan
    if ($Title) {
        Write-Host '  .  ' -NoNewline -ForegroundColor DarkGray
        Write-Host $Title -ForegroundColor DarkCyan
    } else { Write-Host '' }
    Write-Host '  >> ' -NoNewline -ForegroundColor DarkCyan
    Write-Slow $Quote $QColor
    Write-Host ("   " + ('~' * ($w - 1))) -ForegroundColor DarkGray
}

# ----- portraits (deadpan talking heads) ------------------------------------
$Portraits = @{
    greg = @(
        '      ___________      ',
        '     / _________ \     ',
        '    | / GREG    \ |    ',
        '    | |  -   -  | |    ',
        '    | |    >    | |    ',
        '    | |  \___/  | |    ',
        '    | \_________/ |    ',
        '     \___________/     ',
        '      /| collar |\     ',
        '       _[o]_           ',
        '      |     |          ',
        '      |_____|          '
    )
    diane = @(
        '       .-------.       ',
        '      / ~     ~ \      ',
        '     |  .     .  |     ',
        '     |     |     |     ',
        '     |   -----   |     ',
        '     |  (tired)  |     ',
        '      \_________/      ',
        '       | | | | |       ',
        '     done. so done.    ',
        '       _[o]_           ',
        '      |     |          ',
        '      |_____|          '
    )
    kevin = @(
        '       _________       ',
        '      /  KEVIN  \      ',
        '     | ^       ^ |     ',
        '     |  O     O  |     ',
        '     |     v     |     ',
        '     |   \___/   |     ',
        '      \_________/      ',
        '       /lanyard\       ',
        '      [ INTERN ]       ',
        '       _[o]_           ',
        '      |     |          ',
        '      |_____|          '
    )
    martha = @(
        '      .---------.      ',
        '     / MARTHA,HR \     ',
        '    |  =       =  |    ',
        '    |   .  |  .   |    ',
        '    |   |     |   |    ',
        '    |   `-----`   |    ',
        '     \___________/     ',
        '      |I|S|E|E|U|      ',
        '    (this is logged)   ',
        '       _[o]_           ',
        '      |     |          ',
        '      |_____|          '
    )
    todd = @(
        '       _________       ',
        '      / T O D D \      ',
        '     | \       / |     ',
        '     |  -     -  |     ',
        '     |     L     |     ',
        '     |   \___/   |     ',  # the closer's smirk
        '      \_________/      ',
        '       |  SALES |       ',
        '     ($) always be ($) ',
        '       _[o]_           ',
        '      |     |          ',
        '      |_____|          '
    )
}

# ----- the office wide-shot --------------------------------------------------
$OfficeShot = @(
    '  ____________________________________________ ',
    ' |  []   THE OPEN PLAN   []     o open o plan  |',
    ' |   __        __        __        __          |',
    ' |  |GG|      |DD|      |KK|      |TT|          |',
    ' | (-  -)    (~  ~)    (O  O)    (-  -)         |',
    ' |  /|\       /|\       /|\       /|\           |',
    ' |__[==]______[==]______[==]______[==]_________ |',
    ' |  jira       11yrs     unpaid     "synergy"   |',
    ' |______________ standup in 5 min ______________|'
)

# ----- close-up used for the "deadpan into camera" sting --------------------
$CameraStare = @(
    '                               ',
    '          .-----------.        ',
    '         |  -       -  |       ',
    '         |      |      |       ',
    '         |    -----    |       ',
    '          `-----------`        ',
    '     [ stares into the lens ]  ',
    '                               '
)

# ----- content pools ---------------------------------------------------------
# Confessionals: name, title, portrait key, color, and a snark line.
$Confessionals = @(
    @{ n='GREG';   t='Regional Manager';  p='greg';   c='White'; q='People say I am hard to work for. People also say a lot of things in their exit interviews.' },
    @{ n='DIANE';  t='Senior Engineer';   p='diane';  c='Gray';  q='They asked me to "quickly sync." That was ninety minutes ago. I have aged.' },
    @{ n='KEVIN';  t='Intern (Unpaid)';   p='kevin';  c='White'; q='Greg says exposure pays better than money. I checked. It does not.' },
    @{ n='MARTHA'; t='Human Resources';   p='martha'; c='Gray';  q='There is no I in team. There is a U in "I am watching you."' },
    @{ n='TODD';   t='Sales';             p='todd';   c='White'; q='I closed a huge deal today. With myself. I am my own biggest client now.' },
    @{ n='DIANE';  t='Senior Engineer';   p='diane';  c='Gray';  q='I came in to fix one bug eleven years ago. I am the bug now.' },
    @{ n='GREG';   t='Regional Manager';  p='greg';   c='White'; q='I do not micromanage. I "stay deeply, personally involved in your every keystroke."' },
    @{ n='MARTHA'; t='Human Resources';   p='martha'; c='Gray';  q='We did a trust fall Friday. Nobody caught Brian. We are calling it a learning.' },
    @{ n='KEVIN';  t='Intern (Unpaid)';   p='kevin';  c='White'; q='I asked where the bathroom was on day one. They put it in the backlog.' },
    @{ n='TODD';   t='Sales';             p='todd';   c='White'; q='I do not lie. I optimistically pre-confirm.' }
)

# Office scenes: a couple of lines of action, then someone turns to the lens.
$Scenes = @(
    @{ tag='SCENE 1 - STANDUP';      lines=@(
        @{ n='GREG';  t='Regional Manager'; q='Great standup! Let us circle back, take it offline, AND put a pin in it.' },
        @{ n='DIANE'; t='Senior Engineer';  q='...That is three different places to put one idea.' }
    ) },
    @{ tag='SCENE 2 - THE FRIDGE';   lines=@(
        @{ n='TODD';  t='Sales';            q='Whoever took my LABELED yogurt: I will find you. I am in SALES.' },
        @{ n='KEVIN'; t='Intern (Unpaid)';  q='It was Greg. To camera: it is always Greg.' }
    ) },
    @{ tag='SCENE 3 - main BRANCH';  lines=@(
        @{ n='DIANE'; t='Senior Engineer';  q='Someone force-pushed to main. Again.' },
        @{ n='GREG';  t='Regional Manager'; q='Is that bad? It sounds productive. Very forward. Very push.' }
    ) },
    @{ tag='SCENE 4 - THE OFFSITE';  lines=@(
        @{ n='MARTHA';t='Human Resources';  q='The team-building escape room. We have been "escaping" since 9am.' },
        @{ n='DIANE'; t='Senior Engineer';  q='The exit was unlocked. I just did not want to go back to work.' }
    ) },
    @{ tag='SCENE 5 - REPLY ALL';    lines=@(
        @{ n='KEVIN'; t='Intern (Unpaid)';  q='I hit reply-all on the all-hands. To four thousand people. Including the CEO.' },
        @{ n='TODD';  t='Sales';            q='Honestly? Best lead gen weve had all quarter. Forward it again.' }
    ) }
)

# ----- scene renderers -------------------------------------------------------
function Show-TitleCard {
    Clear-Host
    Write-Host ''
    Write-Host '        _____ _   _ _____    ___  ____  _____ _   _ ' -ForegroundColor Cyan
    Write-Host '       |_   _| | | | ____|  / _ \|  _ \| ____| \ | |' -ForegroundColor Cyan
    Write-Host '         | | | |_| |  _|   | | | | |_) |  _| |  \| |' -ForegroundColor Cyan
    Write-Host '         | | |  _  | |___  | |_| |  __/| |___| |\  |' -ForegroundColor DarkCyan
    Write-Host '         |_| |_| |_|_____|  \___/|_|   |_____|_| \_|' -ForegroundColor DarkCyan
    Write-Host ''
    Write-Host '             P   L   A   N' -ForegroundColor Yellow
    Write-Host ''
    Write-Host '          an office mockumentary in one (1) terminal' -ForegroundColor DarkGray
    Write-Host '          ----------------------------------------' -ForegroundColor DarkGray
    Write-Host '          filmed before a studio audience of no one' -ForegroundColor DarkGray
    Write-Host ''
    Pause ($Hold + 600)
}

function Blink-Rec {
    param([string[]]$Picture, [string]$Tag, [System.Diagnostics.Stopwatch]$Sw, [int]$Times = 3)
    for ($i = 0; $i -lt $Times; $i++) {
        Draw-Tv -Picture $Picture -Tag $Tag -RecOn $true  -Time (Tc $Sw); Pause 280
        Draw-Tv -Picture $Picture -Tag $Tag -RecOn $false -Time (Tc $Sw); Pause 220
    }
    Draw-Tv -Picture $Picture -Tag $Tag -RecOn $true -Time (Tc $Sw)
}

function Play-Confessional {
    param([hashtable]$C, [System.Diagnostics.Stopwatch]$Sw)
    $art = $Portraits[$C.p]
    Blink-Rec -Picture $art -Tag 'CONFESSIONAL' -Sw $Sw -Times 2
    Pause $Beat
    Lower-Third -Name $C.n -Title $C.t -Quote $C.q -QColor $C.c
    Pause $Hold
    # the trademark stare
    Draw-Tv -Picture $CameraStare -Tag 'CONFESSIONAL' -RecOn $true -Time (Tc $Sw)
    Pause ([int]($Hold * 0.8))
}

function Play-DeadpanSting {
    param([System.Diagnostics.Stopwatch]$Sw)
    Draw-Tv -Picture $CameraStare -Tag 'B-ROLL' -RecOn $true -Time (Tc $Sw)
    Write-Host ''
    Write-Host '  >> ' -NoNewline -ForegroundColor DarkCyan
    Write-Slow '[ deadpans directly into the camera ]' DarkGray
    Pause $Hold
}

function Play-Scene {
    param([hashtable]$Scene, [System.Diagnostics.Stopwatch]$Sw)
    Blink-Rec -Picture $OfficeShot -Tag $Scene.tag -Sw $Sw -Times 1
    Pause $Beat
    foreach ($l in $Scene.lines) {
        Draw-Tv -Picture $OfficeShot -Tag $Scene.tag -RecOn $true -Time (Tc $Sw)
        Lower-Third -Name $l.n -Title $l.t -Quote $l.q
        Pause $Beat
    }
    Play-DeadpanSting -Sw $Sw   # the ~10s deadpan, guaranteed once per scene
}

function Show-SignOff {
    param([System.Diagnostics.Stopwatch]$Sw)
    Draw-Tv -Picture @(
        '                               ',
        '      ~  END  OF  EPISODE  ~    ',
        '                               ',
        '   no staplers were promoted   ',
        '     during this production    ',
        '                               ',
        '   next week: the printer wins  ',
        '                               '
    ) -Tag 'THAT IS A WRAP' -RecOn $false -Time (Tc $Sw)
    Write-Host ''
    Write-Host '  >> ' -NoNewline -ForegroundColor DarkCyan
    Write-Slow 'Roll credits. Slowly. Like everything else here.' DarkGray
    Pause $Hold
}

# ----- the broadcast ---------------------------------------------------------
function Invoke-Episode {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $confIdx = 0
    $lastConf = 0.0

    Show-TitleCard

    # Open on a confessional, because of course it does.
    Play-Confessional -C $Confessionals[$confIdx] -Sw $sw
    $confIdx = ($confIdx + 1) % $Confessionals.Count
    $lastConf = $sw.Elapsed.TotalSeconds

    foreach ($scene in $Scenes) {
        Play-Scene -Scene $scene -Sw $sw

        # Every ~10 seconds, cut to someone deadpanning into the camera.
        if (($sw.Elapsed.TotalSeconds - $lastConf) -ge 10) {
            Play-Confessional -C $Confessionals[$confIdx] -Sw $sw
            $confIdx = ($confIdx + 1) % $Confessionals.Count
            $lastConf = $sw.Elapsed.TotalSeconds
        }
    }

    # One more for the road.
    Play-Confessional -C $Confessionals[$confIdx] -Sw $sw
    Show-SignOff -Sw $sw
    $sw.Stop()
}

# ----- run it ----------------------------------------------------------------
try {
    try { [Console]::CursorVisible = $false } catch { }
    do {
        Invoke-Episode
    } while ($Forever)
}
finally {
    try { [Console]::CursorVisible = $true } catch { }
    Write-Host ''
    Write-Host 'Fin. (Press up-arrow and run it again. You know you want to.)' -ForegroundColor DarkGray
}
