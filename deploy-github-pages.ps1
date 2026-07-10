# Deploy prototype to GitHub Pages
# Prerequisite: gh auth login (one time)

$ErrorActionPreference = "Stop"
$git = "C:\Program Files\Git\bin\git.exe"
$gh = "C:\Program Files\GitHub CLI\gh.exe"
$repoName = "blok-t-metrics-workspace"

Set-Location $PSScriptRoot

if (-not (Test-Path $gh)) {
  Write-Error "GitHub CLI not found. Install: winget install GitHub.cli"
}

& $gh auth status | Out-Null

$source = Join-Path $PSScriptRoot "metric-tree-builder.html"
if (-not (Test-Path -LiteralPath $source)) {
  $source = Get-ChildItem -LiteralPath $PSScriptRoot -Filter "*.html" | Where-Object { $_.Name -ne "index.html" -and $_.Name -notlike "perechen*" -and $_.Name -notlike "Иерархия*" } | Sort-Object LastWriteTime -Descending | Select-Object -First 1
}
if ($source) { Copy-Item -LiteralPath $source -Destination (Join-Path $PSScriptRoot "index.html") -Force }
if (-not (Test-Path ".\.nojekyll")) { New-Item -Path ".\.nojekyll" -ItemType File | Out-Null }

if (-not (Test-Path ".\.git")) { & $git init; & $git branch -M main }

$env:GIT_AUTHOR_NAME = "avast"
$env:GIT_AUTHOR_EMAIL = "avast@users.noreply.github.com"
$env:GIT_COMMITTER_NAME = $env:GIT_AUTHOR_NAME
$env:GIT_COMMITTER_EMAIL = $env:GIT_AUTHOR_EMAIL

& $git add index.html metric-tree-builder.html README.md .nojekyll deploy-github-pages.ps1 .gitignore
$status = & $git status --porcelain
if ($status) {
  & $git commit -m "Deploy metric tree builder: constructor and metrics library"
}

$remotes = & $git remote 2>$null
if ($remotes -notcontains "origin") {
  & $gh repo create $repoName --public --source=. --remote=origin --push
} else {
  & $git push -u origin main
}

$owner = (& $gh api user -q .login).Trim()
$pagesUrl = "https://$owner.github.io/$repoName/"

try {
  & $gh api -X POST "repos/$owner/$repoName/pages" -f build_type=legacy -f "source[branch]=main" -f "source[path]=/" | Out-Null
} catch {
  & $gh api -X PUT "repos/$owner/$repoName/pages" -f build_type=legacy -f "source[branch]=main" -f "source[path]=/" | Out-Null
}

Write-Host ""
Write-Host "Done. Site URL (may take 1-2 min to become available):"
Write-Host $pagesUrl
