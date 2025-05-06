param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$PackageName,

    [Int64]$SleepFor = 120,

    [String]$OutputDir = "tmp"
)

Start-Sleep -Seconds 60

$i = 0
while($true) {
    adb shell am broadcast -a test.DUMP_COVERAGE

    $eventCount = Get-Content "$OutputDir/../kea.log" | Select-String "Total event count:" | ForEach-Object { ($_ -match "Total event count: (\d+)") | Out-Null; [int]$matches[1] } | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum
    
    adb pull /data/user/0/$PackageName/files/coverage/coverage.ec $OutputDir/coverage.$i.$eventCount.ec

    if ($LASTEXITCODE -ne 0) {
        $i--
    }

    $i++

    Start-Sleep -Seconds $SleepFor
}