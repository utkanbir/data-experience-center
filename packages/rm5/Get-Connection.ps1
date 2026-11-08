[CmdletBinding()]
param([ValidateRange(1024,65535)][int]$Port = 15436)
. (Join-Path $PSScriptRoot 'Common.ps1')
$taskSecret = (Invoke-Rm5Kubectl -Arguments @('-n', $Rm5Namespace, 'get', 'secret', 'rm5-credentials', '-o', 'json') | Out-String) | ConvertFrom-Json
$taskPassword = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($taskSecret.data.'bi-password'))
[pscustomobject]@{ Server = "127.0.0.1:$Port"; Database = 'komtas_rm5'; Username = 'rm5_bi'; Password = $taskPassword } | Format-List
