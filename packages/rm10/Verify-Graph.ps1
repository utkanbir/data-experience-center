[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
$taskGraph=@{}
foreach($taskFile in Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'graph') -File){$taskGraph[$taskFile.Name]=[IO.File]::ReadAllText($taskFile.FullName)}
Write-Rm10Object -Object @{apiVersion='v1';kind='ConfigMap';metadata=@{name='rm10-graph-code';namespace=$Rm10Namespace};data=$taskGraph}
Invoke-Rm10Kubectl -Arguments @('-n',$Rm10Namespace,'exec','rm10-artifacts','--','rm','-f','/artifacts/graph-status.txt','/artifacts/graph-checks.json','/artifacts/graph-results.json') | Out-Host
Start-Rm10Job -Name 'rm10-graph-verify' -Manifest (Join-Path $PSScriptRoot 'k8s/graph-verify-job.yaml')
