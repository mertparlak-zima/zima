# zima orchestration CLI. Windows PowerShell 5.1 verified; UTF-8 BOM + CRLF.
# Parse literal script arguments ourselves: advanced binding treats -R as an
# abbreviation of -Rest and rejects subsequent CLI flags under Windows PS5.1.
param()
$Command='status';$Rest=@()
if($args.Count){$Command=[string]$args[0];if($args.Count -gt 1){$Rest=@($args[1..($args.Count-1)])}}
Set-StrictMode -Version 3.0
$ErrorActionPreference='Stop'
function Get-ZimaRoot { (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).Path }
function Write-Utf8NoBom {
 param([string]$Path,[AllowEmptyString()][string]$Text)
 if([IO.Path]::GetExtension($Path) -in @('.md','.json','.code-workspace')){$Text=$Text.Replace("`r`n","`n").Replace("`r","`n")}
 [IO.File]::WriteAllText($Path,$Text,(New-Object Text.UTF8Encoding($false)))
}
function ConvertTo-HashtableDeep {
 param([AllowNull()]$Node)
 if($null -eq $Node){return $null}
 if($Node -is [pscustomobject]){$h=New-Object hashtable ([StringComparer]::Ordinal);foreach($p in $Node.PSObject.Properties){$h[$p.Name]=ConvertTo-HashtableDeep $p.Value};return $h}
 if($Node -is [array]){$a=@();foreach($i in $Node){$a+=,(ConvertTo-HashtableDeep $i)};return ,$a};return $Node
}
function Read-ZimaManifest {
 param([string]$Path)
 try{
  $raw=Get-Content -LiteralPath $Path -Raw -Encoding UTF8
  # PS versions differ in JSON leniency. Mask string literals before rejecting
  # comments/trailing commas, so URLs and punctuation inside strings stay valid.
  $syntax=[regex]::Replace($raw,'"(?:\\.|[^"\\])*"','""')
  if($syntax -match '//|/\*|,\s*[}\]]'){throw 'Strict JSON required'}
  return ConvertTo-HashtableDeep ($raw|ConvertFrom-Json)
 }catch{throw "Cannot read valid JSON: $Path"}
}
function Read-ZimaEnv {
 param([string]$ZimaRoot=(Get-ZimaRoot))
 # Windows environment keys are case-insensitive. Never allow a later empty
 # assignment to hide a secret-bearing earlier assignment from the Full scan.
 $map=New-Object hashtable ([StringComparer]::OrdinalIgnoreCase)
 $p=Get-ZimaSafePath $ZimaRoot '.env'
 if(Test-Path -LiteralPath $p){
  foreach($line in Get-Content -LiteralPath $p -Encoding UTF8){
   $t=$line.Trim()
   if(!$t -or $t.StartsWith('#')){continue}
   $i=$t.IndexOf('=')
   if($i -le 0){throw 'Malformed .env line (contents withheld)'}
   $key=$t.Substring(0,$i).Trim()
   if($map.ContainsKey($key)){throw 'Duplicate .env key (contents withheld)'}
   # Only the outbound sender reads these local credentials. Redact them here
   # so CLI configuration maps/diagnostics cannot accidentally expose them.
   # All other keys/values still reach the existing Full credential scan.
   if($key -in @('TELEGRAM_BOT_TOKEN','TELEGRAM_CHAT_ID')){$map[$key]=''}else{$map[$key]=$t.Substring($i+1).Trim().Trim('"')}
  }
 }
 return $map
}
function Assert-ZimaPendingAllowed {
 param([string]$ZimaRoot)
 $marker=Get-ZimaSafePath $ZimaRoot '.local-state/migration/PHASE'
 if(Test-Path -LiteralPath $marker){
  $phase=(Get-Content -LiteralPath $marker -Raw -Encoding UTF8).Trim()
  if($phase -cne 'A1'){throw 'Pending is allowed only for A1 (or a fresh clone without a phase marker)'}
 }
}
function Get-ZimaDeclaredPath {
 param([string]$Root,[string]$Relative,[switch]$AllowRoot)
 # Pure metadata validation: this helper never probes a declared member path.
 if([string]::IsNullOrWhiteSpace($Root) -or [string]::IsNullOrWhiteSpace($Relative)){throw 'Empty path refused'}
 $base=[IO.Path]::GetFullPath($Root).TrimEnd('\','/')
 if([IO.Path]::IsPathRooted($Relative) -or $Relative -match '(^|[\\/])\.\.([\\/]|$)' -or $Relative -match ':'){throw 'Absolute/traversal path refused'}
 $full=[IO.Path]::GetFullPath((Join-Path $base $Relative))
 if($full -eq $base){if(!$AllowRoot){throw 'Root path refused'}}elseif(!$full.StartsWith($base+'\',[StringComparison]::OrdinalIgnoreCase)){throw 'Path escapes root'}
 return $full
}
function Get-ZimaSafePath {
 param([string]$Root,[string]$Relative,[switch]$AllowRoot)
 $full=Get-ZimaDeclaredPath $Root $Relative -AllowRoot:$AllowRoot
 # Active paths fail closed on junctions/symlinks at every existing ancestor.
 $p=$full;while($p){if(Test-Path -LiteralPath $p){$item=Get-Item -LiteralPath $p -Force;if($item.Attributes -band [IO.FileAttributes]::ReparsePoint){throw "Reparse ancestor refused: $p"}};$parent=[IO.Path]::GetDirectoryName($p);if($parent -eq $p){break};$p=$parent};return $full
}
function Test-ZimaRepoDeferred {
 param([hashtable]$Repo)
 return $Repo.ContainsKey('deferred') -and $Repo['deferred'] -is [bool] -and $Repo['deferred']
}
function Assert-ZimaRequestedTargetActive {
 param([AllowNull()]$Manifest,[string]$Command,[string[]]$Rest)
 # Refuse explicit excluded targets before full validation can launch even a
 # metadata-only native command. Unvalidated/malformed shapes fail later normally.
 if($Manifest -isnot [Collections.IDictionary] -or !$Manifest.Contains('repos')){return}
 $target=$null
 if($Command -in @('clone','sync','update')){$a=Get-ZimaArguments $Rest @('-all');if($a.Positionals.Count -eq 1){$target=$a.Positionals[0]}}
 elseif($Command -eq 'issues'){$a=Get-ZimaArguments $Rest @('-r','-repo','-stale','-json') @('-r','-repo','-stale');if($a.Options.ContainsKey('-r')){$target=$a.Options['-r']};if($a.Options.ContainsKey('-repo')){$target=$a.Options['-repo']}}
 if(!$target){return}
 foreach($r in $Manifest['repos']){if($r -is [hashtable] -and $r['name'] -ceq $target -and (Test-ZimaRepoDeferred $r)){throw "$target : DEFERRED; operation refused ($($r['defer_reason']))"}}
}
function Test-ZimaSchema {
 param([AllowNull()]$Value,[hashtable]$Schema,[hashtable]$Document=$Schema,[string]$At='$')
 $errors=New-Object 'System.Collections.Generic.List[string]'
 $known=@('$schema','title','description','definitions','type','required','additionalProperties','properties','items','$ref','oneOf','enum','const','pattern','minLength')
 foreach($key in $Schema.Keys){if($known -notcontains $key){$errors.Add("${At}: unsupported schema keyword '$key'")}}
 if($Schema.ContainsKey('$ref')){$ref=$Schema['$ref'];if($ref -notmatch '^#/definitions/[^/]+$'){$errors.Add("${At}: unsupported schema reference")}else{$name=$ref.Substring(14);if(!$Document['definitions'].ContainsKey($name)){$errors.Add("${At}: missing schema reference")}else{foreach($e in Test-ZimaSchema $Value $Document['definitions'][$name] $Document $At){$errors.Add($e)}}};return $errors.ToArray()}
 if($Schema.ContainsKey('oneOf')){$matches=0;foreach($choice in $Schema['oneOf']){if(@(Test-ZimaSchema $Value $choice $Document $At).Count -eq 0){$matches++}};if($matches -ne 1){$errors.Add("${At}: oneOf requires exactly one matching shape")};return $errors.ToArray()}
 $kind='unknown';if($null -eq $Value){$kind='null'}elseif($Value -is [Collections.IDictionary]){$kind='object'}elseif($Value -is [array]){$kind='array'}elseif($Value -is [string]){$kind='string'}elseif($Value -is [bool]){$kind='boolean'}elseif($Value -is [ValueType]){if($Value -is [int] -or $Value -is [long]){$kind='integer'}else{$kind='number'}}
 if($Schema.ContainsKey('type') -and @($Schema['type']) -notcontains $kind){$errors.Add("${At}: expected type $($Schema['type'] -join '|'), got $kind");return $errors.ToArray()}
 if($Schema.ContainsKey('const') -and (ConvertTo-Json -InputObject $Value -Compress -Depth 40) -cne (ConvertTo-Json -InputObject $Schema['const'] -Compress -Depth 40)){$errors.Add("${At}: const mismatch")}
 if($Schema.ContainsKey('enum')){$found=$false;foreach($x in $Schema['enum']){if((ConvertTo-Json -InputObject $Value -Compress -Depth 40) -ceq (ConvertTo-Json -InputObject $x -Compress -Depth 40)){$found=$true}};if(!$found){$errors.Add("${At}: enum mismatch")}}
 if($kind -eq 'string'){if($Schema.ContainsKey('minLength') -and $Value.Length -lt $Schema['minLength']){$errors.Add("${At}: minLength violated")};if($Schema.ContainsKey('pattern') -and $Value -cnotmatch $Schema['pattern']){$errors.Add("${At}: pattern mismatch")}}
 if($kind -eq 'object'){
  if($Schema.ContainsKey('required')){foreach($key in $Schema['required']){if(!$Value.Contains($key)){$errors.Add("${At}: missing required field '$key'")}}}
  foreach($key in $Value.Keys){if($Schema.ContainsKey('properties') -and $Schema['properties'].ContainsKey($key)){foreach($e in Test-ZimaSchema $Value[$key] $Schema['properties'][$key] $Document ($At+'.'+$key)){$errors.Add($e)}}elseif($Schema.ContainsKey('additionalProperties') -and $Schema['additionalProperties'] -eq $false){$errors.Add("${At}: unknown field '$key'")}}
 }
 if($kind -eq 'array' -and $Schema.ContainsKey('items')){for($i=0;$i -lt $Value.Count;$i++){foreach($e in Test-ZimaSchema $Value[$i] $Schema['items'] $Document ($At+'['+$i+']')){$errors.Add($e)}}};return $errors.ToArray()
}
function Test-ZimaSchemaDefinition {
 param([hashtable]$Schema)
 $known=@('$schema','title','description','definitions','type','required','additionalProperties','properties','items','$ref','oneOf','enum','const','pattern','minLength')
 foreach($key in $Schema.Keys){if($known -notcontains $key){"unsupported schema keyword '$key'"}}
 foreach($group in @('properties','definitions')){if($Schema.ContainsKey($group)){foreach($child in $Schema[$group].Values){Test-ZimaSchemaDefinition $child}}}
 if($Schema.ContainsKey('items')){Test-ZimaSchemaDefinition $Schema['items']}
 if($Schema.ContainsKey('oneOf')){foreach($child in $Schema['oneOf']){Test-ZimaSchemaDefinition $child}}
}
function Resolve-ZimaDefaults {
 param([hashtable]$Manifest)
 $copy=ConvertTo-HashtableDeep ($Manifest|ConvertTo-Json -Depth 40|ConvertFrom-Json)
 foreach($r in $copy['repos']){if(!$r.ContainsKey('owner_type')){$r['owner_type']=$copy['defaults']['owner_type']};if(!$r.ContainsKey('default_branch')){$r['default_branch']=$copy['defaults']['branch']};if(!$r.ContainsKey('runner')){$r['runner']=$null};if(!$r.ContainsKey('deferred')){$r['deferred']=$false};if(!$r.ContainsKey('defer_reason')){$r['defer_reason']=$null}};return $copy
}
function Invoke-ZimaNative {
 param([string]$Tool,[string[]]$Arguments)
 if(!(Get-Command $Tool -ErrorAction SilentlyContinue)){return @{Code=127;Output=@();Diagnostics=@()}}
 $old=$ErrorActionPreference
 try{
  $ErrorActionPreference='Continue'
  $records=@(& $Tool @Arguments 2>&1);$code=$LASTEXITCODE
  $output=@();$diagnostics=@()
  foreach($record in $records){
   if($record -is [Management.Automation.ErrorRecord]){$diagnostics+=[string]$record}
   elseif($null -ne $record -and [string]$record -ne ''){$output+=[string]$record}
  }
 }finally{$ErrorActionPreference=$old}
 return @{Code=$code;Output=$output;Diagnostics=$diagnostics}
}
function Invoke-ZimaManifestValidation {
 param([AllowNull()]$Manifest,[string]$ZimaRoot)
 $errors=@();$warnings=@()
 try{
  $schema=Read-ZimaManifest (Join-Path $ZimaRoot 'repos.schema.json');$errors+=@(Test-ZimaSchemaDefinition $schema);$errors+=@(Test-ZimaSchema $Manifest $schema)
  if($errors.Count){return @{Errors=$errors;Warnings=$warnings}}
  $m=Resolve-ZimaDefaults $Manifest;$errors+=@(Test-ZimaSchema $m $schema)
  if($errors.Count){return @{Errors=$errors;Warnings=$warnings}}
  $seenName=@{};$seenPath=@{};$seenLabel=@{};$seenContainer=@{}
  foreach($r in $m['repos']){
   $n=$r['name'];$p=$r['path'];if($n -match '^(con|prn|aux|nul|com[1-9]|lpt[1-9])$'){$errors+="repo ${n}: reserved Windows name"}
   if($seenName.ContainsKey($n)){$errors+="duplicate repo name: $n"};$seenName[$n]=1
   if($seenPath.ContainsKey($p)){$errors+="duplicate path: $p"};$seenPath[$p]=1
   if($p -cne "projects/$n"){$errors+="repo ${n}: path basename must equal name"}
   if((Test-ZimaRepoDeferred $r) -and [string]::IsNullOrWhiteSpace($r['defer_reason'])){$errors+="repo ${n}: deferred requires a nonempty defer_reason"}
   try{if(Test-ZimaRepoDeferred $r){$null=Get-ZimaDeclaredPath $ZimaRoot $p}else{$null=Get-ZimaSafePath $ZimaRoot $p}}catch{$errors+="repo ${n}: unsafe path ($($_.Exception.Message))"}
   $branch=Invoke-ZimaNative git @('check-ref-format','--branch',$r['default_branch']);if($branch.Code -ne 0 -or $r['default_branch'].StartsWith('-')){$errors+="repo ${n}: invalid default_branch"}
   $run=$r['runner'];if($null -eq $run){$errors+="repo ${n}: runner required (local self-hosted Docker runner mandatory)"}
   if(@($r['ci_workflows']).Count -eq 0){$errors+="repo ${n}: ci_workflows must not be empty (local Docker CI mandatory)"}
   if(@($r['quirks']) -contains 'no-ci-by-design'){$errors+="repo ${n}: no-ci-by-design quirk is forbidden"}
   if($null -ne $run){foreach($pair in @(@('label',$seenLabel),@('container',$seenContainer))){$field=$pair[0];$seen=$pair[1];$v=$run[$field];if($seen.ContainsKey($v)){$errors+="duplicate runner ${field}: $v"};$seen[$v]=1};if($run['compose'] -and ![IO.Path]::IsPathRooted($run['compose'])){try{if(Test-ZimaRepoDeferred $r){$null=Get-ZimaDeclaredPath (Join-Path $ZimaRoot $p) $run['compose']}else{$null=Get-ZimaSafePath (Join-Path $ZimaRoot $p) $run['compose']}}catch{$errors+="repo ${n}: unsafe runner compose path"}}}
   $paths=@($r['docs']['readme'],$r['docs']['agents'],$r['docs']['skills'])+@($r['docs']['key'])+@($r['skills_locations'])
   foreach($rel in $paths){if($null -ne $rel){try{if(Test-ZimaRepoDeferred $r){$null=Get-ZimaDeclaredPath (Join-Path $ZimaRoot $p) $rel}else{$null=Get-ZimaSafePath (Join-Path $ZimaRoot $p) $rel}}catch{$errors+="repo ${n}: unsafe doc/skill path"}}}
  }
  foreach($t in $m['third_party']){
   $n=$t['name'];if($seenName.ContainsKey($n)){$errors+="third_party ${n}: duplicate name"};$seenName[$n]=1
   try{$tp=[string]$t['path'];if($tp -notmatch '^[A-Za-z]:[\\/]'){throw 'absolute Windows path required'};$full=[IO.Path]::GetFullPath($tp).TrimEnd('\','/');$base=[IO.Path]::GetFullPath($ZimaRoot).TrimEnd('\','/');if($full -eq $base -or $full.StartsWith($base+'\',[StringComparison]::OrdinalIgnoreCase)){throw 'must be OUTSIDE the zima tree'};$null=Get-ZimaSafePath ([IO.Path]::GetPathRoot($full)) $full.Substring(3) -AllowRoot;if($seenPath.ContainsKey($full)){throw 'duplicate path'};$seenPath[$full]=1}catch{$errors+="third_party ${n}: $($_.Exception.Message)"}
  }
 }catch{$errors+='manifest validation could not complete: '+$_.Exception.Message}
 return @{Errors=@($errors);Warnings=@($warnings)}
}
function Get-ZimaRepoState {
 param([hashtable]$Repo,[string]$ZimaRoot)
 $s=[ordered]@{name=$Repo['name'];dir=$Repo['path'];deferred=$false;defer_reason=$null;inspected=$false;present=$false;isGit=$false;originOk=$false;branch='';expectedBranch=$Repo['default_branch'];detached=$false;staged=0;unstaged=0;untracked=0;conflicts=0;stashes=0;ahead=$null;behind=$null;upstream=$null;error=$null}
 try{
  if(Test-ZimaRepoDeferred $Repo){$s.deferred=$true;$s.defer_reason=$Repo['defer_reason'];$s.present=$null;$s.isGit=$null;$s.originOk=$null;$s.branch=$null;$s.detached=$null;foreach($key in @('staged','unstaged','untracked','conflicts','stashes')){$s[$key]=$null};return $s}
  $s.inspected=$true;$dir=Get-ZimaSafePath $ZimaRoot $Repo['path'];if(!(Test-Path -LiteralPath $dir -PathType Container)){return $s};$s.present=$true
  $null=Get-ZimaSafePath $dir '.git';$g=Invoke-ZimaNative git @('-C',$dir,'rev-parse','--show-toplevel');if($g.Code -ne 0){return $s};if([IO.Path]::GetFullPath(($g.Output -join '').Replace('/','\')).TrimEnd('\') -ine $dir.TrimEnd('\')){return $s};$s.isGit=$true
  $g=Invoke-ZimaNative git @('-C',$dir,'remote','get-url','origin');$s.originOk=($g.Code -eq 0 -and ($g.Output -join '') -ceq $Repo['github'])
  $g=Invoke-ZimaNative git @('-C',$dir,'symbolic-ref','--quiet','--short','HEAD');if($g.Code -eq 0){$s.branch=$g.Output -join ''}else{$s.detached=$true;$s.branch='(detached)'}
  $g=Invoke-ZimaNative git @('--no-optional-locks','-C',$dir,'status','--porcelain=v1','--untracked-files=all');if($g.Code -ne 0){throw 'git status failed'}
  foreach($line in $g.Output){if($line.StartsWith('??')){$s.untracked++;continue};if($line.Length -lt 2){continue};if($line[0] -ne ' '){$s.staged++};if($line[1] -ne ' '){$s.unstaged++};if($line.Substring(0,2) -in @('DD','AU','UD','UA','DU','AA','UU')){$s.conflicts++}}
  $g=Invoke-ZimaNative git @('-C',$dir,'stash','list');if($g.Code -ne 0){throw 'git stash list failed'};$s.stashes=$g.Output.Count
  $g=Invoke-ZimaNative git @('-C',$dir,'rev-parse','--abbrev-ref','--symbolic-full-name','@{upstream}')
  if($g.Code -eq 0){$s.upstream=$g.Output -join '';$g=Invoke-ZimaNative git @('-C',$dir,'rev-list','--left-right','--count','@{upstream}...HEAD');if($g.Code -ne 0){throw 'git ahead/behind failed'};if(($g.Output -join '') -match '^\s*(\d+)\s+(\d+)'){$s.behind=[int]$Matches[1];$s.ahead=[int]$Matches[2]}}
 }catch{$s.error=$_.Exception.Message};return $s
}
function Test-RequiredLines {
 param([string]$Path,[string[]]$Required)
 if(!(Test-Path -LiteralPath $Path)){return "missing file: $Path"};$lines=@(Get-Content -LiteralPath $Path -Encoding UTF8|ForEach-Object{$_.TrimEnd()})
 foreach($l in $Required){if($lines -cnotcontains $l){"required exact line absent in $Path : $l"}}
}
$script:D19Exceptions=@('.git','.agent-tmp','.local-state','.local-archives','artifacts','.jarvis-telegram-mcp','projects','.idea','.claude','.vscode','node_modules')
function Test-FolderReadmes {
 param([string]$ZimaRoot)
 $queue=New-Object 'Collections.Generic.Queue[string]';$queue.Enqueue($ZimaRoot)
 while($queue.Count){$parent=$queue.Dequeue();foreach($dir in Get-ChildItem -LiteralPath $parent -Directory -Force){$rel=$dir.FullName.Substring($ZimaRoot.Length).TrimStart('\','/');$parts=$rel -split '[\\/]';if($script:D19Exceptions -contains $parts[0] -or $dir.Name -eq 'node_modules'){continue};if($dir.Attributes -band [IO.FileAttributes]::ReparsePoint){"$rel (reparse refused)";continue};$skillRoot=$parts.Count -eq 3 -and $parts[0] -eq '.agents' -and $parts[1] -eq 'skills' -and (Test-Path -LiteralPath (Join-Path $dir.FullName 'SKILL.md'));if(!$skillRoot -and !(Test-Path -LiteralPath (Join-Path $dir.FullName 'README.md'))){$rel};$queue.Enqueue($dir.FullName)}}
}
function ConvertTo-ZimaCell {param([AllowNull()]$Value);return ([string]$Value).Replace('|','\|').Replace("`r",' ').Replace("`n",' ')}
function Get-ZimaGenerated {
 param([hashtable]$Manifest,[string]$ZimaRoot)
 $lines=@('# repos.md - workspace index (GENERATED - do not edit by hand)','','Generated by `zima gen` from `repos.json`. Cards live in `repos/<name>.md`.','','| Repo | State | Product | Dir | Stack | CI / Runner | Card |','|---|---|---|---|---|---|---|')
 foreach($r in $Manifest['repos']){$ci='none';if($null -ne $r['runner']){$ci=($r['ci_workflows'] -join ', ')+' / '+$r['runner']['container']};$membership='active';if(Test-ZimaRepoDeferred $r){$membership='DEFERRED: '+$r['defer_reason']};$cells=@($r['name'],$membership,$r['product'],$r['path'],$r['stack'],$ci,"[card]($($r['name']).md)")|ForEach-Object{ConvertTo-ZimaCell $_};$lines+=('| '+($cells -join ' | ')+' |')}
 $reg=@('| Repo | State | Container | Label today | Label target | Lifecycle | Compose |','|---|---|---|---|---|---|---|')
 foreach($r in $Manifest['repos']){if($null -eq $r['runner']){continue};$run=$r['runner'];$today=$run['label'];$target=$run['label'];if($run['label_status'] -eq 'pending-migration'){$today='(shared pool - no repo label yet)'};if($run['label_status'] -eq 'rename-pending-target-call-tracker'){$target='call-tracker'};$membership='active';if(Test-ZimaRepoDeferred $r){$membership='DEFERRED'};$cells=@($r['name'],$membership,$run['container'],$today,$target,$run['lifecycle'],$run['compose'])|ForEach-Object{ConvertTo-ZimaCell $_};$reg+=('| '+($cells -join ' | ')+' |')}
 $p=Get-ZimaSafePath $ZimaRoot 'docs/runners.md';$content=Get-Content -LiteralPath $p -Raw -Encoding UTF8;$pattern='(?s)<!-- BEGIN GENERATED RUNNER REGISTRY -->.*?<!-- END GENERATED RUNNER REGISTRY -->'
 if([regex]::Matches($content,$pattern).Count -ne 1){throw 'Exactly one generated runner registry block required'}
 $block="<!-- BEGIN GENERATED RUNNER REGISTRY -->`n"+($reg -join "`n")+"`n<!-- END GENERATED RUNNER REGISTRY -->";$content=[regex]::Replace($content,$pattern,[Text.RegularExpressions.MatchEvaluator]{param($match) $block}).Replace("`r`n","`n").Replace("`r","`n")
 $folders=@([ordered]@{name='zima';path='.'});foreach($r in $Manifest['repos']){if(!(Test-ZimaRepoDeferred $r)){$folders+=([ordered]@{name=$r['name'];path=$r['path']})}}
 $ws=[ordered]@{folders=$folders;settings=[ordered]@{'search.exclude'=[ordered]@{'**/node_modules'=$true;'**/build'=$true;'**/.gradle'=$true}}}
 $workspaceJson=($ws|ConvertTo-Json -Depth 8).Replace("`r`n","`n").Replace("`r","`n")+"`n"
 return [ordered]@{'repos/repos.md'=($lines -join "`n")+"`n";'docs/runners.md'=$content;'zima.code-workspace'=$workspaceJson}
}
function Invoke-ZimaGen {
 param([hashtable]$Manifest,[string]$ZimaRoot)
 $generated=Get-ZimaGenerated $Manifest $ZimaRoot;foreach($p in $generated.Keys){$null=Get-ZimaSafePath $ZimaRoot $p};foreach($p in $generated.Keys){Write-Utf8NoBom (Get-ZimaSafePath $ZimaRoot $p) $generated[$p]}
}
function Test-ZimaSecretText {
 param([AllowEmptyString()][string]$Text)
 return $Text -match '(?i)(\b\d{6,}:[A-Za-z0-9_-]{30,}|\bghp_[A-Za-z0-9]{20,}|\bgithub_pat_[A-Za-z0-9_]{20,}|-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----)'
}
function ConvertTo-ZimaWindowsArgument {
 param([AllowEmptyString()][string]$Argument)
 # CommandLineToArgvW-compatible quoting. Never route these arguments through a
 # shell: Git filenames may contain spaces, quotes, Unicode or metacharacters.
 $escaped=[regex]::Replace($Argument,'(\\*)"','$1$1\"')
 $escaped=[regex]::Replace($escaped,'(\\+)$','$1$1')
 return '"'+$escaped+'"'
}
function Invoke-ZimaGitRaw {
 param([string[]]$Arguments)
 # PowerShell's native line pipeline cannot preserve NUL-delimited filenames.
 # Read UTF-8 stdout separately from stderr, concurrently, without line splitting.
 $git=Get-Command git.exe -ErrorAction Stop
 $start=New-Object Diagnostics.ProcessStartInfo
 $start.FileName=$git.Source
 $start.Arguments=($Arguments|ForEach-Object{ConvertTo-ZimaWindowsArgument $_}) -join ' '
 $start.UseShellExecute=$false
 $start.CreateNoWindow=$true
 $start.RedirectStandardOutput=$true
 $start.RedirectStandardError=$true
 $start.StandardOutputEncoding=New-Object Text.UTF8Encoding($false)
 $start.StandardErrorEncoding=New-Object Text.UTF8Encoding($false)
 $process=New-Object Diagnostics.Process
 $process.StartInfo=$start
 try{
  $null=$process.Start()
  $stdout=$process.StandardOutput.ReadToEndAsync()
  $stderr=$process.StandardError.ReadToEndAsync()
  $process.WaitForExit()
  return @{Code=$process.ExitCode;Stdout=$stdout.GetAwaiter().GetResult();Diagnostics=$stderr.GetAwaiter().GetResult()}
 }finally{$process.Dispose()}
}
function Test-ZimaIndex {
 param([string]$ZimaRoot)
 $errors=New-Object 'Collections.Generic.List[string]'
 $checked=0
 try{
  $null=Get-ZimaSafePath $ZimaRoot '.git'
  $gitRoot=Invoke-ZimaGitRaw @('-C',$ZimaRoot,'rev-parse','--show-toplevel')
  if($gitRoot.Code -ne 0 -or [IO.Path]::GetFullPath($gitRoot.Stdout.TrimEnd("`r","`n")) -ine [IO.Path]::GetFullPath($ZimaRoot)){
   throw 'Workspace is not the verified Git root'
  }
  $index=Invoke-ZimaGitRaw @('-C',$ZimaRoot,'ls-files','--stage','-z')
  if($index.Code -ne 0){throw 'Cannot enumerate entire Git index'}
  foreach($record in $index.Stdout.Split([char]0)){
   if($record.Length -eq 0){continue}
   if($record -cnotmatch '^([0-7]{6}) ([0-9a-f]{40,64}) ([0-3])\t([\s\S]+)$'){
    $errors.Add('index scan: malformed index record (contents withheld)')
    continue
   }
   $mode=$Matches[1];$oid=$Matches[2];$stage=$Matches[3];$name=$Matches[4]
   # Exact public paths only. Member content, machine configuration, durable
   # local state, evidence and all other harness/IDE files stay uncommittable.
   $publicPath=$name -cin @('projects/.gitkeep','.vscode/settings.json','.vscode/README.md')
   $protected=$name -match '^(?:projects(?:/|$)|\.env|(?:\.local-state|\.local-archives|\.agent-tmp|artifacts|\.jarvis-telegram-mcp|\.claude|\.idea|\.vscode)(?:/|$))'
   if($protected -and !$publicPath){$errors.Add('index scan: prohibited local/member path (contents withheld)');continue}
   if($stage -ne '0'){$errors.Add('index scan: unresolved index stages (contents withheld)');continue}
   if($mode -notin @('100644','100755')){$errors.Add('index scan: non-regular entry (contents withheld)');continue}
   # Scan indexed objects rather than worktree files, including unchanged tracked
   # files and staged content that differs from its working copy.
   $blob=Invoke-ZimaGitRaw @('-C',$ZimaRoot,'cat-file','blob',$oid)
   if($blob.Code -ne 0){$errors.Add('index scan: cannot read indexed blob');continue}
   $checked++
   if(Test-ZimaSecretText $blob.Stdout){$errors.Add('index scan: secret-shaped value (contents withheld)')}
  }
 }catch{$errors.Add('index scan could not complete (details withheld)')}
 return @{Errors=@($errors.ToArray());Checked=$checked}
}
function Resolve-ZimaRgTool {
 $cmd=Get-Command rg -ErrorAction SilentlyContinue
 if($cmd){return $cmd.Source}
 foreach($pattern in @((Join-Path $env:USERPROFILE '.codex\packages\standalone\releases\*\codex-path\rg.exe'),(Join-Path $env:USERPROFILE '.vscode\extensions\*\bin\windows-x86_64\rg.exe'),(Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\resources\app\node_modules.asar.unpacked\@vscode\ripgrep\bin\rg.exe'),(Join-Path $env:ProgramFiles 'Microsoft VS Code\resources\app\node_modules.asar.unpacked\@vscode\ripgrep\bin\rg.exe'))){$found=@(Get-Item -Path $pattern -Force -ErrorAction SilentlyContinue|Sort-Object FullName -Descending);if($found.Count){return $found[0].FullName}}
 return $null
}
function Test-ZimaRgProbe {
 param([string]$ZimaRoot)
 $rgTool=Resolve-ZimaRgTool;if(!$rgTool){throw 'rg missing: search boundary probe cannot run'}
 $rel='.agent-tmp/a1-hardening/rg-'+[guid]::NewGuid().ToString('N');$tree=Get-ZimaSafePath $ZimaRoot $rel
 try{
  $null=New-Item -ItemType Directory -Path $tree -Force;foreach($file in @('.gitignore','.ignore')){Copy-Item -LiteralPath (Get-ZimaSafePath $ZimaRoot $file) -Destination (Join-Path $tree $file)}
  $g=Invoke-ZimaNative git @('-C',$tree,'init','--quiet');if($g.Code -ne 0){throw 'probe git init failed'}
  $files=@('projects/probe/src/visible.txt','projects/probe/.git/hidden.txt','projects/worktree/.git','projects/probe/node_modules/hidden.txt','projects/probe/private/hidden.txt','projects/probe/build/hidden.txt','projects/probe/.env','projects/probe/.env.local','projects/probe/.gradle/hidden.txt','projects/probe/dist/hidden.txt','projects/probe/artifacts/hidden.txt','projects/probe/.planning/hidden.txt','projects/probe/signing.jks','projects/probe/data.db','projects/str-fixer/input/hidden.txt','projects/str-fixer/film.srt','.env','.agent-tmp/hidden.txt')
  foreach($f in $files){$p=Get-ZimaSafePath $tree $f;$null=New-Item -ItemType Directory -Force -Path ([IO.Path]::GetDirectoryName($p));Write-Utf8NoBom $p 'zima-probe'}
  Push-Location -LiteralPath $tree;try{$rg=Invoke-ZimaNative $rgTool @('--files','--hidden','.')}finally{Pop-Location}
  if($rg.Code -ne 0){throw 'rg search failed'};$visible=@($rg.Output|ForEach-Object{($_ -replace '\\','/') -replace '^\./',''});if($visible -notcontains $files[0]){throw 'rg hides member source'}
  foreach($f in $files[1..($files.Count-1)]){if($visible -contains $f){throw "rg exposes excluded probe path: $f"}}
 }finally{if(Test-Path -LiteralPath $tree){$checked=Get-ZimaSafePath $ZimaRoot $rel;Remove-Item -LiteralPath $checked -Recurse -Force}}
}
function Invoke-ZimaVerify {
 param([string]$Mode='fast',[string]$ZimaRoot,[switch]$Pending)
 if($Mode -eq 'pending'){$Pending=$true;$Mode='fast'};$errors=@();$warnings=@();$checks=New-Object 'Collections.Generic.List[string]';$info=New-Object 'Collections.Generic.List[string]'
 if($Pending){try{Assert-ZimaPendingAllowed $ZimaRoot}catch{return @{Errors=@($_.Exception.Message);Warnings=@();Checks=$checks}}}
 try{$m=Read-ZimaManifest (Join-Path $ZimaRoot 'repos.json');$v=Invoke-ZimaManifestValidation $m $ZimaRoot;$errors+=@($v.Errors);if($errors.Count){return @{Errors=$errors;Warnings=$warnings;Checks=$checks}};$m=Resolve-ZimaDefaults $m;$checks.Add('manifest: schema + semantics + safe paths')}catch{return @{Errors=@($_.Exception.Message);Warnings=@();Checks=$checks}}
 $gitLines=@('projects/*','!projects/.gitkeep','projects/.shared/','.local-state/','.local-archives/','artifacts/','.agent-tmp/','.jarvis-telegram-mcp/','.env','.env.*','.idea/','.claude/','.vscode/*','!.vscode/settings.json','!.vscode/README.md')
 $ignoreLines=@('!projects/','!projects/**','projects/**/.git/','projects/**/.git','projects/**/node_modules/','projects/**/private/','projects/**/.env','projects/**/.env.*','projects/**/build/','projects/**/.gradle/','projects/**/dist/','projects/**/.agent-tmp/','projects/**/artifacts/','projects/**/.idea/','projects/**/.opencode/node_modules/','projects/**/.agents/node_modules/','projects/**/.planning/','projects/**/*.jks','projects/**/*.db','projects/str-fixer/input/','projects/str-fixer/**/*.srt')
 foreach($pair in @(@('.gitignore',$gitLines),@('.ignore',$ignoreLines),@('.gitattributes',@('*.md text eol=lf','*.json text eol=lf','*.ps1 text eol=crlf')))){$e=@(Test-RequiredLines (Join-Path $ZimaRoot $pair[0]) $pair[1]);if($e.Count){$errors+=$e}else{$checks.Add($pair[0]+': required exact lines')}}
 # Required lines alone cannot detect a later negation that exposes local data.
 $activeGit=@(Get-Content -LiteralPath (Join-Path $ZimaRoot '.gitignore') -Encoding UTF8|Where-Object{$_.Trim() -and !$_.TrimStart().StartsWith('#')}|ForEach-Object{$_.TrimEnd()})
 if(($activeGit -join "`n") -cne ($gitLines -join "`n")){$errors+='.gitignore: active rules differ from the exact ordered safety set'}
 $extraNegations=@(Get-Content -LiteralPath (Join-Path $ZimaRoot '.ignore') -Encoding UTF8|Where-Object{$_.TrimStart().StartsWith('!') -and $_ -cnotin @('!projects/','!projects/**')})
 if($extraNegations.Count){$errors+='.ignore: unexpected whitelist negation can expose protected data'}
 $agents=Join-Path $ZimaRoot 'AGENTS.md';if(!(Test-Path -LiteralPath $agents)){$errors+='AGENTS.md missing'}elseif(@(Get-Content -LiteralPath $agents -Encoding UTF8).Count -gt 150){$errors+='AGENTS.md exceeds 150 lines'}else{$checks.Add('AGENTS.md: within 150 lines')}
 foreach($rel in @('.agents/skills/zima-leader/SKILL.md','.agents/skills/zima-sync/SKILL.md','.agents/skills/zima-new-repo/SKILL.md','.agents/skills/zima-leader/references/preamble.md','.agents/skills/zima-leader/references/workspace-context.md','docs/templates/PR.md','docs/templates/issue.md','docs/templates/comments.md','docs/templates/folder-README.md')){if(!(Test-Path -LiteralPath (Join-Path $ZimaRoot $rel))){$errors+="required file missing: $rel"}}
 $missing=@(Test-FolderReadmes $ZimaRoot);if($missing.Count){$errors+='folders without README.md (D19): '+($missing -join ', ')}else{$checks.Add('folder READMEs (D19): pruned traversal')}
 try{$generated=Get-ZimaGenerated $m $ZimaRoot;foreach($p in $generated.Keys){$path=Get-ZimaSafePath $ZimaRoot $p;if(!(Test-Path -LiteralPath $path) -or [IO.File]::ReadAllText($path) -cne $generated[$p]){$errors+="generated artifact drift: $p"}else{$checks.Add("generated: $p")}}}catch{$errors+='generated check: '+$_.Exception.Message}
 foreach($r in $m['repos']){
  $card=Get-ZimaSafePath $ZimaRoot ('repos/'+$r['name']+'.md');if(!(Test-Path -LiteralPath $card)){$errors+="repo $($r['name']): card missing";continue};$text=Get-Content -LiteralPath $card -Raw -Encoding UTF8
  if($text -notmatch '\]\(\.\./AGENTS\.md\)'){$errors+="repo $($r['name']): card must link ../AGENTS.md"}
  if(Test-ZimaRepoDeferred $r){if($text -notmatch '(?i)DEFERRED'){$errors+="repo $($r['name']): card must declare DEFERRED"};$info.Add("DEFERRED $($r['name']): $($r['defer_reason']); source/Git/docs/preamble not inspected");continue}
  $links=@($r['docs']['readme'],$r['docs']['agents'],$r['docs']['skills'])+@($r['docs']['key']);foreach($doc in $links){if($null -eq $doc){continue};$expected='../'+$r['path']+'/'+$doc;if(!$text.Contains(']('+$expected+')')){$errors+="repo $($r['name']): card missing doc link $doc"}}
  $st=Get-ZimaRepoState $r $ZimaRoot;if(!$st.present -and $Pending){$info.Add("A1 deferred member checks: $($r['name']) (Pending; not cutover acceptance)");continue}
  if(!$st.present -or !$st.isGit -or !$st.originOk -or $st.error){$errors+="repo $($r['name']): missing, unsafe, non-root, origin mismatch or git failure";continue}
  if($st.branch -ne $st.expectedBranch){$info.Add("observed branch $($r['name']): $($st.branch) (default required only for update)")}
  foreach($doc in $links){if($null -eq $doc){continue};$p=Get-ZimaSafePath (Join-Path $ZimaRoot $r['path']) $doc;if(!(Test-Path -LiteralPath $p)){$errors+="repo $($r['name']): missing doc target $doc"}}
  $repoRoot=Get-ZimaSafePath $ZimaRoot $r['path'];$wfDir=Get-ZimaSafePath $repoRoot '.github/workflows'
  if((@($r['quirks']) -contains 'inherited-github-hosted-ci-awaiting-audit') -and !(Test-Path -LiteralPath (Join-Path $wfDir 'ci.yml'))){$info.Add("pending local runner workflow migration: $($r['name'])")}
  elseif(!($Pending -and !(Test-Path -LiteralPath $wfDir))){
   if($null -ne $r['runner'] -and ![IO.Path]::IsPathRooted($r['runner']['compose'])){$compPath=Get-ZimaSafePath $repoRoot $r['runner']['compose'];if(!(Test-Path -LiteralPath $compPath)){$errors+="repo $($r['name']): missing runner compose $($r['runner']['compose'])"}}
   if(!(Test-Path -LiteralPath $wfDir -PathType Container)){$errors+="repo $($r['name']): missing .github/workflows directory"}else{
    foreach($wf in $r['ci_workflows']){$wfPath=Get-ZimaSafePath $wfDir $wf;if(!(Test-Path -LiteralPath $wfPath -PathType Leaf)){$errors+="repo $($r['name']): missing declared workflow $wf";continue};$roLines=@(Get-Content -LiteralPath $wfPath -Encoding UTF8|Where-Object{$_ -notmatch '^\s*#' -and $_ -match '^\s*runs-on\s*:'});if($roLines.Count -eq 0){$errors+="repo $($r['name']): workflow $wf has no runs-on declaration"};foreach($ro in $roLines){if($ro -match '(?i)\b(ubuntu|windows|macos)-(latest|\d[\w.-]*)' -or $ro -notmatch '(?i)\bself-hosted\b' -or $ro -notmatch '(?i)\bdocker\b'){$errors+="repo $($r['name']): workflow $wf must use self-hosted docker runner (GitHub-hosted runs-on forbidden)";break}}}
    foreach($f in Get-ChildItem -LiteralPath $wfDir -File -Force|Where-Object{$_.Name -match '\.ya?ml$'}){if(@($r['ci_workflows']) -cnotcontains $f.Name){$errors+="repo $($r['name']): undeclared workflow file $($f.Name)"}}
   }
  }
  if($Mode -eq 'full'){$agentRel=$r['docs']['agents'];if(!$agentRel){$errors+="repo $($r['name']): AGENTS.md/preamble mandatory in Full";continue};$p=Get-ZimaSafePath (Join-Path $ZimaRoot $r['path']) $agentRel;$reference=(Get-Content -LiteralPath (Join-Path $ZimaRoot '.agents/skills/zima-leader/references/workspace-context.md') -Raw -Encoding UTF8).Replace('<this-repo>',$r['name']);if(!(Test-Path -LiteralPath $p) -or !(Get-Content -LiteralPath $p -Raw -Encoding UTF8).Replace("`r`n","`n").Contains($reference.Replace("`r`n","`n").Trim())){$errors+="repo $($r['name']): exact workspace preamble missing"}}
 }
 $projectDir=Get-ZimaSafePath $ZimaRoot 'projects';$known=@($m['repos']|ForEach-Object{$_['name']})
 if(Test-Path -LiteralPath $projectDir){foreach($dir in Get-ChildItem -LiteralPath $projectDir -Directory -Force){if($dir.Name -ne '.shared' -and $known -notcontains $dir.Name){$warnings+='unregistered directory under projects/: '+$dir.Name}}}
 if($Mode -eq 'full'){
  try{$null=Test-ZimaRgProbe $ZimaRoot;$checks.Add('rg: real synthetic search boundary probe')}catch{$errors+='rg probe: '+$_.Exception.Message}
  try{$envMap=Read-ZimaEnv $ZimaRoot;foreach($key in $envMap.Keys){if(($key -match '(?i)(TOKEN|SECRET|PASSWORD|API_KEY|CHAT_ID)' -and $envMap[$key]) -or (Test-ZimaSecretText $envMap[$key])){$errors+='.env: secret or disallowed credential key (contents withheld)';break}};$checks.Add('.env: parsed/scanned (contents withheld)')}catch{$errors+=$_.Exception.Message}
  $index=Test-ZimaIndex $ZimaRoot
  if($index.Errors.Count){$errors+=@($index.Errors)}else{$checks.Add("entire index: $($index.Checked) blobs, secret and boundary scan")}
  $info.Add('Full certifies automated structure only; external harness policy/session and live runner/device gates remain separately required')
 };return @{Errors=@($errors);Warnings=@($warnings);Checks=$checks;Info=@($info.ToArray())}
}
function Invoke-ZimaLock {
 param([string]$ZimaRoot,[string]$Action,[string]$Resource,[string]$Owner)
 if($Action -notin @('list','acquire','release')){throw 'locks action must be list|acquire|release'}
 if($Action -ne 'list' -and ($Resource -cnotmatch '^[a-z0-9][a-z0-9-]{0,63}$' -or $Owner -cnotmatch '^[A-Za-z0-9][A-Za-z0-9_.-]{0,127}$')){throw 'Safe resource and explicit -Owner token required'}
 $dir=Get-ZimaSafePath $ZimaRoot 'projects/.shared/locks'
 if($Action -eq 'list'){$rows=@();if(Test-Path -LiteralPath $dir){foreach($f in Get-ChildItem -LiteralPath $dir -Filter '*.lock' -File){$null=Get-ZimaSafePath $ZimaRoot ('projects/.shared/locks/'+$f.Name);try{$obj=Read-ZimaManifest $f.FullName;$rows+=@{resource=$f.BaseName;owner=$obj['owner'];created=$obj['created'];pid=$obj['pid']}}catch{throw 'Malformed lock requires human inspection (contents withheld)'}}};return $rows}
 $null=New-Item -ItemType Directory -Force -Path $dir;$file=Get-ZimaSafePath $ZimaRoot ('projects/.shared/locks/'+$Resource+'.lock')
 $hash=[BitConverter]::ToString([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($file.ToLowerInvariant()))).Replace('-','');$mutex=New-Object Threading.Mutex($false,('Local\zima-lock-'+$hash));$held=$false
 try{try{$held=$mutex.WaitOne(10000)}catch [Threading.AbandonedMutexException]{$held=$true};if(!$held){throw 'Lock contention timed out'}
  if($Action -eq 'acquire'){try{$stream=New-Object IO.FileStream($file,[IO.FileMode]::CreateNew,[IO.FileAccess]::Write,[IO.FileShare]::None)}catch{throw 'Resource locked/unavailable; stale breaking requires a human decision'};try{$data=[Text.Encoding]::UTF8.GetBytes(([ordered]@{owner=$Owner;created=[DateTime]::UtcNow.ToString('o');pid=$PID}|ConvertTo-Json -Compress));$stream.Write($data,0,$data.Length);$stream.Flush()}finally{$stream.Dispose()}}
  else{if(!(Test-Path -LiteralPath $file)){throw 'Lock not held'};$data=Read-ZimaManifest $file;if($data['owner'] -cne $Owner){throw 'Lock ownership mismatch; release refused'};Remove-Item -LiteralPath $file -Force}
 }finally{if($held){$mutex.ReleaseMutex()};$mutex.Dispose()}
}
function Get-ZimaArguments {
 param([string[]]$Arguments,[string[]]$Allowed,[string[]]$ValueOptions=@())
 $options=@{};$positionals=@();for($i=0;$i -lt $Arguments.Count;$i++){$a=$Arguments[$i];if($a.StartsWith('-')){$key=($a -replace '^--','-').ToLowerInvariant();if($Allowed -notcontains $key){throw "Unknown option: $a"};if($options.ContainsKey($key)){throw "Duplicate option: $a"};if($ValueOptions -contains $key){$i++;if($i -ge $Arguments.Count){throw "Missing value: $a"};$options[$key]=$Arguments[$i]}else{$options[$key]=$true}}else{$positionals+=,$a}};return @{Options=$options;Positionals=$positionals}
}
function Get-ZimaTargets {
 param([hashtable]$Manifest,[string[]]$Names,[switch]$All)
 if($All -and $Names.Count){throw 'Choose -All or one repo name'};if(!$All -and $Names.Count -ne 1){throw 'Exactly one repo name (or -All) required'};if($All){return ,@($Manifest['repos']|Where-Object{!(Test-ZimaRepoDeferred $_)})};$r=@($Manifest['repos']|Where-Object{$_['name'] -ceq $Names[0]});if($r.Count -ne 1){throw 'Unknown repo target'};if(Test-ZimaRepoDeferred $r[0]){throw ($r[0]['name']+': DEFERRED; operation refused ('+$r[0]['defer_reason']+')')};return ,$r
}
function Add-ZimaRepo {
 param([hashtable]$Manifest,[hashtable]$Options,[string]$ZimaRoot)
 foreach($k in @('-name','-github','-product','-stack')){if(!$Options.ContainsKey($k) -or [string]::IsNullOrWhiteSpace($Options[$k])){throw "Required: $k"}}
 $n=$Options['-name'];if($n -cnotmatch '^[a-z0-9][a-z0-9-]*$'){throw 'Invalid repo name'};if(@($Manifest['repos']|Where-Object{$_['name'] -ieq $n}).Count){throw 'Repo already exists'}
 $branch=$Manifest['defaults']['branch'];if($Options.ContainsKey('-branch')){$branch=$Options['-branch']}
 $lifecycle='stop-when-idle';if($Options.ContainsKey('-lifecycle')){$lifecycle=$Options['-lifecycle']}
 $candidate=ConvertTo-HashtableDeep ($Manifest|ConvertTo-Json -Depth 40|ConvertFrom-Json);$candidate['repos']+=@(@{name=$n;product=$Options['-product'];github=$Options['-github'];path="projects/$n";owner_type='ours';default_branch=$branch;stack=$Options['-stack'];runner=@{label=$n;container="$n-docker-1";lifecycle=$lifecycle;compose='infra/runner/compose.yml';label_status='compliant'};ci_workflows=@('ci.yml');docs=@{readme='README.md';agents=$null;skills=$null;key=@()};skills_locations=@();local_state='clean';state_note=$null;quirks=@()})
 $v=Invoke-ZimaManifestValidation $candidate $ZimaRoot;if($v.Errors.Count){throw ('New repo validation failed: '+($v.Errors -join '; '))}
 $card=Get-ZimaSafePath $ZimaRoot "repos/$n.md";if(Test-Path -LiteralPath $card){throw 'Card exists; refusing overwrite'};$null=Get-ZimaSafePath $ZimaRoot 'repos.json';$generated=Get-ZimaGenerated $candidate $ZimaRoot;foreach($p in $generated.Keys){$null=Get-ZimaSafePath $ZimaRoot $p}
 $text="# $n - $(ConvertTo-ZimaCell $Options['-product'])`n`n[Workspace rules](../AGENTS.md) | [Index](repos.md)`n`n## Identity`n`n- Path: ``projects/$n```n- GitHub: $($Options['-github'])`n- Stack: $(ConvertTo-ZimaCell $Options['-stack'])`n- Default branch: ``$branch```n- Local state: clean`n`n## Entry documents`n`n- [README](../projects/$n/README.md)`n`n## CI and runner`n`nWorkflow: ``ci.yml``. Runner: ``$n-docker-1``, label ``$n`` (``[self-hosted, linux, x64, docker, $n]``), lifecycle ``$lifecycle``, compose ``infra/runner/compose.yml``. GitHub-hosted runners are forbidden; follow [runner policy](../docs/runners.md) and [onboarding](../.agents/skills/zima-new-repo/SKILL.md).`n`n## Workspace quirks and leader notes`n`nFill before completing onboarding.`n"
 # Validate/render first; restore this finite file set on write failure.
 $writes=[ordered]@{'repos.json'=($candidate|ConvertTo-Json -Depth 40)+"`n";("repos/$n.md")=$text};foreach($p in $generated.Keys){$writes[$p]=$generated[$p]};$old=@{}
 foreach($p in $writes.Keys){$path=Get-ZimaSafePath $ZimaRoot $p;if(Test-Path -LiteralPath $path){$old[$p]=[IO.File]::ReadAllBytes($path)}else{$old[$p]=$null}}
 try{foreach($p in $writes.Keys){Write-Utf8NoBom (Get-ZimaSafePath $ZimaRoot $p) $writes[$p]}}catch{foreach($p in $old.Keys){$path=Get-ZimaSafePath $ZimaRoot $p;if($null -eq $old[$p]){if(Test-Path -LiteralPath $path){Remove-Item -LiteralPath $path -Force}}else{[IO.File]::WriteAllBytes($path,$old[$p])}};throw}
}
function Invoke-ZimaMain {
 param([string]$Command,[string[]]$Rest)
 try{
  $root=Get-ZimaRoot;$cmd=$Command.ToLowerInvariant()
  if($cmd -eq 'help'){Write-Host @'
zima.ps1 - workspace orchestration (PS 5.1)
  status [-Pending] [-q] [--json]
  <repo-name>                         card and live state
  issues [-R <repo|zima>] [-Stale <days>] [--json]
  clone <name> | clone -All           refuses missing irreplaceable state
  sync [<name>|-All]                  fetch-only; defaults to all
  update [<name>|-All]                clean/default/upstream ff-only; defaults all
  new-repo -Name <slug> -Github <url> -Product <p> -Stack <s> [-Branch <b>] [-Lifecycle <l>]
  verify [-Fast|-Full] [-Pending] [--json]
  gen                                deterministic generated artifacts
  runners                            read-only active container status only
  locks list [--json]
  locks acquire|release <resource> -Owner <token>
Deferred members are metadata only: explicit operational targets refuse; bulk operations skip.
Exit: 0 success, 1 failure, 2 verification warnings. Pending never proves cutover.
'@;exit 0}
  $m=Read-ZimaManifest (Join-Path $root 'repos.json');Assert-ZimaRequestedTargetActive $m $cmd $Rest;$v=Invoke-ZimaManifestValidation $m $root;if($v.Errors.Count){throw ('Invalid manifest: '+($v.Errors -join '; '))};$m=Resolve-ZimaDefaults $m
  switch($cmd){
   'status'{
    $a=Get-ZimaArguments $Rest @('-pending','-q','-quiet','-json');if($a.Positionals.Count){throw 'Unexpected status argument'};if($a.Options.ContainsKey('-pending')){Assert-ZimaPendingAllowed $root};$states=@();$bad=0
    foreach($r in $m['repos']){$st=Get-ZimaRepoState $r $root;$states+=,$st;if(!$st.deferred -and ((!$st.present -and !$a.Options.ContainsKey('-pending')) -or ($st.present -and (!$st.isGit -or !$st.originOk -or $st.error)))){$bad++}}
    $known=@($m['repos']|ForEach-Object{$_['name']});$orphans=@();$proj=Get-ZimaSafePath $root 'projects';if(Test-Path -LiteralPath $proj){$orphans=@(Get-ChildItem -LiteralPath $proj -Directory -Force|Where-Object{$known -notcontains $_.Name -and $_.Name -ne '.shared'}|ForEach-Object{$_.Name})}
    if($a.Options.ContainsKey('-json')){[ordered]@{repos=$states;orphans=$orphans;pending=$a.Options.ContainsKey('-pending')}|ConvertTo-Json -Depth 8}else{foreach($st in $states){if($st.deferred){Write-Host ($st.name+': DEFERRED ('+$st.defer_reason+'; no source probe)');continue};if(($a.Options.ContainsKey('-q') -or $a.Options.ContainsKey('-quiet')) -and $st.present -and $st.isGit -and $st.originOk -and !$st.error -and ($st.staged+$st.unstaged+$st.untracked+$st.stashes) -eq 0 -and $st.branch -eq $st.expectedBranch){continue};Write-Host ("{0}: present={1} git={2} origin={3} branch={4} staged/unstaged/untracked/conflicts={5}/{6}/{7}/{8} upstream={9} ahead/behind={10}/{11}" -f $st.name,$st.present,$st.isGit,$st.originOk,$st.branch,$st.staged,$st.unstaged,$st.untracked,$st.conflicts,$st.upstream,$st.ahead,$st.behind)};if($orphans.Count){Write-Host ('orphans: '+($orphans -join ', '))}};if($bad){exit 1};exit 0
   }
   'verify'{
    $a=Get-ZimaArguments $Rest @('-fast','-full','-pending','-json');if($a.Positionals.Count -or ($a.Options.ContainsKey('-fast') -and $a.Options.ContainsKey('-full'))){throw 'Choose Fast or Full'};$mode='fast';if($a.Options.ContainsKey('-full')){$mode='full'};$res=Invoke-ZimaVerify -Mode $mode -ZimaRoot $root -Pending:($a.Options.ContainsKey('-pending'))
    if($a.Options.ContainsKey('-json')){$res|ConvertTo-Json -Depth 8}else{foreach($c in $res.Checks){Write-Host "  PASS $c"};if($res.ContainsKey('Info')){foreach($i in $res.Info){Write-Host "  INFO $i"}};foreach($w in $res.Warnings){Write-Host "  WARN $w"};foreach($e in $res.Errors){Write-Host "  FAIL $e"}};if($res.Errors.Count){exit 1};if($res.Warnings.Count){exit 2};exit 0
   }
   'gen'{$a=Get-ZimaArguments $Rest @();if($a.Positionals.Count){throw 'gen accepts no arguments'};Invoke-ZimaGen $m $root;Write-Host 'generated repos index, runner registry and portable workspace';exit 0}
   'issues'{
    $a=Get-ZimaArguments $Rest @('-r','-repo','-stale','-json') @('-r','-repo','-stale');if($a.Positionals.Count){throw 'Unexpected issues argument'};if($a.Options.ContainsKey('-r') -and $a.Options.ContainsKey('-repo')){throw 'Choose -R or -Repo'};$filter=$null;if($a.Options.ContainsKey('-r')){$filter=$a.Options['-r']};if($a.Options.ContainsKey('-repo')){$filter=$a.Options['-repo']}
    $targets=@();foreach($r in $m['repos']){if(!(Test-ZimaRepoDeferred $r) -and (!$filter -or $r['name'] -ceq $filter)){$targets+=@{name=$r['name'];slug=($r['github'] -replace '^https://github\.com/','' -replace '\.git$','')}}};if(!$filter -or $filter -ceq 'zima'){$targets+=@{name='zima';slug=$m['org']+'/zima'}};if(!$targets.Count){throw 'Unknown issues target'}
    $query=@();if($a.Options.ContainsKey('-stale')){$days=0;if(![int]::TryParse($a.Options['-stale'],[ref]$days) -or $days -lt 1 -or $days -gt 36500){throw 'Stale must be 1..36500 days'};$query=@('--search',('updated:<='+[DateTime]::UtcNow.AddDays(-$days).ToString('yyyy-MM-dd')))}
    $rows=@();foreach($t in $targets){$g=Invoke-ZimaNative gh (@('issue','list','-R',$t.slug,'--json','number,title,milestone,updatedAt','--limit','1000')+$query);if($g.Code -ne 0){throw "gh issue list failed: $($t.name) (output withheld)"};$parsed=($g.Output -join "`n")|ConvertFrom-Json;$issues=@();foreach($issue in $parsed){$issues+=,$issue};$rows+=@{repo=$t.name;issues=$issues}}
    if($a.Options.ContainsKey('-json')){ConvertTo-Json -InputObject $rows -Depth 12}else{foreach($row in $rows){Write-Host ('== '+$row.repo+' ==');foreach($issue in $row.issues){Write-Host ("#{0} {1} (updated {2})" -f $issue.number,$issue.title,$issue.updatedAt)}}};exit 0
   }
   {$_ -in @('clone','sync','update')}{
    $a=Get-ZimaArguments $Rest @('-all');$all=$a.Options.ContainsKey('-all');if($cmd -ne 'clone' -and !$a.Positionals.Count){$all=$true};$targets=Get-ZimaTargets $m $a.Positionals -All:$all
    foreach($r in $targets){$st=Get-ZimaRepoState $r $root;if($cmd -eq 'clone' -and !$st.present){if($r['local_state'] -eq 'irreplaceable'){throw "$($r['name']): irreplaceable directory missing; auto-clone forbidden"};continue};if(!$st.present -or !$st.isGit -or !$st.originOk -or $st.error){throw "$($r['name']): missing/non-root/origin mismatch/git error"};if($cmd -eq 'update' -and ($st.detached -or $st.branch -cne $r['default_branch'] -or ($st.staged+$st.unstaged+$st.untracked) -gt 0 -or $st.upstream -cne ('origin/'+$r['default_branch']))){throw "$($r['name']): update requires clean default branch and matching origin upstream"}}
    foreach($r in $targets){$dir=Get-ZimaSafePath $root $r['path'];if($cmd -eq 'clone'){if(Test-Path -LiteralPath $dir){Write-Host ($r['name']+': already present');continue};$g=Invoke-ZimaNative git @('-C',$root,'clone','--branch',$r['default_branch'],'--',$r['github'],$dir)}elseif($cmd -eq 'sync'){$g=Invoke-ZimaNative git @('-C',$dir,'fetch','--prune','origin',('+refs/heads/'+$r['default_branch']+':refs/remotes/origin/'+$r['default_branch']))}else{$g=Invoke-ZimaNative git @('-C',$dir,'merge','--ff-only','--',('origin/'+$r['default_branch']))};if($g.Code -ne 0){throw "$($r['name']): $cmd failed (output withheld)"};Write-Host ($r['name']+': '+$cmd+' succeeded')};exit 0
   }
   'new-repo'{$a=Get-ZimaArguments $Rest @('-name','-github','-product','-stack','-branch','-lifecycle') @('-name','-github','-product','-stack','-branch','-lifecycle');if($a.Positionals.Count){throw 'Unexpected new-repo argument'};Add-ZimaRepo $m $a.Options $root;Write-Host 'Added manifest/card and regenerated outputs; finish onboarding and verify before commit.';exit 0}
   'locks'{$a=Get-ZimaArguments $Rest @('-owner','-json') @('-owner');if($a.Positionals.Count -lt 1 -or $a.Positionals.Count -gt 2){throw 'locks list|acquire|release <resource> -Owner <token>'};$action=$a.Positionals[0];$resource=$null;if($a.Positionals.Count -eq 2){$resource=$a.Positionals[1]};$owner=$null;if($a.Options.ContainsKey('-owner')){$owner=$a.Options['-owner']};if($action -eq 'list' -and ($resource -or $owner)){throw 'locks list has no resource/owner'};$rows=@(Invoke-ZimaLock $root $action $resource $owner);if($a.Options.ContainsKey('-json')){ConvertTo-Json -InputObject $rows -Depth 5}else{if($action -eq 'list'){if($rows.Count){$rows|ForEach-Object{Write-Host ($_|ConvertTo-Json -Compress)}}else{Write-Host 'no locks held'}}else{Write-Host ($action+': '+$resource)}};exit 0}
   'runners'{$a=Get-ZimaArguments $Rest @();if($a.Positionals.Count){throw 'Unexpected runners argument'};foreach($r in $m['repos']){if($null -eq $r['runner']){continue};$container=$r['runner']['container'];if(Test-ZimaRepoDeferred $r){Write-Host ($container+'|DEFERRED (not probed)');continue};$g=Invoke-ZimaNative docker @('ps','-a','--filter',('name=^/'+[regex]::Escape($container)+'$'),'--format','{{.Names}}|{{.State}}|{{.Status}}');if($g.Code -ne 0){throw 'Docker engine unavailable; do not start solely for check'};$prefix=$container+'|';$row=@($g.Output|Where-Object{$_.StartsWith($prefix)});if($row.Count){Write-Host ($row -join "`n")}else{Write-Host ($container+'|absent')}};exit 0}
   default{$r=@($m['repos']|Where-Object{$_['name'] -ceq $Command});if($r.Count -ne 1){throw "Unknown command/repo: $Command"};if($Rest.Count){throw 'Repo card accepts no options'};$card=Get-ZimaSafePath $root ('repos/'+$Command+'.md');Get-Content -LiteralPath $card -Encoding UTF8;$st=Get-ZimaRepoState $r[0] $root;$st|ConvertTo-Json -Depth 5;if($st.deferred){exit 0};if(!$st.present -or !$st.isGit -or !$st.originOk -or $st.error){exit 1};exit 0}
  }
 }catch{[Console]::Error.WriteLine('ERROR: '+$_.Exception.Message);exit 1}
}
if($env:ZIMA_DOT_SOURCED -ne '1'){Invoke-ZimaMain $Command $Rest}
