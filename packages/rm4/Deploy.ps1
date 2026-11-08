[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) { throw 'kubectl bulunamadi. Docker Desktop kurulumu ve PATH kontrol edilmeli.' }
Invoke-Rm4Kubectl -Arguments @('get', 'nodes', '--request-timeout=10s') | Out-Host
$taskClasses = (Invoke-Rm4Kubectl -Arguments @('get', 'storageclass', '-o', 'json') | Out-String) | ConvertFrom-Json
$taskDefault = @($taskClasses.items | Where-Object { $_.metadata.annotations.'storageclass.kubernetes.io/is-default-class' -eq 'true' -or $_.metadata.annotations.'storageclass.beta.kubernetes.io/is-default-class' -eq 'true' })
if ($taskDefault.Count -eq 0) { throw 'Varsayilan StorageClass bulunamadi. Docker Desktop Kubernetes depolamasi hazir olmali.' }
Invoke-Rm4Kubectl -Arguments @('apply', '-f', (Join-Path $PSScriptRoot 'k8s/namespace.yaml')) | Out-Host
$taskExistingSecret = (Invoke-Rm4Kubectl -Arguments @('-n', $Rm4Namespace, 'get', 'secret', 'rm4-credentials', '--ignore-not-found=true', '-o', 'name') | Out-String).Trim()
if (-not $taskExistingSecret) {
    $taskPod = (Invoke-Rm4Kubectl -Arguments @('-n', $Rm4Namespace, 'get', 'pvc', 'data-postgres-0', '--ignore-not-found=true', '-o', 'name') | Out-String).Trim()
    if ($taskPod) { throw 'Mevcut PVC var ancak parola Secret kayip. Yeni parola uretmeden mevcut Secret yedegini geri yukleyin.' }
    Write-Rm4Object -Object @{
        apiVersion = 'v1'; kind = 'Secret'
        metadata = @{ name = 'rm4-credentials'; namespace = $Rm4Namespace }
        type = 'Opaque'
        stringData = @{ 'admin-password' = (New-Rm4Password); 'bi-password' = (New-Rm4Password); 'dbt-password' = (New-Rm4Password) }
    }
}
$taskSql = @{}
foreach ($taskSqlFile in Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'sql') -Filter '*.sql') {
    $taskSql[$taskSqlFile.Name] = [IO.File]::ReadAllText($taskSqlFile.FullName)
}
Write-Rm4Object -Object @{
    apiVersion = 'v1'; kind = 'ConfigMap'
    metadata = @{ name = 'rm4-sql'; namespace = $Rm4Namespace }
    data = $taskSql
}
Invoke-Rm4Kubectl -Arguments @('apply', '-f', (Join-Path $PSScriptRoot 'k8s/postgres.yaml')) | Out-Host
Invoke-Rm4Kubectl -Arguments @('-n', $Rm4Namespace, 'rollout', 'status', 'statefulset/postgres', '--timeout=330s') | Out-Host
Write-Rm4Object -Object @{ apiVersion='v1'; kind='ConfigMap'; metadata=@{name='rm4-dbt';namespace=$Rm4Namespace}; data=@{'project.json'=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'dbt-project.json'));'runner.py'=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'runner.py'))} }
Invoke-Rm4Kubectl -Arguments @('apply','-f',(Join-Path $PSScriptRoot 'k8s/dbt-artifacts.yaml')) | Out-Host
Invoke-Rm4Kubectl -Arguments @('-n',$Rm4Namespace,'wait','--for=condition=Ready','pod/rm4-artifacts','--timeout=330s') | Out-Host
Start-Rm4Job -Name 'rm4-seed' -Manifest (Join-Path $PSScriptRoot 'k8s/seed-job.yaml')
& (Join-Path $PSScriptRoot 'Build-Models.ps1')
Start-Rm4Job -Name 'rm4-verify' -Manifest (Join-Path $PSScriptRoot 'k8s/verify-job.yaml')
Invoke-Rm4Kubectl -Arguments @('-n', $Rm4Namespace, 'get', 'pods,svc,pvc,jobs') | Out-Host
Invoke-Rm4Kubectl -Arguments @('apply','-f',(Join-Path $PSScriptRoot 'k8s/dbt-docs.yaml')) | Out-Host
Invoke-Rm4Kubectl -Arguments @('-n',$Rm4Namespace,'rollout','status','deployment/dbt-docs','--timeout=180s') | Out-Host

$taskApi = (Invoke-Rm4Kubectl -Arguments @('-n',$Rm4Namespace,'get','secret','rm4-api','--ignore-not-found=true','-o','name') | Out-String).Trim()
if (-not $taskApi) { Write-Rm4Object -Object @{apiVersion='v1';kind='Secret';metadata=@{name='rm4-api';namespace=$Rm4Namespace};type='Opaque';stringData=@{'api-secret'=(New-Rm4Password)}} }
Write-Rm4Object -Object @{apiVersion='v1';kind='ConfigMap';metadata=@{name='rm4-cube-model';namespace=$Rm4Namespace};data=@{'Sales.js'=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'cube/schema/Sales.js'))}}
Write-Rm4Object -Object @{apiVersion='v1';kind='ConfigMap';metadata=@{name='rm4-cube-config';namespace=$Rm4Namespace};data=@{'cube.js'=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'cube/cube.js'))}}
$taskConsumers=@{}
foreach ($taskFile in Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'consumers') -File) { $taskConsumers[$taskFile.Name]=[IO.File]::ReadAllText($taskFile.FullName) }
Write-Rm4Object -Object @{apiVersion='v1';kind='ConfigMap';metadata=@{name='rm4-consumers';namespace=$Rm4Namespace};data=$taskConsumers}
Invoke-Rm4Kubectl -Arguments @('apply','-f',(Join-Path $PSScriptRoot 'k8s/cube.yaml')) | Out-Host
Invoke-Rm4Kubectl -Arguments @('-n',$Rm4Namespace,'rollout','status','deployment/cubestore','--timeout=600s') | Out-Host
Invoke-Rm4Kubectl -Arguments @('-n',$Rm4Namespace,'rollout','status','deployment/cube','--timeout=600s') | Out-Host
Invoke-Rm4Kubectl -Arguments @('apply','-f',(Join-Path $PSScriptRoot 'k8s/dashboard.yaml')) | Out-Host
Invoke-Rm4Kubectl -Arguments @('-n',$Rm4Namespace,'rollout','status','deployment/dashboard','--timeout=900s') | Out-Host
& (Join-Path $PSScriptRoot 'Test-Cube.ps1')

& (Join-Path $PSScriptRoot 'Show-Access.ps1')
