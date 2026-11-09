[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) { throw 'kubectl bulunamadi. Docker Desktop kurulumu ve PATH kontrol edilmeli.' }
Invoke-Rm8Kubectl -Arguments @('get', 'nodes', '--request-timeout=10s') | Out-Host
$taskClasses = (Invoke-Rm8Kubectl -Arguments @('get', 'storageclass', '-o', 'json') | Out-String) | ConvertFrom-Json
$taskDefault = @($taskClasses.items | Where-Object { $_.metadata.annotations.'storageclass.kubernetes.io/is-default-class' -eq 'true' -or $_.metadata.annotations.'storageclass.beta.kubernetes.io/is-default-class' -eq 'true' })
if ($taskDefault.Count -eq 0) { throw 'Varsayilan StorageClass bulunamadi. Docker Desktop Kubernetes depolamasi hazir olmali.' }
Invoke-Rm8Kubectl -Arguments @('apply', '-f', (Join-Path $PSScriptRoot 'k8s/namespace.yaml')) | Out-Host
$taskExistingSecret = (Invoke-Rm8Kubectl -Arguments @('-n', $Rm8Namespace, 'get', 'secret', 'rm8-credentials', '--ignore-not-found=true', '-o', 'name') | Out-String).Trim()
if (-not $taskExistingSecret) {
    $taskPod = (Invoke-Rm8Kubectl -Arguments @('-n', $Rm8Namespace, 'get', 'pvc', 'data-postgres-0', '--ignore-not-found=true', '-o', 'name') | Out-String).Trim()
    if ($taskPod) { throw 'Mevcut PVC var ancak parola Secret kayip. Yeni parola uretmeden mevcut Secret yedegini geri yukleyin.' }
    Write-Rm8Object -Object @{
        apiVersion = 'v1'; kind = 'Secret'
        metadata = @{ name = 'rm8-credentials'; namespace = $Rm8Namespace }
        type = 'Opaque'
        stringData = @{ 'admin-password' = (New-Rm8Password); 'bi-password' = (New-Rm8Password); 'dbt-password' = (New-Rm8Password) }
    }
}
$taskSql = @{}
foreach ($taskSqlFile in Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'sql') -Filter '*.sql') {
    $taskSql[$taskSqlFile.Name] = [IO.File]::ReadAllText($taskSqlFile.FullName)
}
Write-Rm8Object -Object @{
    apiVersion = 'v1'; kind = 'ConfigMap'
    metadata = @{ name = 'rm8-sql'; namespace = $Rm8Namespace }
    data = $taskSql
}
Invoke-Rm8Kubectl -Arguments @('apply', '-f', (Join-Path $PSScriptRoot 'k8s/postgres.yaml')) | Out-Host
Invoke-Rm8Kubectl -Arguments @('-n', $Rm8Namespace, 'rollout', 'status', 'statefulset/postgres', '--timeout=330s') | Out-Host
Write-Rm8Object -Object @{ apiVersion='v1'; kind='ConfigMap'; metadata=@{name='rm8-dbt';namespace=$Rm8Namespace}; data=@{'project.json'=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'dbt-project.json'));'runner.py'=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'runner.py'))} }
Invoke-Rm8Kubectl -Arguments @('apply','-f',(Join-Path $PSScriptRoot 'k8s/dbt-artifacts.yaml')) | Out-Host
Invoke-Rm8Kubectl -Arguments @('-n',$Rm8Namespace,'wait','--for=condition=Ready','pod/rm8-artifacts','--timeout=330s') | Out-Host
Start-Rm8Job -Name 'rm8-seed' -Manifest (Join-Path $PSScriptRoot 'k8s/seed-job.yaml')
& (Join-Path $PSScriptRoot 'Build-Models.ps1')
Start-Rm8Job -Name 'rm8-verify' -Manifest (Join-Path $PSScriptRoot 'k8s/verify-job.yaml')
Invoke-Rm8Kubectl -Arguments @('-n', $Rm8Namespace, 'get', 'pods,svc,pvc,jobs') | Out-Host
Invoke-Rm8Kubectl -Arguments @('apply','-f',(Join-Path $PSScriptRoot 'k8s/dbt-docs.yaml')) | Out-Host
Invoke-Rm8Kubectl -Arguments @('-n',$Rm8Namespace,'rollout','status','deployment/dbt-docs','--timeout=180s') | Out-Host

$taskApi = (Invoke-Rm8Kubectl -Arguments @('-n',$Rm8Namespace,'get','secret','rm8-api','--ignore-not-found=true','-o','name') | Out-String).Trim()
if (-not $taskApi) { Write-Rm8Object -Object @{apiVersion='v1';kind='Secret';metadata=@{name='rm8-api';namespace=$Rm8Namespace};type='Opaque';stringData=@{'api-secret'=(New-Rm8Password)}} }
Write-Rm8Object -Object @{apiVersion='v1';kind='ConfigMap';metadata=@{name='rm8-cube-model';namespace=$Rm8Namespace};data=@{'Sales.js'=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'cube/schema/Sales.js'))}}
Write-Rm8Object -Object @{apiVersion='v1';kind='ConfigMap';metadata=@{name='rm8-cube-config';namespace=$Rm8Namespace};data=@{'cube.js'=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'cube/cube.js'))}}
$taskConsumers=@{}
foreach ($taskFile in Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'consumers') -File) { $taskConsumers[$taskFile.Name]=[IO.File]::ReadAllText($taskFile.FullName) }
Write-Rm8Object -Object @{apiVersion='v1';kind='ConfigMap';metadata=@{name='rm8-consumers';namespace=$Rm8Namespace};data=$taskConsumers}
Invoke-Rm8Kubectl -Arguments @('apply','-f',(Join-Path $PSScriptRoot 'k8s/cube.yaml')) | Out-Host
Invoke-Rm8Kubectl -Arguments @('-n',$Rm8Namespace,'rollout','status','deployment/cubestore','--timeout=600s') | Out-Host
Invoke-Rm8Kubectl -Arguments @('-n',$Rm8Namespace,'rollout','status','deployment/cube','--timeout=600s') | Out-Host
Invoke-Rm8Kubectl -Arguments @('apply','-f',(Join-Path $PSScriptRoot 'k8s/dashboard.yaml')) | Out-Host
Invoke-Rm8Kubectl -Arguments @('-n',$Rm8Namespace,'rollout','status','deployment/dashboard','--timeout=900s') | Out-Host
& (Join-Path $PSScriptRoot 'Test-Cube.ps1')


$taskGovSecret=(Invoke-Rm8Kubectl -Arguments @('-n',$Rm8Namespace,'get','secret','rm8-governance','--ignore-not-found=true','-o','name') | Out-String).Trim()
if (-not $taskGovSecret) { Write-Rm8Object -Object @{apiVersion='v1';kind='Secret';metadata=@{name='rm8-governance';namespace=$Rm8Namespace};type='Opaque';stringData=@{'database-password'=(New-Rm8Password);'admin-password'=('Aa1!'+(New-Rm8Password))}} }
$taskGovFiles=@{}
foreach ($taskFile in Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'governance') -File) { $taskGovFiles[$taskFile.Name]=[IO.File]::ReadAllText($taskFile.FullName) }
Write-Rm8Object -Object @{apiVersion='v1';kind='ConfigMap';metadata=@{name='rm8-catalog';namespace=$Rm8Namespace};data=$taskGovFiles}
Invoke-Rm8Kubectl -Arguments @('apply','-f',(Join-Path $PSScriptRoot 'k8s/governance-config.yaml')) | Out-Host
Invoke-Rm8Kubectl -Arguments @('apply','-f',(Join-Path $PSScriptRoot 'k8s/governance-dependencies.yaml')) | Out-Host
Invoke-Rm8Kubectl -Arguments @('-n',$Rm8Namespace,'rollout','status','statefulset/metadata-postgres','--timeout=600s') | Out-Host
Invoke-Rm8Kubectl -Arguments @('-n',$Rm8Namespace,'rollout','status','statefulset/elasticsearch','--timeout=600s') | Out-Host
Start-Rm8Job -Name 'rm8-om-migrate' -Manifest (Join-Path $PSScriptRoot 'k8s/governance-migrate.yaml')
Invoke-Rm8Kubectl -Arguments @('apply','-f',(Join-Path $PSScriptRoot 'k8s/governance-server.yaml')) | Out-Host
Invoke-Rm8Kubectl -Arguments @('-n',$Rm8Namespace,'rollout','status','deployment/openmetadata','--timeout=900s') | Out-Host
& (Join-Path $PSScriptRoot 'Sync-Catalog.ps1')

& (Join-Path $PSScriptRoot 'Run-CDGC.ps1')
& (Join-Path $PSScriptRoot 'Verify-DualCatalog.ps1')
& (Join-Path $PSScriptRoot 'Show-Access.ps1')
