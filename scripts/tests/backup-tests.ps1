# Synthetic-only regression lane. No production source or D: writes.
param()
Set-StrictMode -Version 3.0
$ErrorActionPreference='Stop'
$repo=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..')).TrimEnd('\')
. (Join-Path $repo 'scripts/backup-local-state.ps1')
$task=Assert-BackupPath (Join-Path $repo '.agent-tmp/a1-backup')
[IO.Directory]::CreateDirectory($task) | Out-Null
$script:Assertions=0; $script:Failures=0
$script:Retained=@()
function Assert([bool]$Value,[string]$Name) {
    $script:Assertions++
    if ($Value) { Write-Host ('PASS '+$Name) } else { $script:Failures++; Write-Host ('FAIL '+$Name) }
}
function New-Fixture {
    $at=Join-Path $task ('fixture-'+[guid]::NewGuid().ToString('N'))
    [IO.Directory]::CreateDirectory($at) | Out-Null
    $source=Join-Path $at 'source'
    foreach ($rel in @('call-tracker/private/empty','call-tracker/.planning','drive-trace/artifacts/device-evidence','str-fixer/input','str-fixer/output','str-fixer/samples')) { [IO.Directory]::CreateDirectory((Join-Path $source $rel)) | Out-Null }
    $binary=New-Object byte[] 4096; for ($i=0;$i -lt $binary.Length;$i++) { $binary[$i]=[byte]($i % 251) }
    [IO.File]::WriteAllBytes((Join-Path $source 'call-tracker/private/state.img'),$binary)
    [IO.File]::WriteAllBytes((Join-Path $source 'call-tracker/private/smaller.img'),[byte[]]@(1,2,3,4,5,6))
    [IO.File]::WriteAllBytes((Join-Path $source 'call-tracker/private/private-signing.jks'),[byte[]]@(0,255,12,34,56))
    foreach ($rel in @('call-tracker/.planning/acceptance.txt','drive-trace/artifacts/device-evidence/receipt.bin','str-fixer/input/personal media.srt','str-fixer/output/converted.srt','str-fixer/root subtitle.srt')) { [IO.File]::WriteAllText((Join-Path $source $rel),'synthetic') }
    [IO.File]::WriteAllBytes((Join-Path $source 'str-fixer/input/larger without streams.srt'),(New-Object byte[] 100))
    Set-Content -LiteralPath (Join-Path $source 'str-fixer/input/personal media.srt') -Stream 'opaque-stream' -Value 'synthetic ADS' -NoNewline
    Set-Content -LiteralPath (Join-Path $source 'call-tracker/private/empty') -Stream 'directory-stream' -Value 'directory ADS' -NoNewline
    # A zero-byte category is deliberately distinct from absence.
    return $at
}
function Source-Fingerprint([string]$At) {
    Initialize-BackupNative $task
    return Get-BackupDigest (Convert-BackupComparable @(Get-BackupInventory (Get-BackupCategories (Join-Path $At 'source')) $true))
}
function Expect-Rejection([string]$At,[string]$Injection,[string]$Name,[switch]$AllowSourceMutation) {
    $before=Source-Fingerprint $At
    $oldDestination=Test-Path -LiteralPath (Join-Path $At 'external/backup')
    $oldReceipt=$null
    if (Test-Path -LiteralPath (Join-Path $At 'external/backup/receipt.json')) { $oldReceipt=Get-BackupHash (Join-Path $At 'external/backup/receipt.json') }
    $caught=$false; $message=''
    try { Invoke-ZimaBackup -FixtureRoot $At -Failure $Injection | Out-Null } catch { $caught=$true; $message=$_.Exception.Message }
    Assert $caught ($Name+' rejects')
    Assert ($message -notmatch 'private-signing|personal media|root subtitle|directory-stream') ($Name+' error redacted')
    if (!$AllowSourceMutation) { Assert ((Source-Fingerprint $At) -eq $before) ($Name+' source bytes/metadata preserved') }
    $receiptPath=Join-Path $At 'external/backup/receipt.json'
    if ($oldDestination) {
        Assert ((Test-Path -LiteralPath (Join-Path $At 'external/backup')) -and (!$oldReceipt -or (Get-BackupHash $receiptPath) -eq $oldReceipt)) ($Name+' existing destination and receipt unchanged')
    } elseif (Test-Path -LiteralPath $receiptPath) {
        $receipt=Get-Content -Raw -Encoding UTF8 -LiteralPath $receiptPath | ConvertFrom-Json
        Assert (!$receipt.integrity_verified -and $receipt.state -eq 'FAILED') ($Name+' receipt cannot claim VERIFIED')
        if ($Injection -eq 'SourceChange') { Assert ($receipt.source_stability -eq 'MISMATCH' -and !$receipt.source_stable_verified) 'source mismatch explicitly recorded as MISMATCH' }
        if ($Injection -eq 'CopyFailure') { Assert ($receipt.failure_code -eq 'COPY_TRANSPORT_FAILURE') 'real robocopy failure propagated through backup receipt' }
        if ($Injection -eq 'WeakAcl') {
            Assert ($receipt.failure_code -eq 'ACL_MISMATCH') 'real Everyone ACL weakening detected after successful injection'
            $safe=$true; $owner=[Security.Principal.WindowsIdentity]::GetCurrent().User.Value
            try { foreach ($item in @(Get-Item -LiteralPath (Join-Path $At 'external/backup') -Force)+@(Get-ChildItem -LiteralPath (Join-Path $At 'external/backup') -Force -Recurse)) { Assert-BackupAcl $item.FullName $owner -Root:($item.FullName -eq (Join-Path $At 'external/backup')) } } catch { $safe=$false }
            Assert ($safe -and $receipt.protection -eq 'VERIFIED') 'failed weak-ACL copy re-hardened including raw manifests and receipts'
        }
    } else { Assert (!(Test-Path -LiteralPath (Join-Path $At 'external/backup'))) ($Name+' rejected before backup creation') }
    $script:Retained += $At
}

$good=New-Fixture
try {
    $before=Source-Fingerprint $good
    $receipt=Invoke-ZimaBackup -FixtureRoot $good
    Assert ($receipt.state -eq 'VERIFIED' -and $receipt.integrity_verified) 'binary/ADS/directory backup verified'
    Assert ($receipt.script_copy_only -and $receipt.source_stable_verified -and $receipt.source_stability -eq 'MATCH') 'source copy-only policy and measured stability distinct'
    Assert ((Source-Fingerprint $good) -eq $before) 'successful backup source unchanged including original DACL'
    Assert (@($receipt.categories).Count -eq 7) 'all seven categories represented'
    Assert (@($receipt.categories | Where-Object { $_.category -eq 'str-samples' -and $_.status -eq 'EMPTY' -and @($_.restore).Count -eq 0 }).Count -eq 1) 'empty category honest and no invented restore'
    $private=@($receipt.categories | Where-Object { $_.category -eq 'private' })[0]
    Assert (@($private.restore | Where-Object { $_.kind -eq 'largest-avd-image' -and $_.result -eq 'MATCH' }).Count -eq 1) 'largest AVD image restored'
    Assert (@($private.restore | Where-Object { $_.kind -eq 'largest-avd-image' -and $_.sha256 -eq (Get-BackupHash (Join-Path $good 'source/call-tracker/private/state.img')) }).Count -eq 1) 'larger of two AVD image candidates restored by exact SHA256'
    Assert (@($private.restore | Where-Object { $_.kind -eq 'signing-artifact' -and $_.result -eq 'MATCH' }).Count -eq 1) 'opaque signing sample restored'
    Assert (@($receipt.categories | Where-Object { $_.status -eq 'PRESENT' -and @($_.restore).Count -eq 0 }).Count -eq 0) 'sample restored for each present category'
    $inputCategory=@($receipt.categories | Where-Object { $_.category -eq 'str-input' })[0]
    Assert ($inputCategory.streams -eq 1 -and @($inputCategory.restore | Where-Object { $_.kind -eq 'named-stream-file' -and $_.streams -eq 1 -and $_.sha256 -eq (Get-BackupHash (Join-Path $good 'source/str-fixer/input/personal media.srt')) }).Count -eq 1) 'file ADS restored despite larger regular file without streams'
    Assert ($private.streams -eq 1) 'directory ADS copied and hashed'
    Assert (@($private.restore | Where-Object { $_.kind -eq 'named-stream-directory' -and $_.streams -eq 1 -and $_.result -eq 'MATCH' }).Count -eq 1) 'directory ADS restored despite other larger files'
    Assert (!(Test-Path -LiteralPath (Join-Path $good 'external/backup/.restore-check'))) 'isolated restore cleanup only'
    $local=Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $good 'evidence/receipt.json')
    $external=Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $good 'external/backup/receipt.json')
    Assert ($local -ceq $external) 'durable redacted receipts agree'
    Assert ($local -notmatch 'private-signing|personal media|root subtitle|opaque-stream|directory-stream') 'receipt excludes all raw personal and stream names'
    Assert ((Get-BackupHash (Join-Path $good 'external/backup/inventory.json')) -eq $receipt.inventory_sha256) 'complete protected inventory hash recorded'
    Assert (@($receipt.copy_exit_codes | Where-Object { $_.exit_code -lt 0 -or $_.exit_code -ge 8 }).Count -eq 0) 'actual robocopy accepted only codes zero through seven'
    $owner=[Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    Assert-BackupAcl (Join-Path $good 'external/backup') $owner -Root
    Assert $true 'root DACL has only owner SYSTEM and Administrators'
    Expect-Rejection $good '' 'existing verified destination'
} catch {
    $script:Failures++; Write-Host ('FAIL initial synthetic success: '+$_.Exception.Message)
}
$script:Retained += $good
foreach ($failure in @('LowSpace','CopyFailure','BackupCorruption','RestoreCorruption','WeakAcl','Emulator')) { Expect-Rejection (New-Fixture) $failure $failure }
Expect-Rejection (New-Fixture) 'SourceChange' 'SourceChange' -AllowSourceMutation
$race=New-Fixture
$raceBefore=Source-Fingerprint $race
$caught=$false; try { Invoke-ZimaBackup -FixtureRoot $race -Failure 'DestinationRace' | Out-Null } catch { $caught=$true }
Assert $caught 'concurrently created same-ACL destination rejected atomically'
Assert ((Get-Content -Raw -LiteralPath (Join-Path $race 'external/backup/unknown-owner-marker')) -ceq 'synthetic existing target') 'racing unknown destination marker preserved'
Assert (@(Get-ChildItem -LiteralPath (Join-Path $race 'external/backup') -Force).Count -eq 1) 'racing destination receives no receipts or source bytes'
Assert ((Source-Fingerprint $race) -eq $raceBefore) 'destination race source unchanged'
$script:Retained += $race
$nativeFailure=New-Fixture
$caught=$false
try { Invoke-BackupTransport (Join-Path $nativeFailure 'source/does-not-exist') (Join-Path $nativeFailure 'native-copy-target') 'tree' | Out-Null } catch { $caught=$true }
Assert $caught 'actual robocopy missing-source code at least eight rejected'
$script:Retained += $nativeFailure

$absent=New-Fixture
Remove-Item -LiteralPath (Join-Path $absent 'source/str-fixer/samples')
Remove-Item -LiteralPath (Join-Path $absent 'source/call-tracker/private/private-signing.jks')
$r=Invoke-ZimaBackup -FixtureRoot $absent
Assert (@($r.categories | Where-Object { $_.category -eq 'str-samples' -and $_.status -eq 'ABSENT' }).Count -eq 1) 'absent category reported ABSENT'
Assert (@($r.categories | Where-Object { $_.category -eq 'private' -and $_.signing_artifact -eq 'ABSENT' -and @($_.restore | Where-Object { $_.kind -eq 'signing-artifact' }).Count -eq 0 }).Count -eq 1) 'missing signing material has no fictitious proof'
$script:Retained += $absent
$missingMember=New-Fixture
Remove-Item -LiteralPath (Join-Path $missingMember 'source/str-fixer') -Recurse -Force
$caught=$false; try { Invoke-ZimaBackup -FixtureRoot $missingMember | Out-Null } catch { $caught=$_.Exception.Message -match 'IRREPLACEABLE_MEMBER_MISSING' }
Assert $caught 'missing irreplaceable member root stops before inventory'
Assert (!(Test-Path -LiteralPath (Join-Path $missingMember 'external/backup'))) 'missing member never becomes an ABSENT VERIFIED backup'
$script:Retained += $missingMember
$missingCritical=New-Fixture
Remove-Item -LiteralPath (Join-Path $missingCritical 'source/call-tracker/.planning/acceptance.txt')
$r=Invoke-ZimaBackup -FixtureRoot $missingCritical
Assert ($r.integrity_verified -and $r.readiness -eq 'BLOCKED_MISSING_CRITICAL_CATEGORY' -and 'planning' -in @($r.critical_categories_unavailable)) 'empty critical category blocks readiness while copied existing data remains verified'
$script:Retained += $missingCritical

$empty=New-Fixture
[IO.Directory]::CreateDirectory((Join-Path $empty 'external/backup')) | Out-Null
Expect-Rejection $empty '' 'existing empty destination'
$bad=Join-Path $task 'not-a-fixture'
[IO.Directory]::CreateDirectory($bad) | Out-Null
$caught=$false; try { Invoke-ZimaBackup -FixtureRoot $bad | Out-Null } catch { $caught=$true }
Assert $caught 'arbitrary fixture root refused'
Assert (!(Test-Path -LiteralPath (Join-Path $bad 'external'))) 'invalid fixture root causes no backup writes'
$caught=$false; try { Invoke-ZimaBackup -Failure 'CopyFailure' | Out-Null } catch { $caught=$true }
Assert $caught 'production fault injection refused before source access'

# Junction escapes and sparse/hard-linked files are rejected before destination creation.
$junction=New-Fixture
$outside=Join-Path $junction 'outside'; [IO.Directory]::CreateDirectory($outside) | Out-Null
$link=Join-Path $junction 'source/str-fixer/input/escape'
$result=New-Item -ItemType Junction -Path $link -Target $outside
$caught=$false; try { Invoke-ZimaBackup -FixtureRoot $junction | Out-Null } catch { $caught=$true }
Assert $caught 'source junction escape refused'
Assert (!(Test-Path -LiteralPath (Join-Path $junction 'external/backup'))) 'source junction rejection before data copy'
$script:Retained += $junction
$hard=New-Fixture
New-Item -ItemType HardLink -Path (Join-Path $hard 'source/str-fixer/input/second.srt') -Target (Join-Path $hard 'source/str-fixer/input/personal media.srt') | Out-Null
$caught=$false; try { Invoke-ZimaBackup -FixtureRoot $hard | Out-Null } catch { $caught=$true }
Assert $caught 'unsupported hard-link topology refused'
Assert (!(Test-Path -LiteralPath (Join-Path $hard 'external/backup'))) 'unsupported metadata rejected before creation'
$script:Retained += $hard
$sparse=New-Fixture
$ErrorActionPreference='Continue'
& fsutil sparse setflag (Join-Path $sparse 'source/call-tracker/private/state.img') 1>$null 2>$null
$sparseCode=$LASTEXITCODE
$ErrorActionPreference='Stop'
Assert ($sparseCode -eq 0) 'fixture sparse attribute created'
$caught=$false; try { Invoke-ZimaBackup -FixtureRoot $sparse | Out-Null } catch { $caught=$true }
Assert $caught 'unsupported sparse metadata refused'
Assert (!(Test-Path -LiteralPath (Join-Path $sparse 'external/backup'))) 'sparse source causes no backup creation'
$script:Retained += $sparse

$destinationLink=New-Fixture
[IO.Directory]::CreateDirectory((Join-Path $destinationLink 'outside')) | Out-Null
New-Item -ItemType Junction -Path (Join-Path $destinationLink 'external') -Target (Join-Path $destinationLink 'outside') | Out-Null
$caught=$false; try { Invoke-ZimaBackup -FixtureRoot $destinationLink | Out-Null } catch { $caught=$true }
Assert $caught 'destination ancestor junction refused'
Assert (@(Get-ChildItem -LiteralPath (Join-Path $destinationLink 'outside') -Force).Count -eq 0) 'destination escape target unchanged'
$script:Retained += $destinationLink
$counts=[ordered]@{assertions=$script:Assertions;failures=$script:Failures;timestamp_utc=[DateTime]::UtcNow.ToString('o');powershell=$PSVersionTable.PSVersion.ToString();script_sha256=(Get-BackupHash (Join-Path $repo 'scripts/backup-local-state.ps1'));tests_sha256=(Get-BackupHash $PSCommandPath);synthetic_only=$true;production_backup_executed=$false;fixtures=@($script:Retained | Select-Object -Unique)}
Write-BackupJson (Join-Path $task 'implementation-tests.json') $counts
Write-Host ('Backup tests: '+$script:Assertions+' assertions; '+$script:Failures+' failures')
if ($script:Failures) { exit 1 }; exit 0
