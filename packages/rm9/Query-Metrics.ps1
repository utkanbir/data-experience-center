[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Invoke-Rm9Kubectl -Arguments @('-n',$Rm9Namespace,'exec','deployment/dashboard','--','python','/consumer/client.py') | Out-Host
