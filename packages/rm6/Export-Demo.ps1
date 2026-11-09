[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
$taskDirectory=Join-Path $PSScriptRoot 'cloud-transfer'
New-Item -ItemType Directory -Path $taskDirectory -Force | Out-Null
$taskDump=Invoke-Rm6Kubectl -Arguments @('-n',$Rm6Namespace,'exec','postgres-0','--','sh','-c','export PGPASSWORD="$POSTGRES_PASSWORD"; exec pg_dump --no-owner --no-privileges --schema=raw -U rm6_admin -d komtas_rm6')
[IO.File]::WriteAllText((Join-Path $taskDirectory 'demo.sql'),($taskDump | Out-String),(New-Object Text.UTF8Encoding $false))
Write-Host 'cloud-transfer/demo.sql olustu: yalniz sentetik raw schema/verisi. Harici sisteme aktarim yapilmadi. Ayrilmis lab PostgreSQL hedefini kendiniz saglayin.'
