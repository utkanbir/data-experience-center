[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) { throw 'kubectl bulunamadi. Docker Desktop kurulumu ve PATH kontrol edilmeli.' }
Invoke-Rm2Kubectl -Arguments @('get', 'nodes', '--request-timeout=10s') | Out-Host
$taskClasses = (Invoke-Rm2Kubectl -Arguments @('get', 'storageclass', '-o', 'json') | Out-String) | ConvertFrom-Json
$taskDefault = @($taskClasses.items | Where-Object { $_.metadata.annotations.'storageclass.kubernetes.io/is-default-class' -eq 'true' -or $_.metadata.annotations.'storageclass.beta.kubernetes.io/is-default-class' -eq 'true' })
if ($taskDefault.Count -eq 0) { throw 'Varsayilan StorageClass bulunamadi. Docker Desktop Kubernetes depolamasi hazir olmali.' }
Invoke-Rm2Kubectl -Arguments @('apply', '-f', (Join-Path $PSScriptRoot 'k8s/namespace.yaml')) | Out-Host
$taskExistingSecret = (Invoke-Rm2Kubectl -Arguments @('-n', $Rm2Namespace, 'get', 'secret', 'rm2-credentials', '--ignore-not-found=true', '-o', 'name') | Out-String).Trim()
if (-not $taskExistingSecret) {
    $taskPod = (Invoke-Rm2Kubectl -Arguments @('-n', $Rm2Namespace, 'get', 'pvc', 'data-postgres-0', '--ignore-not-found=true', '-o', 'name') | Out-String).Trim()
    if ($taskPod) { throw 'Mevcut PVC var ancak parola Secret kayip. Yeni parola uretmeden mevcut Secret yedegini geri yukleyin.' }
    Write-Rm2Object -Object @{
        apiVersion = 'v1'; kind = 'Secret'
        metadata = @{ name = 'rm2-credentials'; namespace = $Rm2Namespace }
        type = 'Opaque'
        stringData = @{ 'admin-password' = (New-Rm2Password); 'bi-password' = (New-Rm2Password); 'dbt-password' = (New-Rm2Password) }
    }
}
$taskSql = @{}
foreach ($taskSqlFile in Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'sql') -Filter '*.sql') {
    $taskSql[$taskSqlFile.Name] = [IO.File]::ReadAllText($taskSqlFile.FullName)
}
Write-Rm2Object -Object @{
    apiVersion = 'v1'; kind = 'ConfigMap'
    metadata = @{ name = 'rm2-sql'; namespace = $Rm2Namespace }
    data = $taskSql
}
Invoke-Rm2Kubectl -Arguments @('apply', '-f', (Join-Path $PSScriptRoot 'k8s/postgres.yaml')) | Out-Host
Invoke-Rm2Kubectl -Arguments @('-n', $Rm2Namespace, 'rollout', 'status', 'statefulset/postgres', '--timeout=330s') | Out-Host
Write-Rm2Object -Object @{ apiVersion='v1'; kind='ConfigMap'; metadata=@{name='rm2-dbt';namespace=$Rm2Namespace}; data=@{'project.json'=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'dbt-project.json'));'runner.py'=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'runner.py'))} }
Invoke-Rm2Kubectl -Arguments @('apply','-f',(Join-Path $PSScriptRoot 'k8s/dbt-artifacts.yaml')) | Out-Host
Invoke-Rm2Kubectl -Arguments @('-n',$Rm2Namespace,'wait','--for=condition=Ready','pod/rm2-artifacts','--timeout=330s') | Out-Host
Start-Rm2Job -Name 'rm2-seed' -Manifest (Join-Path $PSScriptRoot 'k8s/seed-job.yaml')
& (Join-Path $PSScriptRoot 'Build-Models.ps1')
Start-Rm2Job -Name 'rm2-verify' -Manifest (Join-Path $PSScriptRoot 'k8s/verify-job.yaml')
Invoke-Rm2Kubectl -Arguments @('-n', $Rm2Namespace, 'get', 'pods,svc,pvc,jobs') | Out-Host
Invoke-Rm2Kubectl -Arguments @('apply','-f',(Join-Path $PSScriptRoot 'k8s/dbt-docs.yaml')) | Out-Host
Invoke-Rm2Kubectl -Arguments @('-n',$Rm2Namespace,'rollout','status','deployment/dbt-docs','--timeout=180s') | Out-Host
& (Join-Path $PSScriptRoot 'Show-Access.ps1')
