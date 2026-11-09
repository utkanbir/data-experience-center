[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
$taskSql="ALTER TABLE raw.dim_outlet_unavailable RENAME TO dim_outlet;"
$taskSql | & kubectl --context $Rm9Context -n $Rm9Namespace exec -i postgres-reference-0 -- sh -c 'export PGPASSWORD="$POSTGRES_PASSWORD"; exec psql -h 127.0.0.1 -U rm9_admin -d komtas_rm9_reference -v ON_ERROR_STOP=1'
if($LASTEXITCODE -ne 0){throw 'Reference table change failed.'}
Write-Host 'Yalniz bu lab referans tablosunun adi degisti. Restore-Reference sonrasi Build-Models ve deneyi yeniden calistirin.'
