[CmdletBinding()]
param([ValidateRange(1024,65535)][int]$Port = 15438)
. (Join-Path $PSScriptRoot 'Common.ps1')
$taskSecret = (Invoke-Rm7Kubectl -Arguments @('-n', $Rm7Namespace, 'get', 'secret', 'rm7-credentials', '-o', 'json') | Out-String) | ConvertFrom-Json
$taskPassword = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($taskSecret.data.'bi-password'))
[pscustomobject]@{ Server = "127.0.0.1:$Port"; Database = 'komtas_rm7'; Username = 'rm7_bi'; Password = $taskPassword } | Format-List
