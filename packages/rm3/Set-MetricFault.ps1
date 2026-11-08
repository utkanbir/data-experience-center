[CmdletBinding()]
param([Parameter(Mandatory=$true)][ValidateSet('Inject','Restore')][string]$Mode)
. (Join-Path $PSScriptRoot 'Common.ps1')
$taskProject = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'dbt-project.json')) | ConvertFrom-Json
if ($Mode -eq 'Inject') { $taskProject.'models/metrics.yml' = $taskProject.'models/metrics.yml'.Replace('gross_revenue_eur - discount_amount_eur - return_amount_eur','gross_revenue_eur') }
Write-Rm3Object -Object @{apiVersion='v1';kind='ConfigMap';metadata=@{name='rm3-dbt';namespace=$Rm3Namespace};data=@{'project.json'=($taskProject | ConvertTo-Json -Depth 10);'runner.py'=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'runner.py'))}}
Write-Host 'Semantic tanim guncellendi. Run-Scenario.ps1 ile hesap ve referans karsilastirmasini calistirin.'
