[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) { throw 'kubectl bulunamadi. Docker Desktop kurulumu ve PATH kontrol edilmeli.' }
Invoke-Rm9Kubectl -Arguments @('get', 'nodes', '--request-timeout=10s') | Out-Host
$taskClasses = (Invoke-Rm9Kubectl -Arguments @('get', 'storageclass', '-o', 'json') | Out-String) | ConvertFrom-Json
$taskDefault = @($taskClasses.items | Where-Object { $_.metadata.annotations.'storageclass.kubernetes.io/is-default-class' -eq 'true' -or $_.metadata.annotations.'storageclass.beta.kubernetes.io/is-default-class' -eq 'true' })
if ($taskDefault.Count -eq 0) { throw 'Varsayilan StorageClass bulunamadi. Docker Desktop Kubernetes depolamasi hazir olmali.' }
Invoke-Rm9Kubectl -Arguments @('apply', '-f', (Join-Path $PSScriptRoot 'k8s/namespace.yaml')) | Out-Host
$taskExistingSecret = (Invoke-Rm9Kubectl -Arguments @('-n', $Rm9Namespace, 'get', 'secret', 'rm9-credentials', '--ignore-not-found=true', '-o', 'name') | Out-String).Trim()
if (-not $taskExistingSecret) {
    $taskPod = (Invoke-Rm9Kubectl -Arguments @('-n', $Rm9Namespace, 'get', 'pvc', 'data-postgres-0', '--ignore-not-found=true', '-o', 'name') | Out-String).Trim()
    if ($taskPod) { throw 'Mevcut PVC var ancak parola Secret kayip. Yeni parola uretmeden mevcut Secret yedegini geri yukleyin.' }
    Write-Rm9Object -Object @{
        apiVersion = 'v1'; kind = 'Secret'
        metadata = @{ name = 'rm9-credentials'; namespace = $Rm9Namespace }
        type = 'Opaque'
        stringData = @{ 'admin-password' = (New-Rm9Password); 'bi-password' = (New-Rm9Password); 'dbt-password' = (New-Rm9Password) }
    }
}
$taskSql = @{}
foreach ($taskSqlFile in Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'sql') -Filter '*.sql') {
    $taskSql[$taskSqlFile.Name] = [IO.File]::ReadAllText($taskSqlFile.FullName)
}
Write-Rm9Object -Object @{
    apiVersion = 'v1'; kind = 'ConfigMap'
    metadata = @{ name = 'rm9-sql'; namespace = $Rm9Namespace }
    data = $taskSql
}
Invoke-Rm9Kubectl -Arguments @('apply', '-f', (Join-Path $PSScriptRoot 'k8s/postgres.yaml')) | Out-Host
Invoke-Rm9Kubectl -Arguments @('-n', $Rm9Namespace, 'rollout', 'status', 'statefulset/postgres', '--timeout=330s') | Out-Host
Invoke-Rm9Kubectl -Arguments @('apply','-f',(Join-Path $PSScriptRoot 'k8s/postgres-reference.yaml')) | Out-Host
Invoke-Rm9Kubectl -Arguments @('-n',$Rm9Namespace,'rollout','status','statefulset/postgres-reference','--timeout=330s') | Out-Host
Write-Rm9Object -Object @{ apiVersion='v1'; kind='ConfigMap'; metadata=@{name='rm9-dbt';namespace=$Rm9Namespace}; data=@{'project.json'=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'dbt-project.json'));'runner.py'=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'runner.py'))} }
Invoke-Rm9Kubectl -Arguments @('apply','-f',(Join-Path $PSScriptRoot 'k8s/dbt-artifacts.yaml')) | Out-Host
Invoke-Rm9Kubectl -Arguments @('-n',$Rm9Namespace,'wait','--for=condition=Ready','pod/rm9-artifacts','--timeout=330s') | Out-Host
Start-Rm9Job -Name 'rm9-seed' -Manifest (Join-Path $PSScriptRoot 'k8s/seed-job.yaml')
Start-Rm9Job -Name 'rm9-seed-reference' -Manifest (Join-Path $PSScriptRoot 'k8s/seed-reference-job.yaml')
$taskTrino=@{}
$taskTrinoObject=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'trino/config.json') -Raw | ConvertFrom-Json
foreach($taskProperty in $taskTrinoObject.PSObject.Properties){$taskTrino[$taskProperty.Name]=$taskProperty.Value}
Write-Rm9Object -Object @{apiVersion='v1';kind='ConfigMap';metadata=@{name='rm9-trino';namespace=$Rm9Namespace};data=$taskTrino}
Invoke-Rm9Kubectl -Arguments @('apply','-f',(Join-Path $PSScriptRoot 'k8s/trino.yaml')) | Out-Host
Invoke-Rm9Kubectl -Arguments @('-n',$Rm9Namespace,'rollout','status','deployment/trino','--timeout=600s') | Out-Host
& (Join-Path $PSScriptRoot 'Build-Models.ps1')

Invoke-Rm9Kubectl -Arguments @('-n', $Rm9Namespace, 'get', 'pods,svc,pvc,jobs') | Out-Host
Invoke-Rm9Kubectl -Arguments @('apply','-f',(Join-Path $PSScriptRoot 'k8s/dbt-docs.yaml')) | Out-Host
Invoke-Rm9Kubectl -Arguments @('-n',$Rm9Namespace,'rollout','status','deployment/dbt-docs','--timeout=180s') | Out-Host

$taskApi = (Invoke-Rm9Kubectl -Arguments @('-n',$Rm9Namespace,'get','secret','rm9-api','--ignore-not-found=true','-o','name') | Out-String).Trim()
if (-not $taskApi) { Write-Rm9Object -Object @{apiVersion='v1';kind='Secret';metadata=@{name='rm9-api';namespace=$Rm9Namespace};type='Opaque';stringData=@{'api-secret'=(New-Rm9Password)}} }
Write-Rm9Object -Object @{apiVersion='v1';kind='ConfigMap';metadata=@{name='rm9-cube-model';namespace=$Rm9Namespace};data=@{'Sales.js'=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'cube/schema/Sales.js'))}}
Write-Rm9Object -Object @{apiVersion='v1';kind='ConfigMap';metadata=@{name='rm9-cube-config';namespace=$Rm9Namespace};data=@{'cube.js'=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'cube/cube.js'))}}
$taskConsumers=@{}
foreach ($taskFile in Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'consumers') -File) { $taskConsumers[$taskFile.Name]=[IO.File]::ReadAllText($taskFile.FullName) }
Write-Rm9Object -Object @{apiVersion='v1';kind='ConfigMap';metadata=@{name='rm9-consumers';namespace=$Rm9Namespace};data=$taskConsumers}
Invoke-Rm9Kubectl -Arguments @('apply','-f',(Join-Path $PSScriptRoot 'k8s/cube.yaml')) | Out-Host
Invoke-Rm9Kubectl -Arguments @('-n',$Rm9Namespace,'rollout','status','deployment/cubestore','--timeout=600s') | Out-Host
Invoke-Rm9Kubectl -Arguments @('-n',$Rm9Namespace,'rollout','status','deployment/cube','--timeout=600s') | Out-Host
Invoke-Rm9Kubectl -Arguments @('apply','-f',(Join-Path $PSScriptRoot 'k8s/dashboard.yaml')) | Out-Host
Invoke-Rm9Kubectl -Arguments @('-n',$Rm9Namespace,'rollout','status','deployment/dashboard','--timeout=900s') | Out-Host
& (Join-Path $PSScriptRoot 'Test-Cube.ps1')


$taskGovSecret=(Invoke-Rm9Kubectl -Arguments @('-n',$Rm9Namespace,'get','secret','rm9-governance','--ignore-not-found=true','-o','name') | Out-String).Trim()
if (-not $taskGovSecret) { Write-Rm9Object -Object @{apiVersion='v1';kind='Secret';metadata=@{name='rm9-governance';namespace=$Rm9Namespace};type='Opaque';stringData=@{'database-password'=(New-Rm9Password);'admin-password'=('Aa1!'+(New-Rm9Password))}} }
$taskGovFiles=@{}
foreach ($taskFile in Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'governance') -File) { $taskGovFiles[$taskFile.Name]=[IO.File]::ReadAllText($taskFile.FullName) }
Write-Rm9Object -Object @{apiVersion='v1';kind='ConfigMap';metadata=@{name='rm9-catalog';namespace=$Rm9Namespace};data=$taskGovFiles}
Invoke-Rm9Kubectl -Arguments @('apply','-f',(Join-Path $PSScriptRoot 'k8s/governance-config.yaml')) | Out-Host
Invoke-Rm9Kubectl -Arguments @('apply','-f',(Join-Path $PSScriptRoot 'k8s/governance-dependencies.yaml')) | Out-Host
Invoke-Rm9Kubectl -Arguments @('-n',$Rm9Namespace,'rollout','status','statefulset/metadata-postgres','--timeout=600s') | Out-Host
Invoke-Rm9Kubectl -Arguments @('-n',$Rm9Namespace,'rollout','status','statefulset/elasticsearch','--timeout=600s') | Out-Host
Start-Rm9Job -Name 'rm9-om-migrate' -Manifest (Join-Path $PSScriptRoot 'k8s/governance-migrate.yaml')
Invoke-Rm9Kubectl -Arguments @('apply','-f',(Join-Path $PSScriptRoot 'k8s/governance-server.yaml')) | Out-Host
Invoke-Rm9Kubectl -Arguments @('-n',$Rm9Namespace,'rollout','status','deployment/openmetadata','--timeout=900s') | Out-Host
& (Join-Path $PSScriptRoot 'Sync-Catalog.ps1')

& (Join-Path $PSScriptRoot 'Show-Access.ps1')
