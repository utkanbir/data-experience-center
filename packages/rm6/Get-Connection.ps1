[CmdletBinding()]
param([ValidateRange(1024,65535)][int]$Port = 15437)
. (Join-Path $PSScriptRoot 'Common.ps1')
$taskSecret = (Invoke-Rm6Kubectl -Arguments @('-n', $Rm6Namespace, 'get', 'secret', 'rm6-credentials', '-o', 'json') | Out-String) | ConvertFrom-Json
$taskPassword = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($taskSecret.data.'bi-password'))
[pscustomobject]@{ Server = "127.0.0.1:$Port"; Database = 'komtas_rm6'; Username = 'rm6_bi'; Password = $taskPassword } | Format-List
