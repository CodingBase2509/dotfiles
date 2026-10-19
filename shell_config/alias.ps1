# Dot-source this file from your PowerShell profile.
# Navigation does not require any additional tools.
function .. { Set-Location -Path '..' @args }
function ... { Set-Location -Path '../..' @args }
function .... { Set-Location -Path '../../..' @args }

if (Get-Command code -CommandType Application, ExternalScript -ErrorAction SilentlyContinue) {
    Set-Alias -Name c -Value code
    function c. { code . @args }
}

if (Get-Command git -CommandType Application -ErrorAction SilentlyContinue) {
    # Aliases take precedence over functions. Free the Git shortcut names,
    # including built-in PowerShell aliases such as gc, gi, gl, gp and gm.
    foreach ($dotfilesAliasName in @(
        'gst', 'gi', 'gc', 'gcs', 'gcho', 'gchb', 'gchdev', 'gchm',
        'gb', 'gba', 'gbd', 'gbdf', 'gbsu', 'gl', 'glf', 'glo',
        'gp', 'gpf', 'gpo', 'gf', 'gcmsg', 'gstsh', 'gstp', 'gstc',
        'gstd', 'gstl', 'ga', 'gaa', 'grm', 'grmc', 'glog', 'gm',
        'grb', 'gr', 'gra'
    )) {
        if (Test-Path -LiteralPath "Alias:$dotfilesAliasName") {
            Remove-Item -LiteralPath "Alias:$dotfilesAliasName" -Force
        }
    }
    Remove-Variable dotfilesAliasName

    Set-Alias -Name g -Value git
    function gst { git status @args }
    function gi { git init @args }
    function gc { git clone @args }
    function gcs { git clone --recurse-submodules @args }

    function gcho { git checkout @args }
    function gchb { git checkout -b @args }
    function gchdev { git checkout develop @args }
    function gchm { git checkout master @args }

    function gb { git branch @args }
    function gba { git branch -a @args }
    function gbd { git branch -d @args }
    # PowerShell command names are case-insensitive: gbD would replace gbd.
    function gbdf { git branch -D @args }
    function gbsu {
        $branch = git symbolic-ref --short HEAD
        if ($LASTEXITCODE -ne 0) { return }
        git branch "--set-upstream-to=origin/$branch" @args
    }

    function gl { git pull @args }
    function glf { git pull --force @args }
    function glo {
        $branch = git symbolic-ref --short HEAD
        if ($LASTEXITCODE -ne 0) { return }
        git pull origin $branch @args
    }
    function gp { git push @args }
    function gpf { git push --force @args }
    function gpo {
        $branch = git symbolic-ref --short HEAD
        if ($LASTEXITCODE -ne 0) { return }
        git push origin $branch @args
    }
    function gf { git fetch --all --prune @args }
    function gcmsg { git commit -m @args }

    function gstsh { git stash @args }
    function gstp { git stash pop @args }
    function gstc { git stash clear @args }
    function gstd { git stash drop @args }
    function gstl { git stash list @args }

    function ga { git add @args }
    function gaa { git add --all @args }
    function grm { git rm @args }
    function grmc { git rm --cached @args }
    function glog { git log @args }
    function gm { git merge @args }
    function grb { git rebase @args }
    function gr { git remote @args }
    function gra { git remote add @args }
}
