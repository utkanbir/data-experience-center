[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) { throw 'kubectl bulunamadi. Docker Desktop kurulumu ve PATH kontrol edilmeli.' }
Invoke-Rm7Kubectl -Arguments @('get', 'nodes', '--request-timeout=10s') | Out-Host
$taskClasses = (Invoke-Rm7Kubectl -Arguments @('get', 'storageclass', '-o', 'json') | Out-String) | ConvertFrom-Json
$taskDefault = @($taskClasses.items | Where-Object { $_.metadata.annotations.'storageclass.kubernetes.io/is-default-class' -eq 'true' -or $_.metadata.annotations.'storageclass.beta.kubernetes.io/is-default-class' -eq 'true' })
if ($taskDefault.Count -eq 0) { throw 'Varsayilan StorageClass bulunamadi. Docker Desktop Kubernetes depolamasi hazir olmali.' }
Invoke-Rm7Kubectl -Arguments @('apply', '-f', (Join-Path $PSScriptRoot 'k8s/namespace.yaml')) | Out-Host
& (Join-Path $PSScriptRoot 'Initialize-ExternalConnection.ps1')
$taskExistingSecret = (Invoke-Rm7Kubectl -Arguments @('-n', $Rm7Namespace, 'get', 'secret', 'rm7-credentials', '--ignore-not-found=true', '-o', 'name') | Out-String).Trim()
if (-not $taskExistingSecret) {
    $taskPod = (Invoke-Rm7Kubectl -Arguments @('-n', $Rm7Namespace, 'get', 'pvc', 'data-postgres-0', '--ignore-not-found=true', '-o', 'name') | Out-String).Trim()
    if ($taskPod) { throw 'Mevcut PVC var ancak parola Secret kayip. Yeni parola uretmeden mevcut Secret yedegini geri yukleyin.' }
    Write-Rm7Object -Object @{
        apiVersion = 'v1'; kind = 'Secret'
        metadata = @{ name = 'rm7-credentials'; namespace = $Rm7Namespace }
        type = 'Opaque'
        stringData = @{ 'admin-password' = (New-Rm7Password); 'bi-password' = (New-Rm7Password); 'dbt-password' = (New-Rm7Password) }
    }
}
$taskSql = @{}
foreach ($taskSqlFile in Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'sql') -Filter '*.sql') {
    $taskSql[$taskSqlFile.Name] = [IO.File]::ReadAllText($taskSqlFile.FullName)
}
Write-Rm7Object -Object @{
    apiVersion = 'v1'; kind = 'ConfigMap'
    metadata = @{ name = 'rm7-sql'; namespace = $Rm7Namespace }
    data = $taskSql
}
Invoke-Rm7Kubectl -Arguments @('apply', '-f', (Join-Path $PSScriptRoot 'k8s/postgres.yaml')) | Out-Host
Invoke-Rm7Kubectl -Arguments @('-n', $Rm7Namespace, 'rollout', 'status', 'statefulset/postgres', '--timeout=330s') | Out-Host
Write-Rm7Object -Object @{ apiVersion='v1'; kind='ConfigMap'; metadata=@{name='rm7-dbt';namespace=$Rm7Namespace}; data=@{'project.json'=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'dbt-project.json'));'runner.py'=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'runner.py'))} }
Invoke-Rm7Kubectl -Arguments @('apply','-f',(Join-Path $PSScriptRoot 'k8s/dbt-artifacts.yaml')) | Out-Host
Invoke-Rm7Kubectl -Arguments @('-n',$Rm7Namespace,'wait','--for=condition=Ready','pod/rm7-artifacts','--timeout=330s') | Out-Host
Start-Rm7Job -Name 'rm7-seed' -Manifest (Join-Path $PSScriptRoot 'k8s/seed-job.yaml')
& (Join-Path $PSScriptRoot 'Build-Models.ps1')
Start-Rm7Job -Name 'rm7-verify' -Manifest (Join-Path $PSScriptRoot 'k8s/verify-job.yaml')
Invoke-Rm7Kubectl -Arguments @('-n', $Rm7Namespace, 'get', 'pods,svc,pvc,jobs') | Out-Host
Invoke-Rm7Kubectl -Arguments @('apply','-f',(Join-Path $PSScriptRoot 'k8s/dbt-docs.yaml')) | Out-Host
Invoke-Rm7Kubectl -Arguments @('-n',$Rm7Namespace,'rollout','status','deployment/dbt-docs','--timeout=180s') | Out-Host

$taskApi = (Invoke-Rm7Kubectl -Arguments @('-n',$Rm7Namespace,'get','secret','rm7-api','--ignore-not-found=true','-o','name') | Out-String).Trim()
if (-not $taskApi) { Write-Rm7Object -Object @{apiVersion='v1';kind='Secret';metadata=@{name='rm7-api';namespace=$Rm7Namespace};type='Opaque';stringData=@{'api-secret'=(New-Rm7Password)}} }
Write-Rm7Object -Object @{apiVersion='v1';kind='ConfigMap';metadata=@{name='rm7-cube-model';namespace=$Rm7Namespace};data=@{'Sales.js'=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'cube/schema/Sales.js'))}}
Write-Rm7Object -Object @{apiVersion='v1';kind='ConfigMap';metadata=@{name='rm7-cube-config';namespace=$Rm7Namespace};data=@{'cube.js'=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'cube/cube.js'))}}
$taskConsumers=@{}
foreach ($taskFile in Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'consumers') -File) { $taskConsumers[$taskFile.Name]=[IO.File]::ReadAllText($taskFile.FullName) }
Write-Rm7Object -Object @{apiVersion='v1';kind='ConfigMap';metadata=@{name='rm7-consumers';namespace=$Rm7Namespace};data=$taskConsumers}
Invoke-Rm7Kubectl -Arguments @('apply','-f',(Join-Path $PSScriptRoot 'k8s/cube.yaml')) | Out-Host
Invoke-Rm7Kubectl -Arguments @('-n',$Rm7Namespace,'rollout','status','deployment/cubestore','--timeout=600s') | Out-Host
Invoke-Rm7Kubectl -Arguments @('-n',$Rm7Namespace,'rollout','status','deployment/cube','--timeout=600s') | Out-Host
$taskGovernance=@{}
foreach($taskFile in Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'governance') -File) { if($taskFile.Extension -in @('.py','.json','.txt')) { $taskGovernance[$taskFile.Name]=[IO.File]::ReadAllText($taskFile.FullName) } }
Write-Rm7Object -Object @{apiVersion='v1';kind='ConfigMap';metadata=@{name='rm7-governance';namespace=$Rm7Namespace};data=$taskGovernance}
Invoke-Rm7Kubectl -Arguments @('apply','-f',(Join-Path $PSScriptRoot 'k8s/dashboard.yaml')) | Out-Host
Invoke-Rm7Kubectl -Arguments @('-n',$Rm7Namespace,'rollout','status','deployment/dashboard','--timeout=900s') | Out-Host
& (Join-Path $PSScriptRoot 'Test-Cube.ps1')

& (Join-Path $PSScriptRoot 'Run-Governance.ps1')
& (Join-Path $PSScriptRoot 'Show-Access.ps1')
