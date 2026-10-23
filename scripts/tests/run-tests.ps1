# Synthetic regression suite; no Pester/network/member-repo writes. PS5.1, BOM+CRLF.
$ErrorActionPreference='Stop'
$root=(Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
$env:ZIMA_DOT_SOURCED='1';. (Join-Path $root 'scripts/zima.ps1');$env:ZIMA_DOT_SOURCED=$null
$script:Count=0;$script:Failures=0
function Assert {param([bool]$Ok,[string]$Name);$script:Count++;if(!$Ok){$script:Failures++;Write-Host "FAIL $Name"}else{Write-Host "PASS $Name"}}
function Throws {param([scriptblock]$Action,[string]$Name);$caught=$false;try{&$Action|Out-Null}catch{$caught=$true};Assert $caught $Name}
function Copy-M {param($M);ConvertTo-HashtableDeep ($M|ConvertTo-Json -Depth 40|ConvertFrom-Json)}
function Valid {param($M);return (Invoke-ZimaManifestValidation $M $root).Errors.Count -eq 0}
function Invoke-FixtureGit {param([string]$Cwd,[string[]]$NativeArgs);$g=Invoke-ZimaNative git (@('-C',$Cwd)+$NativeArgs);if($g.Code -ne 0){throw ('Fixture git command failed: '+($NativeArgs -join ' '))};return $g}
function Invoke-FixtureCli {param([string[]]$NativeArgs);Invoke-ZimaNative powershell (@('-NoProfile','-ExecutionPolicy','Bypass','-File',(Join-Path $script:Workspace 'scripts/zima.ps1'))+$NativeArgs)}
function Save-M {param($M);Write-Utf8NoBom (Join-Path $script:Workspace 'repos.json') (($M|ConvertTo-Json -Depth 40)+"`n")}
function Get-FixtureSnapshot {
 param([string]$RepoDir)
 $status=Invoke-ZimaGitRaw @('-C',$RepoDir,'status','--porcelain=v1','-z','--untracked-files=all')
 if($status.Code -ne 0){throw 'Cannot snapshot fixture status'}
 $files=[ordered]@{}
 foreach($file in Get-ChildItem -LiteralPath $RepoDir -Recurse -Force -File|Sort-Object FullName){
  if($file.FullName.StartsWith((Join-Path $RepoDir '.git')+'\',[StringComparison]::OrdinalIgnoreCase)){continue}
  $name=$file.FullName.Substring($RepoDir.Length)
  $files[$name]=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
 }
 $head=Invoke-FixtureGit $RepoDir @('rev-parse','HEAD')
 $stash=Invoke-FixtureGit $RepoDir @('stash','list','--format=%H')
 return ([ordered]@{head=($head.Output -join '');index=(Get-FileHash -LiteralPath (Join-Path $RepoDir '.git/index') -Algorithm SHA256).Hash;status=$status.Stdout;stashes=$stash.Output;files=$files}|ConvertTo-Json -Depth 20 -Compress)
}
$real=Read-ZimaManifest (Join-Path $root 'repos.json');$base=Copy-M $real
# Preserve the original all-active fixture coverage independently of production deferrals.
foreach($repo in $base['repos']){$repo.Remove('deferred');$repo.Remove('defer_reason')}
$rel='.agent-tmp/a1-hardening/tests-'+[guid]::NewGuid().ToString('N');$tree=Get-ZimaSafePath $root $rel
$null=New-Item -ItemType Directory -Force -Path $tree
try{
 Assert (Valid $real) 'real manifest validates'
 $m=Copy-M $base;$m['Version']=$m['version'];$m.Remove('version');Assert (!(Valid $m)) 'case-sensitive JSON property names enforced'
 foreach($text in @('{"a":1,}','{/*comment*/"a":1}','{"a":1}//comment')){$p=Join-Path $tree 'bad.json';Write-Utf8NoBom $p $text;Throws {Read-ZimaManifest $p} 'strict JSON comments/trailing comma rejected'}
 $stderrScript=Join-Path $tree 'stderr.ps1';Write-Utf8NoBom $stderrScript "[Console]::Out.WriteLine('stdout-data')`n[Console]::Error.WriteLine('stderr-warning')`nexit 0`n"
 $native=Invoke-ZimaNative powershell @('-NoProfile','-ExecutionPolicy','Bypass','-File',$stderrScript);Assert ($native.Code -eq 0 -and $native.Output.Count -eq 1 -and $native.Output[0] -ceq 'stdout-data' -and ($native.Diagnostics -join ' ') -match 'stderr-warning') 'successful native stderr cannot pollute stdout data'
 foreach($file in Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'fixtures') -Filter 'bad-*.json') {Assert (!(Valid (Read-ZimaManifest $file.FullName))) ('fixture rejected: '+$file.Name)}
 foreach($bad in @($null,@(),3,'bad')){Assert (!(Valid $bad)) 'non-object manifest rejected'}
 foreach($field in @('repos','defaults','third_party')){$m=Copy-M $base;$m[$field]='bad';Assert (!(Valid $m)) ("wrong type rejected: $field")}
 foreach($field in @('docs','ci_workflows','skills_locations','runner')){$m=Copy-M $base;$m['repos'][0][$field]='bad';Assert (!(Valid $m)) ("nested wrong type rejected: $field")}
 $m=Copy-M $base;$m['extra']=1;Assert (!(Valid $m)) 'unknown root property rejected'
 $m=Copy-M $base;$m['repos'][0]['extra']=1;Assert (!(Valid $m)) 'unknown repo property rejected'
 $m=Copy-M $base;$m['repos'][0]['runner']['extra']=1;Assert (!(Valid $m)) 'unknown runner property rejected'
 $m=Copy-M $base;$m['repos'][0]['product']='';Assert (!(Valid $m)) 'empty required string rejected'
 $m=Copy-M $base;$m['repos'][0]['github']='https://githubXcom/a/bXgit';Assert (!(Valid $m)) 'URL pattern enforced'
 $m=Copy-M $base;$m['repos'][0]['owner_type']='third-party';Assert (!(Valid $m)) 'explicit invalid owner rejected'
 $m=Copy-M $base;$m['repos'][0].Remove('owner_type');$m['repos'][0].Remove('default_branch');Assert (Valid $m) 'omitted fields inherit valid defaults'
 $normalized=Resolve-ZimaDefaults $m;Assert ($normalized['repos'][0]['default_branch'] -ceq 'main') 'default branch normalized';Assert (!$m['repos'][0].ContainsKey('default_branch')) 'normalization does not mutate input'
 $m['defaults']['owner_type']='third-party';Assert (!(Valid $m)) 'invalid inherited repo owner rejected'
 $m=Copy-M $base;$m['repos'][0]['default_branch']='feature/valid';Assert (Valid $m) 'explicit valid branch overrides default'
 foreach($branch in @('-bad','bad..ref','x.lock','bad ref')){$m=Copy-M $base;$m['repos'][0]['default_branch']=$branch;Assert (!(Valid $m)) ("invalid git branch rejected: $branch")}
 $schema=Read-ZimaManifest (Join-Path $root 'repos.schema.json');$schema['definitions']['repo']['maxLength']=1;Assert (@(Test-ZimaSchemaDefinition $schema).Count -gt 0) 'unsupported schema keyword fails closed even unused definition'
 $m=Copy-M $base;$m['third_party']=@(@{name='external';github='https://github.com/a/b.git';path=(Join-Path $root 'docs/../projects');trusted=$false});Assert (!(Valid $m)) 'canonical third-party inside path rejected'
 $m['third_party'][0]['path']=$tree;$m['third_party'][0]['trusted']=0;Assert (!(Valid $m)) 'trusted numeric zero rejected'
 $m=Copy-M $base;$m['repos'][0]['docs']['key']=@('../outside.md');Assert (!(Valid $m)) 'doc traversal rejected'
 $m=Copy-M $base;$m['repos'][0]['name']='con';$m['repos'][0]['path']='projects/con';Assert (!(Valid $m)) 'reserved Windows slug rejected'
 foreach($p in @('../outside','C:\outside','projects/../../bad','','projects/a:stream')){Throws {Get-ZimaSafePath $tree $p} ('unsafe path: '+$p)}

 # Junction target is synthetic and outside the fixture workspace, within this task.
 $outside=Join-Path $tree 'outside';$junctionRoot=Join-Path $tree 'junction-case';$null=New-Item -ItemType Directory -Path $outside,$junctionRoot
 $junction=Join-Path $junctionRoot 'projects';$null=New-Item -ItemType Junction -Path $junction -Target $outside
 Copy-Item -LiteralPath (Join-Path $root 'repos.schema.json') -Destination (Join-Path $junctionRoot 'repos.schema.json')
 try{Throws {Get-ZimaSafePath $junctionRoot 'projects/escape'} 'junction ancestor rejected';$m=Copy-M $base;Assert (@((Invoke-ZimaManifestValidation $m $junctionRoot).Errors|Where-Object{$_ -match 'Reparse ancestor'}).Count -gt 0) 'manifest rejects junction member path'}finally{[IO.Directory]::Delete($junction)}
 Assert (!(Test-Path -LiteralPath (Join-Path $outside 'escape'))) 'junction probe wrote nothing outside destination'

 $exact=Join-Path $tree 'exact';Write-Utf8NoBom $exact '# projects/*';Assert (@(Test-RequiredLines $exact @('projects/*')).Count -eq 1) 'comment substring not exact ignore rule'
 Write-Utf8NoBom $exact 'projects/anything';Assert (@(Test-RequiredLines $exact @('projects/*')).Count -eq 1) 'wildcard substring not exact ignore rule'
 Write-Utf8NoBom $exact "projects/*`n";Assert (@(Test-RequiredLines $exact @('projects/*')).Count -eq 0) 'literal wildcard accepted'
 $d19=Join-Path $tree 'd19';$null=New-Item -ItemType Directory -Force -Path (Join-Path $d19 'a/b/c/d/e'),(Join-Path $d19 'projects/member/deep'),(Join-Path $d19 '.agents/skills/example/references')
 Write-Utf8NoBom (Join-Path $d19 '.agents/skills/example/SKILL.md') 'skill';$missing=@(Test-FolderReadmes $d19)
 Assert ($missing -contains 'a\b\c\d\e') 'D19 checks depth beyond four'
 Assert ($missing -notcontains 'projects\member') 'D19 prunes member repositories'
 Assert ($missing -notcontains '.agents\skills\example') 'D19 exempts exact skill root'
 Assert ($missing -contains '.agents\skills\example\references') 'D19 does not exempt references'

 # Complete synthetic zima workspace: CLI entry resolves here, never real zima root.
 $script:Workspace=Join-Path $tree 'workspace';$null=New-Item -ItemType Directory -Path $script:Workspace
 foreach($folder in @('docs','repos','.agents')){Copy-Item -LiteralPath (Join-Path $root $folder) -Destination (Join-Path $script:Workspace $folder) -Recurse}
 $null=New-Item -ItemType Directory -Path (Join-Path $script:Workspace 'scripts'),(Join-Path $script:Workspace 'projects')
 foreach($file in @('AGENTS.md','README.md','repos.schema.json','.gitignore','.ignore','.gitattributes')){Copy-Item -LiteralPath (Join-Path $root $file) -Destination (Join-Path $script:Workspace $file)}
 Copy-Item -LiteralPath (Join-Path $root 'scripts/zima.ps1') -Destination (Join-Path $script:Workspace 'scripts/zima.ps1');Write-Utf8NoBom (Join-Path $script:Workspace 'scripts/README.md') 'fixture'
 # Production's deferred card uses reference text rather than live member links.
 # The original all-active fixture still exercises every required card link.
 foreach($r in $base['repos']){$card=Join-Path $script:Workspace ('repos/'+$r['name']+'.md');$cardText=[IO.File]::ReadAllText($card);foreach($doc in @($r['docs']['readme'],$r['docs']['agents'],$r['docs']['skills'])+@($r['docs']['key'])){if($null -ne $doc){$target='../'+$r['path']+'/'+$doc;if(!$cardText.Contains(']('+$target+')')){$cardText+="`n- [Synthetic entry]($target)`n"}}};Write-Utf8NoBom $card $cardText}
 Save-M $base;$null=Invoke-FixtureGit $script:Workspace @('init','--quiet');$m=Resolve-ZimaDefaults $base
 Invoke-ZimaGen $m $script:Workspace;$first=Get-ZimaGenerated $m $script:Workspace;Invoke-ZimaGen $m $script:Workspace;$second=Get-ZimaGenerated $m $script:Workspace
 foreach($p in $first.Keys){Assert ($first[$p] -ceq $second[$p]) ('deterministic generation: '+$p)}
 $ws=Read-ZimaManifest (Join-Path $script:Workspace 'zima.code-workspace');Assert ($ws['folders'].Count -eq 6) 'workspace contains all six paths while members absent';Assert ($ws['folders'][0]['path'] -ceq '.') 'workspace root portable';Assert (@($ws['folders']|Where-Object{[IO.Path]::IsPathRooted($_['path'])}).Count -eq 0) 'workspace has no machine absolute paths'
 Write-Utf8NoBom (Join-Path $script:Workspace 'repos/repos.md') ($first['repos/repos.md'].Replace('DriveTrace','Drift'))
 $v=Invoke-ZimaVerify -Mode fast -ZimaRoot $script:Workspace -Pending;Assert (@($v.Errors|Where-Object{$_ -match 'generated artifact drift: repos/repos.md'}).Count -eq 1) 'Pending detects same-row-count generated drift';Invoke-ZimaGen $m $script:Workspace
 $c=Invoke-FixtureCli @('status','-Pending','--json');Assert ($c.Code -eq 0) 'status Pending exits zero';$obj=($c.Output -join "`n")|ConvertFrom-Json;Assert ($obj.repos.Count -eq 5) '--json emits actual parseable five repo data'
 $c=Invoke-FixtureCli @('verify','-Fast','-Pending','--json');Assert ($c.Code -eq 0) ('verify clean exit0; actual '+$c.Code)
 $orphan=Get-ZimaSafePath $script:Workspace 'projects/orphan';$null=New-Item -ItemType Directory -Path $orphan;$c=Invoke-FixtureCli @('verify','-Fast','-Pending','--json');Assert ($c.Code -eq 2) ('verify warning exit2; actual '+$c.Code);[IO.Directory]::Delete($orphan)
 $phaseDir=Get-ZimaSafePath $script:Workspace '.local-state/migration';$null=New-Item -ItemType Directory -Force -Path $phaseDir;$phasePath=Join-Path $phaseDir 'PHASE'
 foreach($phase in @('A2','COMMITTED','CLEANED','a1','')){Write-Utf8NoBom $phasePath $phase;Throws {Assert-ZimaPendingAllowed $script:Workspace} ('Pending rejects phase '+$phase)}
 Write-Utf8NoBom $phasePath 'A2';$c=Invoke-FixtureCli @('status','-Pending');Assert ($c.Code -eq 1) 'status Pending forbidden after A1';$c=Invoke-FixtureCli @('verify','-Pending');Assert ($c.Code -eq 1) 'verify Pending forbidden after A1';Write-Utf8NoBom $phasePath 'A1';Assert-ZimaPendingAllowed $script:Workspace;Remove-Item -LiteralPath $phasePath
 foreach($caseArgs in @(@('status'),@('clone','unknown'),@('clone'),@('sync','unknown'),@('sync'),@('update'),@('issues','-R','unknown'),@('issues','-Stale','0'),@('new-repo','-Clone'),@('status','--typo'),@('unknown'))){$c=Invoke-FixtureCli $caseArgs;Assert ($c.Code -eq 1) ('CLI fails non-success: '+($caseArgs -join ' '))}
 $c=Invoke-FixtureCli @('clone','-All');Assert ($c.Code -eq 1 -and (($c.Output+$c.Diagnostics) -join ' ') -match 'irreplaceable') 'clone -All preflight, no positional indexing bug'
 Assert (!(Test-Path -LiteralPath (Join-Path $script:Workspace 'projects/drive-trace'))) 'clone -All never creates missing irreplaceable repo'
 $before=[IO.File]::ReadAllText((Join-Path $script:Workspace 'repos.json'))
 foreach($name in @('../escape','CON','bad/name','UPPER')){$c=Invoke-FixtureCli @('new-repo','-Name',$name,'-Github','https://github.com/a/b.git','-Product','P','-Stack','S');Assert ($c.Code -eq 1) ('new-repo rejects '+$name)}
 Assert ([IO.File]::ReadAllText((Join-Path $script:Workspace 'repos.json')) -ceq $before) 'invalid new-repo leaves manifest unchanged'
 Assert (!(Test-Path -LiteralPath (Join-Path $tree 'escape.md'))) 'invalid new-repo no outside writes'
 $c=Invoke-FixtureCli @('new-repo','-Name','new-test','-Github','invalid','-Product','P','-Stack','S');Assert ($c.Code -eq 1) 'new-repo validates URL before write'
 $c=Invoke-FixtureCli @('new-repo','-Name','new-test','-Github','https://github.com/a/b.git','-Product','P','-Stack','S');Assert ($c.Code -eq 0) 'new-repo valid success';$ws=Read-ZimaManifest (Join-Path $script:Workspace 'zima.code-workspace');Assert ($ws['folders'].Count -eq 7) 'new-repo refreshes generated workspace';Assert ((Get-Content -LiteralPath (Join-Path $script:Workspace 'repos/repos.md') -Raw).Contains('[card](new-test.md)')) 'new-repo refreshes index'
 Save-M $base;Invoke-ZimaGen $m $script:Workspace

 # Actual Git porcelain/index/worktree cases, all inside fixture.
 $repo=$m['repos'][1];$repoDir=Join-Path $script:Workspace $repo['path'];$null=New-Item -ItemType Directory -Path $repoDir
 $null=Invoke-FixtureGit $repoDir @('init','--quiet','-b','main');$null=Invoke-FixtureGit $repoDir @('config','user.email','test@example.invalid');$null=Invoke-FixtureGit $repoDir @('config','user.name','Fixture');$null=Invoke-FixtureGit $repoDir @('remote','add','origin',$repo['github'])
 foreach($f in @('both.txt','deleted.txt','conflict.txt')){Write-Utf8NoBom (Join-Path $repoDir $f) 'base'};$null=Invoke-FixtureGit $repoDir @('add','.');$null=Invoke-FixtureGit $repoDir @('commit','--quiet','-m','fixture base')
 $state=Get-ZimaRepoState $repo $script:Workspace;Assert ($state.isGit -and $state.originOk -and !$state.error) 'git root/origin verified';Assert ($null -eq $state.upstream -and $null -eq $state.ahead) 'missing upstream explicit null, no invented zero'
 Write-Utf8NoBom (Join-Path $repoDir 'both.txt') 'staged';$null=Invoke-FixtureGit $repoDir @('add','both.txt');Write-Utf8NoBom (Join-Path $repoDir 'both.txt') 'unstaged';$null=Invoke-FixtureGit $repoDir @('rm','--quiet','deleted.txt');Write-Utf8NoBom (Join-Path $repoDir 'untracked.txt') 'new'
 $state=Get-ZimaRepoState $repo $script:Workspace;Assert ($state.staged -eq 2 -and $state.unstaged -eq 1 -and $state.untracked -eq 1) 'M+M, staged deletion and untracked counts correct'
 $c=Invoke-FixtureCli @('update','coin-tracker');Assert ($c.Code -eq 1) 'dirty update refused nonzero'
 $null=Invoke-FixtureGit $repoDir @('reset','--hard','--quiet','HEAD');Remove-Item -LiteralPath (Join-Path $repoDir 'untracked.txt');$null=Invoke-FixtureGit $repoDir @('checkout','--quiet','--detach');$state=Get-ZimaRepoState $repo $script:Workspace;Assert $state.detached 'detached HEAD explicit';$c=Invoke-FixtureCli @('update','coin-tracker');Assert ($c.Code -eq 1) 'detached update refused';$null=Invoke-FixtureGit $repoDir @('checkout','--quiet','main')
 $null=Invoke-FixtureGit $repoDir @('update-ref','refs/remotes/origin/main','HEAD');$null=Invoke-FixtureGit $repoDir @('branch','--set-upstream-to=origin/main','main');$state=Get-ZimaRepoState $repo $script:Workspace;Assert ($state.upstream -ceq 'origin/main' -and $state.ahead -eq 0 -and $state.behind -eq 0) 'upstream counts actual tracked refs'
 $null=Invoke-FixtureGit $repoDir @('checkout','--quiet','-b','feature');Write-Utf8NoBom (Join-Path $repoDir 'conflict.txt') 'feature';$null=Invoke-FixtureGit $repoDir @('add','.');$null=Invoke-FixtureGit $repoDir @('commit','--quiet','-m','feature');$null=Invoke-FixtureGit $repoDir @('checkout','--quiet','main');Write-Utf8NoBom (Join-Path $repoDir 'conflict.txt') 'main';$null=Invoke-FixtureGit $repoDir @('add','.');$null=Invoke-FixtureGit $repoDir @('commit','--quiet','-m','main');$conflict=Invoke-ZimaNative git @('-C',$repoDir,'merge','feature');Assert ($conflict.Code -ne 0) 'fixture created actual conflict';$state=Get-ZimaRepoState $repo $script:Workspace;Assert ($state.conflicts -eq 1 -and $state.staged -eq 1 -and $state.unstaged -eq 1) 'conflict counted in both columns';$null=Invoke-FixtureGit $repoDir @('merge','--abort')
 $null=Invoke-FixtureGit $repoDir @('remote','set-url','origin','https://github.com/wrong/repo.git');$c=Invoke-FixtureCli @('sync','coin-tracker');Assert ($c.Code -eq 1 -and (($c.Output+$c.Diagnostics) -join ' ') -match 'origin mismatch') 'sync origin mismatch refused before network';$null=Invoke-FixtureGit $repoDir @('remote','set-url','origin',$repo['github'])

 # Fake external CLIs only for network failure propagation/argument contract.
 $shim=Join-Path $tree 'shim';$null=New-Item -ItemType Directory -Path $shim;$realGit=(Get-Command git.exe).Source
 Write-Utf8NoBom (Join-Path $shim 'git.cmd') ("@echo off`r`nif `"%~3`"==`"fetch`" exit /b 17`r`nif `"%~3`"==`"merge`" exit /b 18`r`n`"$realGit`" %*`r`nexit /b %errorlevel%`r`n")
 $mockSource='using System; using System.IO; class GhMock { static int Main(string[] args) { string dir=AppDomain.CurrentDomain.BaseDirectory; File.WriteAllLines(Path.Combine(dir,"gh-args.txt"),args); if(File.Exists(Path.Combine(dir,"gh-fail"))) return 19; Console.WriteLine("[]"); return 0; } }'
 $savedTemp=$env:TEMP;$savedTmp=$env:TMP
 try{$env:TEMP=$shim;$env:TMP=$shim;Add-Type -TypeDefinition $mockSource -OutputAssembly (Join-Path $shim 'gh.exe') -OutputType ConsoleApplication}finally{$env:TEMP=$savedTemp;$env:TMP=$savedTmp}
 $oldPath=$env:PATH;$env:PATH=$shim+';'+$env:PATH
 try{$c=Invoke-FixtureCli @('sync','coin-tracker');Assert ($c.Code -eq 1 -and (($c.Output+$c.Diagnostics) -join ' ') -match 'sync failed') 'fetch external failure propagates';$c=Invoke-FixtureCli @('update','coin-tracker');Assert ($c.Code -eq 1 -and (($c.Output+$c.Diagnostics) -join ' ') -match 'update failed') 'ff-only external failure propagates';$c=Invoke-FixtureCli @('issues','-R','zima','-Stale','7','--json');Assert ($c.Code -eq 0) 'issues zima target and empty JSON array succeed';$argsText=Get-Content -LiteralPath (Join-Path $shim 'gh-args.txt') -Raw;Assert ($argsText -match 'mertparlak-zima/zima' -and $argsText -match 'updated:<=') 'issues Stale reaches gh query';Write-Utf8NoBom (Join-Path $shim 'gh-fail') 'fail';$c=Invoke-FixtureCli @('issues','-R','zima');Assert ($c.Code -eq 1) 'gh failure propagated'}finally{$env:PATH=$oldPath}

 # Success/divergence exercise real Git against a local bare remote. The wrapper
 # changes only fetch transport (GitHub URL -> fixture); origin checks and every
 # fetch/merge are delegated to the real executable, without fabricated success.
 $bare=Join-Path $tree 'remote.git';$publisher=Join-Path $tree 'publisher'
 $null=Invoke-FixtureGit $tree @('clone','--bare','--quiet',$repoDir,$bare)
 $null=Invoke-FixtureGit $tree @('clone','--quiet',$bare,$publisher)
 $null=Invoke-FixtureGit $publisher @('config','user.email','test@example.invalid');$null=Invoke-FixtureGit $publisher @('config','user.name','Fixture')
 Write-Utf8NoBom (Join-Path $publisher 'remote-new.txt') 'first remote advancement'
 $null=Invoke-FixtureGit $publisher @('add','.');$null=Invoke-FixtureGit $publisher @('commit','--quiet','-m','remote advancement');$null=Invoke-FixtureGit $publisher @('push','--quiet','origin','main')
 Write-Utf8NoBom (Join-Path $repoDir '.git/info/exclude') ".ignored/`n"
 Write-Utf8NoBom (Join-Path $repoDir 'both.txt') 'stash seed';$null=Invoke-FixtureGit $repoDir @('stash','push','--quiet','-m','preserved fixture stash')
 Write-Utf8NoBom (Join-Path $repoDir 'both.txt') 'indexed dirty bytes';$null=Invoke-FixtureGit $repoDir @('add','both.txt');Write-Utf8NoBom (Join-Path $repoDir 'both.txt') 'worktree dirty bytes'
 Write-Utf8NoBom (Join-Path $repoDir 'dirty-only.txt') 'untracked bytes';$null=New-Item -ItemType Directory -Path (Join-Path $repoDir '.ignored');Write-Utf8NoBom (Join-Path $repoDir '.ignored/cache.bin') 'ignored bytes'
 $transport=@('@echo off','setlocal','if not "%~3"=="fetch" goto execute','set "GIT_CONFIG_COUNT=1"',('set "GIT_CONFIG_KEY_0=url.'+$bare.Replace('\','/')+'.insteadOf"'),('set "GIT_CONFIG_VALUE_0='+$repo['github']+'"'),'set "GIT_ALLOW_PROTOCOL=file"',':execute',('"'+$realGit+'" %*'),'exit /b %errorlevel%') -join "`r`n"
 Write-Utf8NoBom (Join-Path $shim 'git.cmd') ($transport+"`r`n")
 $env:PATH=$shim+';'+$oldPath
 try{
  $beforeFetch=Get-FixtureSnapshot $repoDir;$c=Invoke-FixtureCli @('sync','coin-tracker');$afterFetch=Get-FixtureSnapshot $repoDir
  Assert ($c.Code -eq 0) 'actual dirty fetch through fixture transport succeeds'
  Assert ($beforeFetch -ceq $afterFetch) 'dirty fetch preserves HEAD/index bytes/worktree/stash/untracked/ignored bytes'
  $target=Invoke-FixtureGit $bare @('rev-parse','refs/heads/main');$fetched=Invoke-FixtureGit $repoDir @('rev-parse','refs/remotes/origin/main');Assert (($target.Output -join '') -ceq ($fetched.Output -join '')) 'actual fetch advances matching origin tracking ref'
  $null=Invoke-FixtureGit $repoDir @('reset','--hard','--quiet','HEAD');Remove-Item -LiteralPath (Get-ZimaSafePath $repoDir 'dirty-only.txt')
  $stashBefore=Invoke-FixtureGit $repoDir @('stash','list','--format=%H');$ignoredBefore=(Get-FileHash -LiteralPath (Join-Path $repoDir '.ignored/cache.bin') -Algorithm SHA256).Hash
  $c=Invoke-FixtureCli @('update','coin-tracker');$headAfter=Invoke-FixtureGit $repoDir @('rev-parse','HEAD')
  Assert ($c.Code -eq 0 -and ($headAfter.Output -join '') -ceq ($target.Output -join '')) 'actual ff-only update advances HEAD to fetched target'
  $stashAfter=Invoke-FixtureGit $repoDir @('stash','list','--format=%H');Assert (($stashBefore.Output -join '') -ceq ($stashAfter.Output -join '') -and $ignoredBefore -ceq (Get-FileHash -LiteralPath (Join-Path $repoDir '.ignored/cache.bin') -Algorithm SHA256).Hash) 'ff-only advancement preserves stash and ignored bytes'
  Write-Utf8NoBom (Join-Path $publisher 'remote-next.txt') 'second remote advancement';$null=Invoke-FixtureGit $publisher @('add','.');$null=Invoke-FixtureGit $publisher @('commit','--quiet','-m','remote divergence');$null=Invoke-FixtureGit $publisher @('push','--quiet','origin','main')
  Write-Utf8NoBom (Join-Path $repoDir 'local-only.txt') 'local advancement';$null=Invoke-FixtureGit $repoDir @('add','local-only.txt');$null=Invoke-FixtureGit $repoDir @('commit','--quiet','-m','local divergence')
  $c=Invoke-FixtureCli @('sync','coin-tracker');Assert ($c.Code -eq 0) 'actual fetch of diverging target succeeds'
  $beforeDiverged=Get-FixtureSnapshot $repoDir;$c=Invoke-FixtureCli @('update','coin-tracker');$afterDiverged=Get-FixtureSnapshot $repoDir
  Assert ($c.Code -eq 1) 'actual ff-only merge refuses diverged histories'
  Assert ($beforeDiverged -ceq $afterDiverged) 'diverged refusal preserves HEAD/index/worktree/stash/untracked/ignored state'
 }finally{$env:PATH=$oldPath}

 # Lock lifecycle/ownership, traversal and genuinely competing child processes.
 Assert (@(Invoke-ZimaLock $script:Workspace list).Count -eq 0) 'lock list initially empty';Invoke-ZimaLock $script:Workspace acquire test-resource owner-a
 Throws {Invoke-ZimaLock $script:Workspace acquire test-resource owner-b} 'atomic existing lock acquisition refused';Throws {Invoke-ZimaLock $script:Workspace release test-resource owner-b} 'wrong owner release refused'
 Assert (@(Invoke-ZimaLock $script:Workspace list).Count -eq 1) 'wrong owner preserves held lock';Invoke-ZimaLock $script:Workspace release test-resource owner-a;Assert (@(Invoke-ZimaLock $script:Workspace list).Count -eq 0) 'owner releases lock'
 foreach($resource in @('../escape','a/b','..','CON:','')){Throws {Invoke-ZimaLock $script:Workspace acquire $resource owner} ('lock traversal/invalid rejected: '+$resource)}
 $fixtureCliPath=Join-Path $script:Workspace 'scripts/zima.ps1'
 $processes=@()
 foreach($ownerToken in @('one','two')){
  $startInfo=New-Object Diagnostics.ProcessStartInfo
  $startInfo.FileName=(Get-Command powershell.exe).Source
  $startInfo.Arguments='-NoProfile -ExecutionPolicy Bypass -File "'+$fixtureCliPath+'" locks acquire race -Owner '+$ownerToken
  $startInfo.UseShellExecute=$false;$startInfo.CreateNoWindow=$true
  $startInfo.RedirectStandardOutput=$true;$startInfo.RedirectStandardError=$true
  $processes+=,[Diagnostics.Process]::Start($startInfo)
 }
 $codes=@()
 foreach($process in $processes){$process.WaitForExit();$codes+=,$process.ExitCode;$process.Dispose()}
 Assert (@($codes|Where-Object{$_ -eq 0}).Count -eq 1 -and @($codes|Where-Object{$_ -eq 1}).Count -eq 1) ('two simultaneous lock processes; exits '+($codes -join ','))
 $held=@(Invoke-ZimaLock $script:Workspace list);Invoke-ZimaLock $script:Workspace release race $held[0]['owner']
 $probeOK=$true;try{Test-ZimaRgProbe $script:Workspace}catch{$probeOK=$false;Write-Host $_.Exception.Message};Assert $probeOK 'real rg probe includes member source and hides secrets/build/media'
 Write-Utf8NoBom (Join-Path $script:Workspace '.env') "FOO=bar`nQUOTED=`"hello world`"`nEMPTY=`n";$map=Read-ZimaEnv $script:Workspace;Assert ($map['FOO'] -ceq 'bar' -and $map['QUOTED'] -ceq 'hello world' -and $map.ContainsKey('EMPTY')) 'actual env parser handles ordinary values'
 Write-Utf8NoBom (Join-Path $script:Workspace '.env') 'TELEGRAM_BOT_TOKEN=not-a-real-secret';$v=Invoke-ZimaVerify -Mode full -ZimaRoot $script:Workspace -Pending;Assert (@($v.Errors|Where-Object{$_ -match 'disallowed credential'}).Count -eq 1) 'Full rejects secret key without exposing value'
 foreach($duplicate in @("TELEGRAM_BOT_TOKEN=not-a-real-secret`nTELEGRAM_BOT_TOKEN=", "TELEGRAM_BOT_TOKEN=not-a-real-secret`ntelegram_bot_token=")){
  Write-Utf8NoBom (Join-Path $script:Workspace '.env') $duplicate
  Throws {Read-ZimaEnv $script:Workspace} 'duplicate environment key rejected before overwrite'
  $v=Invoke-ZimaVerify -Mode full -ZimaRoot $script:Workspace -Pending
  Assert (@($v.Errors|Where-Object{$_ -match 'Duplicate .env key'}).Count -eq 1 -and ($v.Errors -join ' ') -notmatch 'not-a-real-secret') 'Full duplicate-key rejection withholds contents'
 }
 Remove-Item -LiteralPath (Join-Path $script:Workspace '.env')
 Write-Utf8NoBom (Join-Path $script:Workspace 'staged-secret.txt') ('ghp_'+('A'*30));$null=Invoke-FixtureGit $script:Workspace @('add','staged-secret.txt');$v=Invoke-ZimaVerify -Mode full -ZimaRoot $script:Workspace -Pending;Assert (@($v.Errors|Where-Object{$_ -match 'index scan: secret-shaped'}).Count -eq 1) 'Full scans staged blob contents';Assert (($v.Errors -join ' ') -notmatch 'ghp_') 'Full diagnostics withhold secret contents'
 Assert (@($v.Errors|Where-Object{$_ -match 'workspace preamble'}).Count -gt 0) 'Full requires mandatory preamble on present member'

 # The whole index is checked, including unchanged already-committed blobs.
 $indexCase=Join-Path $tree 'index-case';$null=New-Item -ItemType Directory -Path $indexCase
 $null=Invoke-FixtureGit $indexCase @('init','--quiet','-b','main');$null=Invoke-FixtureGit $indexCase @('config','user.email','test@example.invalid');$null=Invoke-FixtureGit $indexCase @('config','user.name','Fixture')
 Copy-Item -LiteralPath (Join-Path $root '.gitignore') -Destination (Join-Path $indexCase '.gitignore')
 $null=New-Item -ItemType Directory -Path (Join-Path $indexCase 'projects')
 Write-Utf8NoBom (Join-Path $indexCase 'projects/.gitkeep') '';Write-Utf8NoBom (Join-Path $indexCase 'Türkçe spaced name.txt') 'safe text'
 $null=Invoke-FixtureGit $indexCase @('add','--','projects/.gitkeep','Türkçe spaced name.txt')
 $scan=Test-ZimaIndex $indexCase;Assert ($scan.Errors.Count -eq 0 -and $scan.Checked -eq 2) 'entire index allows exact projects/.gitkeep and Unicode/space filenames'
 Write-Utf8NoBom (Join-Path $indexCase 'Türkçe secret file.txt') ('ghp_'+('B'*30));$null=Invoke-FixtureGit $indexCase @('add','--','Türkçe secret file.txt')
 Write-Utf8NoBom (Join-Path $indexCase 'Türkçe secret file.txt') 'safe worktree differs from index'
 $scan=Test-ZimaIndex $indexCase;Assert (@($scan.Errors|Where-Object{$_ -match 'secret-shaped'}).Count -eq 1) 'indexed Unicode/space secret blob is read despite safe working copy'
 $null=Invoke-FixtureGit $indexCase @('commit','--quiet','-m','synthetic indexed secret regression')
 $diff=Invoke-ZimaGitRaw @('-C',$indexCase,'diff','--cached','--name-only');Assert ($diff.Code -eq 0 -and $diff.Stdout.Length -eq 0) 'unchanged-index secret fixture has no staged diff'
 $scan=Test-ZimaIndex $indexCase;Assert (@($scan.Errors|Where-Object{$_ -match 'secret-shaped'}).Count -eq 1) 'unchanged committed secret remains rejected by entire-index scan'
 $protected=@('.local-state/a.txt','.local-archives/a.txt','.agent-tmp/a.txt','artifacts/a.txt','.jarvis-telegram-mcp/a.txt','.claude/a.txt','.idea/a.txt','.vscode/a.txt','.env.local','.env-shadow','projects/member/a.txt')
 foreach($name in $protected){$p=Get-ZimaSafePath $indexCase $name;$null=New-Item -ItemType Directory -Force -Path ([IO.Path]::GetDirectoryName($p));Write-Utf8NoBom $p 'synthetic protected fixture';$null=Invoke-FixtureGit $indexCase @('add','-f','--',$name)}
 $scan=Test-ZimaIndex $indexCase;Assert (@($scan.Errors|Where-Object{$_ -match 'prohibited local/member'}).Count -eq $protected.Count) 'force-added protected roots and env variants rejected; skeleton exception stays exact'
 $null=Invoke-FixtureGit $indexCase @('commit','--quiet','-m','synthetic protected-root regression')
 $diff=Invoke-ZimaGitRaw @('-C',$indexCase,'diff','--cached','--name-only');$scan=Test-ZimaIndex $indexCase;Assert ($diff.Stdout.Length -eq 0 -and @($scan.Errors|Where-Object{$_ -match 'prohibited local/member'}).Count -eq $protected.Count) 'unchanged tracked protected files remain rejected'
}catch{$script:Failures++;Write-Host ('UNEXPECTED: '+$_.Exception.Message);Write-Host $_.ScriptStackTrace}
finally{
 $summary="Assertions: $script:Count`nFailures: $script:Failures`nFixture: $rel`n";Write-Utf8NoBom (Get-ZimaSafePath $root '.agent-tmp/a1-hardening/test-summary.txt') $summary
 # Cleanup only the canonical GUID task fixture; preserve summary evidence.
 if(Test-Path -LiteralPath $tree){$safe=Get-ZimaSafePath $root $rel;Remove-Item -LiteralPath $safe -Recurse -Force}
}
Write-Host "RESULT: $($script:Count) assertions; $($script:Failures) failures"
if($script:Failures){exit 1};exit 0
