[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Invoke-Rm5Kubectl -Arguments @('-n',$Rm5Namespace,'exec','deployment/dashboard','--','python','/consumer/client.py') | Out-Host
