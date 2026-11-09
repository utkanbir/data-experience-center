[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
$taskRun='run-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'-'+[Guid]::NewGuid().ToString('N').Substring(0,8)
$taskReportDir=Join-Path $PSScriptRoot ('reports/'+$taskRun)
$taskOld=@('dbt-status.txt','cube-status.txt','governance-status.txt','manifest.json','build_results.json','catalog.json','static_index.html','dbt-checks.json','cube-checks.json','cube-results.json','cube-sql.json','python-results.json','dashboard-results.json','governance-checks.json','catalog-lineage-map.json','graph-status.txt','graph-checks.json','graph-results.json') | ForEach-Object {'/artifacts/'+$_}
Invoke-Rm10Kubectl -Arguments (@('-n',$Rm10Namespace,'exec','rm10-artifacts','--','rm','-f')+$taskOld) | Out-Host
$taskStages=@{dbt=$true;cube=$true;catalog=$true;graph=$true}
try { & (Join-Path $PSScriptRoot 'Build-Models.ps1') } catch { Write-Warning 'dbt failed; report will preserve evidence.' }
try { & (Join-Path $PSScriptRoot 'Test-Cube.ps1') } catch { Write-Warning 'Cube failed; report will preserve evidence.' }
try { & (Join-Path $PSScriptRoot 'Verify-Catalog.ps1') } catch { Write-Warning 'Catalog measurement failed; report will preserve evidence.' }
try { & (Join-Path $PSScriptRoot 'Verify-Graph.ps1') } catch { Write-Warning 'Graph verification failed; report will preserve evidence.' }
$taskData=@{'scenario.py'=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'experience/scenario.py'));'report-profile.json'=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'report-profile.json'));'ontology.json'=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'graph/ontology.json'));'run.json'=(@{runId=$taskRun;stages=$taskStages}|ConvertTo-Json -Depth 8 -Compress)}
foreach($taskName in @('01-kanal-geliri.sql','02-horeca-degisim.sql','03-distributor-urun.sql','verify.sql')){$taskData[$taskName]=[IO.File]::ReadAllText((Join-Path $PSScriptRoot ('sql/'+$taskName)))}
Write-Rm10Object -Object @{apiVersion='v1';kind='ConfigMap';metadata=@{name='rm10-experience';namespace=$Rm10Namespace};data=$taskData}
Start-Rm10Job -Name 'rm10-scenario' -Manifest (Join-Path $PSScriptRoot 'k8s/scenario-job.yaml')
New-Item -ItemType Directory -Path $taskReportDir -Force | Out-Null
Push-Location -LiteralPath $taskReportDir
try { & kubectl --context $Rm10Context -n $Rm10Namespace cp ("rm10-artifacts:/artifacts/runs/"+$taskRun+"/.") './';if($LASTEXITCODE -ne 0){throw 'Report copying failed.'} } finally {Pop-Location}
$taskJson=[IO.File]::ReadAllText((Join-Path $taskReportDir 'sonuc.json'))
$taskResult=$taskJson|ConvertFrom-Json
$taskBase64=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($taskJson))
$taskGraphResult=Join-Path $taskReportDir 'kanitlar/graph-results.json'
$taskGraphJson=if(Test-Path -LiteralPath $taskGraphResult){[IO.File]::ReadAllText($taskGraphResult)}else{'{}'}
$taskGraphBase64=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($taskGraphJson))
$taskHtml=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'report-template.html')).Replace('__RESULT_BASE64__',$taskBase64).Replace('__GRAPH_RESULTS_BASE64__',$taskGraphBase64)
[IO.File]::WriteAllText((Join-Path $taskReportDir 'rapor.html'),$taskHtml,(New-Object Text.UTF8Encoding $false))
Write-Host "Rapor: $taskReportDir/rapor.html"
Write-Host "Uygulamaya yukle: $taskReportDir/sonuc.json"
if(@($taskResult.executions|Where-Object {$_.status -ne 'passed'}).Count -or @($taskResult.observation.checks|Where-Object {$_.status -ne 'passed'}).Count){throw 'Graph deneyi tam dogrulanmadi. Rapordaki basarisiz/denenmedi kontrollerini inceleyin.'}
