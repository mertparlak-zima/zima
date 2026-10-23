# Copy-only, explicitly approved A1 backup. No production cutover or source mutation.
[CmdletBinding()]
param(
    [switch]$Execute,
    [string]$FixtureRoot,
    [ValidateSet('', 'LowSpace', 'CopyFailure', 'SourceChange', 'BackupCorruption', 'RestoreCorruption', 'WeakAcl', 'Emulator', 'DestinationRace')]
    [string]$FixtureFailure = ''
)
Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'
$script:BackupRepoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')).TrimEnd('\')
$script:BackupUtf8 = New-Object Text.UTF8Encoding($false)

function Assert-BackupPath([string]$Path) {
    if (!$Path -or ![IO.Path]::IsPathRooted($Path) -or $Path.StartsWith('\\') -or $Path -match '^[A-Za-z]:[^\\]') { throw 'Non-local absolute path refused' }
    $full = [IO.Path]::GetFullPath($Path).TrimEnd('\')
    if ($full.Substring(2).Contains(':')) { throw 'Alternate path syntax refused' }
    $ancestor = $full
    while ($ancestor) {
        if (Test-Path -LiteralPath $ancestor) {
            $item = Get-Item -LiteralPath $ancestor -Force
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Reparse path refused' }
        }
        $parent = [IO.Path]::GetDirectoryName($ancestor)
        if (!$parent -or $parent -eq $ancestor) { break }
        $ancestor = $parent
    }
    return $full
}
function Test-BackupWithin([string]$Child,[string]$Parent) {
    return $Child.Equals($Parent,[StringComparison]::OrdinalIgnoreCase) -or $Child.StartsWith($Parent+'\',[StringComparison]::OrdinalIgnoreCase)
}
function Initialize-BackupNative([string]$TempRoot) {
    if ('ZimaA1Backup.Native' -as [type]) { return }
    $compiler = Join-Path $TempRoot ('compiler-'+[guid]::NewGuid().ToString('N'))
    [IO.Directory]::CreateDirectory($compiler) | Out-Null
    $oldTemp = $env:TEMP; $oldTmp = $env:TMP
    try {
        $env:TEMP = $compiler; $env:TMP = $compiler
        Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;
namespace ZimaA1Backup {
  public static class Native {
    [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)]
    private struct StreamData { public long Size; [MarshalAs(UnmanagedType.ByValTStr, SizeConst=296)] public string Name; }
    [StructLayout(LayoutKind.Sequential)]
    private struct Info { public uint Attributes; public System.Runtime.InteropServices.ComTypes.FILETIME Creation, Access, Write; public uint Volume, SizeHigh, SizeLow, Links, IndexHigh, IndexLow; }
    [StructLayout(LayoutKind.Sequential)] private struct IoStatus { public IntPtr Status; public UIntPtr Information; }
    [StructLayout(LayoutKind.Sequential)] private struct SecurityAttributes { public uint Length; public IntPtr Descriptor; [MarshalAs(UnmanagedType.Bool)] public bool Inherit; }
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)] private static extern IntPtr FindFirstStreamW(string path, int level, out StreamData data, uint flags);
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)] private static extern bool FindNextStreamW(IntPtr handle, out StreamData data);
    [DllImport("kernel32.dll", SetLastError=true)] private static extern bool FindClose(IntPtr handle);
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)] private static extern SafeFileHandle CreateFileW(string path, uint access, uint share, IntPtr security, uint mode, uint flags, IntPtr template);
    [DllImport("kernel32.dll", SetLastError=true)] private static extern bool GetFileInformationByHandle(SafeFileHandle handle, out Info info);
    [DllImport("ntdll.dll")] private static extern int NtQueryInformationFile(SafeFileHandle handle, out IoStatus status, out uint eaSize, uint length, int infoClass);
    [DllImport("kernel32.dll", CharSet=CharSet.Unicode, SetLastError=true)] private static extern bool CreateDirectoryW(string path, ref SecurityAttributes security);
    public static void CreateExclusiveDirectory(string path, byte[] descriptor) {
      var pin=GCHandle.Alloc(descriptor,GCHandleType.Pinned);
      try {
        var security=new SecurityAttributes { Length=(uint)Marshal.SizeOf(typeof(SecurityAttributes)), Descriptor=pin.AddrOfPinnedObject(), Inherit=false };
        if (!CreateDirectoryW(path,ref security)) {
          if (Marshal.GetLastWin32Error()==183) throw new InvalidOperationException("Exclusive destination already exists");
          throw new InvalidOperationException("Exclusive directory creation failed");
        }
      } finally { pin.Free(); }
    }
    public static string[] Streams(string path) {
      var names = new List<string>(); StreamData data;
      IntPtr h = FindFirstStreamW(path, 0, out data, 0);
      if (h == new IntPtr(-1)) { if (Marshal.GetLastWin32Error()==38) return names.ToArray(); throw new InvalidOperationException("Stream enumeration failed"); }
      try {
        do {
          if (data.Name != "::$DATA") { if (!data.Name.EndsWith(":$DATA",StringComparison.Ordinal)) throw new InvalidOperationException("Unsupported stream type"); names.Add(data.Name); }
        } while (FindNextStreamW(h, out data));
        if (Marshal.GetLastWin32Error()!=38) throw new InvalidOperationException("Incomplete stream enumeration");
      } finally { FindClose(h); }
      names.Sort(StringComparer.Ordinal); return names.ToArray();
    }
    public static void ValidateMetadata(string path, bool directory) {
      using (var h = CreateFileW(path, 0x88, 7, IntPtr.Zero, 3, 0x02000000, IntPtr.Zero)) {
        if (h.IsInvalid) throw new InvalidOperationException("Metadata handle refused");
        Info info; if (!GetFileInformationByHandle(h,out info)) throw new InvalidOperationException("Metadata query failed");
        if (!directory && info.Links!=1) throw new InvalidOperationException("Hard-linked file unsupported");
        IoStatus io; uint ea; if (NtQueryInformationFile(h,out io,out ea,4,7)!=0) throw new InvalidOperationException("Extended attributes query failed");
        if (ea!=0) throw new InvalidOperationException("Extended attributes unsupported");
      }
    }
    public static System.IO.FileStream OpenStream(string path, bool write) {
      var h=CreateFileW(path,write?0x40000000u:0x80000000u,write?0u:1u,IntPtr.Zero,write?1u:3u,0x02000000,IntPtr.Zero);
      if (h.IsInvalid) { h.Dispose(); throw new InvalidOperationException("Data stream handle refused"); }
      try { return new System.IO.FileStream(h,write?System.IO.FileAccess.Write:System.IO.FileAccess.Read); }
      catch { h.Dispose(); throw; }
    }
  }
}
'@ | Out-Null
    } finally {
        $env:TEMP = $oldTemp; $env:TMP = $oldTmp
        # Only this invocation's canonical, task-scoped compiler directory is removed.
        $checked = Assert-BackupPath $compiler
        if (!(Test-BackupWithin $checked $TempRoot)) { throw 'Compiler cleanup containment failed' }
        Remove-Item -LiteralPath $checked -Recurse -Force
    }
}
function Get-BackupHash([string]$Path) {
    $stream = [ZimaA1Backup.Native]::OpenStream($Path,$false)
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-','').ToLowerInvariant() }
    finally { $stream.Dispose(); $sha.Dispose() }
}
function Get-BackupDigest($Value) {
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return [BitConverter]::ToString($sha.ComputeHash($script:BackupUtf8.GetBytes(($Value | ConvertTo-Json -Depth 30 -Compress)))).Replace('-','').ToLowerInvariant() }
    finally { $sha.Dispose() }
}
function Get-BackupCategories([string]$Workspace) {
    $definitions = @(
        @('private','call-tracker/private','tree'), @('planning','call-tracker/.planning','tree'),
        @('device-evidence','drive-trace/artifacts/device-evidence','tree'),
        @('str-input','str-fixer/input','tree'), @('str-output','str-fixer/output','tree'),
        @('str-samples','str-fixer/samples','tree'), @('str-root-srt','str-fixer','root-srt')
    )
    return @($definitions | ForEach-Object { [pscustomobject]@{ id=$_[0]; path=(Join-Path $Workspace $_[1]); mode=$_[2] } })
}
function Get-BackupEntry([IO.FileSystemInfo]$Item,[string]$Relative,[bool]$Hash) {
    Assert-BackupPath $Item.FullName | Out-Null
    # Archive/readonly/hidden/system/normal/not-content-indexed and Directory are supported.
    $allowed = 1 -bor 2 -bor 4 -bor 16 -bor 32 -bor 128 -bor 8192
    if (([int]$Item.Attributes -band (-bnot $allowed)) -ne 0) { throw 'Unsupported file attributes (including sparse/compressed/encrypted/offline)' }
    $directory = $Item -is [IO.DirectoryInfo]
    [ZimaA1Backup.Native]::ValidateMetadata($Item.FullName,$directory)
    $streams = @()
    foreach ($name in [ZimaA1Backup.Native]::Streams($Item.FullName)) {
        $streamPath = $Item.FullName+$name
        $handle = [ZimaA1Backup.Native]::OpenStream($streamPath,$false)
        try { $length = $handle.Length } finally { $handle.Dispose() }
        $digest = $null; if ($Hash) { $digest = Get-BackupHash $streamPath }
        $streams += [pscustomobject][ordered]@{ name=$name; bytes=$length; sha256=$digest }
    }
    $digest = $null; $bytes = [long]0
    if (!$directory) { $bytes=$Item.Length; if ($Hash) { $digest=Get-BackupHash $Item.FullName } }
    $security = [Security.AccessControl.AccessControlSections]::Access -bor [Security.AccessControl.AccessControlSections]::Owner -bor [Security.AccessControl.AccessControlSections]::Group
    $acl = Get-Acl -LiteralPath $Item.FullName
    return [pscustomobject][ordered]@{
        relative=$Relative; directory=$directory; bytes=$bytes; sha256=$digest
        attributes=[int]$Item.Attributes; created_utc=$Item.CreationTimeUtc.Ticks; written_utc=$Item.LastWriteTimeUtc.Ticks
        streams=@($streams); original_owner_group_dacl=$acl.GetSecurityDescriptorSddlForm($security)
    }
}
function Get-BackupInventory($Categories,[bool]$Hash) {
    $result = @()
    foreach ($category in $Categories) {
        $path = Assert-BackupPath $category.path
        $entries = New-Object 'Collections.Generic.Dictionary[string,object]' ([StringComparer]::Ordinal)
        $status = 'ABSENT'
        if (Test-Path -LiteralPath $path) {
            $root = Get-Item -LiteralPath $path -Force
            if (!$root.PSIsContainer) { throw 'Expected source directory missing' }
            if ($category.mode -eq 'tree') {
                $queue = New-Object 'Collections.Generic.Queue[IO.DirectoryInfo]'; $queue.Enqueue($root)
                while ($queue.Count -gt 0) {
                    $dir = $queue.Dequeue()
                    $relative = '.'; if ($dir.FullName.Length -gt $path.Length) { $relative=$dir.FullName.Substring($path.Length+1) }
                    $entries.Add($relative,(Get-BackupEntry $dir $relative $Hash))
                    foreach ($item in Get-ChildItem -LiteralPath $dir.FullName -Force) {
                        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Source reparse point refused' }
                        if ($item.PSIsContainer) { $queue.Enqueue($item) }
                        else { $rel=$item.FullName.Substring($path.Length+1); $entries.Add($rel,(Get-BackupEntry $item $rel $Hash)) }
                    }
                }
            } else {
                foreach ($item in Get-ChildItem -LiteralPath $path -Force) {
                    if (!$item.PSIsContainer -and $item.Extension -ieq '.srt') { $entries.Add($item.Name,(Get-BackupEntry $item $item.Name $Hash)) }
                }
            }
            $status = 'EMPTY'
            if (@($entries.Values | Where-Object { !$_.directory -or @($_.streams).Count -gt 0 }).Count -gt 0) { $status='PRESENT' }
        }
        $keys = [string[]]@($entries.Keys); [Array]::Sort($keys,[StringComparer]::Ordinal)
        $result += [pscustomobject][ordered]@{ id=$category.id; mode=$category.mode; status=$status; entries=@($keys | ForEach-Object { $entries[$_] }) }
    }
    return $result
}
function Convert-BackupComparable($Inventory,[switch]$WithoutSecurity,[switch]$WithoutHashes) {
    return @($Inventory | ForEach-Object {
        $entries=@($_.entries | ForEach-Object {
            $entry=[ordered]@{relative=$_.relative;directory=$_.directory;bytes=$_.bytes;attributes=$_.attributes;created_utc=$_.created_utc;written_utc=$_.written_utc}
            if (!$WithoutHashes) { $entry.sha256=$_.sha256 }
            $entry.streams=@($_.streams | ForEach-Object { $s=[ordered]@{name=$_.name;bytes=$_.bytes}; if (!$WithoutHashes) { $s.sha256=$_.sha256 }; [pscustomobject]$s })
            if (!$WithoutSecurity) { $entry.original_owner_group_dacl=$_.original_owner_group_dacl }
            [pscustomobject]$entry
        })
        [pscustomobject][ordered]@{id=$_.id;mode=$_.mode;status=$_.status;entries=$entries}
    })
}
function New-BackupSecurity([string]$OwnerSid,[switch]$File) {
    $acl = New-Object Security.AccessControl.DirectorySecurity
    if ($File) { $acl = New-Object Security.AccessControl.FileSecurity }
    $owner = New-Object Security.Principal.SecurityIdentifier($OwnerSid)
    $acl.SetOwner($owner); $acl.SetAccessRuleProtection($true,$false)
    foreach ($sid in @($OwnerSid,'S-1-5-18','S-1-5-32-544') | Select-Object -Unique) {
        $identity=New-Object Security.Principal.SecurityIdentifier($sid)
        $rule=New-Object Security.AccessControl.FileSystemAccessRule($identity,'FullControl','ContainerInherit,ObjectInherit','None','Allow')
        if ($File) { $rule=New-Object Security.AccessControl.FileSystemAccessRule($identity,'FullControl','Allow') }
        $acl.AddAccessRule($rule)
    }
    return $acl
}
function Assert-BackupAcl([string]$Path,[string]$OwnerSid,[switch]$Root) {
    $acl=Get-Acl -LiteralPath $Path
    if ($Root -and (!$acl.AreAccessRulesProtected -or $acl.GetOwner([Security.Principal.SecurityIdentifier]).Value -ne $OwnerSid)) { throw 'Protected backup root ACL mismatch' }
    $rules=@($acl.GetAccessRules($true,$true,[Security.Principal.SecurityIdentifier]))
    $allowed=@($OwnerSid,'S-1-5-18','S-1-5-32-544') | Select-Object -Unique
    if ($rules.Count -ne $allowed.Count) { throw 'Backup ACL entry count mismatch' }
    foreach ($sid in $allowed) {
        $matches=@($rules | Where-Object { $_.IdentityReference.Value -eq $sid -and $_.AccessControlType -eq 'Allow' -and $_.FileSystemRights -eq 'FullControl' })
        if ($matches.Count -ne 1) { throw 'Backup ACL rights mismatch' }
    }
}
function Repair-BackupProtection([string]$Path,[string]$OwnerSid) {
    # Only called for this invocation's exclusively created run root, never for a
    # rejected existing destination or any source. Do not follow reparse children.
    $root=Assert-BackupPath $Path
    [IO.Directory]::SetAccessControl($root,(New-BackupSecurity $OwnerSid))
    Assert-BackupAcl $root $OwnerSid -Root
    $queue=New-Object 'Collections.Generic.Queue[string]'; $queue.Enqueue($root)
    while ($queue.Count) {
        $parent=$queue.Dequeue()
        foreach ($item in Get-ChildItem -LiteralPath $parent -Force) {
            $safe=Assert-BackupPath $item.FullName
            if (!(Test-BackupWithin $safe $root)) { throw 'Protection repair containment failed' }
            if ($item.PSIsContainer) { [IO.Directory]::SetAccessControl($safe,(New-BackupSecurity $OwnerSid)) }
            else { [IO.File]::SetAccessControl($safe,(New-BackupSecurity $OwnerSid -File)) }
            Assert-BackupAcl $safe $OwnerSid
            if ($item.PSIsContainer) { $queue.Enqueue($safe) }
        }
    }
}
function Write-BackupJson([string]$Path,$Value) {
    $bytes=$script:BackupUtf8.GetBytes(($Value | ConvertTo-Json -Depth 35)+"`n")
    $handle=New-Object IO.FileStream($Path,[IO.FileMode]::Create,[IO.FileAccess]::Write,[IO.FileShare]::Read)
    try { $handle.Write($bytes,0,$bytes.Length); $handle.Flush($true) } finally { $handle.Dispose() }
}
function Copy-BackupStream([string]$From,[string]$To) {
    $read=[ZimaA1Backup.Native]::OpenStream($From,$false)
    try {
        $write=[ZimaA1Backup.Native]::OpenStream($To,$true)
        try { $read.CopyTo($write); $write.Flush($true) } finally { $write.Dispose() }
    } finally { $read.Dispose() }
}
function Set-BackupMetadata([string]$Path,$Entry) {
    if ($Entry.directory) { [IO.Directory]::SetCreationTimeUtc($Path,(New-Object DateTime([long]$Entry.created_utc,[DateTimeKind]::Utc))); [IO.Directory]::SetLastWriteTimeUtc($Path,(New-Object DateTime([long]$Entry.written_utc,[DateTimeKind]::Utc))) }
    else { [IO.File]::SetCreationTimeUtc($Path,(New-Object DateTime([long]$Entry.created_utc,[DateTimeKind]::Utc))); [IO.File]::SetLastWriteTimeUtc($Path,(New-Object DateTime([long]$Entry.written_utc,[DateTimeKind]::Utc))) }
    [IO.File]::SetAttributes($Path,[IO.FileAttributes][int]$Entry.attributes)
}
function Invoke-BackupTransport([string]$From,[string]$To,[string]$Mode) {
    $options=@('/COPY:DAT','/DCOPY:DAT','/R:0','/W:0','/XJ','/NP','/NFL','/NDL','/NJH','/NJS')
    if ($Mode -eq 'tree') { $options+='/E' } else { $options+='*.srt' }
    # Source/destination are fixed category paths; no personal names enter argv or logs.
    $ErrorActionPreference='Continue'
    & robocopy $From $To @options 1>$null 2>$null
    $code=$LASTEXITCODE
    $ErrorActionPreference='Stop'
    if ($code -lt 0 -or $code -ge 8) { throw 'Copy transport failed' }
    return $code
}
function Invoke-ZimaBackup {
    [CmdletBinding()]
    param([string]$FixtureRoot,[string]$Failure='')
    $stage='PREFLIGHT'; $destination=$null; $evidence=$null; $receipt=$null; $created=$false
    try {
        $repo=Assert-BackupPath $script:BackupRepoRoot
        $fixture = !!$FixtureRoot
        if ($fixture) {
            $fixture=Assert-BackupPath $FixtureRoot
            $parent=Assert-BackupPath (Join-Path $repo '.agent-tmp/a1-backup')
            if ([IO.Path]::GetDirectoryName($fixture) -ine $parent -or [IO.Path]::GetFileName($fixture) -cnotmatch '^fixture-[0-9a-f]{32}$' -or !(Test-Path -LiteralPath $fixture -PathType Container)) { throw 'Synthetic fixture path refused' }
            $workspace=Join-Path $fixture 'source'; $destination=Join-Path $fixture 'external/backup'; $evidence=Join-Path $fixture 'evidence'
            $ownerSid=[Security.Principal.WindowsIdentity]::GetCurrent().User.Value
            $tempRoot=$fixture
        } else {
            if ($Failure) { throw 'Fault injection is fixture-only' }
            if ($repo -ine 'C:\Users\mertp\Desktop\projects\zima') { throw 'Production repository path mismatch' }
            $workspace='C:\Users\mertp\Desktop\projects'; $destination='D:\projects\zima\backups\pre-cutover-2026-10-20'
            $evidence=Join-Path $repo ('.local-state/migration/backup-'+[guid]::NewGuid().ToString('N'))
            $ownerSid=(New-Object Security.Principal.NTAccount('Zima\mertp')).Translate([Security.Principal.SecurityIdentifier]).Value
            $actualOwner=(Get-Acl -LiteralPath $workspace).GetOwner([Security.Principal.SecurityIdentifier]).Value
            if ($actualOwner -ne $ownerSid -or [Security.Principal.WindowsIdentity]::GetCurrent().User.Value -ne $ownerSid) { throw 'Production backup must run as the approved workspace owner' }
            $tempRoot=Join-Path $repo '.agent-tmp/a1-backup'
        }
        $workspace=Assert-BackupPath $workspace; $destination=Assert-BackupPath $destination; $evidence=Assert-BackupPath $evidence
        if (!(Test-Path -LiteralPath $workspace -PathType Container)) { throw 'Workspace source missing' }
        if ((Test-BackupWithin $destination $workspace) -or (Test-BackupWithin $workspace $destination)) { throw 'Source/destination overlap refused' }
        if (Test-Path -LiteralPath $destination) { throw 'Existing backup destination refused (empty or nonempty)' }
        if (Test-Path -LiteralPath $evidence) { throw 'Existing evidence destination refused' }
        $disk=New-Object IO.DriveInfo([IO.Path]::GetPathRoot($destination))
        if ($disk.DriveFormat -ne 'NTFS' -or !$disk.IsReady) { throw 'Ready NTFS destination required' }
        foreach ($name in @('emulator','qemu-system-x86_64','qemu-system-aarch64')) { if (Get-Process -Name $name -ErrorAction SilentlyContinue) { throw 'Running emulator blocks consistent backup' } }
        if ($Failure -eq 'Emulator') { throw 'Running emulator blocks consistent backup' }
        foreach ($member in @('call-tracker','drive-trace','str-fixer')) {
            $memberRoot=Assert-BackupPath (Join-Path $workspace $member)
            if (!(Test-Path -LiteralPath $memberRoot -PathType Container)) { throw 'Irreplaceable member root missing' }
        }
        Assert-BackupPath $tempRoot | Out-Null
        [IO.Directory]::CreateDirectory($tempRoot) | Out-Null
        Initialize-BackupNative $tempRoot
        $categories=Get-BackupCategories $workspace
        # Metadata/size preflight happens before hashing large files or creating a backup.
        $metadata=@(Get-BackupInventory $categories $false)
        $criticalIds=@('private','planning','device-evidence','str-input','str-output')
        $criticalUnavailable=@($metadata | Where-Object { $_.id -in $criticalIds -and $_.status -ne 'PRESENT' } | ForEach-Object { $_.id })
        $all=@($metadata | ForEach-Object { $_.entries })
        $total=[long]0; $largest=[long]0
        foreach ($entry in $all) {
            $size=[long]$entry.bytes; foreach ($stream in $entry.streams) { $size += [long]$stream.bytes }
            $total += $size; if ($size -gt $largest) { $largest=$size }
        }
        $margin=[long][Math]::Max(1GB,[Math]::Ceiling($total*0.10)); $required=$total+$largest+$margin
        $free=[long]$disk.AvailableFreeSpace; if ($Failure -eq 'LowSpace') { $free=0 }
        if ($free -lt $required) { throw 'Insufficient destination capacity' }
        $stage='SOURCE_HASHES'
        $before=@(Get-BackupInventory $categories $true)
        if ((Get-BackupDigest (Convert-BackupComparable $before -WithoutHashes)) -ne (Get-BackupDigest (Convert-BackupComparable $metadata -WithoutHashes))) { throw 'Source changed during preflight' }
        $security=New-BackupSecurity $ownerSid
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination)) | Out-Null
        Assert-BackupPath $destination | Out-Null
        if ($Failure -eq 'DestinationRace') {
            [IO.Directory]::CreateDirectory($destination,$security) | Out-Null
            [IO.File]::WriteAllText((Join-Path $destination 'unknown-owner-marker'),'synthetic existing target')
        }
        # The private root is created atomically with its restrictive DACL, before data.
        # CreateDirectoryW fails if a competing actor created it since preflight.
        [ZimaA1Backup.Native]::CreateExclusiveDirectory($destination,$security.GetSecurityDescriptorBinaryForm())
        $created=$true
        Assert-BackupAcl $destination $ownerSid -Root
        [ZimaA1Backup.Native]::CreateExclusiveDirectory($evidence,$security.GetSecurityDescriptorBinaryForm())
        Assert-BackupAcl $evidence $ownerSid -Root
        $receipt=[ordered]@{schema=1; run_id=[guid]::NewGuid().ToString('N'); timestamp_utc=[DateTime]::UtcNow.ToString('o');state='PREPARED';source=$workspace;destination=$destination;script_copy_only=($Failure -ne 'SourceChange');source_stability='PENDING';source_stable_verified=$false;integrity_verified=$false;protection='VERIFIED';cutover_authorized=$false;capacity=[ordered]@{free_bytes=$free;required_bytes=$required;source_bytes=$total;largest_restore_bytes=$largest;margin_bytes=$margin};metadata_policy='Content + all DATA streams + DOS attributes + creation/write times; original owner/group/DACL recorded privately; backup ACL hardened. Last-access/SACL/object IDs/USN excluded. Reparse/sparse/compressed/encrypted/offline/hard-links/EA refused.';categories=@();error_stage=$null;failure_code=$null}
        $receipt['critical_categories_unavailable']=$criticalUnavailable
        Write-BackupJson (Join-Path $destination 'source-before.json') $before
        Write-BackupJson (Join-Path $destination 'receipt.json') $receipt
        Write-BackupJson (Join-Path $evidence 'receipt.json') $receipt
        $stage='COPY'
        $copyCodes=@()
        foreach ($category in $categories) {
            $inventory=@($before | Where-Object { $_.id -eq $category.id })[0]
            if ($inventory.status -eq 'ABSENT') { continue }
            $target=Join-Path $destination ('data/'+$category.id)
            [IO.Directory]::CreateDirectory($target) | Out-Null
            if ($Failure -eq 'CopyFailure') {
                # Exercise actual robocopy >=8 propagation in the synthetic lane.
                Invoke-BackupTransport (Join-Path $FixtureRoot 'missing-source') $target $category.mode | Out-Null
                throw 'Fixture transport unexpectedly succeeded'
            }
            $copyCodes += [pscustomobject]@{category=$category.id;exit_code=(Invoke-BackupTransport $category.path $target $category.mode)}
            # Directory ADS are explicitly copied; robocopy's directory stream behavior
            # is not trusted. File ADS are copied by /COPY:DAT and independently hashed.
            foreach ($entry in @($inventory.entries | Where-Object { $_.directory })) {
                $sourceDir=$category.path; $targetDir=$target
                if ($entry.relative -ne '.') { $sourceDir=Join-Path $sourceDir $entry.relative; $targetDir=Join-Path $targetDir $entry.relative }
                foreach ($stream in $entry.streams) {
                    if (@([ZimaA1Backup.Native]::Streams($targetDir)) -ccontains $stream.name) {
                        if ((Get-BackupHash ($sourceDir+$stream.name)) -ne (Get-BackupHash ($targetDir+$stream.name))) { throw 'Copied directory stream mismatch' }
                    } else { Copy-BackupStream ($sourceDir+$stream.name) ($targetDir+$stream.name) }
                }
            }
            # Restore directory timestamps only after all children/streams are complete.
            $dirs=@($inventory.entries | Where-Object { $_.directory } | Sort-Object { $_.relative.Length } -Descending)
            foreach ($entry in $dirs) { $at=$target; if ($entry.relative -ne '.') { $at=Join-Path $at $entry.relative }; Set-BackupMetadata $at $entry }
        }
        if ($Failure -eq 'SourceChange') { [IO.File]::AppendAllText((Join-Path $workspace 'call-tracker/private/state.img'),'fixture-change') }
        if ($Failure -eq 'BackupCorruption') { [IO.File]::AppendAllText((Join-Path $destination 'data/private/state.img'),'fixture-corruption') }
        if ($Failure -eq 'WeakAcl') { $acl=Get-Acl -LiteralPath $destination; $everyone=New-Object Security.Principal.SecurityIdentifier('S-1-1-0'); $acl.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule($everyone,'FullControl','ContainerInherit,ObjectInherit','None','Allow'))); [IO.Directory]::SetAccessControl($destination,$acl) }
        $stage='COPY_VERIFICATION'
        $backupCategories=@($categories | ForEach-Object { [pscustomobject]@{id=$_.id;mode=$_.mode;path=(Join-Path $destination ('data/'+$_.id))} })
        # Every selected source entry, empty directory and ADS must exist exactly once.
        $copied=@(Get-BackupInventory $backupCategories $true)
        if ((Get-BackupDigest (Convert-BackupComparable $before -WithoutSecurity)) -ne (Get-BackupDigest (Convert-BackupComparable $copied -WithoutSecurity))) { throw 'Full backup inventory mismatch' }
        foreach ($item in @(Get-Item -LiteralPath $destination -Force)+@(Get-ChildItem -LiteralPath $destination -Force -Recurse)) { Assert-BackupPath $item.FullName | Out-Null; Assert-BackupAcl $item.FullName $ownerSid -Root:($item.FullName -eq $destination) }
        $stage='RESTORE'
        $restoreRoot=Join-Path $destination '.restore-check'; [IO.Directory]::CreateDirectory($restoreRoot) | Out-Null
        $summary=@()
        foreach ($category in $before) {
            $files=@($category.entries | Where-Object { !$_.directory })
            $samples=@(); $restores=@(); $signing='NOT_APPLICABLE'; $avd='NOT_APPLICABLE'
            if ($files.Count -gt 0) { $samples += [pscustomobject]@{kind='representative';entry=@($files | Sort-Object bytes -Descending)[0]} }
            $namedFiles=@($files | Where-Object { @($_.streams).Count -gt 0 } | Sort-Object bytes -Descending)
            if ($namedFiles.Count) { $samples += [pscustomobject]@{kind='named-stream-file';entry=$namedFiles[0]} }
            $namedDirs=@($category.entries | Where-Object { $_.directory -and @($_.streams).Count -gt 0 })
            if ($namedDirs.Count) { $samples += [pscustomobject]@{kind='named-stream-directory';entry=$namedDirs[0]} }
            if ($category.id -eq 'private') {
                $images=@($files | Where-Object { $_.relative -match '(?i)\.(img|qcow2|vmdk|vdi|vhd|vhdx)$' } | Sort-Object bytes -Descending)
                $keys=@($files | Where-Object { $_.relative -match '(?i)\.(jks|keystore|p12|pfx|pkcs12|pk8|pem|key|der)$' } | Sort-Object bytes -Descending)
                $avd='ABSENT'; $signing='ABSENT'
                if ($images.Count) { $avd='PRESENT'; $samples += [pscustomobject]@{kind='largest-avd-image';entry=$images[0]} }
                if ($keys.Count) { $signing='PRESENT'; $samples += [pscustomobject]@{kind='signing-artifact';entry=$keys[0]} }
            }
            $verifiedSamples=@{}
            foreach ($sample in $samples) {
                $entry=$sample.entry; $from=Join-Path $destination ('data/'+$category.id)
                if ($verifiedSamples.ContainsKey($entry.relative)) {
                    # The representative and largest AVD may be the same file; one
                    # physical restore proves both roles without redundant large I/O.
                    $restores += [pscustomobject]@{kind=$sample.kind;sha256=$entry.sha256;streams=@($entry.streams).Count;result='MATCH'}
                    continue
                }
                if ($entry.relative -ne '.') { $from=Join-Path $from $entry.relative }
                $to=Join-Path $restoreRoot 'sample'
                if ($entry.directory) { [IO.Directory]::CreateDirectory($to) | Out-Null } else { Copy-BackupStream $from $to }
                foreach ($stream in $entry.streams) { Copy-BackupStream ($from+$stream.name) ($to+$stream.name) }
                Set-BackupMetadata $to $entry
                if ($Failure -eq 'RestoreCorruption' -and !$entry.directory) { [IO.File]::AppendAllText($to,'fixture-corruption') }
                $restored=Get-BackupEntry (Get-Item -LiteralPath $to -Force) $entry.relative $true
                $a=@([pscustomobject]@{id='sample';mode='tree';status='PRESENT';entries=@($entry)})
                $b=@([pscustomobject]@{id='sample';mode='tree';status='PRESENT';entries=@($restored)})
                if ((Get-BackupDigest (Convert-BackupComparable $a -WithoutSecurity)) -ne (Get-BackupDigest (Convert-BackupComparable $b -WithoutSecurity))) { throw 'Restore sample mismatch' }
                Assert-BackupAcl $to $ownerSid
                $restores += [pscustomobject]@{kind=$sample.kind;sha256=$entry.sha256;streams=@($entry.streams).Count;result='MATCH'}
                $verifiedSamples[$entry.relative]=$true
                # Only the just-created, verified isolated sample is removed. Backup
                # data and every source remain untouched. Peak restore space = largest.
                $safe=Assert-BackupPath $to
                if (!(Test-BackupWithin $safe $restoreRoot)) { throw 'Restore cleanup containment failed' }
                [IO.File]::SetAttributes($safe,[IO.FileAttributes]::Normal)
                if ($entry.directory) { [IO.Directory]::Delete($safe) } else { [IO.File]::Delete($safe) }
            }
            $bytes=[long]0; $streamBytes=[long]0; $streamCount=0
            foreach ($entry in $category.entries) { $bytes += [long]$entry.bytes; foreach ($stream in $entry.streams) { $streamBytes += [long]$stream.bytes; $streamCount++ } }
            $summary += [pscustomobject][ordered]@{category=$category.id;status=$category.status;files=$files.Count;directories=@($category.entries|Where-Object {$_.directory}).Count;bytes=$bytes;streams=$streamCount;stream_bytes=$streamBytes;inventory_sha256=(Get-BackupDigest (Convert-BackupComparable @($category) -WithoutSecurity));restore=@($restores);avd_image=$avd;signing_artifact=$signing}
        }
        [IO.Directory]::Delete($restoreRoot)
        $stage='SOURCE_RECHECK'
        $after=@(Get-BackupInventory $categories $true)
        if ((Get-BackupDigest (Convert-BackupComparable $before)) -ne (Get-BackupDigest (Convert-BackupComparable $after))) { $receipt.source_stability='MISMATCH'; throw 'Source changed during backup' }
        $receipt.source_stability='MATCH'; $receipt.source_stable_verified=$true
        # Rehash destination after restore and immediately before final evidence.
        $final=@(Get-BackupInventory $backupCategories $true)
        if ((Get-BackupDigest (Convert-BackupComparable $before -WithoutSecurity)) -ne (Get-BackupDigest (Convert-BackupComparable $final -WithoutSecurity))) { throw 'Final backup inventory mismatch' }
        Write-BackupJson (Join-Path $destination 'inventory.json') ([ordered]@{source_before=$before;source_after=$after;backup=$final})
        Assert-BackupAcl (Join-Path $destination 'inventory.json') $ownerSid
        Assert-BackupAcl (Join-Path $destination 'source-before.json') $ownerSid
        $receipt.categories=$summary; $receipt.state='VERIFIED'; $receipt.integrity_verified=$true; $receipt.source_stable_verified=$true
        $receipt['copy_exit_codes']=$copyCodes
        $receipt['inventory_sha256']=Get-BackupHash (Join-Path $destination 'inventory.json')
        $receipt['readiness']='REQUIRES_SEPARATE_A2_GATES'
        if ($criticalUnavailable.Count) { $receipt.readiness='BLOCKED_MISSING_CRITICAL_CATEGORY' }
        $receipt['retention']='Retain until Faz B completes; no automated deletion'
        $receipt.timestamp_utc=[DateTime]::UtcNow.ToString('o')
        Write-BackupJson (Join-Path $destination 'receipt.json') $receipt
        Write-BackupJson (Join-Path $evidence 'receipt.json') $receipt
        Assert-BackupAcl (Join-Path $destination 'receipt.json') $ownerSid
        Assert-BackupAcl (Join-Path $evidence 'receipt.json') $ownerSid
        return [pscustomobject]$receipt
    } catch {
        # Never forward native exception text: it can contain private relative paths.
        $nativeFailure=$_
        $safeCode='IO_OR_METADATA_FAILURE'
        $reasons=[ordered]@{
            'Unsupported file attributes'='UNSUPPORTED_ATTRIBUTES'; 'Hard-linked file unsupported'='UNSUPPORTED_HARDLINK'
            'Extended attributes unsupported'='UNSUPPORTED_EA'; 'Reparse'='REPARSE_REFUSED'
            'Existing backup destination refused'='DESTINATION_EXISTS'; 'Exclusive destination already exists'='DESTINATION_RACE'
            'Insufficient destination capacity'='INSUFFICIENT_CAPACITY'; 'Running emulator'='EMULATOR_RUNNING'
            'Copy transport failed'='COPY_TRANSPORT_FAILURE'; 'inventory mismatch'='INVENTORY_MISMATCH'; 'Source changed'='SOURCE_CHANGED'
            'Restore sample mismatch'='RESTORE_MISMATCH'; 'ACL'='ACL_MISMATCH'; 'approved workspace owner'='WRONG_EXECUTION_OWNER'
            'fixture path refused'='FIXTURE_SCOPE_REFUSED'; 'fixture-only'='FIXTURE_ONLY_OPERATION'
            'Irreplaceable member root missing'='IRREPLACEABLE_MEMBER_MISSING'
        }
        foreach ($reason in $reasons.Keys) { if ($nativeFailure.Exception.Message.IndexOf($reason,[StringComparison]::OrdinalIgnoreCase) -ge 0) { $safeCode=$reasons[$reason]; break } }
        $protection='NOT_CREATED'
        if ($created) {
            $protection='UNKNOWN'
            try { Repair-BackupProtection $destination $ownerSid; $protection='VERIFIED' }
            catch { if ($safeCode -eq 'ACL_MISMATCH') { $protection='FAILED' } }
        }
        if ($created -and $receipt) {
            $receipt.state='FAILED'; $receipt.integrity_verified=$false; $receipt.protection=$protection; $receipt.error_stage=$stage; $receipt.failure_code=$safeCode; $receipt.timestamp_utc=[DateTime]::UtcNow.ToString('o')
            try { Write-BackupJson (Join-Path $destination 'receipt.json') $receipt; Write-BackupJson (Join-Path $evidence 'receipt.json') $receipt } catch { }
        }
        throw ('ZIMA_BACKUP_FAILED stage='+$stage+' code='+$safeCode+' protection='+$protection+'; partial copy retained if created')
    }
}

# Dot-sourcing defines the isolated-test API without starting any operation.
if ($MyInvocation.InvocationName -ne '.') {
    if (!$Execute -and !$FixtureRoot) { Write-Output 'Use -Execute for the approved fixed production backup, or -FixtureRoot for an isolated synthetic test.'; exit 0 }
    if ($Execute -and $FixtureRoot) { Write-Error 'Production and fixture modes are mutually exclusive'; exit 1 }
    try { $result=Invoke-ZimaBackup -FixtureRoot $FixtureRoot -Failure $FixtureFailure; $result | ConvertTo-Json -Depth 20; if (@($result.critical_categories_unavailable).Count) { exit 2 }; exit 0 }
    catch { Write-Output $_.Exception.Message; exit 1 }
}
