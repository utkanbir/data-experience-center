[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
$taskBridge=@{}
foreach($taskFile in Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'bridge') -File) { $taskBridge[$taskFile.Name]=[IO.File]::ReadAllText($taskFile.FullName) }
Write-Rm8Object -Object @{apiVersion='v1';kind='ConfigMap';metadata=@{name='rm8-dual';namespace=$Rm8Namespace};data=$taskBridge}
Invoke-Rm8Kubectl -Arguments @('-n',$Rm8Namespace,'exec','rm8-artifacts','--','rm','-f','/artifacts/dual-status.txt','/artifacts/dual-checks.json') | Out-Host
Start-Rm8Job -Name 'rm8-dual-verify' -Manifest (Join-Path $PSScriptRoot 'k8s/dual-verify-job.yaml')
