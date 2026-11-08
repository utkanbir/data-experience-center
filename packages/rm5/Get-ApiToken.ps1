[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Write-Host '5 dakika gecerli yerel lab tokeni; paylasmayin. API: http://127.0.0.1:4005/cubejs-api/v1/meta'
Invoke-Rm5Kubectl -Arguments @('-n',$Rm5Namespace,'exec','deployment/dashboard','--','python','-c','import sys;sys.path.insert(0,"/consumer");from client import token;print(token())') | Out-Host
