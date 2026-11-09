[CmdletBinding()]
param([string]$ApiHost,[string]$OrgId)
. (Join-Path $PSScriptRoot 'Common.ps1')
$taskConfig=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'cdgc/settings.json') -Raw | ConvertFrom-Json
if(-not $ApiHost) { $ApiHost=[string]$taskConfig.apiHost }
if(-not $OrgId) { $OrgId=[string]$taskConfig.orgId }
if(-not $ApiHost) { $ApiHost=Read-Host 'CDGC API host (idmc-api...informaticacloud.com)' }
if(-not $OrgId) { $OrgId=Read-Host 'Informatica Org ID' }
$ApiHost=$ApiHost.Trim().ToLowerInvariant()
if($ApiHost -notmatch '^idmc-api(\.[a-z0-9-]+)+\.informaticacloud\.com$') { throw 'Resmi idmc-api host adi gerekli; URL yolu veya token girmeyin.' }
if($OrgId -notmatch '^[A-Za-z0-9_-]{1,100}$') { throw 'Org ID gecersiz.' }
$taskSecure=Read-Host 'CDGC JWT (gizli; suresi dolunca yenileyin)' -AsSecureString
$taskPointer=[Runtime.InteropServices.Marshal]::SecureStringToBSTR($taskSecure)
try {
 $taskToken=[Runtime.InteropServices.Marshal]::PtrToStringBSTR($taskPointer)
 if([string]::IsNullOrWhiteSpace($taskToken) -or $taskToken -match '[\r\n]') { throw 'JWT gecersiz.' }
 Write-Rm8Object -Object @{apiVersion='v1';kind='Secret';metadata=@{name='rm8-informatica';namespace=$Rm8Namespace};type='Opaque';stringData=@{'api-token'=$taskToken;'api-host'=$ApiHost;'org-id'=$OrgId}}
} finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($taskPointer);$taskToken=$null }
Write-Host 'Kimlik bilgileri yalniz yerel Kubernetes Secret icinde. cdgc/settings.json varlik eslemesini tamamlayip Run-CDGC.ps1 calistirin.'

[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'cdgc/connection-mode.txt'),"connect`n",(New-Object Text.UTF8Encoding $false))
