[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Invoke-Rm7Kubectl -Arguments @('-n',$Rm7Namespace,'exec','deployment/dashboard','--','python','/consumer/client.py') | Out-Host
