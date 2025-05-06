param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$SourceFile,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string[]]$ClassFiles,

    [string]$BaseDir = "tmp",

    [string]$OutputDir = "coverage",

    [string]$JaCoCoPath = "jacococli.jar"
)

Write-Host "SourceFile = $SourceFile"
Write-Host "ClassFiles = $ClassFiles"
Write-Host "BaseDir = $BaseDir"
Write-Host "OutputDir = $OutputDir"


$Files = Get-ChildItem -Path $BaseDir -Include *.ec -Recurse | Select-Object -ExpandProperty FullName

$classFilesArgs = @()
foreach ($cf in $ClassFiles) {
    $classFilesArgs += "--classfiles"
    $classFilesArgs += $cf
}

$merged = "$BaseDir/merged.ec"


for ($i = 0; $i -lt $Files.Count; $i++) {
    $fileName = Get-ChildItem -Path $BaseDir -Filter "coverage.$i.*.ec" | Select-Object -ExpandProperty FullName

    if ($i -eq 0) {
        Copy-Item $fileName -Destination $merged
    }
    else {
        Remove-Item $merged
        $mergeArgs = @()
        for ($j = 0; $j -le $i; $j++) {
            $mergeArgs += $(Get-ChildItem -Path $BaseDir -Filter "coverage.$j.*.ec" | Select-Object -ExpandProperty FullName)
        }
        java -jar $JaCoCoPath merge @mergeArgs --destfile $merged
    }

    java -jar $JaCoCoPath report $merged `
        $classFilesArgs `
        --sourcefiles $SourceFile `
        --html "$OutputDir/coverage_report#$i#$($fileName.Split('.')[-2])" `
        --name "Coverage Report $i"
}

