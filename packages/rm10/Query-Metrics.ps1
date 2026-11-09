[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Invoke-Rm10Kubectl -Arguments @('-n',$Rm10Namespace,'exec','deployment/dashboard','--','python','/consumer/client.py') | Out-Host
