$ErrorActionPreference = 'Stop'
$Rm3Namespace = 'komtas-rm3'
$Rm3Context = 'docker-desktop'

function Invoke-Rm3Kubectl {
    param([string[]]$Arguments,[string]$InputText)
    $taskExecutable=(Get-Command kubectl -ErrorAction Stop).Source
    for($taskAttempt=1;$taskAttempt -le 4;$taskAttempt++){
        $taskErrorFile=[IO.Path]::GetTempFileName()
        $taskPreviousPreference=$ErrorActionPreference
        try {
            $ErrorActionPreference='Continue'
            if($PSBoundParameters.ContainsKey('InputText')){$taskResult=$InputText | & $taskExecutable --context $Rm3Context @Arguments 2> $taskErrorFile}
            else{$taskResult=& $taskExecutable --context $Rm3Context @Arguments 2> $taskErrorFile}
            $taskExitCode=$LASTEXITCODE
        } finally {
            $ErrorActionPreference=$taskPreviousPreference
            $taskErrorText=Get-Content -LiteralPath $taskErrorFile -Raw -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $taskErrorFile -Force -ErrorAction SilentlyContinue
        }
        if($taskExitCode -eq 0){
            if($taskErrorText){Write-Warning $taskErrorText.Trim()}
            return $taskResult
        }
        $taskFailure=(@($taskResult)+@($taskErrorText)) -join [Environment]::NewLine
        if($taskAttempt -lt 4 -and $taskFailure -match '(?i)TLS handshake timeout|client connection lost|connection reset|unexpected EOF|ServiceUnavailable|context deadline exceeded|connection refused|i/o timeout'){
            Write-Warning "Kubernetes baglantisi gecici kesildi; yeniden deneniyor ($taskAttempt/4)."
            Start-Sleep -Seconds 2
            continue
        }
        throw $taskFailure
    }
}

function Write-Rm3Object {
    param($Object)
    $taskJson=$Object | ConvertTo-Json -Depth 30 -Compress
    Invoke-Rm3Kubectl -Arguments @('apply','-f','-') -InputText $taskJson | Out-Host
}

function New-Rm3Password {
    $taskBytes = New-Object byte[] 24
    $taskGenerator = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try { $taskGenerator.GetBytes($taskBytes) } finally { $taskGenerator.Dispose() }
    return ([BitConverter]::ToString($taskBytes)).Replace('-', '').ToLowerInvariant()
}

function Start-Rm3Job {
    param([string]$Name, [string]$Manifest)
    Invoke-Rm3Kubectl -Arguments @('-n',$Rm3Namespace,'delete','job',$Name,'--ignore-not-found=true','--wait=true') | Out-Host
    Invoke-Rm3Kubectl -Arguments @('apply','-f',$Manifest) | Out-Host
    $taskDeadline = [DateTime]::UtcNow.AddMinutes(20)
    while ([DateTime]::UtcNow -lt $taskDeadline) {
        $taskJob = (Invoke-Rm3Kubectl -Arguments @('-n',$Rm3Namespace,'get','job',$Name,'-o','json') | Out-String) | ConvertFrom-Json
        if ($taskJob.status.succeeded -ge 1) { Invoke-Rm3Kubectl -Arguments @('-n',$Rm3Namespace,'logs',"job/$Name") | Out-Host; return }
        if ($taskJob.status.failed -ge 1) {
            & kubectl --context $Rm3Context -n $Rm3Namespace logs "job/$Name" --all-containers=true
            throw "Job failed: $Name"
        }
        Start-Sleep -Seconds 2
    }
    & kubectl --context $Rm3Context -n $Rm3Namespace describe job $Name
    throw "Job timeout: $Name"
}
