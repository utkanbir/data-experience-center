[CmdletBinding()]
param([Parameter(Mandatory=$true)][ValidateSet('Inject','Restore')][string]$Mode)
. (Join-Path $PSScriptRoot 'Common.ps1')
$taskName = if ($Mode -eq 'Inject') { 'fault-inject.sql' } else { 'fault-restore.sql' }
$taskSql = [IO.File]::ReadAllText((Join-Path $PSScriptRoot "sql/$taskName"))
$taskSql | & kubectl --context $Rm2Context -n $Rm2Namespace exec -i postgres-0 -- sh -c 'export PGPASSWORD="$POSTGRES_PASSWORD"; exec psql --no-psqlrc -h 127.0.0.1 -U rm2_admin -d komtas_rm2 -v ON_ERROR_STOP=1'
if ($LASTEXITCODE -ne 0) { throw 'Demo fault operation failed.' }
Write-Host 'Kaynak guncellendi. Run-Scenario.ps1 ile modeli/testleri ve raporu yeniden olusturun.'
