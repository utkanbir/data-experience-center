[CmdletBinding()]
param([switch]$RequireComplete)
. (Join-Path $PSScriptRoot 'Common.ps1')
$taskReportDir = Join-Path $PSScriptRoot ('reports/run-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [Guid]::NewGuid().ToString('N').Substring(0,8))
$taskEvidenceDir = Join-Path $taskReportDir 'kanitlar'
New-Item -ItemType Directory -Path $taskEvidenceDir -Force | Out-Null
$taskExecutions = @()
try { & (Join-Path $PSScriptRoot 'Build-Models.ps1') } catch { Write-Warning 'dbt build/test failed; report will preserve the evidence.' }
try { & (Join-Path $PSScriptRoot 'Run-RemoteChecks.ps1') } catch { Write-Warning 'Managed service check failed; preserving evidence.' }
$taskRemoteStates=@('not_tested','not_tested','not_tested','not_tested','not_tested')
try { $taskLines=@(Invoke-Rm6Kubectl -Arguments @('-n',$Rm6Namespace,'exec','rm6-artifacts','--','cat','/artifacts/managed-status.txt')); if ($taskLines.Count -eq 5 -and @($taskLines | Where-Object { $_ -notin @('passed','failed','not_tested') }).Count -eq 0) { $taskRemoteStates=$taskLines } } catch { Write-Warning 'Managed evidence unavailable.' }
$taskDbtStates = @('not_tested','not_tested','not_tested','not_tested')
try {
    $taskStatusLines = @(Invoke-Rm6Kubectl -Arguments @('-n',$Rm6Namespace,'exec','rm6-artifacts','--','cat','/artifacts/dbt-status.txt'))
    if ($taskStatusLines.Count -eq 4 -and @($taskStatusLines | Where-Object { $_ -notin @('passed','failed','not_tested') }).Count -eq 0) { $taskDbtStates = $taskStatusLines }
} catch { Write-Warning 'dbt evidence unavailable.' }
foreach ($taskArtifact in @('manifest.json','build_results.json','catalog.json','static_index.html','dbt-checks.json','semantic_manifest.json','managed-checks.json','managed-results.json','managed-sql.txt','powerbi-results.json')) {
    Push-Location -LiteralPath $taskEvidenceDir
    try {
        $ErrorActionPreference = 'Continue'
        & kubectl --context $Rm6Context -n $Rm6Namespace cp "rm6-artifacts:/artifacts/$taskArtifact" ("./" + $taskArtifact) 2>$null
        if ($LASTEXITCODE -ne 0 -and $taskArtifact -notin @('managed-results.json','managed-sql.txt','powerbi-results.json')) { Write-Warning "Evidence file unavailable: $taskArtifact" }
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
        $taskOutput = ("SET ROLE rm6_bi;`n" + $taskSql) | & kubectl --context $Rm6Context -n $Rm6Namespace exec -i postgres-0 -- sh -c 'export PGPASSWORD="$POSTGRES_PASSWORD"; exec psql --no-psqlrc -h 127.0.0.1 -U rm6_admin -d komtas_rm6 -v ON_ERROR_STOP=1' 2>&1
        $ErrorActionPreference = 'Stop'
        if ($LASTEXITCODE -eq 0) { $taskStatus = 'passed' }
    } catch { $taskOutput = $_.Exception.Message } finally { $ErrorActionPreference = 'Stop' }
    $taskOutput | Out-Host
    [IO.File]::WriteAllText((Join-Path $taskEvidenceDir ($taskFile + '.txt')), ($taskOutput | Out-String), (New-Object Text.UTF8Encoding $false))
    $taskExecutions += @{ file = $taskFile; status = $taskStatus }
}
$taskObservation = $null
try {
    $taskReportSql = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'sql/report.sql')).Replace('__DBT_MODELS__',$taskDbtStates[0]).Replace('__DBT_TESTS__',$taskDbtStates[1]).Replace('__DBT_DOCS__',$taskDbtStates[2]).Replace('__SEMANTIC_MODEL__',$taskDbtStates[3]).Replace('__SL_METADATA__',$taskRemoteStates[0]).Replace('__SL_QUERY__',$taskRemoteStates[1]).Replace('__SL_SQL__',$taskRemoteStates[2]).Replace('__SL_MATCH__',$taskRemoteStates[3]).Replace('__SL_POWERBI__',$taskRemoteStates[4])
    $global:LASTEXITCODE = 1
    $ErrorActionPreference = 'Continue'
    $taskRaw = ("SET ROLE rm6_bi;`n" + $taskReportSql) | & kubectl --context $Rm6Context -n $Rm6Namespace exec -i postgres-0 -- sh -c 'export PGPASSWORD="$POSTGRES_PASSWORD"; exec psql --no-psqlrc -Atq -h 127.0.0.1 -U rm6_admin -d komtas_rm6 -v ON_ERROR_STOP=1' 2> (Join-Path $taskEvidenceDir 'report-error.txt')
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
        $taskIndex = @('dbt_models','dbt_tests','dbt_docs','semantic_model').IndexOf([string]$taskCheck[0])
        $taskRemoteIndex=@('sl_metadata','sl_query','sl_sql','sl_match','sl_powerbi').IndexOf([string]$taskCheck[0])
        $taskState = if ($taskIndex -ge 0) { $taskDbtStates[$taskIndex] } elseif ($taskRemoteIndex -ge 0) { $taskRemoteStates[$taskRemoteIndex] } else { 'not_tested' }
        $taskFallbackChecks += @{ id=[string]$taskCheck[0]; status=$taskState }
    }
    $taskObservation = @{ checks=$taskFallbackChecks; metrics=@{janRevenue=$null;febRevenue=$null;janLiters=$null;febLiters=$null;change=$null} }
}
$taskResult = @{ schemaVersion = 1; architecture = $taskProfile.architecture; architectureVersion = $taskProfile.architectureVersion; scenario = $taskProfile.scenario; generatedAt = [DateTime]::UtcNow.ToString('o'); namespace = $Rm6Namespace; executions = $taskExecutions; observation = $taskObservation }
$taskJson = $taskResult | ConvertTo-Json -Depth 12
[IO.File]::WriteAllText((Join-Path $taskReportDir 'sonuc.json'), $taskJson, (New-Object Text.UTF8Encoding $false))
$taskBase64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($taskJson))
$taskHtml = [IO.File]::ReadAllText((Join-Path $PSScriptRoot 'report-template.html')).Replace('__RESULT_BASE64__', $taskBase64)
[IO.File]::WriteAllText((Join-Path $taskReportDir 'rapor.html'), $taskHtml, (New-Object Text.UTF8Encoding $false))
Write-Host "Rapor: $taskReportDir/rapor.html"
Write-Host "Uygulamaya yukle: $taskReportDir/sonuc.json"
if ($taskDbtStates | Where-Object { $_ -ne 'passed' }) { throw 'Yerel dbt / semantic manifest adimlari dogrulanmadi. Raporu inceleyin.' }
if (($taskExecutions | Where-Object { $_.status -ne 'passed' }) -or -not $taskObservation -or ($taskObservation.checks | Where-Object { $_.status -eq 'failed' })) { throw 'Deney tam dogrulanmadi. Raporu ve kanitlari inceleyin.' }

if ($taskObservation.checks | Where-Object { $_.status -eq 'not_tested' }) { Write-Warning 'Deney kismi: harici dbt / Power BI kontrolleri henuz denenmedi. rapor.html icindeki gri adimlari tamamlayin.'; if ($RequireComplete) { throw 'Tam dogrulama isteniyor ancak harici kanitlar eksik.' } }
