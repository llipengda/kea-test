param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$AvdName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ApkPath,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$SourceFile,
    
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string[]]$ClassFiles,

    [Int32]$Times = 1,

    [Int64]$TimeOut = 14400,
    
    [string]$Policy = "random",

    [Int64]$Port = 5554,

    [bool]$Headless = $true,

    [Int64]$Limit = 1000000000,
    
    [string]$OutputDir # init later
)



function WaitForDevice {
    param (
        [string]$DeviceName
    )

    function GetBootAnimStatus {
        param (
            [string]$DeviceName
        )
        $bootAnimStatus = & adb -s $DeviceName shell getprop init.svc.bootanim | Out-String
        return $bootAnimStatus.Trim()
    }

    Write-Host "Waiting for device $DeviceName to be ready..."

    & adb -s $DeviceName wait-for-device

    $bootAnimStatus = GetBootAnimStatus -DeviceName $DeviceName
    $i = 0

    while ($bootAnimStatus -ne "stopped") {
        Write-Host "   Waiting for emulator ($DeviceName) to fully boot (#$i Times) ..."
        Start-Sleep -Seconds 5
        $i++

        if ($i -eq 20) {
            Write-Host "Cannot connect to the device: ($DeviceName) after (#$i Times)..."
            exit -1
        }

        $bootAnimStatus = GetBootAnimStatus -DeviceName $DeviceName
    }

    if ($bootAnimStatus -eq "stopped") {
        Write-Host "Device $DeviceName is fully booted."
    }
}

$apkPackageName = & aapt dump badging $ApkPath
$apkPackageName = $apkPackageName.Split("'")[1]

$emulatorArgs = @(
    "-port", $Port,
    "-avd", $AvdName,
    "-read-only"
)

if ($Headless) {
    $emulatorArgs += "-no-window"
}

Write-Host "APK Package Name: #$apkPackageName#" -ForegroundColor Green

$t = 0

while ($t -lt $Times) {
    if (-not $OutputDir) {
        $OutputDir = "output/$apkPackageName/$(Get-Date -Format "yyyy-MM-ddTHH.mm.ss")"
    }

    mkdir $OutputDir -Force
    mkdir $OutputDir/tmp -Force
    
    $deviceName = "emulator-$Port"        

    $emulatorProcess = Start-Process -FilePath "emulator" -ArgumentList $emulatorArgs -NoNewWindow -RedirectStandardOutput "$OutputDir/emulator.log" -RedirectStandardError "$OutputDir/emulator.err.log" -PassThru 

    WaitForDevice -DeviceName $deviceName

    adb -s $deviceName root

    $logcatProcess = Start-Process -FilePath "adb" -ArgumentList "-s $deviceName logcat" -NoNewWindow -PassThru -RedirectStandardOutput "$OutputDir/logcat.log" -RedirectStandardError "$OutputDir/logcat.err.log"

    Write-Host "Logcat process started."

    $dumpProcess = Start-Process -FilePath "pwsh" -ArgumentList "dump.ps1 -PackageName $apkPackageName -OutputDir $OutputDir/tmp" -NoNewWindow -PassThru -RedirectStandardOutput "$OutputDir/dump.log" -RedirectStandardError "$OutputDir/dump.err.log"

    Write-Host "Dump process started."

    Write-Host "Starting kea at $(Get-Date -Format "yyyy-MM-ddTHH:mm:ss")"

    kea -d $deviceName -a $ApkPath -o $OutputDir/kea -t $TimeOut -grant_perm -is_emulator -disable_rotate -p $Policy -f fake.py -utg --limit $Limit 2>&1 | tee -FilePath $OutputDir/kea.log

    Write-Host "Kea process finished at $(Get-Date -Format "yyyy-MM-ddTHH:mm:ss")"

    Write-Host "Cleaning up processes..."

    if ($DumpProcess) {
        Write-Host "Stopping dump process..."
        try { Stop-Process -Id $DumpProcess.Id -Force } catch {}
    }
    if ($LogcatProcess) {
        Write-Host "Stopping logcat process..."
        try { Stop-Process -Id $LogcatProcess.Id -Force } catch {}
    }
    if ($EmulatorProcess) {
        Write-Host "Stopping emulator process..."
        try { Stop-Process -Id $EmulatorProcess.Id -Force } catch {}
    }
    if ($DeviceName) {
        Write-Host "Stopping emulator $DeviceName..."
        try { adb -s $DeviceName emu kill } catch {}
    }

    if ($OutputDir) {
        try {
            Write-Host "Generating coverage report..."
            ./generate_coverage.ps1 -SourceFile $SourceFile -ClassFiles $ClassFiles -OutputDir "$OutputDir/coverage" -BaseDir "$OutputDir/tmp"
            Write-Host "Processing coverage report..."
            python process_coverage.py "$OutputDir/coverage"
        }
        catch {
            Write-Host "Coverage generation failed: $_" -ForegroundColor Red
        }
    }

    Write-Host "Cleanup and postprocessing complete."
    
    Start-Sleep -Seconds 5
    
    $OutputDir = $null
    
    $t++
}
