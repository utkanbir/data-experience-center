[CmdletBinding()]
param([ValidateRange(1024,65535)][int]$Port = 15433)
. (Join-Path $PSScriptRoot 'Common.ps1')
$taskSecret = (Invoke-Rm2Kubectl -Arguments @('-n', $Rm2Namespace, 'get', 'secret', 'rm2-credentials', '-o', 'json') | Out-String) | ConvertFrom-Json
$taskPassword = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($taskSecret.data.'bi-password'))
[pscustomobject]@{ Server = "127.0.0.1:$Port"; Database = 'komtas_rm2'; Username = 'rm2_bi'; Password = $taskPassword } | Format-List
