[CmdletBinding()]
param([ValidateRange(1024,65535)][int]$Port = 15434)
. (Join-Path $PSScriptRoot 'Common.ps1')
$taskSecret = (Invoke-Rm3Kubectl -Arguments @('-n', $Rm3Namespace, 'get', 'secret', 'rm3-credentials', '-o', 'json') | Out-String) | ConvertFrom-Json
$taskPassword = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($taskSecret.data.'bi-password'))
[pscustomobject]@{ Server = "127.0.0.1:$Port"; Database = 'komtas_rm3'; Username = 'rm3_bi'; Password = $taskPassword } | Format-List
