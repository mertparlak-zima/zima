# Fast in-memory unit test suite for zima manifest, runner rules and generated artifacts.
$ErrorActionPreference='Stop'
$root=(Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
$env:ZIMA_DOT_SOURCED='1';. (Join-Path $root 'scripts/zima.ps1');$env:ZIMA_DOT_SOURCED=$null
$script:Count=0;$script:Failures=0
function Assert([bool]$Ok,[string]$Name){$script:Count++;if(!$Ok){$script:Failures++;Write-Host "FAIL $Name"}else{Write-Host "PASS $Name"}}
function Throws([scriptblock]$Action,[string]$Name){$caught=$false;try{&$Action|Out-Null}catch{$caught=$true};Assert $caught $Name}
function Copy-M($M){ConvertTo-HashtableDeep ($M|ConvertTo-Json -Depth 40|ConvertFrom-Json)}
function Valid($M){return (Invoke-ZimaManifestValidation $M $root).Errors.Count -eq 0}

$real=Read-ZimaManifest (Join-Path $root 'repos.json')
$base=Copy-M $real
Assert (Valid $real) 'real manifest validates'

foreach($file in Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'fixtures') -Filter 'bad-*.json'){
 Assert (!(Valid (Read-ZimaManifest $file.FullName))) ('fixture rejected: '+$file.Name)
}

$m=Copy-M $base;$m['repos'][0]['runner']=$null;Assert (!(Valid $m)) 'null runner rejected'
$m=Copy-M $base;$m['repos'][0]['ci_workflows']=@();Assert (!(Valid $m)) 'empty ci_workflows rejected'
$m=Copy-M $base;$m['repos'][0]['ci_workflows']=@('../escape.yml');Assert (!(Valid $m)) 'traversal ci_workflow rejected'
$m=Copy-M $base;$m['repos'][0]['quirks']=@('no-ci-by-design');Assert (!(Valid $m)) 'no-ci-by-design quirk rejected'
$m=Copy-M $base;$m['repos'][0]['runner']['compose']='../escape.yml';Assert (!(Valid $m)) 'traversal runner.compose rejected'
$m=Copy-M $base;$m['repos'][0]['docs']['key']=@('../outside.md');Assert (!(Valid $m)) 'doc traversal rejected'
foreach($p in @('../outside','C:\outside','projects/../../bad','')){Throws {Get-ZimaSafePath $root $p} ('unsafe path: '+$p)}

$def=Copy-M $base;$def['repos'][0]['deferred']=$true;$def['repos'][0]['defer_reason']='Synthetic test'
$normDef=Resolve-ZimaDefaults $def
Assert ((Invoke-ZimaManifestValidation $def $root).Errors.Count -eq 0) 'valid deferred member accepted'
$targets=Get-ZimaTargets $normDef @() -All
Assert ($targets.Count -eq ($base['repos'].Count - 1)) 'bulk targets skip deferred member'
Throws {Get-ZimaTargets $normDef @($def['repos'][0]['name'])} 'explicit target refuses deferred member'

$norm=Resolve-ZimaDefaults $real
$gen=Get-ZimaGenerated $norm $root
foreach($rel in @('repos/repos.md','docs/runners.md','zima.code-workspace')){
 $actual=([IO.File]::ReadAllText((Join-Path $root $rel)) -replace "`r`n","`n")
 Assert ($actual -ceq $gen[$rel]) ('generated up-to-date: '+$rel)
}

$bytes=[IO.File]::ReadAllBytes((Join-Path $root 'scripts/zima.ps1'))
$text=[Text.Encoding]::UTF8.GetString($bytes)
Assert ($bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191 -and !$text.Replace("`r`n",'').Contains("`n")) 'zima.ps1 preserves UTF-8 BOM and CRLF'

Write-Host "RESULT: $($script:Count) assertions; $($script:Failures) failures"
if($script:Failures){exit 1};exit 0
