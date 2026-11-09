[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
Write-Host '5 dakika gecerli yerel lab tokeni; paylasmayin. API: http://127.0.0.1:4009/cubejs-api/v1/meta'
Invoke-Rm9Kubectl -Arguments @('-n',$Rm9Namespace,'exec','deployment/dashboard','--','python','-c','import sys;sys.path.insert(0,"/consumer");from client import token;print(token())') | Out-Host
