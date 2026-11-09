param([string]$PackagePath,[string]$Case,[int]$Architecture)
$ErrorActionPreference='Stop'
$global:taskPromptCount=0
$global:taskApplied=$null
$global:taskExisting=''
$global:LASTEXITCODE=0
$taskPlan=Get-Content -LiteralPath (Join-Path $PackagePath 'external-connections.json') -Raw | ConvertFrom-Json
$taskService=$taskPlan.services[0]
$taskEndpoint=if($Architecture -eq 6){$taskService.settings.host}else{$taskService.settings.apiHost}
$taskIdentity=if($Architecture -eq 6){$taskService.settings.environmentId}else{$taskService.settings.orgId}
if($Case -in @('existing','mismatch')) {
 $taskHostKey=if($Architecture -eq 6){'host'}else{'api-host'}
 $taskIdKey=if($Architecture -eq 6){'environment-id'}else{'org-id'}
 $taskStoredHost=if($Case -eq 'mismatch'){'different.invalid'}else{$taskEndpoint}
 $taskData=@{'api-token'=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes('existing-placeholder'))}
 $taskData[$taskHostKey]=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($taskStoredHost))
 $taskData[$taskIdKey]=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($taskIdentity))
 $global:taskExisting=@{data=$taskData} | ConvertTo-Json -Depth 8 -Compress
}
function global:kubectl {
 $taskArgs=@($args)
 $global:LASTEXITCODE=0
 if($taskArgs -contains 'apply') {
  $global:taskApplied=($input | Out-String) | ConvertFrom-Json
  Write-Output 'mock secret applied'
 } elseif($taskArgs -contains 'secret') { if($global:taskExisting){Write-Output $global:taskExisting} }
}
function global:Read-Host {
 param([string]$Prompt,[switch]$AsSecureString)
 $global:taskPromptCount++
 if(-not $AsSecureString){throw 'Non-secret connection settings were not transferred.'}
 ConvertTo-SecureString 'unit-test-placeholder' -AsPlainText -Force
}
$taskRejected=$false
try { & (Join-Path $PackagePath 'Initialize-ExternalConnection.ps1') } catch { $taskRejected=$true;if($Case -ne 'mismatch'){throw} }
if($Case -eq 'mismatch' -and -not $taskRejected){throw 'Mismatched existing identity was silently reused.'}
if($Case -eq 'new') {
 if($global:taskPromptCount -ne 1 -or -not $global:taskApplied){throw 'Expected exactly one hidden runtime credential prompt.'}
 if($global:taskApplied.kind -ne 'Secret' -or $global:taskApplied.metadata.namespace -ne 'komtas-external-test'){throw 'Secret isolation failed.'}
 if($global:taskApplied.stringData.'api-token' -ne 'unit-test-placeholder'){throw 'Credential was not passed to the local Secret mock.'}
} elseif($global:taskPromptCount -ne 0 -or $global:taskApplied){throw 'Skipped or existing connection unexpectedly requested or rewrote credentials.'}
Write-Output ('PASS '+$Architecture+' '+$Case)
