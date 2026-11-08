[CmdletBinding()]
param([ValidateRange(1024,65535)][int]$Port = 15435)
. (Join-Path $PSScriptRoot 'Common.ps1')
$taskSecret = (Invoke-Rm4Kubectl -Arguments @('-n', $Rm4Namespace, 'get', 'secret', 'rm4-credentials', '-o', 'json') | Out-String) | ConvertFrom-Json
$taskPassword = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($taskSecret.data.'bi-password'))
[pscustomobject]@{ Server = "127.0.0.1:$Port"; Database = 'komtas_rm4'; Username = 'rm4_bi'; Password = $taskPassword } | Format-List
