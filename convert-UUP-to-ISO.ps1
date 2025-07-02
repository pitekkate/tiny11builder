param(
    [string]$SourcePath,
    [string]$OutputPath,
    [string]$Edition
)

# Create ISO structure
$isoDir = Join-Path $SourcePath "ISO"
New-Item -ItemType Directory -Path $isoDir -Force

# Copy essential files
Copy-Item -Path "$SourcePath\*" -Destination $isoDir -Recurse -Exclude "*.cab"

# Process install.wim
$wimFile = Join-Path $SourcePath "install.wim"
if (-not (Test-Path $wimFile)) {
    # Find largest wim file if install.wim doesn't exist
    $wimFile = Get-ChildItem -Path $SourcePath -Filter *.wim | 
                Sort-Object Length -Descending | 
                Select-Object -First 1 -ExpandProperty FullName
}

if (-not $wimFile) {
    throw "No WIM file found!"
}

# Build ISO
$bootData = '2#p0,e,b"{0}\boot\etfsboot.com"#pEF,e,b"{0}\efi\microsoft\boot\efisys.bin"' -f $isoDir
Start-Process oscdimg.exe -ArgumentList @(
    "-m",
    "-o",
    "-u2",
    "-udfver102",
    "-bootdata:$bootData",
    $isoDir,
    $OutputPath
) -Wait -NoNewWindow -RedirectStandardOutput ".\oscdimg.log"

if (Test-Path $OutputPath)) {
    Write-Host "ISO created at $OutputPath"
} else {
    throw "ISO creation failed!"
}
