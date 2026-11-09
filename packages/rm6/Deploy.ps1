[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) { throw 'kubectl bulunamadi. Docker Desktop kurulumu ve PATH kontrol edilmeli.' }
Invoke-Rm6Kubectl -Arguments @('get', 'nodes', '--request-timeout=10s') | Out-Host
$taskClasses = (Invoke-Rm6Kubectl -Arguments @('get', 'storageclass', '-o', 'json') | Out-String) | ConvertFrom-Json
$taskDefault = @($taskClasses.items | Where-Object { $_.metadata.annotations.'storageclass.kubernetes.io/is-default-class' -eq 'true' -or $_.metadata.annotations.'storageclass.beta.kubernetes.io/is-default-class' -eq 'true' })
if ($taskDefault.Count -eq 0) { throw 'Varsayilan StorageClass bulunamadi. Docker Desktop Kubernetes depolamasi hazir olmali.' }
Invoke-Rm6Kubectl -Arguments @('apply', '-f', (Join-Path $PSScriptRoot 'k8s/namespace.yaml')) | Out-Host
$taskExistingSecret = (Invoke-Rm6Kubectl -Arguments @('-n', $Rm6Namespace, 'get', 'secret', 'rm6-credentials', '--ignore-not-found=true', '-o', 'name') | Out-String).Trim()
if (-not $taskExistingSecret) {
    $taskPod = (Invoke-Rm6Kubectl -Arguments @('-n', $Rm6Namespace, 'get', 'pvc', 'data-postgres-0', '--ignore-not-found=true', '-o', 'name') | Out-String).Trim()
    if ($taskPod) { throw 'Mevcut PVC var ancak parola Secret kayip. Yeni parola uretmeden mevcut Secret yedegini geri yukleyin.' }
    Write-Rm6Object -Object @{
        apiVersion = 'v1'; kind = 'Secret'
        metadata = @{ name = 'rm6-credentials'; namespace = $Rm6Namespace }
        type = 'Opaque'
        stringData = @{ 'admin-password' = (New-Rm6Password); 'bi-password' = (New-Rm6Password); 'dbt-password' = (New-Rm6Password) }
    }
}
$taskSql = @{}
foreach ($taskSqlFile in Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'sql') -Filter '*.sql') {
    $taskSql[$taskSqlFile.Name] = [IO.File]::ReadAllText($taskSqlFile.FullName)
}
Write-Rm6Object -Object @{
    apiVersion = 'v1'; kind = 'ConfigMap'
    metadata = @{ name = 'rm6-sql'; namespace = $Rm6Namespace }
    data = $taskSql
}
Invoke-Rm6Kubectl -Arguments @('apply', '-f', (Join-Path $PSScriptRoot 'k8s/postgres.yaml')) | Out-Host
Invoke-Rm6Kubectl -Arguments @('-n', $Rm6Namespace, 'rollout', 'status', 'statefulset/postgres', '--timeout=330s') | Out-Host
Write-Rm6Object -Object @{ apiVersion='v1'; kind='ConfigMap'; metadata=@{name='rm6-dbt';namespace=$Rm6Namespace}; data=@{'project.json'=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'dbt-project.json'));'runner.py'=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'runner.py'))} }
Invoke-Rm6Kubectl -Arguments @('apply','-f',(Join-Path $PSScriptRoot 'k8s/dbt-artifacts.yaml')) | Out-Host
Invoke-Rm6Kubectl -Arguments @('-n',$Rm6Namespace,'wait','--for=condition=Ready','pod/rm6-artifacts','--timeout=330s') | Out-Host
Start-Rm6Job -Name 'rm6-seed' -Manifest (Join-Path $PSScriptRoot 'k8s/seed-job.yaml')
& (Join-Path $PSScriptRoot 'Build-Models.ps1')
Start-Rm6Job -Name 'rm6-verify' -Manifest (Join-Path $PSScriptRoot 'k8s/verify-job.yaml')
Invoke-Rm6Kubectl -Arguments @('-n', $Rm6Namespace, 'get', 'pods,svc,pvc,jobs') | Out-Host
Invoke-Rm6Kubectl -Arguments @('apply','-f',(Join-Path $PSScriptRoot 'k8s/dbt-docs.yaml')) | Out-Host
Invoke-Rm6Kubectl -Arguments @('-n',$Rm6Namespace,'rollout','status','deployment/dbt-docs','--timeout=180s') | Out-Host

$taskManaged=@{}
foreach ($taskFile in Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'managed') -File) { $taskManaged[$taskFile.Name]=[IO.File]::ReadAllText($taskFile.FullName) }
Write-Rm6Object -Object @{apiVersion='v1';kind='ConfigMap';metadata=@{name='rm6-managed';namespace=$Rm6Namespace};data=$taskManaged}
& (Join-Path $PSScriptRoot 'Run-RemoteChecks.ps1')

& (Join-Path $PSScriptRoot 'Show-Access.ps1')
