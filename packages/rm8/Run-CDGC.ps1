[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
$taskFiles=@{}
foreach($taskFile in Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'cdgc') -File) { if($taskFile.Extension -in @('.py','.json')) { $taskFiles[$taskFile.Name]=[IO.File]::ReadAllText($taskFile.FullName) } }
Write-Rm8Object -Object @{apiVersion='v1';kind='ConfigMap';metadata=@{name='rm8-cdgc';namespace=$Rm8Namespace};data=$taskFiles}
Invoke-Rm8Kubectl -Arguments @('-n',$Rm8Namespace,'exec','rm8-artifacts','--','rm','-f','/artifacts/cdgc-status.txt','/artifacts/cdgc-checks.json','/artifacts/cdgc-approval-template.json') | Out-Host
Start-Rm8Job -Name 'rm8-cdgc' -Manifest (Join-Path $PSScriptRoot 'k8s/cdgc-job.yaml')
