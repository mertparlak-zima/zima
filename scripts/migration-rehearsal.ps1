# Fixture-only rehearsal: cannot accept production source/destination paths.
param()
Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$taskRoot = Join-Path $root '.agent-tmp/a1-hardening'
# Refuse redirected workspace/temp ancestors before creating any fixture directory.
$ancestor = [IO.Path]::GetFullPath($taskRoot)
while ($ancestor) {
    if (Test-Path -LiteralPath $ancestor) {
        $item = Get-Item -LiteralPath $ancestor -Force
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Fixture ancestor is a reparse point' }
    }
    $parent = [IO.Path]::GetDirectoryName($ancestor)
    if ($parent -eq $ancestor) { break }
    $ancestor = $parent
}
New-Item -ItemType Directory -Path $taskRoot -Force | Out-Null
$run = Join-Path $taskRoot ('rehearsal-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $run | Out-Null
$source = Join-Path $run 'source'
$target = Join-Path $run 'target'
$worktree = Join-Path $run 'linked'
$journal = Join-Path $run 'journal.jsonl'
$recovery = Join-Path $run 'recovery'
New-Item -ItemType Directory -Path $recovery | Out-Null
$mirror = Join-Path $recovery 'journal.jsonl'
$script:Assertions = 0
$script:Failures = 0
$utf8 = New-Object Text.UTF8Encoding($false)
$excludeFile = Join-Path $run 'git-excludes'
[IO.File]::WriteAllText($excludeFile, '', $utf8)
function Write-Text([string]$Path,[string]$Text) { [IO.File]::WriteAllText($Path,$Text,$utf8) }
function Assert([bool]$Condition,[string]$Name) {
    $script:Assertions++
    if (!$Condition) { $script:Failures++; Write-Host "FAIL $Name" } else { Write-Host "PASS $Name" }
}
function Invoke-FixtureGit([string]$At,[string[]]$Arguments) {
    # PS5.1 surfaces successful git-worktree repair diagnostics as error records.
    # Capture them and rely on the native exit code; never treat stderr as success.
    $ErrorActionPreference = 'Continue'
    $actual = (& git -c "core.excludesFile=$excludeFile" -C $At rev-parse --show-toplevel 2>$null)
    if ($LASTEXITCODE -ne 0 -or [IO.Path]::GetFullPath($actual) -ne [IO.Path]::GetFullPath($At)) { throw 'Fixture Git root mismatch' }
    $output = @(& git -c "core.excludesFile=$excludeFile" -C $At @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) { throw 'Fixture Git command failed (no production data)' }
    return ($output -join "`n")
}
function Inventory([string]$At) {
    $resolved = (Resolve-Path -LiteralPath $At).Path
    if (!$resolved.StartsWith($run+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Inventory outside fixture refused' }
    $map = @{}
    foreach ($item in Get-ChildItem -LiteralPath $resolved -Recurse -Force) {
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Fixture reparse point refused' }
        $rel = $item.FullName.Substring($resolved.Length+1).Replace('\','/')
        if ($item.PSIsContainer) { $map[$rel+'/'] = 'DIRECTORY' }
        else { $map[$rel] = (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash }
    }
    return $map
}
function Same([hashtable]$A,[hashtable]$B) {
    if ($A.Count -ne $B.Count) { return $false }
    foreach ($key in $A.Keys) { if (!$B.ContainsKey($key) -or $A[$key] -ne $B[$key]) { return $false } }
    return $true
}
function Digest([hashtable]$Map) {
    $keys = [string[]]@($Map.Keys)
    [Array]::Sort($keys, [StringComparer]::Ordinal)
    $lines = @($keys | ForEach-Object { $_ + [char]0 + $Map[$_] })
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return [BitConverter]::ToString($sha.ComputeHash($utf8.GetBytes(($lines -join "`n")))).Replace('-','') }
    finally { $sha.Dispose() }
}
function Record([string]$State,[string]$Result) {
    $post = $null
    if (Test-Path -LiteralPath $target) { $post = Digest (Inventory $target) }
    $entry = [ordered]@{run_id=(Split-Path $run -Leaf);attempt=1;step='FIXTURE';repo='fixture';state=$State;source=$source;destination=$target;pre_hash=(Digest (Inventory $source));post_hash=$post;timestamp=[DateTime]::UtcNow.ToString('o');result=$Result;evidence='inventory.json'}
    $bytes = $utf8.GetBytes(($entry|ConvertTo-Json -Compress)+"`n")
    foreach ($path in @($journal, $mirror)) {
        $stream = New-Object IO.FileStream($path,[IO.FileMode]::Append,[IO.FileAccess]::Write,[IO.FileShare]::Read)
        try { $stream.Write($bytes,0,$bytes.Length); $stream.Flush($true) }
        finally { $stream.Dispose() }
    }
}
function Copy-Exit([int]$Code) { if ($Code -ge 8 -or $Code -lt 0) { throw 'Copy transport failed; source must be preserved' } }
function Resume-Fixture {
    # Resume from durable files rather than trusting in-memory success flags.
    $primaryText = [IO.File]::ReadAllText($journal)
    $mirrorText = [IO.File]::ReadAllText($mirror)
    if ($primaryText -cne $mirrorText -or !$primaryText.EndsWith("`n")) { throw 'Journal disagreement or truncated transition' }
    $records = @($primaryText.TrimEnd("`n").Split("`n") | ForEach-Object { $_ | ConvertFrom-Json })
    if (!$records.Count -or $records[-1].state -notin @('COPIED','VERIFIED')) { throw 'Unexpected resume checkpoint' }
    $saved = Get-Content -LiteralPath (Join-Path $run 'inventory.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    $expected = @{}
    foreach ($property in $saved.PSObject.Properties) { $expected[$property.Name] = $property.Value }
    $last = $records[-1]
    if ($last.run_id -ne (Split-Path $run -Leaf) -or $last.source -ne $source -or $last.destination -ne $target -or $last.result -ne 'OK' -or $last.pre_hash -ne (Digest $expected) -or $last.post_hash -ne (Digest $expected)) {
        throw 'Journal identity or hash does not match evidence'
    }
    if (!(Same $expected (Inventory $source)) -or !(Same $expected (Inventory $target))) {
        throw 'Resume inventory mismatch; cleanup forbidden'
    }
    return $true
}
function Remove-FixtureTarget {
    $actual = (Resolve-Path -LiteralPath $target).Path
    $expected = [IO.Path]::GetFullPath((Join-Path $run 'target'))
    if ($actual -ne $expected -or !$actual.StartsWith($run+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe rollback path refused' }
    foreach ($item in Get-ChildItem -LiteralPath $actual -Recurse -Force) {
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Rollback reparse point refused' }
    }
    Remove-Item -LiteralPath $actual -Recurse -Force
}
$previousOptional = $env:GIT_OPTIONAL_LOCKS
try {
    $env:GIT_OPTIONAL_LOCKS = '0'
    New-Item -ItemType Directory -Path $source | Out-Null
    & git -c "core.excludesFile=$excludeFile" -C $source init -b main --quiet
    if ($LASTEXITCODE -ne 0) { throw 'Fixture init failed' }
    Invoke-FixtureGit $source @('config','user.name','Zima Fixture') | Out-Null
    Invoke-FixtureGit $source @('config','user.email','fixture@example.invalid') | Out-Null
    Invoke-FixtureGit $source @('config','core.autocrlf','false') | Out-Null
    Write-Text (Join-Path $source '.gitignore') "ignored.txt`n"
    Write-Text (Join-Path $source 'tracked.txt') "base`n"
    Invoke-FixtureGit $source @('add','.') | Out-Null
    Invoke-FixtureGit $source @('commit','--quiet','-m','fixture base') | Out-Null
    Write-Text (Join-Path $source 'tracked.txt') "stash-content`n"
    Invoke-FixtureGit $source @('stash','push','--quiet','-m','fixture stash') | Out-Null
    Invoke-FixtureGit $source @('worktree','add','--quiet','-b','fixture-linked',$worktree) | Out-Null
    Write-Text (Join-Path $worktree 'tracked.txt') "linked dirty`n"
    Write-Text (Join-Path $source 'tracked.txt') "staged`n"
    Invoke-FixtureGit $source @('add','tracked.txt') | Out-Null
    Write-Text (Join-Path $source 'tracked.txt') "staged plus unstaged`n"
    Write-Text (Join-Path $source 'untracked.txt') "untracked`n"
    Write-Text (Join-Path $source 'ignored.txt') "ignored-state`n"
    $statusBefore = Invoke-FixtureGit $source @('status','--porcelain=v1','--untracked-files=all')
    $stashBefore = Invoke-FixtureGit $source @('stash','list','--format=%H')
    $stagedBefore = Invoke-FixtureGit $source @('diff','--cached','--binary')
    $dirtyBefore = Invoke-FixtureGit $source @('diff','--binary')
    $before = Inventory $source
    Write-Text (Join-Path $run 'inventory.json') (($before | ConvertTo-Json -Depth 5) + "`n")
    Record 'PREPARED' 'OK'
    foreach ($code in 0..7) { $ok=$true; try { Copy-Exit $code } catch { $ok=$false }; Assert $ok "G01 copy exit $code accepted" }
    $caught=$false;try { Copy-Exit 8 } catch { $caught=$true }
    Assert ($caught -and (Same $before (Inventory $source))) 'G01 exit 8 abort preserves source'
    $injected = $false
    try {
        & robocopy $source $target /E /COPY:DAT /DCOPY:DAT /R:0 /W:0 /NFL /NDL /NJH /NJS /NP | Out-Null
        Copy-Exit $LASTEXITCODE
        Record 'COPIED' 'OK'
        throw 'INJECTED_INTERRUPTION_AFTER_COPY'
    } catch {
        if ($_.Exception.Message -ne 'INJECTED_INTERRUPTION_AFTER_COPY') { throw }
        $injected = $true
    }
    Assert (Same $before (Inventory $target)) 'G02 full file hashes match after actual robocopy'
    Assert ($injected -and (Resume-Fixture)) 'G04 injected exception resumes from persisted checkpoint and inventory'
    $validJournal = [IO.File]::ReadAllText($journal)
    [IO.File]::AppendAllText($journal, '{"state":"VERIFIED"}', $utf8)
    $stopped = $false; try { $null = Resume-Fixture } catch { $stopped = $true }
    Assert ($stopped -and (Same $before (Inventory $source))) 'G04 one-sided interrupted journal write stops with source retained'
    Write-Text $journal $validJournal
    $truncated = $validJournal.Substring(0,$validJournal.Length-4)
    Write-Text $journal $truncated; Write-Text $mirror $truncated
    $stopped = $false; try { $null = Resume-Fixture } catch { $stopped = $true }
    Assert ($stopped -and (Same $before (Inventory $source))) 'G04 matching truncated journals stop with source retained'
    Write-Text $journal $validJournal; Write-Text $mirror $validJournal
    $wrongHash = $validJournal.Replace((Digest $before),('0'*64))
    Write-Text $journal $wrongHash; Write-Text $mirror $wrongHash
    $stopped = $false; try { $null = Resume-Fixture } catch { $stopped = $true }
    Assert ($stopped -and (Same $before (Inventory $source))) 'G04 matching journals with stale hashes stop with source retained'
    Write-Text $journal $validJournal; Write-Text $mirror $validJournal
    Write-Text (Join-Path $target 'untracked.txt') "injected corruption`n"
    Assert (!(Same $before (Inventory $target))) 'G02 changed untracked file detected'
    $rejected = $false
    try { $null = Resume-Fixture } catch { $rejected = $true }
    Assert $rejected 'G04 resume refuses stale OK when target content changed'
    Write-Text (Join-Path $target 'untracked.txt') "untracked`n"
    Remove-Item -LiteralPath (Join-Path $target 'ignored.txt')
    Assert (!(Same $before (Inventory $target))) 'G02 missing ignored file detected'
    Write-Text (Join-Path $target 'ignored.txt') "ignored-state`n"
    Write-Text (Join-Path $target 'extra.txt') "extra`n"
    Assert (!(Same $before (Inventory $target))) 'G02 extra file detected'
    Remove-Item -LiteralPath (Join-Path $target 'extra.txt')
    Assert (Same $before (Inventory $target)) 'G04 corrected target resumes to verified state'
    Record 'VERIFIED' 'OK'
    Assert (Resume-Fixture) 'G04 verified checkpoint resumes only after dual-journal/hash validation'
    Assert ((Invoke-FixtureGit $target @('status','--porcelain=v1','--untracked-files=all')) -eq $statusBefore) 'G03 dirty/staged/untracked status retained'
    Assert ((Invoke-FixtureGit $target @('stash','list','--format=%H')) -eq $stashBefore) 'G03 stash ref retained'
    Assert ((Invoke-FixtureGit $target @('diff','--cached','--binary')) -eq $stagedBefore) 'G03 staged content retained'
    Assert ((Invoke-FixtureGit $target @('diff','--binary')) -eq $dirtyBefore) 'G03 unstaged content retained'
    $linkedBefore = Inventory $worktree
    Invoke-FixtureGit $target @('worktree','repair',$worktree) | Out-Null
    $common = Invoke-FixtureGit $worktree @('rev-parse','--path-format=absolute','--git-common-dir')
    Assert ([IO.Path]::GetFullPath($common) -eq [IO.Path]::GetFullPath((Join-Path $target '.git'))) 'G05 linked worktree points to copied main'
    Assert ((Invoke-FixtureGit $worktree @('status','--porcelain=v1')) -match ' M tracked.txt') 'G05 worktree dirty state retained'
    # Reverse planned metadata mutation before rolling back the copied tree.
    Invoke-FixtureGit $source @('worktree','repair',$worktree) | Out-Null
    Assert (Same $linkedBefore (Inventory $worktree)) 'G05 reverse repair restores exact worktree files'
    Remove-FixtureTarget
    Assert ((Test-Path -LiteralPath $source) -and !(Test-Path -LiteralPath $target) -and (Same $before (Inventory $source))) 'G04 rollback removes only copy and preserves exact source'
    Record 'ROLLED_BACK' 'OK'
} finally { $env:GIT_OPTIONAL_LOCKS=$previousOptional }
$summary = [ordered]@{fixture=$run;assertions=$script:Assertions;failures=$script:Failures;production_cutover=$false;scope='synthetic copy/hash/Git/worktree/rollback only'}
Write-Text (Join-Path $run 'result.json') (($summary|ConvertTo-Json)+"`n")
Write-Host ($summary|ConvertTo-Json -Compress)
if ($script:Failures) { exit 1 }
exit 0
