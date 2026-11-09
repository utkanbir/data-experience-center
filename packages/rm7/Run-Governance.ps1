[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
$taskFiles=@{}
foreach($taskFile in Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'governance') -File) { if($taskFile.Extension -in @('.py','.json','.txt')) { $taskFiles[$taskFile.Name]=[IO.File]::ReadAllText($taskFile.FullName) } }
Write-Rm7Object -Object @{apiVersion='v1';kind='ConfigMap';metadata=@{name='rm7-governance';namespace=$Rm7Namespace};data=$taskFiles}
Invoke-Rm7Kubectl -Arguments @('-n',$Rm7Namespace,'exec','rm7-artifacts','--','rm','-f','/artifacts/cdgc-status.txt','/artifacts/cdgc-checks.json','/artifacts/cdgc-approval-template.json') | Out-Host
Start-Rm7Job -Name 'rm7-governance' -Manifest (Join-Path $PSScriptRoot 'k8s/governance-job.yaml')
