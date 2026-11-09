[CmdletBinding()]
param([string]$HostName,[string]$EnvironmentId)
. (Join-Path $PSScriptRoot 'Common.ps1')
$taskConfig=Get-Content (Join-Path $PSScriptRoot 'managed/settings.json') -Raw | ConvertFrom-Json
if (-not $HostName) { $HostName=[string]$taskConfig.host }
if (-not $EnvironmentId) { $EnvironmentId=[string]$taskConfig.environmentId }
if (-not $HostName) { $HostName=Read-Host 'dbt Semantic Layer host (yalniz host adi)' }
if (-not $EnvironmentId) { $EnvironmentId=Read-Host 'dbt deployment Environment ID' }
$HostName=$HostName.Trim().ToLowerInvariant()
if ($HostName -notmatch '^[a-z0-9.-]+$' -or $HostName -notmatch '(^|\.)semantic-layer\.' -or $HostName -notmatch '\.(getdbt\.com|dbt\.com)$') { throw 'Resmi dbt Semantic Layer host adi gerekli; URL veya token girmeyin.' }
if ($EnvironmentId -notmatch '^[0-9]{1,20}$' -or [decimal]$EnvironmentId -lt 1) { throw 'Pozitif Environment ID gerekli.' }
$taskSecure=Read-Host 'Semantic Layer service token (gizli)' -AsSecureString
$taskPointer=[Runtime.InteropServices.Marshal]::SecureStringToBSTR($taskSecure)
try {
    $taskToken=[Runtime.InteropServices.Marshal]::PtrToStringBSTR($taskPointer)
    if ([string]::IsNullOrWhiteSpace($taskToken)) { throw 'Token bos olamaz.' }
    Write-Rm6Object -Object @{apiVersion='v1';kind='Secret';metadata=@{name='rm6-dbt-service';namespace=$Rm6Namespace};type='Opaque';stringData=@{'api-token'=$taskToken;'host'=$HostName;'environment-id'=$EnvironmentId}}
} finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($taskPointer);$taskToken=$null }
Write-Host 'Harici servis bilgileri yalniz yerel Kubernetes Secret icinde saklandi. Run-RemoteChecks.ps1 ile gercek servisi sinayin.'
