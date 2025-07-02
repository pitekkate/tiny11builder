param(
    [string]$SourcePath,
    [string]$OutputPath,
    [string]$Edition
)

Write-Host "Creating ISO from UUP files..."
Write-Host "Source: $SourcePath"
Write-Host "Output: $OutputPath"
Write-Host "Edition: $Edition"

# Create basic ISO structure
$isoDir = Join-Path $SourcePath "ISO"
New-Item -ItemType Directory -Path $isoDir -Force

# Copy all files to ISO folder
Copy-Item -Path "$SourcePath\*" -Destination $isoDir -Recurse -Exclude "*.cab"

# Find main WIM file
$wimFiles = Get-ChildItem -Path $SourcePath -Filter *.wim -ErrorAction SilentlyContinue
if (-not $wimFiles) {
    throw "No WIM files found!"
}

# Use the largest WIM file
$wimFile = $wimFiles | Sort-Object Length -Descending | Select-Object -First 1 -ExpandProperty FullName
Write-Host "Using WIM file: $wimFile"

# Create ISO using oscdimg
try {
    $bootData = '2#p0,e,b"{0}\boot\etfsboot.com"#pEF,e,b"{0}\efi\microsoft\boot\efisys.bin"' -f $isoDir
    Start-Process "oscdimg.exe" -ArgumentList @(
        "-m",
        "-o",
        "-u2",
        "-udfver102",
        "-bootdata:$bootData",
        "`"$isoDir`"",
        "`"$OutputPath`""
    ) -Wait -NoNewWindow
    
    if (Test-Path $OutputPath) {
        Write-Host "ISO created successfully at $OutputPath"
    } else {
        throw "ISO creation failed - no output file found"
    }
}
catch {
    throw "ISO creation failed: $($_.Exception.Message)"
}
