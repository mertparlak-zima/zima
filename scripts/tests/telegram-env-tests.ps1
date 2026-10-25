# Targeted Telegram .env/index contract. Synthetic files and Git only; no real .env.
$ErrorActionPreference='Stop'
$root=(Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
$env:ZIMA_DOT_SOURCED='1';. (Join-Path $root 'scripts/zima.ps1');$env:ZIMA_DOT_SOURCED=$null
$script:Count=0;$script:Failures=0
function Assert-Telegram([bool]$Ok,[string]$Name){$script:Count++;if($Ok){Write-Host ('PASS '+$Name)}else{$script:Failures++;Write-Host ('FAIL '+$Name)}}
function Full-EnvErrors { $v=Invoke-ZimaVerify -Mode full -ZimaRoot $tree;return @($v.Errors|Where-Object{$_ -match '^\.env:|Duplicate \.env key'}) }
function Fixture-Git([string[]]$Arguments){$r=Invoke-ZimaGitRaw (@('-C',$tree)+$Arguments);if($r.Code -ne 0){throw 'Synthetic Git command failed'};return $r}
$rel='.agent-tmp/telegram-send-only-2026-10-25/tests-'+[guid]::NewGuid().ToString('N')
$tree=Get-ZimaSafePath $root $rel
try{
 $null=New-Item -ItemType Directory -Path $tree
 foreach($dir in @('projects','docs','repos')){$null=New-Item -ItemType Directory -Path (Join-Path $tree $dir)}
 foreach($name in @('.gitignore','.ignore','.gitattributes','repos.schema.json')){Copy-Item -LiteralPath (Join-Path $root $name) -Destination (Join-Path $tree $name)}
 Write-Utf8NoBom (Join-Path $tree 'README.md') 'Synthetic Telegram configuration fixture.'
 Write-Utf8NoBom (Join-Path $tree 'AGENTS.md') 'Synthetic fixture only.'
 Write-Utf8NoBom (Join-Path $tree 'docs/README.md') 'Synthetic generated-doc fixture.'
 Write-Utf8NoBom (Join-Path $tree 'docs/runners.md') "<!-- BEGIN GENERATED RUNNER REGISTRY -->`n<!-- END GENERATED RUNNER REGISTRY -->"
 Write-Utf8NoBom (Join-Path $tree 'repos.json') '{"version":1,"org":"fixture","defaults":{"owner_type":"ours","branch":"main"},"repos":[],"third_party":[]}'
 $null=Fixture-Git @('init','--quiet')
 # No credential-shaped literals enter committed test sources.
 $token=([string](123456+1))+':'+('x'*35);$chat=[string](987654+1)
 $valid="TELEGRAM_BOT_TOKEN=$token`nTELEGRAM_CHAT_ID=$chat`nZIMA_LOCALE=en-US`n"
 [IO.File]::WriteAllText((Join-Path $tree '.env'),$valid,(New-Object Text.UTF8Encoding($true)))
 $map=Read-ZimaEnv $tree
 Assert-Telegram ($map['TELEGRAM_BOT_TOKEN'] -ceq '' -and $map['TELEGRAM_CHAT_ID'] -ceq '' -and $map['ZIMA_LOCALE'] -ceq 'en-US') 'configuration map redacts both credentials and retains ordinary config'
 Assert-Telegram (($map|ConvertTo-Json -Compress) -notmatch [regex]::Escape($token) -and ($map|ConvertTo-Json -Compress) -notmatch [regex]::Escape($chat)) 'serialized CLI config contains no token or chat'
 Assert-Telegram (@(Full-EnvErrors).Count -eq 0) 'Full accepts only the selected local Telegram credentials'
 foreach($duplicate in @("$valid`ntelegram_bot_token=", "$valid`ntelegram_chat_id=")){
  Write-Utf8NoBom (Join-Path $tree '.env') $duplicate
  $rejected=$false;try{Read-ZimaEnv $tree|Out-Null}catch{$rejected=$_.Exception.Message -ceq 'Duplicate .env key (contents withheld)'}
  Assert-Telegram $rejected 'case-insensitive duplicate selected key is refused before redaction can hide it'
  Assert-Telegram (@(Full-EnvErrors).Count -eq 1) 'Full still reports duplicate selected keys'
 }
 foreach($line in @('GH_TOKEN=fixture','OTHER_SECRET=fixture','TELEGRAM_BOT_TOKEN_OTHER=fixture',('ORDINARY='+$token))){
  Write-Utf8NoBom (Join-Path $tree '.env') ($valid+$line+"`n")
  Assert-Telegram (@(Full-EnvErrors).Count -eq 1) 'unselected credential keys and secret-shaped ordinary values remain forbidden'
 }
 Write-Utf8NoBom (Join-Path $tree '.env') $valid
 Write-Utf8NoBom (Join-Path $tree 'notice.md') ('TELEGRAM_BOT_TOKEN='+$token)
 $null=Fixture-Git @('add','--','notice.md')
 Write-Utf8NoBom (Join-Path $tree 'notice.md') 'Safe working copy differs from indexed bytes.'
 $scan=Test-ZimaIndex $tree
 Assert-Telegram (@($scan.Errors|Where-Object{$_ -match 'secret-shaped'}).Count -eq 1) 'indexed Telegram value remains forbidden even with safe working copy'
 Assert-Telegram (($scan.Errors -join ' ') -notmatch [regex]::Escape($token)) 'index diagnostics redact secret values'
 $null=Fixture-Git @('add','-f','--','.env')
 $scan=Test-ZimaIndex $tree
 Assert-Telegram (@($scan.Errors|Where-Object{$_ -match 'prohibited local/member path'}).Count -eq 1) 'force-added local env remains forbidden in the index'
 $bytes=[IO.File]::ReadAllBytes((Join-Path $root 'scripts/zima.ps1'))
 $text=[Text.Encoding]::UTF8.GetString($bytes)
 Assert-Telegram ($bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191 -and !$text.Replace("`r`n",'').Contains("`n")) 'existing CLI preserves UTF-8 BOM and CRLF'
}catch{$script:Failures++;Write-Host 'FAIL unexpected fixture error (details withheld)'}
finally{
 $summaryPath=Get-ZimaSafePath $root '.agent-tmp/telegram-send-only-2026-10-25/env-test-summary.txt'
 $null=New-Item -ItemType Directory -Force -Path ([IO.Path]::GetDirectoryName($summaryPath))
 $summary="Assertions: $script:Count`nFailures: $script:Failures`nFixture: $rel`n"
 Write-Utf8NoBom $summaryPath $summary
 if(Test-Path -LiteralPath $tree){$checked=Get-ZimaSafePath $root $rel;Remove-Item -LiteralPath $checked -Recurse -Force}
}
Write-Host $summary
if($script:Failures){exit 1};exit 0
