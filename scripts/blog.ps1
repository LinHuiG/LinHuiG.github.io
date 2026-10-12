#requires -Version 7.0
param(
    [ValidateSet('preview','build','new')][string]$Action = 'preview',
    [string]$Slug
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$version = '0.167.0'
$hugo = Join-Path $root '.tools\hugo\hugo.exe'
$cacheDir = Join-Path $root '.cache'
if (-not (Test-Path -LiteralPath $hugo)) {
    $toolsDir = Join-Path $root '.tools\hugo'
    New-Item -ItemType Directory -Force -Path $toolsDir | Out-Null
    $asset = "hugo_extended_${version}_windows-amd64.zip"
    $release = "https://github.com/gohugoio/hugo/releases/download/v$version"
    $zip = Join-Path $toolsDir $asset
    $checksums = Join-Path $toolsDir 'checksums.txt'
    Write-Host "Downloading Hugo $version from its official release..."
    Invoke-WebRequest -Uri "$release/$asset" -OutFile $zip -TimeoutSec 300
    Invoke-WebRequest -Uri "$release/hugo_${version}_checksums.txt" -OutFile $checksums -TimeoutSec 60
    $line = Get-Content -LiteralPath $checksums | Where-Object { $_ -match "\s+$([regex]::Escape($asset))$" }
    if (-not $line) { throw 'Missing official checksum.' }
    $expected = ($line -split '\s+')[0]
    if ((Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash -ne $expected) { throw 'Hugo checksum mismatch.' }
    Expand-Archive -LiteralPath $zip -DestinationPath $toolsDir -Force
}
Push-Location $root
try {
    switch ($Action) {
        'preview' { & $hugo server --cacheDir $cacheDir --bind 127.0.0.1 --baseURL http://localhost:1313/ --port 1313 -D }
        'build' { & $hugo --cacheDir $cacheDir --gc --minify --panicOnWarning }
        'new' {
            if ($Slug -notmatch '^[a-z0-9]+(?:-[a-z0-9]+)*$') { throw 'Use a slug such as my-first-post.' }
            & $hugo new content "posts/$Slug/index.md"
        }
    }
    if ($LASTEXITCODE -ne 0) { throw "Hugo exited with $LASTEXITCODE" }
} finally { Pop-Location }
