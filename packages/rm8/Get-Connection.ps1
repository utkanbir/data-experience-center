[CmdletBinding()]
param([ValidateRange(1024,65535)][int]$Port = 15439)
. (Join-Path $PSScriptRoot 'Common.ps1')
$taskSecret = (Invoke-Rm8Kubectl -Arguments @('-n', $Rm8Namespace, 'get', 'secret', 'rm8-credentials', '-o', 'json') | Out-String) | ConvertFrom-Json
$taskPassword = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($taskSecret.data.'bi-password'))
[pscustomobject]@{ Server = "127.0.0.1:$Port"; Database = 'komtas_rm8'; Username = 'rm8_bi'; Password = $taskPassword } | Format-List
