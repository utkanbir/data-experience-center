[CmdletBinding()]
param([ValidateSet('Inject','Restore')][string]$Mode)
. (Join-Path $PSScriptRoot 'Common.ps1')
if (-not $Mode) { throw '-Mode Inject veya Restore gerekli.' }
$taskModel = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'cube/schema/Sales.js'))
if ($Mode -eq 'Inject') { $taskModel=$taskModel.Replace('gross_revenue_eur - discount_amount_eur - return_amount_eur','gross_revenue_eur') }
Write-Rm7Object -Object @{apiVersion='v1';kind='ConfigMap';metadata=@{name='rm7-cube-model';namespace=$Rm7Namespace};data=@{'Sales.js'=$taskModel}}
Invoke-Rm7Kubectl -Arguments @('-n',$Rm7Namespace,'rollout','restart','deployment/cube') | Out-Host
Invoke-Rm7Kubectl -Arguments @('-n',$Rm7Namespace,'rollout','status','deployment/cube','--timeout=180s') | Out-Host
Write-Host "Metric formula mode: $Mode. Run-Scenario.ps1 ile raporu yeniden uretin."
