[CmdletBinding()]
param([ValidateRange(1024,65535)][int]$Port = 15440)
. (Join-Path $PSScriptRoot 'Common.ps1')
$taskSecret = (Invoke-Rm9Kubectl -Arguments @('-n', $Rm9Namespace, 'get', 'secret', 'rm9-credentials', '-o', 'json') | Out-String) | ConvertFrom-Json
$taskPassword = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($taskSecret.data.'bi-password'))
[pscustomobject]@{ Server = "127.0.0.1:$Port"; Database = 'komtas_rm9'; Username = 'rm9_bi'; Password = $taskPassword } | Format-List
