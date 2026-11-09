$ErrorActionPreference = 'Stop'
$Rm7Namespace = 'komtas-rm7'
$Rm7Context = 'docker-desktop'

function Invoke-Rm7Kubectl {
    param([string[]]$Arguments)
    $taskResult = & kubectl --context $Rm7Context @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw ($taskResult -join [Environment]::NewLine)
    }
    return $taskResult
}

function Write-Rm7Object {
    param($Object)
    $taskJson = $Object | ConvertTo-Json -Depth 30 -Compress
    $taskResult = $taskJson | & kubectl --context $Rm7Context apply -f - 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw ($taskResult -join [Environment]::NewLine)
    }
    $taskResult | ForEach-Object { Write-Host $_ }
}

function New-Rm7Password {
    $taskBytes = New-Object byte[] 24
    $taskGenerator = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try { $taskGenerator.GetBytes($taskBytes) } finally { $taskGenerator.Dispose() }
    return ([BitConverter]::ToString($taskBytes)).Replace('-', '').ToLowerInvariant()
}

function Start-Rm7Job {
    param([string]$Name, [string]$Manifest)
    Invoke-Rm7Kubectl -Arguments @('-n',$Rm7Namespace,'delete','job',$Name,'--ignore-not-found=true','--wait=true') | Out-Host
    Invoke-Rm7Kubectl -Arguments @('apply','-f',$Manifest) | Out-Host
    $taskDeadline = [DateTime]::UtcNow.AddMinutes(20)
    while ([DateTime]::UtcNow -lt $taskDeadline) {
        $taskJob = (Invoke-Rm7Kubectl -Arguments @('-n',$Rm7Namespace,'get','job',$Name,'-o','json') | Out-String) | ConvertFrom-Json
        if ($taskJob.status.succeeded -ge 1) { Invoke-Rm7Kubectl -Arguments @('-n',$Rm7Namespace,'logs',"job/$Name") | Out-Host; return }
        if ($taskJob.status.failed -ge 1) {
            & kubectl --context $Rm7Context -n $Rm7Namespace logs "job/$Name" --all-containers=true
            throw "Job failed: $Name"
        }
        Start-Sleep -Seconds 2
    }
    & kubectl --context $Rm7Context -n $Rm7Namespace describe job $Name
    throw "Job timeout: $Name"
}
