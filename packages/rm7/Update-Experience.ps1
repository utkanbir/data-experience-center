[CmdletBinding()]
param()
. (Join-Path $PSScriptRoot 'Common.ps1')
foreach($taskPair in @(@('consumers','rm7-consumers'),@('governance','rm7-governance'))) {
 $taskData=@{}
 foreach($taskFile in Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot $taskPair[0]) -File) { if($taskFile.Extension -in @('.py','.json','.txt')) { $taskData[$taskFile.Name]=[IO.File]::ReadAllText($taskFile.FullName) } }
 Write-Rm7Object -Object @{apiVersion='v1';kind='ConfigMap';metadata=@{name=$taskPair[1];namespace=$Rm7Namespace};data=$taskData}
}
Invoke-Rm7Kubectl -Arguments @('apply','-f',(Join-Path $PSScriptRoot 'k8s/dashboard.yaml')) | Out-Host
Invoke-Rm7Kubectl -Arguments @('-n',$Rm7Namespace,'rollout','restart','deployment/dashboard') | Out-Host
Invoke-Rm7Kubectl -Arguments @('-n',$Rm7Namespace,'rollout','status','deployment/dashboard','--timeout=900s') | Out-Host
Write-Host 'Dashboard guncellendi. PostgreSQL, dbt verisi ve Informatica kayitlari yeniden olusturulmadi.'
