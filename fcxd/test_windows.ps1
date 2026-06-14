# Integration smoke test: feed NUL-delimited requests, check the responses.
$ErrorActionPreference = "Stop"
$dir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $dir
$exe = "zig-out\bin\FullControlX.exe"
if (-not (Test-Path $exe)) { throw "build first with: zig build" }

# system_info only: works headless, still exercises multi-request framing.
$requests = @(
    '[1,"system_info"]',
    '[2,"system_info"]'
)

$bytes = New-Object System.Collections.Generic.List[byte]
foreach ($r in $requests) {
    $bytes.AddRange([System.Text.Encoding]::UTF8.GetBytes($r))
    $bytes.Add(0)  # NUL frame terminator
}
[System.IO.File]::WriteAllBytes("$dir\_in.bin", $bytes.ToArray())

cmd /c "$exe < _in.bin > _out.bin"

$out = [System.Text.Encoding]::UTF8.GetString([System.IO.File]::ReadAllBytes("$dir\_out.bin"))
$responses = $out.Split([char]0) | Where-Object { $_ -ne '' }
Remove-Item "$dir\_in.bin", "$dir\_out.bin" -ErrorAction SilentlyContinue

if ($responses.Count -ne $requests.Count) {
    throw "expected $($requests.Count) responses, got $($responses.Count)"
}
foreach ($resp in $responses) {
    $obj = $resp | ConvertFrom-Json
    if ($null -ne $obj.error) { throw "request $($obj.id) failed: $($obj.error)" }
}
Write-Host "OK: $($responses.Count) responses, no errors"
