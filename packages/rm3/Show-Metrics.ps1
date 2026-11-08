[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
foreach ($taskName in @('metricflow-results.csv','metricflow-sql.txt')) { Invoke-Rm3Kubectl -Arguments @('-n',$Rm3Namespace,'exec','rm3-artifacts','--','cat',"/artifacts/$taskName") | Out-Host }
