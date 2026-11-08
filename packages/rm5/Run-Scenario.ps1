[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
$taskReportDir = Join-Path $PSScriptRoot ('reports/run-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [Guid]::NewGuid().ToString('N').Substring(0,8))
$taskEvidenceDir = Join-Path $taskReportDir 'kanitlar'
New-Item -ItemType Directory -Path $taskEvidenceDir -Force | Out-Null
$taskExecutions = @()
try { & (Join-Path $PSScriptRoot 'Build-Models.ps1') } catch { Write-Warning 'dbt build/test failed; report will preserve the evidence.' }
try { & (Join-Path $PSScriptRoot 'Test-Cube.ps1') } catch { Write-Warning 'Cube checks failed; report will preserve evidence.' }
try { & (Join-Path $PSScriptRoot 'Verify-Catalog.ps1') } catch { Write-Warning 'Governance checks failed; report will preserve evidence.' }
$taskGovStates=@('not_tested','not_tested','not_tested','not_tested','not_tested','not_tested','not_tested')
try { $taskLines=@(Invoke-Rm5Kubectl -Arguments @('-n',$Rm5Namespace,'exec','rm5-artifacts','--','cat','/artifacts/governance-status.txt')); if ($taskLines.Count -eq 7 -and @($taskLines | Where-Object { $_ -notin @('passed','failed','not_tested') }).Count -eq 0) { $taskGovStates=$taskLines } } catch { Write-Warning 'Governance evidence unavailable.' }
$taskCubeStates=@('not_tested','not_tested','not_tested','not_tested','not_tested')
try { $taskLines=@(Invoke-Rm5Kubectl -Arguments @('-n',$Rm5Namespace,'exec','rm5-artifacts','--','cat','/artifacts/cube-status.txt')); if ($taskLines.Count -eq 5 -and @($taskLines | Where-Object { $_ -notin @('passed','failed','not_tested') }).Count -eq 0) { $taskCubeStates=$taskLines } } catch { Write-Warning 'Cube evidence unavailable.' }
$taskDbtStates = @('not_tested','not_tested','not_tested')
try {
    $taskStatusLines = @(Invoke-Rm5Kubectl -Arguments @('-n',$Rm5Namespace,'exec','rm5-artifacts','--','cat','/artifacts/dbt-status.txt'))
    if ($taskStatusLines.Count -eq 3 -and @($taskStatusLines | Where-Object { $_ -notin @('passed','failed','not_tested') }).Count -eq 0) { $taskDbtStates = $taskStatusLines }
} catch { Write-Warning 'dbt evidence unavailable.' }
foreach ($taskArtifact in @('manifest.json','build_results.json','catalog.json','static_index.html','dbt-checks.json','cube-checks.json','cube-results.json','cube-sql.json','python-results.json','dashboard-results.json','governance-checks.json','catalog-lineage-map.json')) {
    Push-Location -LiteralPath $taskEvidenceDir
    try {
        $ErrorActionPreference = 'Continue'
        & kubectl --context $Rm5Context -n $Rm5Namespace cp "rm5-artifacts:/artifacts/$taskArtifact" ("./" + $taskArtifact) 2>$null
        if ($LASTEXITCODE -ne 0) { Write-Warning "Evidence file unavailable: $taskArtifact" }
    } finally { Pop-Location; $ErrorActionPreference = 'Stop' }
}

foreach ($taskFile in @('01-kanal-geliri.sql','02-horeca-degisim.sql','03-distributor-urun.sql','verify.sql')) {
    Write-Host "Running: $taskFile"
    $taskSql = [IO.File]::ReadAllText((Join-Path $PSScriptRoot "sql/$taskFile"))
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot "sql/$taskFile") -Destination $taskEvidenceDir
    $taskStatus = 'failed'
    try {
        $global:LASTEXITCODE = 1
        $ErrorActionPreference = 'Continue'
        $taskOutput = ("SET ROLE rm5_bi;`n" + $taskSql) | & kubectl --context $Rm5Context -n $Rm5Namespace exec -i postgres-0 -- sh -c 'export PGPASSWORD="$POSTGRES_PASSWORD"; exec psql --no-psqlrc -h 127.0.0.1 -U rm5_admin -d komtas_rm5 -v ON_ERROR_STOP=1' 2>&1
        $ErrorActionPreference = 'Stop'
        if ($LASTEXITCODE -eq 0) { $taskStatus = 'passed' }
    } catch { $taskOutput = $_.Exception.Message } finally { $ErrorActionPreference = 'Stop' }
    $taskOutput | Out-Host
    [IO.File]::WriteAllText((Join-Path $taskEvidenceDir ($taskFile + '.txt')), ($taskOutput | Out-String), (New-Object Text.UTF8Encoding $false))
    $taskExecutions += @{ file = $taskFile; status = $taskStatus }
}
$taskObservation = $null
try {
    $taskReportSql = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'sql/report.sql')).Replace('__DBT_MODELS__',$taskDbtStates[0]).Replace('__DBT_TESTS__',$taskDbtStates[1]).Replace('__DBT_DOCS__',$taskDbtStates[2]).Replace('__API_AUTH__',$taskCubeStates[4]).Replace('__TWO_CONSUMERS__',$taskCubeStates[3]).Replace('__CUBE_MATCH__',$taskCubeStates[2]).Replace('__CUBE_SQL__',$taskCubeStates[1]).Replace('__CUBE_API__',$taskCubeStates[0]).Replace('__OM_CATALOG__',$taskGovStates[0]).Replace('__OM_OWNER__',$taskGovStates[1]).Replace('__OM_GLOSSARY__',$taskGovStates[2]).Replace('__OM_LINEAGE__',$taskGovStates[3]).Replace('__OM_METRIC__',$taskGovStates[4]).Replace('__OM_QUALITY__',$taskGovStates[5]).Replace('__OM_PRODUCT__',$taskGovStates[6])
    $global:LASTEXITCODE = 1
    $ErrorActionPreference = 'Continue'
    $taskRaw = ("SET ROLE rm5_bi;`n" + $taskReportSql) | & kubectl --context $Rm5Context -n $Rm5Namespace exec -i postgres-0 -- sh -c 'export PGPASSWORD="$POSTGRES_PASSWORD"; exec psql --no-psqlrc -Atq -h 127.0.0.1 -U rm5_admin -d komtas_rm5 -v ON_ERROR_STOP=1' 2> (Join-Path $taskEvidenceDir 'report-error.txt')
    $ErrorActionPreference = 'Stop'
    if ($LASTEXITCODE -ne 0) { throw 'Database report query failed.' }
    $taskObservation = ($taskRaw | Out-String) | ConvertFrom-Json
} catch {
    [IO.File]::AppendAllText((Join-Path $taskEvidenceDir 'report-error.txt'), $_.Exception.Message)
} finally { $ErrorActionPreference = 'Stop' }
$taskProfile = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'report-profile.json') -Raw -Encoding UTF8 | ConvertFrom-Json
if (-not $taskObservation) {
    $taskFallbackChecks = @()
    foreach ($taskCheck in $taskProfile.checks) {
        $taskIndex = @('dbt_models','dbt_tests','dbt_docs').IndexOf([string]$taskCheck[0])
        $taskCubeIndex = @('cube_api','cube_sql','cube_match','two_consumers','api_auth').IndexOf([string]$taskCheck[0])
        $taskGovIndex = @('om_catalog','om_owner','om_glossary','om_lineage','om_metric','om_quality','om_product').IndexOf([string]$taskCheck[0])
        $taskState = if ($taskIndex -ge 0) { $taskDbtStates[$taskIndex] } elseif ($taskCubeIndex -ge 0) { $taskCubeStates[$taskCubeIndex] } elseif ($taskGovIndex -ge 0) { $taskGovStates[$taskGovIndex] } else { 'not_tested' }
        $taskFallbackChecks += @{ id=[string]$taskCheck[0]; status=$taskState }
    }
    $taskObservation = @{ checks=$taskFallbackChecks; metrics=@{janRevenue=$null;febRevenue=$null;janLiters=$null;febLiters=$null;change=$null} }
}
$taskResult = @{ schemaVersion = 1; architecture = $taskProfile.architecture; architectureVersion = $taskProfile.architectureVersion; scenario = $taskProfile.scenario; generatedAt = [DateTime]::UtcNow.ToString('o'); namespace = $Rm5Namespace; executions = $taskExecutions; observation = $taskObservation }
$taskJson = $taskResult | ConvertTo-Json -Depth 12
[IO.File]::WriteAllText((Join-Path $taskReportDir 'sonuc.json'), $taskJson, (New-Object Text.UTF8Encoding $false))
$taskBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($taskJson))
$taskHtml = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'report-template.html')).Replace('__RESULT_BASE64__', $taskBase64)
[IO.File]::WriteAllText((Join-Path $taskReportDir 'rapor.html'), $taskHtml, (New-Object Text.UTF8Encoding $false))
Write-Host "Rapor: $taskReportDir/rapor.html"
Write-Host "Uygulamaya yukle: $taskReportDir/sonuc.json"
if (($taskExecutions | Where-Object { $_.status -ne 'passed' }) -or -not $taskObservation -or ($taskObservation.checks | Where-Object { $_.status -ne 'passed' })) { throw 'Deney tam dogrulanmadi. Raporu ve kanitlari inceleyin.' }
