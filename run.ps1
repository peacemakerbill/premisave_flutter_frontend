<#
.SYNOPSIS
  Premisave launcher for Windows. Asks where to run the app, then runs it.

.DESCRIPTION
  .\run.bat                         double click or type it, picks from menus
  .\run.ps1 -Platform windows       skip the platform menu
  .\run.ps1 -Device emulator-5554 -Env development.local -Mode debug
  .\run.ps1 -Devices                list what Flutter can see

  Works in Windows PowerShell 5.1 and PowerShell 7. Needs only Flutter on the PATH.
  Anything after -- goes straight to flutter run.

.PARAMETER Platform  web, windows, android, ios, web-server (linux and macos on those computers)
.PARAMETER Device    a device id from `flutter devices`
.PARAMETER Env       a file in config\env, with or without .json
.PARAMETER Mode      debug, profile or release
.PARAMETER Port      web port, default 3000 (the sign in callback uses 3000)
.PARAMETER Yes       take the first choice for anything not given, ask nothing
.PARAMETER Quick     skip the animation
#>
param(
  [string]$Platform = '',
  [string]$Device = '',
  [string]$Env = $env:APP_ENV,
  [string]$Mode = '',
  [int]$Port = 3000,
  [switch]$Yes,
  [switch]$Quick,
  [switch]$Devices,
  [switch]$Doctor,
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Extra = @()
)

$ErrorActionPreference = 'Continue'
Set-Location -LiteralPath $PSScriptRoot
if ($Extra.Count -gt 0 -and $Extra[0] -eq '--') { $Extra = @($Extra | Select-Object -Skip 1) }

# ---------------------------------------------------------------------------
# Terminal: ANSI colour needs virtual terminal processing on older consoles
# ---------------------------------------------------------------------------
$ESC = [char]27
$Interactive = $true
try { if ([Console]::IsInputRedirected -or [Console]::IsOutputRedirected) { $Interactive = $false } } catch { $Interactive = $false }

$UseColor = $Interactive -and -not $env:NO_COLOR
if ($UseColor -and -not $env:WT_SESSION -and $env:TERM_PROGRAM -ne 'vscode') {
  try {
    Add-Type -Namespace Premisave -Name Vt -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("kernel32.dll")] public static extern System.IntPtr GetStdHandle(int h);
[System.Runtime.InteropServices.DllImport("kernel32.dll")] public static extern bool GetConsoleMode(System.IntPtr h, out uint m);
[System.Runtime.InteropServices.DllImport("kernel32.dll")] public static extern bool SetConsoleMode(System.IntPtr h, uint m);
'@ -ErrorAction Stop
    $h = [Premisave.Vt]::GetStdHandle(-11)
    $m = 0
    if ([Premisave.Vt]::GetConsoleMode($h, [ref]$m)) {
      if (-not [Premisave.Vt]::SetConsoleMode($h, $m -bor 4)) { $UseColor = $false }
    } else { $UseColor = $false }
  } catch { $UseColor = $false }
}
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }

$Animate = $UseColor -and -not $Quick -and -not $Yes -and -not $env:PREMISAVE_QUICK
$Cols = 80; $Rows = 30
try { $Cols = [Console]::WindowWidth; $Rows = [Console]::WindowHeight } catch { }
if ($Cols -lt 20) { $Cols = 80 }
if ($Rows -lt 5) { $Rows = 30 }

function Fg([int]$r, [int]$g, [int]$b) { if ($UseColor) { return "$ESC[38;2;$r;$g;${b}m" } else { return '' } }
function Bg([int]$r, [int]$g, [int]$b) { if ($UseColor) { return "$ESC[48;2;$r;$g;${b}m" } else { return '' } }

$RST = ''; $BOLD = ''
if ($UseColor) { $RST = "$ESC[0m"; $BOLD = "$ESC[1m" }
$DIM  = Fg 138 134 168
$GOLD = Fg 245 182 66
$OKC  = Fg 80 220 150
$WARNC = Fg 255 190 80
$ERRC = Fg 255 100 115
$INKC = Fg 24 20 52
$C_ROOF = Bg 245 182 66
$C_WALL = Bg 74 63 219
$C_WON  = (Bg 74 63 219) + (Fg 255 214 120)
$C_WOFF = (Bg 74 63 219) + (Fg 52 44 160)

# characters are built from code points so the file stays plain ASCII
function U([int]$code) { return [string][char]$code }
$S_OK = U 0x2714; $S_ERR = U 0x2718; $S_PTR = U 0x276F; $S_DOT = U 0x2022
$S_WIN = U 0x25AA; $S_STAR = U 0xB7; $S_BARL = U 0x2500; $FULL = U 0x2588
$SpinFrames = @((U 0x280B), (U 0x2819), (U 0x2839), (U 0x2838), (U 0x283C), (U 0x2834), (U 0x2826), (U 0x2827), (U 0x2807), (U 0x280F))

function Out-Raw([string]$s) { [Console]::Out.Write($s) }
function Say([string]$s = '') { Out-Raw ($s + "`n") }
function Info([string]$s) { Say "  $(Fg 150 130 255)$S_DOT$RST $s" }
function Good([string]$s) { Say "  $OKC$S_OK$RST $s" }
function Warn([string]$s) { Say "  $WARNC!$RST $s" }
function Fail([string]$s) { Say "  $ERRC$S_ERR$RST $s" }
# the cursor is hidden and line wrap is off while a menu is on screen
function HideCursor { if ($Interactive -and $UseColor) { Out-Raw "$ESC[?25l$ESC[?7l" } }
function ShowCursor { if ($Interactive -and $UseColor) { Out-Raw "$ESC[?25h$ESC[?7h" } }
function Rule {
  $w = [Math]::Min($Cols - 2, 70)
  Say "  $DIM$($S_BARL * $w)$RST"
}

# ---------------------------------------------------------------------------
# Splash
# ---------------------------------------------------------------------------
# The wordmark is drawn from a small bitmap, so this file stays plain ASCII.
$Bitmap = @{
  'P' = @('1111 ', '1  11', '1111 ', '1    ', '1    ')
  'R' = @('1111 ', '1  11', '1111 ', '1  11', '1   1')
  'E' = @('11111', '1    ', '1111 ', '1    ', '11111')
  'M' = @('1   1', '11 11', '1 1 1', '1   1', '1   1')
  'I' = @('111', ' 1 ', ' 1 ', ' 1 ', '111')
  'S' = @(' 1111', '1    ', ' 111 ', '    1', '1111 ')
  'A' = @(' 111 ', '1   1', '11111', '1   1', '1   1')
  'V' = @('1   1', '1   1', '1   1', ' 1 1 ', '  1  ')
}
function Build-Logo {
  $rows = @('', '', '', '', '')
  foreach ($ch in 'PREMISAVE'.ToCharArray()) {
    $g = $Bitmap[[string]$ch]
    for ($r = 0; $r -lt 5; $r++) {
      $rows[$r] += $g[$r].Replace('1', $FULL) + ' '
    }
  }
  return $rows
}
$Logo = Build-Logo
$LogoW = $Logo[0].Length

function Grad([int]$x, [int]$w) {
  $t = [int](($x * 200) / [Math]::Max(1, $w - 1))
  if ($t -lt 100) {
    $r = 245 + [int]((255 - 245) * $t / 100); $g = 182 + [int]((112 - 182) * $t / 100); $b = 66 + [int]((130 - 66) * $t / 100)
  } else {
    $s = $t - 100
    $r = 255 + [int]((140 - 255) * $s / 100); $g = 112 + [int]((110 - 112) * $s / 100); $b = 130 + [int]((255 - 130) * $s / 100)
  }
  return (Fg $r $g $b)
}
$LogoCol = @(); for ($x = 0; $x -lt $LogoW; $x++) { $LogoCol += (Grad $x $LogoW) }

function Draw-Logo([int]$cols) {
  $sb = New-Object System.Text.StringBuilder
  foreach ($line in $Logo) {
    [void]$sb.Append('  ')
    $n = [Math]::Min($cols, $line.Length)
    for ($x = 0; $x -lt $n; $x++) { [void]$sb.Append($LogoCol[$x]).Append($line[$x]) }
    [void]$sb.Append($RST).Append("$ESC[K`n")
  }
  Out-Raw $sb.ToString()
}

$SkW = 0; $SkH = 7
$script:SkHeight = @(); $script:SkStart = @(); $script:SkEnd = @(); $script:SkLit = @(); $script:SkStar = @()
function Build-City {
  $script:SkW = [Math]::Min($Cols - 4, $LogoW)
  $w = $script:SkW
  $script:SkHeight = New-Object int[] $w; $script:SkStart = New-Object int[] $w; $script:SkEnd = New-Object int[] $w
  $x = 0
  while ($x -lt $w) {
    $bw = 4 + (Get-Random -Maximum 5); $bh = 2 + (Get-Random -Maximum ($SkH - 1))
    if ($x + $bw -gt $w) { $bw = $w - $x }
    for ($i = $x; $i -lt $x + $bw; $i++) { $script:SkHeight[$i] = $bh; $script:SkStart[$i] = $x; $script:SkEnd[$i] = $x + $bw - 1 }
    $x += $bw
    if ((Get-Random -Maximum 3) -eq 0) { $x++ }
  }
  $script:SkLit = New-Object int[] ($w * $SkH); $script:SkStar = New-Object int[] ($w * $SkH)
  for ($i = 0; $i -lt $w * $SkH; $i++) {
    if ((Get-Random -Maximum 100) -lt 42) { $script:SkLit[$i] = 1 }
    if ((Get-Random -Maximum 100) -lt 4) { $script:SkStar[$i] = 1 }
  }
}
function Draw-City([int]$p) {
  $w = $script:SkW
  $sb = New-Object System.Text.StringBuilder
  for ($r = $SkH - 1; $r -ge 0; $r--) {
    [void]$sb.Append('  ')
    for ($x = 0; $x -lt $w; $x++) {
      $h = $script:SkHeight[$x]; $vis = [int][Math]::Floor(($h * $p + 99) / 100); $idx = $r * $w + $x
      if ($r -lt $vis) {
        $rel = $x - $script:SkStart[$x]
        if ($r -eq $h - 1 -and $vis -ge $h) { [void]$sb.Append($C_ROOF).Append(' ') }
        elseif (($rel % 2) -eq 1 -and ($r % 2) -eq 1 -and $x -lt $script:SkEnd[$x] -and $r -gt 0) {
          if ($script:SkLit[$idx] -eq 1) { [void]$sb.Append($C_WON) } else { [void]$sb.Append($C_WOFF) }
          [void]$sb.Append($S_WIN)
        } else { [void]$sb.Append($C_WALL).Append(' ') }
        [void]$sb.Append($RST)
      } elseif ($script:SkStar[$idx] -eq 1 -and $r -gt 2) { [void]$sb.Append($DIM).Append($S_STAR).Append($RST) }
      else { [void]$sb.Append(' ') }
    }
    [void]$sb.Append("$ESC[K`n")
  }
  Out-Raw $sb.ToString()
}
function Twinkle {
  $n = [int]($script:SkW * $SkH / 9)
  for ($k = 0; $k -lt $n; $k++) { $i = Get-Random -Maximum ($script:SkW * $SkH); $script:SkLit[$i] = 1 - $script:SkLit[$i] }
}

function Show-Splash {
  $ver = ''
  try { $m = Select-String -Path 'pubspec.yaml' -Pattern '^version:\s*(.+)$' | Select-Object -First 1; if ($m) { $ver = 'v' + $m.Matches[0].Groups[1].Value.Trim() } } catch { }
  if ($Animate -and $Cols -ge 76 -and $Rows -ge 26) {
    HideCursor
    Build-City
    Say ''
    foreach ($p in 0, 14, 28, 42, 56, 70, 84, 100) {
      if ($p -gt 0) { Out-Raw "$ESC[${SkH}A" }
      Draw-City $p; Start-Sleep -Milliseconds 45
    }
    for ($t = 0; $t -lt 6; $t++) { Twinkle; Out-Raw "$ESC[${SkH}A"; Draw-City 100; Start-Sleep -Milliseconds 90 }
    for ($c = 0; $c -le $LogoW; $c += 5) {
      if ($c -gt 0) { Out-Raw "$ESC[5A" }
      Draw-Logo $c; Start-Sleep -Milliseconds 20
    }
    Out-Raw "$ESC[5A"; Draw-Logo $LogoW
    ShowCursor
  } elseif ($UseColor -and $Cols -ge 76) {
    Say ''; Draw-Logo $LogoW
  } else {
    Say ''; Say '  P R E M I S A V E'
  }
  Say ''
  Say "  $BOLD$(('Find it. Rent it. Pay for it. All in one app.'))$RST"
  Say "  $DIM$('Flutter app ' + $ver)$RST"
  Say ''
}

# ---------------------------------------------------------------------------
# Menu
# ---------------------------------------------------------------------------
# each item: @{ Label; Hint; On; Head; Tag }
function New-Item($label, $hint = '', $on = $true, $tag = '') { return @{ Label = $label; Hint = $hint; On = $on; Head = $false; Tag = $tag } }
function New-Head($label) { return @{ Label = $label; Hint = ''; On = $false; Head = $true; Tag = '' } }

function Draw-Menu($items, [int]$cur) {
  $sb = New-Object System.Text.StringBuilder
  $num = 0
  for ($i = 0; $i -lt $items.Count; $i++) {
    $it = $items[$i]
    if ($it.Head) { [void]$sb.Append("  $DIM$($it.Label)$RST$ESC[K`n"); continue }
    if ($it.On) {
      $num++
      $tag = '  '; if ($num -le 9) { $tag = "$num " }
      if ($i -eq $cur) {
        [void]$sb.Append("  $GOLD$S_PTR$RST $GOLD$tag$RST$BOLD$($it.Label)$RST")
      } else {
        [void]$sb.Append("    $DIM$tag$RST$($it.Label)")
      }
      if ($it.Hint) { [void]$sb.Append("  $DIM$($it.Hint)$RST") }
    } else {
      [void]$sb.Append("    $DIM  $($it.Label)  $($it.Hint)$RST")
    }
    [void]$sb.Append("$ESC[K`n")
  }
  Out-Raw $sb.ToString()
}
function Step-Menu($items, [int]$cur, [int]$dir) {
  $n = $items.Count; $nxt = $cur
  for ($k = 0; $k -lt $n; $k++) { $nxt = ($nxt + $dir + $n) % $n; if ($items[$nxt].On) { return $nxt } }
  return $cur
}
function Nth-Item($items, [int]$nth) {
  $c = 0
  for ($i = 0; $i -lt $items.Count; $i++) { if ($items[$i].On) { $c++; if ($c -eq $nth) { return $i } } }
  return -1
}
function First-Item($items) { for ($i = 0; $i -lt $items.Count; $i++) { if ($items[$i].On) { return $i } }; return 0 }

# Returns the index of the chosen item.
function Choose($title, $items) {
  $n = $items.Count
  $cur = First-Item $items
  Say "  $BOLD$title$RST"
  if (-not $Interactive -or ($n + 4) -gt $Rows) {
    $num = 0
    foreach ($it in $items) {
      if ($it.Head) { Say "      $($it.Label)" }
      elseif ($it.On) { $num++; Say ('    {0,2}  {1}  {2}' -f $num, $it.Label, $it.Hint) }
      else { Say "        $($it.Label)  $($it.Hint)" }
    }
    while ($true) {
      $a = Read-Host '  Number (Enter for 1, q to quit)'
      if ([string]::IsNullOrWhiteSpace($a) -or $a -eq '1') { return (First-Item $items) }
      if ($a -match '^[qQ]$') { Say "  ${DIM}See you soon.$RST"; exit 0 }
      if ($a -match '^\d+$') { $hit = Nth-Item $items ([int]$a); if ($hit -ge 0) { return $hit } }
    }
  }
  $help = "  ${DIM}up and down to move, Enter to pick, q to quit$RST"
  HideCursor
  try {
    Draw-Menu $items $cur; Out-Raw $help
    while ($true) {
      $k = [Console]::ReadKey($true)
      $done = $false
      switch ($k.Key) {
        'UpArrow'   { $cur = Step-Menu $items $cur -1 }
        'DownArrow' { $cur = Step-Menu $items $cur 1 }
        'Home'      { $cur = First-Item $items }
        'Enter'     { $done = $true }
        'Q'         { Out-Raw "`r$ESC[K$ESC[${n}A$ESC[J"; ShowCursor; Say "  ${DIM}See you soon.$RST"; exit 0 }
        default {
          if ($k.KeyChar -ge '1' -and $k.KeyChar -le '9') {
            $hit = Nth-Item $items ([int][string]$k.KeyChar)
            if ($hit -ge 0) { $cur = $hit; $done = $true }
          } elseif ($k.KeyChar -eq 'k') { $cur = Step-Menu $items $cur -1 }
          elseif ($k.KeyChar -eq 'j') { $cur = Step-Menu $items $cur 1 }
        }
      }
      if ($done) { break }
      Out-Raw "`r$ESC[K$ESC[${n}A"; Draw-Menu $items $cur; Out-Raw $help
    }
    # wipe the help line, the menu and the title
    Out-Raw "`r$ESC[K$ESC[${n}A$ESC[J$ESC[1A$ESC[J"
  } finally { ShowCursor }
  return $cur
}

# ---------------------------------------------------------------------------
# Devices
# ---------------------------------------------------------------------------
function Test-Flutter { return [bool](Get-Command flutter -ErrorAction SilentlyContinue) }

function Invoke-Spin([string]$message, [scriptblock]$work) {
  if (-not $Interactive) { Info $message; return (& $work) }
  $job = Start-Job -ScriptBlock $work
  $i = 0
  HideCursor
  while ($job.State -eq 'Running') {
    Out-Raw ("`r  $GOLD{0}$RST {1}$ESC[K" -f $SpinFrames[$i % $SpinFrames.Count], $message)
    $i++; Start-Sleep -Milliseconds 80
  }
  $out = Receive-Job $job; Remove-Job $job -Force
  Out-Raw "`r$ESC[K"; ShowCursor
  return $out
}

function Get-Plat([string]$t) {
  $t = "$t".ToLower()
  foreach ($p in 'android', 'ios', 'darwin', 'linux', 'windows', 'web') { if ($t.StartsWith($p)) { if ($p -eq 'darwin') { return 'macos' } else { return $p } } }
  return 'other'
}

function Load-Devices {
  $text = (Invoke-Spin 'Looking for devices' { & flutter devices --machine 2>$null }) | Out-String
  $list = @()
  $i = $text.IndexOf('[')
  if ($i -ge 0) {
    try {
      $data = $text.Substring($i) | ConvertFrom-Json
      foreach ($d in @($data)) {
        $list += [pscustomobject]@{ Id = $d.id; Name = $d.name; Plat = (Get-Plat $d.targetPlatform); Emu = [bool]$d.emulator }
      }
    } catch { }
  }
  return $list
}

function Get-Badge([string]$plat, [bool]$emu) {
  $label = ' OTHER '; $c = 170, 170, 190
  switch ($plat) {
    'web'     { $label = ' WEB ';     $c = 66, 165, 245 }
    'linux'   { $label = ' LINUX ';   $c = 250, 204, 21 }
    'windows' { $label = ' WINDOWS '; $c = 0, 164, 239 }
    'macos'   { $label = ' MACOS ';   $c = 205, 205, 220 }
    'android' { $label = ' ANDROID '; $c = 61, 220, 132 }
    'ios'     { $label = ' IOS ';     $c = 190, 150, 255 }
  }
  if ($emu) { $label = ' EMULATOR '; $c = 255, 150, 120 }
  if (-not $UseColor) { return '[' + $label.Trim() + ']' }
  return (Bg $c[0] $c[1] $c[2]) + $INKC + $BOLD + $label + $RST
}

function Sort-Devices($devs) {
  $rank = { param($d)
    switch ($d.Plat) {
      { $_ -in 'android', 'ios' } { if ($d.Emu) { return 1 } else { return 0 } }
      { $_ -in 'linux', 'windows', 'macos' } { return 2 }
      'web' { if ($d.Id -eq 'web-server') { return 4 } else { return 3 } }
      default { return 4 }
    }
  }
  return @($devs | Sort-Object { & $rank $_ })
}

function Start-Emulator {
  $text = (Invoke-Spin 'Listing emulators' { & flutter emulators 2>$null }) | Out-String
  $emus = @()
  foreach ($line in ($text -split "`r?`n")) {
    $parts = $line -split ' [\u2022*] '
    if ($parts.Count -ge 3 -and $parts[0].Trim() -ne 'Id' -and $parts[0].Trim() -notmatch '\s') {
      $emus += [pscustomobject]@{ Id = $parts[0].Trim(); Name = $parts[1].Trim() }
    }
  }
  if ($emus.Count -eq 0) {
    Warn 'No emulators or simulators are set up.'
    Say '    Android: open Android Studio, Device Manager, Create device.'
    Read-Host "  ${DIM}Press Enter to go back${RST}" | Out-Null
    return
  }
  $items = @(); foreach ($e in $emus) { $items += (New-Item $e.Name $e.Id) }
  $items += (New-Item 'Back')
  $pick = Choose 'Which one should start?' $items
  if ($pick -ge $emus.Count) { return }
  $e = $emus[$pick]
  $before = (Load-Devices).Count
  Info "Starting $($e.Name)"
  & flutter emulators --launch $e.Id 2>&1 | Out-Null
  for ($t = 0; $t -lt 20; $t++) {
    Invoke-Spin 'Waiting for it to finish booting' { Start-Sleep -Seconds 3 } | Out-Null
    if ((Load-Devices).Count -gt $before) { break }
  }
}

function Select-Platform {
  $devs = Sort-Devices (Load-Devices)
  while ($true) {
    $items = @(); $map = @()
    $seen = @{}
    if ($devs.Count -gt 0) {
      $items += (New-Head 'Ready to run')
      foreach ($d in $devs) {
        $items += (New-Item ("$(Get-Badge $d.Plat $d.Emu) $($d.Name)") $d.Id)
        $map += ,@('dev', $d); $seen[$d.Plat] = $true
      }
    }
    $missing = @()
    if (-not $seen['android']) { $missing += , @('android', 'Phone or emulator', 'plug in a phone with USB debugging, or start an emulator below') }
    if (-not $seen['ios'])     { $missing += , @('ios', 'iPhone or simulator', 'needs a Mac') }
    if (-not $seen['macos'])   { $missing += , @('macos', 'macOS desktop', 'needs a Mac') }
    if (-not $seen['windows']) { $missing += , @('windows', 'Windows desktop', 'run: flutter config --enable-windows-desktop') }
    if (-not $seen['linux'])   { $missing += , @('linux', 'Linux desktop', 'needs a Linux PC') }
    if (-not $seen['web'])     { $missing += , @('web', 'Browser', 'run: flutter config --enable-web, and install Chrome or Edge') }
    if ($missing.Count -gt 0) {
      $items += (New-Head 'Not ready on this computer')
      foreach ($m in $missing) { $items += (New-Item ("$(Get-Badge $m[0] $false) $($m[1])") $m[2] $false); $map += ,@('x', $null) }
    }
    $items += (New-Head 'More')
    $items += (New-Item 'Start an emulator'); $map += ,@('emu', $null)
    $items += (New-Item 'Look for devices again'); $map += ,@('refresh', $null)
    $items += (New-Item 'Check my setup with flutter doctor'); $map += ,@('doctor', $null)
    $items += (New-Item 'Quit'); $map += ,@('quit', $null)

    $pick = Choose 'Where do you want to run Premisave?' $items
    $k = 0; $target = $null
    for ($j = 0; $j -lt $items.Count; $j++) {
      if ($items[$j].Head) { continue }
      if ($j -eq $pick) { $target = $map[$k]; break }
      $k++
    }
    switch ($target[0]) {
      'dev'     { return $target[1] }
      'emu'     { Start-Emulator; $devs = Sort-Devices (Load-Devices) }
      'refresh' { $devs = Sort-Devices (Load-Devices) }
      'doctor'  { Say ''; & flutter doctor; Read-Host "`n  ${DIM}Press Enter to go back${RST}" | Out-Null }
      'quit'    { Say "  ${DIM}See you soon.$RST"; exit 0 }
    }
  }
}

# ---------------------------------------------------------------------------
# Environment and mode
# ---------------------------------------------------------------------------
$EnvDir = 'config/env'
function Select-Env {
  $names = @()
  foreach ($w in @($Env, 'development.local', 'development', 'staging', 'production')) {
    if (-not $w) { continue }
    $w = $w -replace '\.json$', ''
    if ((Test-Path "$EnvDir/$w.json") -and ($names -notcontains $w)) { $names += $w }
  }
  Get-ChildItem -Path $EnvDir -Filter '*.json' -ErrorAction SilentlyContinue | ForEach-Object {
    $n = $_.BaseName; if ($names -notcontains $n) { $names += $n }
  }
  if ($names.Count -eq 0) { Fail "No environment files found in $EnvDir."; exit 1 }
  if ($Env) {
    $e = $Env -replace '\.json$', ''
    if (-not (Test-Path "$EnvDir/$e.json")) { Fail "There is no $EnvDir\$e.json. Available: $($names -join ', ')"; exit 1 }
    return $e
  }
  if ($Yes -or $names.Count -eq 1) { return $names[0] }
  $items = @()
  foreach ($n in $names) {
    $url = ''
    try { $url = (Get-Content "$EnvDir/$n.json" -Raw | ConvertFrom-Json).BASE_URL } catch { }
    if (-not $url) { $hint = 'auth-service on this computer, port 8080' }
    elseif ($url -match 'example') { $hint = "${WARNC}placeholder address, put the real one in first$RST$DIM" }
    else { $hint = $url }
    if ($n -like '*.local') { $hint += '   private, git ignores it' }
    $items += (New-Item $n $hint)
  }
  $pick = Choose 'Which settings file?' $items
  return $names[$pick]
}

function Select-Mode {
  if ($Mode) { $m = $Mode.ToLower() }
  elseif ($Yes) { $m = 'debug' }
  else {
    $items = @(
      (New-Item 'Debug' 'hot reload, best for working on the app'),
      (New-Item 'Profile' 'close to real speed, with the performance tools'),
      (New-Item 'Release' 'the real thing, no hot reload'))
    $pick = Choose 'How should it run?' $items
    $m = @('debug', 'profile', 'release')[$pick]
  }
  if ($m -notin 'debug', 'profile', 'release') { Fail 'Mode must be debug, profile or release.'; exit 2 }
  return $m
}

function Test-PortBusy([int]$p) {
  try {
    $c = New-Object System.Net.Sockets.TcpClient
    $iar = $c.BeginConnect('127.0.0.1', $p, $null, $null)
    $ok = $iar.AsyncWaitHandle.WaitOne(300) -and $c.Connected
    $c.Close(); return $ok
  } catch { return $false }
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
if (-not (Test-Flutter)) {
  Fail 'Flutter is not on your PATH.'
  Say '    Install it from https://docs.flutter.dev/get-started/install, then open a new terminal.'
  exit 1
}
if ($Doctor) { & flutter doctor; exit $LASTEXITCODE }
if ($Devices) { & flutter devices; exit $LASTEXITCODE }

Show-Splash

$sel = $null
if ($Device) {
  $sel = [pscustomobject]@{ Id = $Device; Name = $Device; Plat = 'other'; Emu = $false }
  foreach ($d in (Load-Devices)) { if ($d.Id -eq $Device) { $sel = $d } }
} elseif ($Platform -or $Yes) {
  $devs = Sort-Devices (Load-Devices)
  $want = $Platform.ToLower(); if ($want -eq 'browser') { $want = 'web' }
  if (-not $want) { $want = 'windows' }
  foreach ($d in $devs) { if ($d.Plat -eq $want -or $d.Id -eq $want) { $sel = $d; break } }
  if (-not $sel -and $Yes -and -not $Platform -and $devs.Count -gt 0) { $sel = $devs[0] }
  if (-not $sel) { Fail "No $want device found. Run .\run.ps1 -Devices to see what Flutter can use."; exit 1 }
} else {
  $sel = Select-Platform
}
Good "Platform  $(Get-Badge $sel.Plat $sel.Emu) $($sel.Name)"

$envName = Select-Env
Good "Settings  $envName"
$modeName = Select-Mode
Good "Mode      $modeName"
Say ''

# packages
$cfg = '.dart_tool\package_config.json'
$stale = -not (Test-Path $cfg)
if (-not $stale) {
  $t = (Get-Item $cfg).LastWriteTime
  if ((Get-Item 'pubspec.yaml').LastWriteTime -gt $t) { $stale = $true }
  elseif ((Test-Path 'pubspec.lock') -and (Get-Item 'pubspec.lock').LastWriteTime -gt $t) { $stale = $true }
}
if ($stale) {
  $res = Invoke-Spin 'Fetching packages' { $o = & flutter pub get 2>&1; [pscustomobject]@{ Out = $o; Code = $LASTEXITCODE } }
  if ($res.Code -ne 0) { Fail 'flutter pub get failed:'; $res.Out | ForEach-Object { Say "    $_" }; exit 1 }
  Good 'Packages are up to date'
}

$cmd = @('run', '-d', $sel.Id, "--dart-define-from-file=$EnvDir/$envName.json")
$url = ''
if ($sel.Plat -eq 'web') {
  if (Test-PortBusy $Port) {
    Warn "Port $Port is already in use. Sign in with GitHub, Google or Facebook sends you back to port 3000,"
    Say '    so stop whatever uses it, or pick another with -Port and expect those callbacks to miss.'
    if ($Interactive -and -not $Yes) {
      $a = Read-Host "  Continue on port $Port anyway? [y/N]"
      if ($a -notmatch '^(y|yes)$') { exit 1 }
    }
  }
  $cmd += "--web-port=$Port"; $url = "http://localhost:$Port"
}
if ($modeName -eq 'profile') { $cmd += '--profile' } elseif ($modeName -eq 'release') { $cmd += '--release' }
if ($Extra.Count -gt 0) { $cmd += $Extra }

try {
  $base = (Get-Content "$EnvDir/$envName.json" -Raw | ConvertFrom-Json).BASE_URL
  if ($base -match 'example') { Warn "$envName.json still has a placeholder address, so the app may not reach your server." }
} catch { }

Rule
Say "  ${GOLD}Launching$RST  $($sel.Name)"
if ($url) { Say "  ${GOLD}Opens at$RST   $BOLD$url$RST" }
Say "  ${GOLD}Command$RST    ${DIM}flutter $($cmd -join ' ')$RST"
Say "  ${GOLD}Keys$RST       r hot reload, R hot restart, q quit"
Rule
Say ''

$start = Get-Date
& flutter @cmd
$rc = $LASTEXITCODE
$dur = [int]((Get-Date) - $start).TotalSeconds

Say ''
Rule
if ($rc -eq 0) { Good ("Done after {0}m {1}s" -f [int][Math]::Floor($dur / 60), ($dur % 60)) }
else {
  Fail ("Flutter stopped with code {0} after {1}m {2}s" -f $rc, [int][Math]::Floor($dur / 60), ($dur % 60))
  Say '    Try .\run.ps1 -Doctor to check your setup, or run again and pick another device.'
}
exit $rc
