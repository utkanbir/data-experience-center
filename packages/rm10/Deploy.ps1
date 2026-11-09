[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) { throw 'kubectl bulunamadi. Docker Desktop kurulumu ve PATH kontrol edilmeli.' }
Invoke-Rm10Kubectl -Arguments @('get', 'nodes', '--request-timeout=10s') | Out-Host
$taskClasses = (Invoke-Rm10Kubectl -Arguments @('get', 'storageclass', '-o', 'json') | Out-String) | ConvertFrom-Json
$taskDefault = @($taskClasses.items | Where-Object { $_.metadata.annotations.'storageclass.kubernetes.io/is-default-class' -eq 'true' -or $_.metadata.annotations.'storageclass.beta.kubernetes.io/is-default-class' -eq 'true' })
if ($taskDefault.Count -eq 0) { throw 'Varsayilan StorageClass bulunamadi. Docker Desktop Kubernetes depolamasi hazir olmali.' }
Invoke-Rm10Kubectl -Arguments @('apply', '-f', (Join-Path $PSScriptRoot 'k8s/namespace.yaml')) | Out-Host
$taskExistingSecret = (Invoke-Rm10Kubectl -Arguments @('-n', $Rm10Namespace, 'get', 'secret', 'rm10-credentials', '--ignore-not-found=true', '-o', 'name') | Out-String).Trim()
if (-not $taskExistingSecret) {
    $taskPod = (Invoke-Rm10Kubectl -Arguments @('-n', $Rm10Namespace, 'get', 'pvc', 'data-postgres-0', '--ignore-not-found=true', '-o', 'name') | Out-String).Trim()
    if ($taskPod) { throw 'Mevcut PVC var ancak parola Secret kayip. Yeni parola uretmeden mevcut Secret yedegini geri yukleyin.' }
    Write-Rm10Object -Object @{
        apiVersion = 'v1'; kind = 'Secret'
        metadata = @{ name = 'rm10-credentials'; namespace = $Rm10Namespace }
        type = 'Opaque'
        stringData = @{ 'admin-password' = (New-Rm10Password); 'bi-password' = (New-Rm10Password); 'dbt-password' = (New-Rm10Password) }
    }
}
$taskSql = @{}
foreach ($taskSqlFile in Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'sql') -Filter '*.sql') {
    $taskSql[$taskSqlFile.Name] = [IO.File]::ReadAllText($taskSqlFile.FullName)
}
Write-Rm10Object -Object @{
    apiVersion = 'v1'; kind = 'ConfigMap'
    metadata = @{ name = 'rm10-sql'; namespace = $Rm10Namespace }
    data = $taskSql
}
Invoke-Rm10Kubectl -Arguments @('apply', '-f', (Join-Path $PSScriptRoot 'k8s/postgres.yaml')) | Out-Host
Invoke-Rm10Kubectl -Arguments @('-n', $Rm10Namespace, 'rollout', 'status', 'statefulset/postgres', '--timeout=330s') | Out-Host
Write-Rm10Object -Object @{ apiVersion='v1'; kind='ConfigMap'; metadata=@{name='rm10-dbt';namespace=$Rm10Namespace}; data=@{'project.json'=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'dbt-project.json'));'runner.py'=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'runner.py'))} }
Invoke-Rm10Kubectl -Arguments @('apply','-f',(Join-Path $PSScriptRoot 'k8s/dbt-artifacts.yaml')) | Out-Host
Invoke-Rm10Kubectl -Arguments @('-n',$Rm10Namespace,'wait','--for=condition=Ready','pod/rm10-artifacts','--timeout=330s') | Out-Host
Start-Rm10Job -Name 'rm10-seed' -Manifest (Join-Path $PSScriptRoot 'k8s/seed-job.yaml')
& (Join-Path $PSScriptRoot 'Build-Models.ps1')
Start-Rm10Job -Name 'rm10-verify' -Manifest (Join-Path $PSScriptRoot 'k8s/verify-job.yaml')
Invoke-Rm10Kubectl -Arguments @('-n', $Rm10Namespace, 'get', 'pods,svc,pvc,jobs') | Out-Host
Invoke-Rm10Kubectl -Arguments @('apply','-f',(Join-Path $PSScriptRoot 'k8s/dbt-docs.yaml')) | Out-Host
Invoke-Rm10Kubectl -Arguments @('-n',$Rm10Namespace,'rollout','status','deployment/dbt-docs','--timeout=180s') | Out-Host

$taskApi = (Invoke-Rm10Kubectl -Arguments @('-n',$Rm10Namespace,'get','secret','rm10-api','--ignore-not-found=true','-o','name') | Out-String).Trim()
if (-not $taskApi) { Write-Rm10Object -Object @{apiVersion='v1';kind='Secret';metadata=@{name='rm10-api';namespace=$Rm10Namespace};type='Opaque';stringData=@{'api-secret'=(New-Rm10Password)}} }
Write-Rm10Object -Object @{apiVersion='v1';kind='ConfigMap';metadata=@{name='rm10-cube-model';namespace=$Rm10Namespace};data=@{'Sales.js'=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'cube/schema/Sales.js'))}}
Write-Rm10Object -Object @{apiVersion='v1';kind='ConfigMap';metadata=@{name='rm10-cube-config';namespace=$Rm10Namespace};data=@{'cube.js'=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'cube/cube.js'))}}
$taskConsumers=@{}
foreach ($taskFile in Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'consumers') -File) { $taskConsumers[$taskFile.Name]=[IO.File]::ReadAllText($taskFile.FullName) }
Write-Rm10Object -Object @{apiVersion='v1';kind='ConfigMap';metadata=@{name='rm10-consumers';namespace=$Rm10Namespace};data=$taskConsumers}
Invoke-Rm10Kubectl -Arguments @('apply','-f',(Join-Path $PSScriptRoot 'k8s/cube.yaml')) | Out-Host
Invoke-Rm10Kubectl -Arguments @('-n',$Rm10Namespace,'rollout','status','deployment/cubestore','--timeout=600s') | Out-Host
Invoke-Rm10Kubectl -Arguments @('-n',$Rm10Namespace,'rollout','status','deployment/cube','--timeout=600s') | Out-Host
Invoke-Rm10Kubectl -Arguments @('apply','-f',(Join-Path $PSScriptRoot 'k8s/dashboard.yaml')) | Out-Host
Invoke-Rm10Kubectl -Arguments @('-n',$Rm10Namespace,'rollout','status','deployment/dashboard','--timeout=900s') | Out-Host
& (Join-Path $PSScriptRoot 'Test-Cube.ps1')


$taskGovSecret=(Invoke-Rm10Kubectl -Arguments @('-n',$Rm10Namespace,'get','secret','rm10-governance','--ignore-not-found=true','-o','name') | Out-String).Trim()
if (-not $taskGovSecret) { Write-Rm10Object -Object @{apiVersion='v1';kind='Secret';metadata=@{name='rm10-governance';namespace=$Rm10Namespace};type='Opaque';stringData=@{'database-password'=(New-Rm10Password);'admin-password'=('Aa1!'+(New-Rm10Password))}} }
$taskGovFiles=@{}
foreach ($taskFile in Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'governance') -File) { $taskGovFiles[$taskFile.Name]=[IO.File]::ReadAllText($taskFile.FullName) }
Write-Rm10Object -Object @{apiVersion='v1';kind='ConfigMap';metadata=@{name='rm10-catalog';namespace=$Rm10Namespace};data=$taskGovFiles}
Invoke-Rm10Kubectl -Arguments @('apply','-f',(Join-Path $PSScriptRoot 'k8s/governance-config.yaml')) | Out-Host
Invoke-Rm10Kubectl -Arguments @('apply','-f',(Join-Path $PSScriptRoot 'k8s/governance-dependencies.yaml')) | Out-Host
Invoke-Rm10Kubectl -Arguments @('-n',$Rm10Namespace,'rollout','status','statefulset/metadata-postgres','--timeout=600s') | Out-Host
Invoke-Rm10Kubectl -Arguments @('-n',$Rm10Namespace,'rollout','status','statefulset/elasticsearch','--timeout=600s') | Out-Host
Start-Rm10Job -Name 'rm10-om-migrate' -Manifest (Join-Path $PSScriptRoot 'k8s/governance-migrate.yaml')
Invoke-Rm10Kubectl -Arguments @('apply','-f',(Join-Path $PSScriptRoot 'k8s/governance-server.yaml')) | Out-Host
Invoke-Rm10Kubectl -Arguments @('-n',$Rm10Namespace,'rollout','status','deployment/openmetadata','--timeout=900s') | Out-Host
& (Join-Path $PSScriptRoot 'Sync-Catalog.ps1')


$taskGraphSecret=(Invoke-Rm10Kubectl -Arguments @('-n',$Rm10Namespace,'get','secret','rm10-graph','--ignore-not-found=true','-o','name') | Out-String).Trim()
if(-not $taskGraphSecret){
 $taskOldData=(Invoke-Rm10Kubectl -Arguments @('-n',$Rm10Namespace,'get','pvc','data-neo4j-0','--ignore-not-found=true','-o','name') | Out-String).Trim()
 if($taskOldData){throw 'Neo4j verisi var ancak Secret yok; eski Secret yedegini geri yukleyin.'}
 $taskGraphPassword=New-Rm10Password
 Write-Rm10Object -Object @{apiVersion='v1';kind='Secret';metadata=@{name='rm10-graph';namespace=$Rm10Namespace};type='Opaque';stringData=@{'password'=$taskGraphPassword;'auth'=('neo4j/'+$taskGraphPassword)}}
}
Invoke-Rm10Kubectl -Arguments @('apply','-f',(Join-Path $PSScriptRoot 'k8s/neo4j.yaml')) | Out-Host
Invoke-Rm10Kubectl -Arguments @('-n',$Rm10Namespace,'rollout','status','statefulset/neo4j','--timeout=600s') | Out-Host
& (Join-Path $PSScriptRoot 'Sync-Graph.ps1')
& (Join-Path $PSScriptRoot 'Show-Access.ps1')
