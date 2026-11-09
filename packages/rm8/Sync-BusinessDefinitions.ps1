[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
$taskBridge=@{}
foreach($taskFile in Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'bridge') -File) { $taskBridge[$taskFile.Name]=[IO.File]::ReadAllText($taskFile.FullName) }
Write-Rm8Object -Object @{apiVersion='v1';kind='ConfigMap';metadata=@{name='rm8-dual';namespace=$Rm8Namespace};data=$taskBridge}
& (Join-Path $PSScriptRoot 'Run-CDGC.ps1')
Start-Rm8Job -Name 'rm8-dual-sync' -Manifest (Join-Path $PSScriptRoot 'k8s/dual-sync-job.yaml')
