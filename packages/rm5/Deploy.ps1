[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) { throw 'kubectl bulunamadi. Docker Desktop kurulumu ve PATH kontrol edilmeli.' }
Invoke-Rm5Kubectl -Arguments @('get', 'nodes', '--request-timeout=10s') | Out-Host
$taskClasses = (Invoke-Rm5Kubectl -Arguments @('get', 'storageclass', '-o', 'json') | Out-String) | ConvertFrom-Json
$taskDefault = @($taskClasses.items | Where-Object { $_.metadata.annotations.'storageclass.kubernetes.io/is-default-class' -eq 'true' -or $_.metadata.annotations.'storageclass.beta.kubernetes.io/is-default-class' -eq 'true' })
if ($taskDefault.Count -eq 0) { throw 'Varsayilan StorageClass bulunamadi. Docker Desktop Kubernetes depolamasi hazir olmali.' }
Invoke-Rm5Kubectl -Arguments @('apply', '-f', (Join-Path $PSScriptRoot 'k8s/namespace.yaml')) | Out-Host
$taskExistingSecret = (Invoke-Rm5Kubectl -Arguments @('-n', $Rm5Namespace, 'get', 'secret', 'rm5-credentials', '--ignore-not-found=true', '-o', 'name') | Out-String).Trim()
if (-not $taskExistingSecret) {
    $taskPod = (Invoke-Rm5Kubectl -Arguments @('-n', $Rm5Namespace, 'get', 'pvc', 'data-postgres-0', '--ignore-not-found=true', '-o', 'name') | Out-String).Trim()
    if ($taskPod) { throw 'Mevcut PVC var ancak parola Secret kayip. Yeni parola uretmeden mevcut Secret yedegini geri yukleyin.' }
    Write-Rm5Object -Object @{
        apiVersion = 'v1'; kind = 'Secret'
        metadata = @{ name = 'rm5-credentials'; namespace = $Rm5Namespace }
        type = 'Opaque'
        stringData = @{ 'admin-password' = (New-Rm5Password); 'bi-password' = (New-Rm5Password); 'dbt-password' = (New-Rm5Password) }
    }
}
$taskSql = @{}
foreach ($taskSqlFile in Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'sql') -Filter '*.sql') {
    $taskSql[$taskSqlFile.Name] = [IO.File]::ReadAllText($taskSqlFile.FullName)
}
Write-Rm5Object -Object @{
    apiVersion = 'v1'; kind = 'ConfigMap'
    metadata = @{ name = 'rm5-sql'; namespace = $Rm5Namespace }
    data = $taskSql
}
Invoke-Rm5Kubectl -Arguments @('apply', '-f', (Join-Path $PSScriptRoot 'k8s/postgres.yaml')) | Out-Host
Invoke-Rm5Kubectl -Arguments @('-n', $Rm5Namespace, 'rollout', 'status', 'statefulset/postgres', '--timeout=330s') | Out-Host
Write-Rm5Object -Object @{ apiVersion='v1'; kind='ConfigMap'; metadata=@{name='rm5-dbt';namespace=$Rm5Namespace}; data=@{'project.json'=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'dbt-project.json'));'runner.py'=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'runner.py'))} }
Invoke-Rm5Kubectl -Arguments @('apply','-f',(Join-Path $PSScriptRoot 'k8s/dbt-artifacts.yaml')) | Out-Host
Invoke-Rm5Kubectl -Arguments @('-n',$Rm5Namespace,'wait','--for=condition=Ready','pod/rm5-artifacts','--timeout=330s') | Out-Host
Start-Rm5Job -Name 'rm5-seed' -Manifest (Join-Path $PSScriptRoot 'k8s/seed-job.yaml')
& (Join-Path $PSScriptRoot 'Build-Models.ps1')
Start-Rm5Job -Name 'rm5-verify' -Manifest (Join-Path $PSScriptRoot 'k8s/verify-job.yaml')
Invoke-Rm5Kubectl -Arguments @('-n', $Rm5Namespace, 'get', 'pods,svc,pvc,jobs') | Out-Host
Invoke-Rm5Kubectl -Arguments @('apply','-f',(Join-Path $PSScriptRoot 'k8s/dbt-docs.yaml')) | Out-Host
Invoke-Rm5Kubectl -Arguments @('-n',$Rm5Namespace,'rollout','status','deployment/dbt-docs','--timeout=180s') | Out-Host

$taskApi = (Invoke-Rm5Kubectl -Arguments @('-n',$Rm5Namespace,'get','secret','rm5-api','--ignore-not-found=true','-o','name') | Out-String).Trim()
if (-not $taskApi) { Write-Rm5Object -Object @{apiVersion='v1';kind='Secret';metadata=@{name='rm5-api';namespace=$Rm5Namespace};type='Opaque';stringData=@{'api-secret'=(New-Rm5Password)}} }
Write-Rm5Object -Object @{apiVersion='v1';kind='ConfigMap';metadata=@{name='rm5-cube-model';namespace=$Rm5Namespace};data=@{'Sales.js'=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'cube/schema/Sales.js'))}}
Write-Rm5Object -Object @{apiVersion='v1';kind='ConfigMap';metadata=@{name='rm5-cube-config';namespace=$Rm5Namespace};data=@{'cube.js'=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'cube/cube.js'))}}
$taskConsumers=@{}
foreach ($taskFile in Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'consumers') -File) { $taskConsumers[$taskFile.Name]=[IO.File]::ReadAllText($taskFile.FullName) }
Write-Rm5Object -Object @{apiVersion='v1';kind='ConfigMap';metadata=@{name='rm5-consumers';namespace=$Rm5Namespace};data=$taskConsumers}
Invoke-Rm5Kubectl -Arguments @('apply','-f',(Join-Path $PSScriptRoot 'k8s/cube.yaml')) | Out-Host
Invoke-Rm5Kubectl -Arguments @('-n',$Rm5Namespace,'rollout','status','deployment/cubestore','--timeout=600s') | Out-Host
Invoke-Rm5Kubectl -Arguments @('-n',$Rm5Namespace,'rollout','status','deployment/cube','--timeout=600s') | Out-Host
Invoke-Rm5Kubectl -Arguments @('apply','-f',(Join-Path $PSScriptRoot 'k8s/dashboard.yaml')) | Out-Host
Invoke-Rm5Kubectl -Arguments @('-n',$Rm5Namespace,'rollout','status','deployment/dashboard','--timeout=900s') | Out-Host
& (Join-Path $PSScriptRoot 'Test-Cube.ps1')


$taskGovSecret=(Invoke-Rm5Kubectl -Arguments @('-n',$Rm5Namespace,'get','secret','rm5-governance','--ignore-not-found=true','-o','name') | Out-String).Trim()
if (-not $taskGovSecret) { Write-Rm5Object -Object @{apiVersion='v1';kind='Secret';metadata=@{name='rm5-governance';namespace=$Rm5Namespace};type='Opaque';stringData=@{'database-password'=(New-Rm5Password);'admin-password'=('Aa1!'+(New-Rm5Password))}} }
$taskGovFiles=@{}
foreach ($taskFile in Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'governance') -File) { $taskGovFiles[$taskFile.Name]=[IO.File]::ReadAllText($taskFile.FullName) }
Write-Rm5Object -Object @{apiVersion='v1';kind='ConfigMap';metadata=@{name='rm5-catalog';namespace=$Rm5Namespace};data=$taskGovFiles}
Invoke-Rm5Kubectl -Arguments @('apply','-f',(Join-Path $PSScriptRoot 'k8s/governance-config.yaml')) | Out-Host
Invoke-Rm5Kubectl -Arguments @('apply','-f',(Join-Path $PSScriptRoot 'k8s/governance-dependencies.yaml')) | Out-Host
Invoke-Rm5Kubectl -Arguments @('-n',$Rm5Namespace,'rollout','status','statefulset/metadata-postgres','--timeout=600s') | Out-Host
Invoke-Rm5Kubectl -Arguments @('-n',$Rm5Namespace,'rollout','status','statefulset/elasticsearch','--timeout=600s') | Out-Host
Start-Rm5Job -Name 'rm5-om-migrate' -Manifest (Join-Path $PSScriptRoot 'k8s/governance-migrate.yaml')
Invoke-Rm5Kubectl -Arguments @('apply','-f',(Join-Path $PSScriptRoot 'k8s/governance-server.yaml')) | Out-Host
Invoke-Rm5Kubectl -Arguments @('-n',$Rm5Namespace,'rollout','status','deployment/openmetadata','--timeout=900s') | Out-Host
& (Join-Path $PSScriptRoot 'Sync-Catalog.ps1')

& (Join-Path $PSScriptRoot 'Show-Access.ps1')
