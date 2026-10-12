#requires -Version 7.0
# Requires Git and GitHub CLI (https://cli.github.com/), authenticated with gh auth login.
param([switch]$ConfigureComments)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$owner = 'LinHuiG'
$repoName = 'LinHuiG.github.io'
$repo = "$owner/$repoName"
function Run-Gh {
    param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Arguments)
    $result = & gh @Arguments
    if ($LASTEXITCODE -ne 0) { throw "GitHub CLI failed: $($Arguments[0])" }
    return $result
}
function Run-Git {
    param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Arguments)
    & git @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Git failed: $($Arguments[0])" }
}
Get-Command git,gh -ErrorAction Stop | Out-Null
$login = (Run-Gh @('api','user','--jq','.login')).Trim()
if ($login -cne $owner) { throw "Expected GitHub account $owner; currently authenticated as $login." }
Push-Location $root
try {
    if (-not $ConfigureComments) {
        if (-not (Test-Path -LiteralPath (Join-Path $root '.git'))) {
            Run-Git @('init','-b','main')
            # Avoid publishing a personal or work email address from global Git settings.
            $userId = (Run-Gh @('api','user','--jq','.id')).Trim()
            Run-Git @('config','user.name',$owner)
            Run-Git @('config','user.email',"$userId+$owner@users.noreply.github.com")
        }
        $branch = (& git branch --show-current).Trim()
        if ($branch -ne 'main') { throw 'Run this script from the main branch.' }
        $remote = & git remote get-url origin 2>$null
        $hasOrigin = $LASTEXITCODE -eq 0
        if ($hasOrigin) {
            if ($remote -notin @("https://github.com/$repo.git","https://github.com/$repo","git@github.com:$repo.git")) { throw "Unexpected origin: $remote" }
            $details = Run-Gh @('repo','view',$repo,'--json','isPrivate') | ConvertFrom-Json
            if ($details.isPrivate) { throw 'Repository is private; this script will not change its visibility.' }
        }
        Run-Git @('add','.')
        & git diff --cached --quiet
        if ($LASTEXITCODE -eq 1) { Run-Git @('commit','-m','Create personal blog with Hugo, PaperMod and giscus') }
        elseif ($LASTEXITCODE -ne 0) { throw 'Could not inspect staged changes.' }
        if (-not $hasOrigin) {
            # Creation deliberately stops if that repository already exists; it never overwrites it.
            Run-Gh @('repo','create',$repo,'--public','--description','相思不扫久积弥厚 · LinHuiG 的个人博客','--source','.','--remote','origin')
        }
        Run-Gh @('api',"repos/$repo",'--method','PATCH','-F','has_discussions=true') | Out-Null
        Run-Git @('push','-u','origin','main')
        $pages = & gh api "repos/$repo/pages" 2>$null
        if ($LASTEXITCODE -eq 0) {
            Run-Gh @('api',"repos/$repo/pages",'--method','PUT','-f','build_type=workflow') | Out-Null
        } else {
            Run-Gh @('api',"repos/$repo/pages",'--method','POST','-f','build_type=workflow') | Out-Null
        }
        # Explicitly build after Pages is enabled, even if the first push raced with setup.
        Run-Gh @('workflow','run','pages.yml','--repo',$repo,'--ref','main')
        Write-Host "Source uploaded. Follow the deployment: https://github.com/$repo/actions"
        Write-Host 'Next: install https://github.com/apps/giscus for this repository only, then run this script with -ConfigureComments.'
    } else {
        $query = 'query($owner:String!,$name:String!){repository(owner:$owner,name:$name){id discussionCategories(first:100){nodes{id name}}}}'
        $data = Run-Gh @('api','graphql','-f',"query=$query",'-f',"owner=$owner",'-f',"name=$repoName") | ConvertFrom-Json
        $repository = $data.data.repository
        $category = $repository.discussionCategories.nodes | Where-Object { $_.name -eq 'Announcements' } | Select-Object -First 1
        if (-not $repository.id -or -not $category.id) { throw 'Enable Discussions and create an Announcements category first.' }
        Run-Gh @('variable','set','GISCUS_REPO_ID','--repo',$repo,'--body',$repository.id)
        Run-Gh @('variable','set','GISCUS_CATEGORY','--repo',$repo,'--body',$category.name)
        Run-Gh @('variable','set','GISCUS_CATEGORY_ID','--repo',$repo,'--body',$category.id)
        Run-Gh @('workflow','run','pages.yml','--repo',$repo,'--ref','main')
        Write-Host 'Comment configuration saved and rebuild requested. Verify the giscus application is installed, then check a published article.'
    }
} finally { Pop-Location }
