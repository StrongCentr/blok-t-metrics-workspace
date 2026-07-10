# Deploy both prototypes to GitHub Pages
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

$metric = Join-Path $PSScriptRoot "metric-tree-builder.html"
$kursor = Join-Path $PSScriptRoot "Курсор.html"
$hub = Join-Path $PSScriptRoot "index.html"

if (-not (Test-Path -LiteralPath $metric)) { Write-Error "metric-tree-builder.html not found" }
if (-not (Test-Path -LiteralPath $kursor)) { Write-Error "Курсор.html not found" }
if (-not (Test-Path -LiteralPath $hub)) { Write-Error "index.html hub not found" }
if (-not (Test-Path ".\.nojekyll")) { New-Item -Path ".\.nojekyll" -ItemType File | Out-Null }

if (-not (Test-Path ".\.git")) { & $git init; & $git branch -M main }

$env:GIT_AUTHOR_NAME = "avast"
$env:GIT_AUTHOR_EMAIL = "avast@users.noreply.github.com"
$env:GIT_COMMITTER_NAME = $env:GIT_AUTHOR_NAME
$env:GIT_COMMITTER_EMAIL = $env:GIT_AUTHOR_EMAIL

& $git add index.html metric-tree-builder.html "Курсор.html" README.md .nojekyll deploy-github-pages.ps1 .gitignore
$status = & $git status --porcelain
if ($status) {
  & $git commit -m "Deploy hub, metric tree builder and leader workspace"
}

$remotes = & $git remote 2>$null
if ($remotes -notcontains "origin") {
  & $gh repo create $repoName --public --source=. --remote=origin --push
} else {
  & $git push -u origin main
}

$owner = (& $gh api user -q .login).Trim()
$base = "https://$owner.github.io/$repoName"

Write-Host ""
Write-Host "Done. URLs (may take 1-2 min):"
Write-Host "$base/"
Write-Host "$base/metric-tree-builder.html"
Write-Host "$base/%D0%9A%D1%83%D1%80%D1%81%D0%BE%D1%80.html"
