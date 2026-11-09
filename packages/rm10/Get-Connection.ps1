[CmdletBinding()]
param([ValidateRange(1024,65535)][int]$Port = 15441)
. (Join-Path $PSScriptRoot 'Common.ps1')
$taskSecret = (Invoke-Rm10Kubectl -Arguments @('-n', $Rm10Namespace, 'get', 'secret', 'rm10-credentials', '-o', 'json') | Out-String) | ConvertFrom-Json
$taskPassword = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($taskSecret.data.'bi-password'))
[pscustomobject]@{ Server = "127.0.0.1:$Port"; Database = 'komtas_rm10'; Username = 'rm10_bi'; Password = $taskPassword } | Format-List
