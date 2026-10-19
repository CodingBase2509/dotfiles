# Invoked from Git Bash once for each installed PowerShell edition.
$ErrorActionPreference = 'Stop'
$profilePath = $PROFILE.CurrentUserAllHosts
$content = if (Test-Path -LiteralPath $profilePath) {
    [System.IO.File]::ReadAllText($profilePath)
} else { '' }
$originalContent = $content
$hasStarship = $false

foreach ($existingProfile in @($profilePath, $PROFILE.CurrentUserCurrentHost)) {
    if (Test-Path -LiteralPath $existingProfile) {
        $existingContent = [System.IO.File]::ReadAllText($existingProfile)
        if ($existingContent -match '(?m)^\s*[^#\s].*starship\s+init\s+powershell\b') {
            $hasStarship = $true
        }
    }
}

$aliasPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'shell_config/alias.ps1'
if (-not (Test-Path -LiteralPath $aliasPath -PathType Leaf)) {
    throw "Alias file is missing: $aliasPath"
}
# Single-quoted PowerShell paths escape apostrophes by doubling them.
$aliasLine = ". '$($aliasPath.Replace("'", "''"))'"
if (($content -split '\r?\n' | ForEach-Object { $_.Trim() }) -notcontains $aliasLine) {
    $aliasBlock = "# Dotfiles aliases (dotfiles setup)`r`n$aliasLine`r`n`r`n"
    $starshipLine = [regex]::Match($content, '(?m)^[^\S\r\n]*[^#\s][^\r\n]*starship\s+init\s+powershell\b')
    if ($starshipLine.Success) {
        $content = $content.Insert($starshipLine.Index, $aliasBlock)
    } else {
        $content += "`r`n$aliasBlock"
    }
}
if (-not $hasStarship) {
    $content += "`r`n# Starship prompt (dotfiles setup)`r`nInvoke-Expression (&starship init powershell)`r`n"
}
if ($content -ceq $originalContent) {
    Write-Host "PowerShell profile is already configured: $profilePath"
    exit 0
}

$null = New-Item -ItemType Directory -Force -Path (Split-Path -Parent $profilePath)
if (Test-Path -LiteralPath $profilePath) {
    $backup = "$profilePath.backup.$([guid]::NewGuid().ToString('N'))"
    Copy-Item -LiteralPath $profilePath -Destination $backup
    Write-Host "Backup: $backup"
}
# A BOM also preserves non-ASCII profile content in Windows PowerShell 5.1.
[System.IO.File]::WriteAllText($profilePath, $content, [System.Text.UTF8Encoding]::new($true))
Write-Host "Configured shell: $profilePath"
