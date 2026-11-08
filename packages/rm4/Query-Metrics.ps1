[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Invoke-Rm4Kubectl -Arguments @('-n',$Rm4Namespace,'exec','deployment/dashboard','--','python','/consumer/client.py') | Out-Host
