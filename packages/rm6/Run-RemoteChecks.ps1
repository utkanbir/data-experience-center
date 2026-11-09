[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
$taskManaged=@{}
foreach($taskFile in Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'managed') -File) { $taskManaged[$taskFile.Name]=[IO.File]::ReadAllText($taskFile.FullName) }
Write-Rm6Object -Object @{apiVersion='v1';kind='ConfigMap';metadata=@{name='rm6-managed';namespace=$Rm6Namespace};data=$taskManaged}
Invoke-Rm6Kubectl -Arguments @('-n',$Rm6Namespace,'exec','rm6-artifacts','--','rm','-f','/artifacts/managed-status.txt','/artifacts/managed-checks.json') | Out-Host
Start-Rm6Job -Name 'rm6-managed' -Manifest (Join-Path $PSScriptRoot 'k8s/managed-job.yaml')
