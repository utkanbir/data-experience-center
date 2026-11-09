[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Invoke-Rm8Kubectl -Arguments @('-n',$Rm8Namespace,'exec','deployment/dashboard','--','python','/consumer/client.py') | Out-Host
