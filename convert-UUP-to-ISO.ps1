param(
    [string]$SourcePath,
    [string]$OutputPath,
    [string]$Edition
)

# Step 1: Create ISO structure
$isoDir = Join-Path $SourcePath "ISO"
New-Item -ItemType Directory -Path $isoDir -Force

# Step 2: Copy essential files
Copy-Item -Path "$SourcePath\*" -Destination $isoDir -Recurse -Exclude "*.cab"

# Step 3: Process install.wim
$wimFile = Join-Path $SourcePath "install.wim"
$tempMount = Join-Path $SourcePath "mount"

if (Test-Path $wimFile) {
    # Create basic image
    New-WindowsImage -ImagePath $wimFile -CapturePath $isoDir -Name "Windows 11 UUP" -LogPath ".\wim.log"
} else {
    Write-Error "install.wim not found!"
    exit 1
}

# Step 4: Build ISO
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

if (Test-Path $OutputPath) {
    Write-Host "ISO created at $OutputPath"
} else {
    Write-Error "ISO creation failed!"
}
