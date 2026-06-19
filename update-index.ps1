<#
.SYNOPSIS
  Regenerate index.toml for Strata-Library from the shader-library/ folders.

.DESCRIPTION
  The contributor workflow. Scans shader-library/<slug>/manifest.toml, hashes
  each shader's authored content, and rewrites index.toml:
    * NEW shader folders -> added with added_in = <new version>, updated = today
    * CHANGED shaders     -> updated = today (added_in preserved), sha refreshed
    * REMOVED folders     -> dropped from the index
  Then, if anything changed, it asks for the new library_version (or pass -Version).

  Needs nothing but PowerShell (built into Windows) - no Rust, no engine checkout,
  no GPU. It does NOT render thumbnails: add your own thumbnail.png to the folder,
  or let the Strata app generate one at runtime.

.PARAMETER Version
  The new library_version to stamp (e.g. 1.1.0). If omitted and content changed,
  you'll be prompted with a suggested minor bump.

.EXAMPLE
  .\update-index.ps1
.EXAMPLE
  .\update-index.ps1 -Version 1.1.0
#>
param(
    [string]$Version,   # explicit library_version (implies -Release)
    [switch]$Release,   # maintainer: stamp/prompt the library_version + tag the release
    [switch]$NoPause    # CI: don't wait for a keypress at the end
)

$ErrorActionPreference = 'Stop'
$root  = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root
$today = (Get-Date).ToString('yyyy-MM-dd')

function Finish([int]$code = 0) {
    if (-not $NoPause) { Write-Host ""; $null = Read-Host 'Press Enter to close' }
    exit $code
}
# Pause on any terminating error too, so a double-clicked window doesn't vanish.
trap {
    Write-Host "`nERROR: $($_.Exception.Message)" -ForegroundColor Red
    if (-not $NoPause) { Write-Host ""; $null = Read-Host 'Press Enter to close' }
    exit 1
}

if (-not (Test-Path 'shader-library')) {
    throw "Run this from the Strata-Library root (no shader-library/ folder here)."
}

# --- helpers -------------------------------------------------------------------

function Get-TomlString([string]$s) {
    '"' + ($s -replace '\\', '\\' -replace '"', '\"') + '"'
}

# Hash a shader's AUTHORED files (manifest.toml + *.glsl), sorted by name. Matches
# the engine's algorithm exactly: for each file, utf8(name) + 0x00 + raw bytes.
function Get-Sha256OfShader([string]$dir) {
    $files = Get-ChildItem -LiteralPath $dir -File |
        Where-Object { $_.Name -eq 'manifest.toml' -or $_.Name -like '*.glsl' } |
        Sort-Object Name
    $ms = New-Object System.IO.MemoryStream
    foreach ($f in $files) {
        $nb = [System.Text.Encoding]::UTF8.GetBytes($f.Name)
        $ms.Write($nb, 0, $nb.Length)
        $ms.WriteByte(0)
        $b = [System.IO.File]::ReadAllBytes($f.FullName)
        $ms.Write($b, 0, $b.Length)
    }
    $hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash($ms.ToArray())
    (($hash | ForEach-Object { $_.ToString('x2') }) -join '')
}

# Minimal [wallpaper] reader for our controlled manifest format.
function Read-Manifest([string]$path) {
    $text = Get-Content -LiteralPath $path -Raw
    $m = [regex]::Match($text, '(?s)\[wallpaper\](.*?)(\r?\n\[|\Z)')
    $body = if ($m.Success) { $m.Groups[1].Value } else { $text }
    $val = {
        param($key)
        $mm = [regex]::Match($body, "(?m)^\s*$key\s*=\s*""(.*?)""")
        if ($mm.Success) { $mm.Groups[1].Value } else { '' }
    }
    $tags = @()
    $tm = [regex]::Match($body, "(?m)^\s*tags\s*=\s*\[(.*?)\]")
    if ($tm.Success) {
        $tags = [regex]::Matches($tm.Groups[1].Value, '"(.*?)"') | ForEach-Object { $_.Groups[1].Value }
    }
    [pscustomobject]@{
        name       = & $val 'name'
        author     = & $val 'author'
        source_url = & $val 'source_url'
        tags       = $tags
    }
}

function Suggest-Bump([string]$v) {
    $p = ($v -replace '^[vV]', '').Split('.')
    $maj = [int]($p[0])
    $min = if ($p.Count -ge 2) { [int]$p[1] } else { 0 }
    "$maj.$($min + 1).0"
}

# --- read the existing index.toml (prior version + per-shader state) -----------

$prevShaders = @{}
$prevVersion = '1.0.0'

if (Test-Path 'index.toml') {
    $idx = Get-Content 'index.toml' -Raw
    $vm = [regex]::Match($idx, '(?m)^\s*library_version\s*=\s*"(.*?)"')
    if ($vm.Success) { $prevVersion = $vm.Groups[1].Value }
    foreach ($blk in [regex]::Matches($idx, '(?s)\[\[shader\]\](.*?)(?=\r?\n\[\[shader\]\]|\Z)')) {
        $b = $blk.Groups[1].Value
        $slug = [regex]::Match($b, '(?m)^\s*slug\s*=\s*"(.*?)"').Groups[1].Value
        if ($slug) {
            $prevShaders[$slug] = [pscustomobject]@{
                added_in = [regex]::Match($b, '(?m)^\s*added_in\s*=\s*"(.*?)"').Groups[1].Value
                updated  = [regex]::Match($b, '(?m)^\s*updated\s*=\s*"(.*?)"').Groups[1].Value
                sha256   = [regex]::Match($b, '(?m)^\s*sha256\s*=\s*"(.*?)"').Groups[1].Value
            }
        }
    }
}

# --- scan shader-library -------------------------------------------------------

$dirs = Get-ChildItem 'shader-library' -Directory |
    Where-Object { Test-Path (Join-Path $_.FullName 'manifest.toml') } |
    Sort-Object Name

$shaders = @()
$added = @(); $updated = @()
foreach ($d in $dirs) {
    $slug = $d.Name
    $man  = Read-Manifest (Join-Path $d.FullName 'manifest.toml')
    $sha  = Get-Sha256OfShader $d.FullName

    if (-not $man.name)   { Write-Warning "${slug}: manifest has no name" }
    if (-not $man.author) { Write-Warning "${slug}: manifest has no author" }
    if (-not $man.source_url) { Write-Warning "${slug}: no source_url (attribution link will be blank)" }
    if (-not (Test-Path (Join-Path $d.FullName 'thumbnail.png'))) {
        Write-Warning "${slug}: no thumbnail.png (the app will generate one at runtime; better to include it)"
    }

    $p = $prevShaders[$slug]
    if ($null -eq $p) {
        $added += $slug
        $addedIn = '<NEW>'   # resolved to the new version once chosen
        $upd     = $today
    } elseif ($p.sha256 -ne $sha) {
        $updated += $slug
        $addedIn = $p.added_in
        $upd     = $today
    } else {
        $addedIn = $p.added_in
        $upd     = $p.updated
    }
    $shaders += [pscustomobject]@{ slug = $slug; man = $man; sha = $sha; addedIn = $addedIn; updated = $upd }
}

$removed = @($prevShaders.Keys | Where-Object { $_ -notin ($shaders | ForEach-Object slug) })

$changed = ($added.Count -or $updated.Count -or $removed.Count)

# --- report --------------------------------------------------------------------

Write-Host ""
Write-Host "Strata-Library index update" -ForegroundColor Cyan
Write-Host "  shaders found : $($shaders.Count)"
if ($added.Count)   { Write-Host "  added         : $($added -join ', ')"   -ForegroundColor Green }
if ($updated.Count) { Write-Host "  changed       : $($updated -join ', ')" -ForegroundColor Yellow }
if ($removed.Count) { Write-Host "  removed       : $($removed -join ', ')" -ForegroundColor Red }

# --- decide the version --------------------------------------------------------
# Contributors (default) NEVER change library_version: new shaders are marked
# `added_in = "unreleased"` and the maintainer assigns the real version later by
# running with -Release (or -Version x.y.z), which finalizes every "unreleased"
# entry. This lets several contributor PRs be merged, then versioned + tagged once.

$releaseMode = $Release.IsPresent -or [bool]$Version

if (-not $changed -and -not $releaseMode) {
    Write-Host "`nNo content changes - index.toml is up to date (library_version $prevVersion)." -ForegroundColor Green
    Finish
}

if ($releaseMode) {
    if ($Version) {
        $newVersion = $Version.Trim()
    } else {
        $suggest = Suggest-Bump $prevVersion
        $ans = Read-Host "`nRelease mode. New library_version [$suggest]"
        $newVersion = if ($ans.Trim()) { $ans.Trim() } else { $suggest }
    }
    # Brand-new and any pending "unreleased" shaders adopt the release version.
    foreach ($s in $shaders) { if ($s.addedIn -eq '<NEW>' -or $s.addedIn -eq 'unreleased') { $s.addedIn = $newVersion } }
} else {
    $newVersion = $prevVersion
    foreach ($s in $shaders) { if ($s.addedIn -eq '<NEW>') { $s.addedIn = 'unreleased' } }
    if ($added.Count) {
        Write-Host "`nNew shaders marked 'unreleased'. The maintainer will assign a version with -Release." -ForegroundColor Cyan
    }
}

# --- write index.toml ----------------------------------------------------------

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('# Strata-Library manifest - generated by update-index.ps1 (do NOT hand-edit).')
[void]$sb.AppendLine('# Re-run after adding/editing shaders:  .\update-index.ps1')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('schema_version = 1')
[void]$sb.AppendLine("library_version = $(Get-TomlString $newVersion)")
foreach ($s in $shaders) {
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('[[shader]]')
    [void]$sb.AppendLine("slug = $(Get-TomlString $s.slug)")
    [void]$sb.AppendLine("name = $(Get-TomlString $s.man.name)")
    [void]$sb.AppendLine("author = $(Get-TomlString $s.man.author)")
    if ($s.man.source_url) { [void]$sb.AppendLine("source_url = $(Get-TomlString $s.man.source_url)") }
    $tagsStr = (@($s.man.tags) | ForEach-Object { Get-TomlString $_ }) -join ', '
    [void]$sb.AppendLine("tags = [$tagsStr]")
    [void]$sb.AppendLine("added_in = $(Get-TomlString $s.addedIn)")
    [void]$sb.AppendLine("updated = $(Get-TomlString $s.updated)")
    [void]$sb.AppendLine("sha256 = $(Get-TomlString $s.sha)")
}

# UTF-8 without BOM (a BOM can trip TOML parsers).
[System.IO.File]::WriteAllText((Join-Path $root 'index.toml'), $sb.ToString(), (New-Object System.Text.UTF8Encoding $false))

Write-Host "`nWrote index.toml  (library_version $newVersion, $($shaders.Count) shaders)." -ForegroundColor Green
if ($releaseMode) {
    Write-Host "Release: commit, then  git tag library-v$newVersion  and push the tag." -ForegroundColor Cyan
} else {
    Write-Host "Commit your shader folder + index.toml and open a PR (version stays $newVersion)." -ForegroundColor Cyan
}
Finish
