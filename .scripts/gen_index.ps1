# Regenerate the note index of every domain README.md.
#
# Layout of a domain README:
#
#     # 20-backend ...              <- hand-written intro (title, tables, notes)
#
#     ## <index heading>            <- everything from the first level-2 heading
#     ### <group>                      down to the end of file is GENERATED
#     - [note](relative/path.md)
#
# Usage:
#     powershell -NoProfile -ExecutionPolicy Bypass -File .scripts\gen_index.ps1
#
# The hand-written intro is preserved verbatim, so edit the intro directly in the
# README. Domains without any note keep their intro untouched.
#
# This file is intentionally ASCII-only: Windows PowerShell 5.1 reads BOM-less
# script files with the ANSI code page, which corrupts non-ASCII literals. Keep
# non-ASCII text in the Markdown files, not in here.

$ErrorActionPreference = 'Stop'
$enc     = New-Object Text.UTF8Encoding($false)
$root    = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$domains = @('00-inbox', '10-dev', '20-backend', '30-hardware', '40-system',
             '50-network', '60-windows', '90-refs', '99-archive')

function Get-IndexBody([string]$domain, [string]$base) {
    $notes = Get-ChildItem -LiteralPath $base -Recurse -File -Filter *.md -ErrorAction SilentlyContinue |
             Where-Object { $_.FullName -ne (Join-Path $base 'README.md') } | Sort-Object FullName
    $sb = New-Object Text.StringBuilder
    $groups = $notes | Group-Object {
        [IO.Path]::GetDirectoryName($_.FullName).Replace($base, '').TrimStart('\').Replace('\', '/')
    }
    foreach ($g in ($groups | Sort-Object Name)) {
        [void]$sb.AppendLine('### ' + $(if ($g.Name) { $g.Name } else { $domain }))
        foreach ($n in $g.Group) {
            $rel   = $n.FullName.Replace($base + '\', '').Replace('\', '/').Replace(' ', '%20')
            $label = $(if ($n.BaseName -eq 'README') { Split-Path $n.DirectoryName -Leaf } else { $n.BaseName })
            [void]$sb.AppendLine('- [' + $label + '](' + $rel + ')')
        }
        [void]$sb.AppendLine('')
    }
    return $sb.ToString().TrimEnd()
}

foreach ($d in $domains) {
    $base = Join-Path $root $d
    $path = Join-Path $base 'README.md'
    if (-not [IO.File]::Exists($path)) { Write-Host ("{0,-12} SKIP (no README.md)" -f $d); continue }

    $text  = [IO.File]::ReadAllText($path, [Text.Encoding]::UTF8)
    $lines = $text -split "`r?`n"
    $cut   = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*##\s') { $cut = $i; break }
    }
    $head = $(if ($cut -ge 0) { $lines[0..$cut] -join "`r`n" } else { $text.TrimEnd() })
    $body = Get-IndexBody $d $base

    $out = $head.TrimEnd() + "`r`n"
    if ($body) { $out += "`r`n" + $body + "`r`n" }
    [IO.File]::WriteAllText($path, $out, $enc)

    $n = ($body -split "`r`n" | Where-Object { $_ -like '- *' } | Measure-Object).Count
    Write-Host ("{0,-12} index regenerated, {1} notes" -f $d, $n)
}
