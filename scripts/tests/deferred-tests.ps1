# Deferred-member regressions. All repositories, shims and paths are synthetic.
$ErrorActionPreference='Stop'
$root=(Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
$env:ZIMA_DOT_SOURCED='1';. (Join-Path $root 'scripts/zima.ps1');$env:ZIMA_DOT_SOURCED=$null
$script:Count=0;$script:Failures=0
function Assert-Deferred([bool]$Ok,[string]$Name){$script:Count++;if($Ok){Write-Host ('PASS '+$Name)}else{$script:Failures++;Write-Host ('FAIL '+$Name)}}
function Copy-DeferredManifest($M){ConvertTo-HashtableDeep ($M|ConvertTo-Json -Depth 40|ConvertFrom-Json)}
function Save-DeferredManifest($M){Write-Utf8NoBom (Join-Path $tree 'repos.json') (($M|ConvertTo-Json -Depth 40)+"`n")}
function Invoke-DeferredCli([string[]]$Arguments){Invoke-ZimaNative powershell (@('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $tree 'scripts/zima.ps1'))+$Arguments)}
function Test-DeferredThrows([scriptblock]$Action){try{&$Action|Out-Null;return $false}catch{return $true}}
$rel='.agent-tmp/partial-cutover-2026-10-23/deferred-tests-'+[guid]::NewGuid().ToString('N')
$tree=Get-ZimaSafePath $root $rel
$oldPath=$env:PATH;$originalSafe=${function:Get-ZimaSafePath}
try{
 $null=New-Item -ItemType Directory -Path $tree
 foreach($dir in @('docs','repos','.agents')){Copy-Item -LiteralPath (Join-Path $root $dir) -Destination (Join-Path $tree $dir) -Recurse}
 $null=New-Item -ItemType Directory -Path (Join-Path $tree 'scripts'),(Join-Path $tree 'projects'),(Join-Path $tree 'shim')
 foreach($file in @('AGENTS.md','README.md','repos.schema.json','.gitignore','.ignore','.gitattributes')){Copy-Item -LiteralPath (Join-Path $root $file) -Destination (Join-Path $tree $file)}
 Copy-Item -LiteralPath (Join-Path $root 'scripts/zima.ps1') -Destination (Join-Path $tree 'scripts/zima.ps1')
 Write-Utf8NoBom (Join-Path $tree 'scripts/README.md') 'Synthetic test code only.'
 $native=Invoke-ZimaNative git @('-C',$tree,'init','--quiet');if($native.Code -ne 0){throw 'Fixture Git init failed'}
 $base=Read-ZimaManifest (Join-Path $root 'repos.json');$m=Resolve-ZimaDefaults $base
 Assert-Deferred ((Invoke-ZimaManifestValidation $base $tree).Errors.Count -eq 0) 'actual deferred manifest validates without member sources'
 $plain=Copy-DeferredManifest $base;foreach($r in $plain['repos']){$r.Remove('deferred');$r.Remove('defer_reason')}
 $normal=Resolve-ZimaDefaults $plain
 Assert-Deferred (@($normal['repos']|Where-Object{Test-ZimaRepoDeferred $_}).Count -eq 0) 'omitted deferral defaults active'
 Assert-Deferred (!$plain['repos'][0].ContainsKey('deferred')) 'default normalization preserves original manifest'
 foreach($bad in @('true',1,$null)){$badM=Copy-DeferredManifest $base;$badM['repos'][0]['deferred']=$bad;Assert-Deferred ((Invoke-ZimaManifestValidation $badM $tree).Errors.Count -gt 0) 'invalid deferred type rejected'}
 foreach($bad in @($null,'','  ')){$badM=Copy-DeferredManifest $base;$badM['repos'][0]['defer_reason']=$bad;Assert-Deferred ((Invoke-ZimaManifestValidation $badM $tree).Errors.Count -gt 0) 'deferred member requires nonempty reason'}
 $badM=Copy-DeferredManifest $base;$badM['repos'][0].Remove('defer_reason');Assert-Deferred ((Invoke-ZimaManifestValidation $badM $tree).Errors.Count -gt 0) 'deferred member requires reason even when omitted'
 $badM=Copy-DeferredManifest $base;$badM['repos'][0]['path']='../drive-trace';Assert-Deferred ((Invoke-ZimaManifestValidation $badM $tree).Errors.Count -gt 0) 'deferral cannot admit external/traversal member paths'
 $badM=Copy-DeferredManifest $base;$badM['repos'][0]['docs']['agents']='../escape';Assert-Deferred ((Invoke-ZimaManifestValidation $badM $tree).Errors.Count -gt 0) 'deferred document paths still checked lexically'

 # A junction exists only in this synthetic workspace. Deferral must not follow it;
 # activating the same declared member must restore the existing reparse rejection.
 $outside=Join-Path $tree 'excluded-target';$null=New-Item -ItemType Directory -Path $outside
 $junction=Join-Path $tree 'projects/drive-trace';$null=New-Item -ItemType Junction -Path $junction -Target $outside
 try{
  Assert-Deferred ((Invoke-ZimaManifestValidation $base $tree).Errors.Count -eq 0) 'deferred path is metadata only even with junction at planned path'
  $activeM=Copy-DeferredManifest $base;$activeM['repos'][0]['deferred']=$false
  Assert-Deferred (@((Invoke-ZimaManifestValidation $activeM $tree).Errors|Where-Object{$_ -match 'Reparse ancestor'}).Count -gt 0) 'active member retains filesystem reparse guard'
 }finally{[IO.Directory]::Delete($junction)}

 $script:DeferredProbes=0;$script:OriginalDeferredSafe=$originalSafe
 function Get-ZimaSafePath {
  param([string]$Root,[string]$Relative,[switch]$AllowRoot)
  if($Relative -eq 'projects/drive-trace' -or $Root.TrimEnd('\','/').EndsWith('\projects\drive-trace',[StringComparison]::OrdinalIgnoreCase)){$script:DeferredProbes++;throw 'Synthetic excluded path was probed'}
  & $script:OriginalDeferredSafe $Root $Relative -AllowRoot:$AllowRoot
 }
 $state=Get-ZimaRepoState $m['repos'][0] $tree
 Assert-Deferred ($state.deferred -and !$state.inspected -and $null -eq $state.present -and $null -eq $state.isGit -and $null -eq $state.staged) 'deferred state is explicitly uninspected with no invented source state'
 Assert-Deferred ($script:DeferredProbes -eq 0) 'deferred state returns before path probe'
 Save-DeferredManifest $base;Invoke-ZimaGen $m $tree
 $verify=Invoke-ZimaVerify -Mode full -ZimaRoot $tree
 Assert-Deferred (@($verify.Errors|Where-Object{$_ -match 'repo drive-trace'}).Count -eq 0 -and @($verify.Info|Where-Object{$_ -match '^DEFERRED drive-trace'}).Count -eq 1) 'normal Full explicitly excludes deferred source/docs/preamble checks'
 Assert-Deferred (@($verify.Errors|Where-Object{$_ -match 'missing, unsafe, non-root'}).Count -eq 4) 'normal Full still rejects all four missing active members'
 Assert-Deferred ($script:DeferredProbes -eq 0) 'manifest and Full verification never probe excluded source'
 Set-Item Function:Get-ZimaSafePath -Value $originalSafe
 $generated=Get-ZimaGenerated $m $tree;$workspace=$generated['zima.code-workspace']|ConvertFrom-Json
 Assert-Deferred ($workspace.folders.Count -eq 5 -and @($workspace.folders|Where-Object{$_.name -eq 'drive-trace'}).Count -eq 0) 'portable workspace contains root plus four active entries only'
 Assert-Deferred ($generated['repos/repos.md'].Contains('DEFERRED: ') -and $generated['docs/runners.md'].Contains('| drive-trace | DEFERRED |')) 'generated catalog and runner registry label excluded metadata'
 $allActiveGenerated=Get-ZimaGenerated $normal $tree;$allActiveWorkspace=$allActiveGenerated['zima.code-workspace']|ConvertFrom-Json
 Assert-Deferred ($allActiveWorkspace.folders.Count -eq 6) 'all-active generation retains root plus all five members'
 $targets=Get-ZimaTargets $m @() -All
 Assert-Deferred ($targets.Count -eq 4 -and @($targets|Where-Object{$_['name'] -eq 'drive-trace'}).Count -eq 0) 'bulk targets exclude deferred member'
 Assert-Deferred (Test-DeferredThrows {Get-ZimaTargets $m @('drive-trace')}) 'explicit target selector refuses deferred member'

 # Relocated files have new stat/inode data. A clean status read must not refresh
 # the raw index, which is preserved byte-for-byte by the migration transaction.
 $statusMember=@($m['repos']|Where-Object{$_['name'] -eq 'lg-tv-channel-sort'})[0]
 $statusDir=Get-ZimaSafePath $tree $statusMember['path'];$null=New-Item -ItemType Directory -Path $statusDir
 $oldOptionalLocks=$env:GIT_OPTIONAL_LOCKS
 try{
  $env:GIT_OPTIONAL_LOCKS='1'
  foreach($arguments in @(@('init','--quiet','-b','main'),@('config','user.name','Synthetic'),@('config','user.email','synthetic@example.invalid'),@('config','core.fsmonitor','false'),@('config','core.untrackedCache','false'),@('remote','add','origin',$statusMember['github']))){
   $g=Invoke-ZimaNative git (@('-C',$statusDir)+$arguments);if($g.Code -ne 0){throw 'Synthetic status Git setup failed'}
  }
  $tracked=Join-Path $statusDir 'tracked.txt';Write-Utf8NoBom $tracked "Unchanged synthetic tracked content.`n"
  foreach($arguments in @(@('add','tracked.txt'),@('commit','--quiet','-m','Synthetic baseline'))){$g=Invoke-ZimaNative git (@('-C',$statusDir)+$arguments);if($g.Code -ne 0){throw 'Synthetic status Git commit failed'}}
  [IO.File]::SetLastWriteTimeUtc($tracked,[DateTime]::UtcNow.AddDays(-1))
  $index=Join-Path $statusDir '.git/index';$beforeHash=(Get-FileHash -LiteralPath $index -Algorithm SHA256).Hash;$beforeTime=[IO.File]::GetLastWriteTimeUtc($index).Ticks
  $readState=Get-ZimaRepoState $statusMember $tree
  Assert-Deferred ($readState.isGit -and $readState.originOk -and $null -eq $readState.error -and $readState.staged -eq 0 -and $readState.unstaged -eq 0 -and $readState.untracked -eq 0) 'stale tracked-file mtime still reports a clean synthetic repository'
  Assert-Deferred ($beforeHash -ceq (Get-FileHash -LiteralPath $index -Algorithm SHA256).Hash -and $beforeTime -eq [IO.File]::GetLastWriteTimeUtc($index).Ticks) 'status read preserves raw index bytes and mtime despite stale stat data'
 }finally{
  $env:GIT_OPTIONAL_LOCKS=$oldOptionalLocks
  if(Test-Path -LiteralPath $statusDir){$checkedStatus=Get-ZimaSafePath $tree $statusMember['path'];Remove-Item -LiteralPath $checkedStatus -Recurse -Force}
 }

 # Actual child CLI processes use synthetic native shims; explicit refusal must
 # happen before even metadata-only native calls. No real network/runner exists.
 $shim=Join-Path $tree 'shim';$gitLog=Join-Path $shim 'git.log';$ghLog=Join-Path $shim 'gh.log';$dockerLog=Join-Path $shim 'docker.log'
 Write-Utf8NoBom (Join-Path $shim 'git.cmd') ("@echo off`r`necho %*>>`"$gitLog`"`r`nexit /b 0`r`n")
 Write-Utf8NoBom (Join-Path $shim 'gh.cmd') ("@echo off`r`necho %*>>`"$ghLog`"`r`necho []`r`nexit /b 0`r`n")
 # Use a native executable shim: cmd.exe would reinterpret the literal pipes in
 # Docker's format argument, which is unrelated to the production docker.exe API.
 $compiler=Join-Path $shim 'compiler';$null=New-Item -ItemType Directory -Path $compiler
 $oldTemp=$env:TEMP;$oldTmp=$env:TMP
 try{
  $env:TEMP=$compiler;$env:TMP=$compiler
  $source=@'
using System;
using System.IO;
public static class DeferredDockerShim {
  public static int Main(string[] args) {
    File.AppendAllText(@"__LOG__",string.Join(" ",args)+Environment.NewLine);
    Console.WriteLine("ct-docker-1|running|Up");
    Console.WriteLine("dm-docker-1|exited|Exited");
    return 0;
  }
}
'@
  $source=$source.Replace('__LOG__',$dockerLog.Replace('"','""'))
  Add-Type -TypeDefinition $source -OutputAssembly (Join-Path $shim 'docker.exe') -OutputType ConsoleApplication | Out-Null
 }finally{$env:TEMP=$oldTemp;$env:TMP=$oldTmp}
 $env:PATH=$shim+';'+$oldPath
 foreach($arguments in @(@('clone','drive-trace'),@('sync','drive-trace'),@('update','drive-trace'),@('issues','-R','drive-trace'))){
  if(Test-Path -LiteralPath $gitLog){Remove-Item -LiteralPath $gitLog}
  $result=Invoke-DeferredCli $arguments
  Assert-Deferred ($result.Code -eq 1 -and (($result.Output+$result.Diagnostics) -join ' ') -match 'DEFERRED') ('child CLI refuses '+($arguments -join ' '))
  Assert-Deferred (!(Test-Path -LiteralPath $gitLog) -and !(Test-Path -LiteralPath $ghLog) -and !(Test-Path -LiteralPath $dockerLog)) 'explicit refusal occurs before every native call'
 }
 $result=Invoke-DeferredCli @('issues','--json');$rows=($result.Output -join "`n")|ConvertFrom-Json
 $log=Get-Content -LiteralPath $ghLog -Raw
 Assert-Deferred ($result.Code -eq 0 -and @($rows).Count -eq 5 -and $log -notmatch 'drive-trace') 'bulk issues reaches four active repos plus zima only'
 $result=Invoke-DeferredCli @('runners');if($result.Code -ne 0){throw ('Synthetic runners CLI failed: '+(($result.Output+$result.Diagnostics) -join ' '))};$log=Get-Content -LiteralPath $dockerLog -Raw
 Assert-Deferred ($result.Code -eq 0 -and $log -notmatch 'dt-docker-1' -and @($log -split "`r?`n"|Where-Object{$_}).Count -eq 2) 'runner queries only active containers, never excluded runner'
 Assert-Deferred ($log.Contains('--filter name=^/ct-docker-1$') -and $log.Contains('--filter name=^/dm-docker-1$')) 'runner Docker filters are exact active container names'
 $result=Invoke-DeferredCli @('drive-trace')
 Assert-Deferred ($result.Code -eq 0 -and ($result.Output -join ' ') -match '"inspected":\s*false') 'metadata-only deferred card succeeds without source inspection'
 $result=Invoke-DeferredCli @('status','-Pending','--json');$status=($result.Output -join "`n")|ConvertFrom-Json
 Assert-Deferred ($result.Code -eq 0 -and $status.repos[0].deferred -and !$status.repos[0].inspected -and $null -eq $status.repos[0].present) 'child status exposes DEFERRED without fake source presence'
 $phase=Join-Path $tree '.local-state/migration';$null=New-Item -ItemType Directory -Force -Path $phase;Write-Utf8NoBom (Join-Path $phase 'PHASE') 'PARTIAL'
 $result=Invoke-DeferredCli @('verify','-Pending');Assert-Deferred ($result.Code -eq 1 -and (($result.Output+$result.Diagnostics) -join ' ') -match 'only for A1') 'PARTIAL phase cannot use Pending to bypass active-member validation'
 $allDeferred=Copy-DeferredManifest $base;foreach($r in $allDeferred['repos']){$r['deferred']=$true;$r['defer_reason']='Synthetic explicit exclusion';Write-Utf8NoBom (Join-Path $tree ('repos/'+$r['name']+'.md')) "# DEFERRED fixture`n`n[Router](../AGENTS.md)`n"};Save-DeferredManifest $allDeferred
 if(Test-Path -LiteralPath $dockerLog){Remove-Item -LiteralPath $dockerLog}
 $result=Invoke-DeferredCli @('runners');Assert-Deferred ($result.Code -eq 0 -and !(Test-Path -LiteralPath $dockerLog)) 'all-deferred runner list performs zero Docker calls'
 $result=Invoke-DeferredCli @('status','--json');Assert-Deferred ($result.Code -eq 0) 'normal status succeeds for deliberately uninspected deferred-only manifest'
 foreach($operation in @('clone','sync','update')){
  if(Test-Path -LiteralPath $gitLog){Remove-Item -LiteralPath $gitLog}
  $result=Invoke-DeferredCli @($operation,'-All');$nativeCalls=@(Get-Content -LiteralPath $gitLog)
  Assert-Deferred ($result.Code -eq 0 -and $nativeCalls.Count -eq 5 -and @($nativeCalls|Where-Object{$_ -notmatch '^check-ref-format --branch main$'}).Count -eq 0) ('all-deferred '+$operation+' performs no source/transport mutation calls')
 }
}catch{$script:Failures++;Write-Host ('UNEXPECTED: '+$_.Exception.Message);Write-Host $_.ScriptStackTrace}
finally{
 $env:PATH=$oldPath;Set-Item Function:Get-ZimaSafePath -Value $originalSafe
 $evidence=Join-Path $root '.agent-tmp/partial-cutover-2026-10-23/deferred-tests.json'
 $receipt=[ordered]@{timestamp_utc=[DateTime]::UtcNow.ToString('o');assertions=$script:Count;failures=$script:Failures;synthetic_only=$true;source_members_accessed=$false;script_sha256=(Get-FileHash -LiteralPath (Join-Path $root 'scripts/zima.ps1') -Algorithm SHA256).Hash.ToLowerInvariant();tests_sha256=(Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash.ToLowerInvariant()}
 Write-Utf8NoBom $evidence (($receipt|ConvertTo-Json -Depth 5)+"`n")
 if(Test-Path -LiteralPath $tree){$checked=Get-ZimaSafePath $root $rel;Remove-Item -LiteralPath $checked -Recurse -Force}
}
Write-Host ("Deferred tests: {0} assertions; {1} failures" -f $script:Count,$script:Failures)
if($script:Failures){exit 1};exit 0
