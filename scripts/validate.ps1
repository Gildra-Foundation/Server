[CmdletBinding()]
param(
    [switch]$Production,
    [string]$EnvFile
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$composeFile = Join-Path $repoRoot 'compose/compose.yaml'
$envFile = if ($EnvFile) {
    if ([System.IO.Path]::IsPathRooted($EnvFile)) {
        $EnvFile
    } else {
        Join-Path $repoRoot $EnvFile
    }
} else {
    Join-Path $repoRoot 'compose/env.example'
}
$failed = $false

function Write-CheckResult {
    param([string]$Name, [bool]$Passed, [string]$Detail)
    $status = if ($Passed) { 'PASS' } else { 'FAIL' }
    Write-Host "[$status] $Name - $Detail"
    if (-not $Passed) {
        $script:failed = $true
    }
}

$repositoryFiles = @(git -C $repoRoot ls-files --cached --others --exclude-standard)
$forbiddenTracked = @($repositoryFiles | Where-Object {
    $_ -match '(^|/)(\.env|hosts\.yml)$' -or
    $_ -match '\.(pem|key|p12|pfx)$' -or
    $_ -match '(^|/)secrets/(?!.*\.example$|README\.md$)'
})
$trackedDetail = if ($forbiddenTracked.Count -eq 0) {
    'none found'
} else {
    $forbiddenTracked -join ', '
}
Write-CheckResult 'tracked secret paths' ($forbiddenTracked.Count -eq 0) $trackedDetail

$textFiles = $repositoryFiles | Where-Object {
    $_ -match '\.(md|yml|yaml|json|j2|ps1|example|gitignore|editorconfig)$'
}
$secretPatterns = @(
    '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----',
    'gh[pousr]_[A-Za-z0-9_]{20,}',
    'github_pat_[A-Za-z0-9_]{20,}',
    'AKIA[0-9A-Z]{16}'
)
$secretHits = @()
foreach ($relativePath in $textFiles) {
    $path = Join-Path $repoRoot $relativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
    $content = Get-Content -LiteralPath $path -Raw
    foreach ($pattern in $secretPatterns) {
        if ($content -match $pattern) {
            $secretHits += "$relativePath ($pattern)"
        }
    }
}
$secretDetail = if ($secretHits.Count -eq 0) {
    'no known credential patterns'
} else {
    $secretHits -join ', '
}
Write-CheckResult 'secret pattern scan' ($secretHits.Count -eq 0) $secretDetail

$latestHits = Select-String -Path @($composeFile, $envFile) `
    -Pattern '(^|:)latest($|\s)' -CaseSensitive:$false
Write-CheckResult 'mutable latest tags' ($null -eq $latestHits) 'compose file contains no latest tags'

$publishedPorts = Select-String -Path $composeFile -Pattern '^\s+ports:\s*$'
Write-CheckResult 'database port exposure' ($null -eq $publishedPorts) 'no host ports are published'

if ($Production) {
    $imageLines = Get-Content -LiteralPath $envFile | Where-Object { $_ -match '_IMAGE=' }
    $unpinned = $imageLines | Where-Object { $_ -notmatch '@sha256:[0-9a-f]{64}$' }
    $digestDetail = if ($unpinned.Count -eq 0) {
        'all images use digests'
    } else {
        'replace review tags with digests'
    }
    Write-CheckResult 'production image digests' ($unpinned.Count -eq 0) $digestDetail
}

if (Get-Command docker -ErrorAction SilentlyContinue) {
    & docker compose --env-file $envFile -f $composeFile config --quiet
    Write-CheckResult 'docker compose config' ($LASTEXITCODE -eq 0) 'configuration rendered'
} else {
    Write-Host '[SKIP] docker compose config - Docker CLI is not installed'
}

if (Get-Command yamllint -ErrorAction SilentlyContinue) {
    & yamllint -c (Join-Path $repoRoot '.yamllint.yml') (Join-Path $repoRoot 'ansible') `
        (Join-Path $repoRoot 'compose') (Join-Path $repoRoot '.github/workflows')
    Write-CheckResult 'yamllint' ($LASTEXITCODE -eq 0) 'YAML lint completed'
} else {
    Write-Host '[SKIP] yamllint - install yamllint==1.38.0'
}

if (Get-Command ansible-playbook -ErrorAction SilentlyContinue) {
    Push-Location (Join-Path $repoRoot 'ansible')
    try {
        & ansible-playbook playbooks/audit.yml --syntax-check `
            --inventory inventories/production/hosts.example.yml
        $auditCode = $LASTEXITCODE
        & ansible-playbook playbooks/bootstrap.yml --syntax-check `
            --inventory inventories/production/hosts.example.yml
        $bootstrapCode = $LASTEXITCODE
    } finally {
        Pop-Location
    }
    Write-CheckResult 'ansible syntax' (($auditCode -eq 0) -and ($bootstrapCode -eq 0)) `
        'audit and bootstrap syntax checked'
} else {
    Write-Host '[SKIP] ansible syntax - install ansible-core==2.19.12 on Linux or WSL'
}

if ($failed) {
    exit 1
}

Write-Host 'Validation completed without detected failures.'
