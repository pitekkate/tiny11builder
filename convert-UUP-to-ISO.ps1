param(
    [string]$SourcePath,
    [string]$OutputPath,
    [string]$Edition
)

Write-Host "Creating ISO from UUP files..."
Write-Host "Source: $SourcePath"
Write-Host "Output: $OutputPath"
Write-Host "Edition: $Edition"

# Buat struktur ISO dasar
$isoDir = Join-Path $SourcePath "ISO"
New-Item -ItemType Directory -Path $isoDir -Force

# Salin semua file ke folder ISO
Copy-Item -Path "$SourcePath\*" -Destination $isoDir -Recurse -Exclude "*.cab"

# Cari file install.wim
$wimFile = Get-ChildItem -Path $SourcePath -Filter *.wim | 
            Sort-Object Length -Descending | 
            Select-Object -First 1 -ExpandProperty FullName

if (-not $wimFile) {
    throw "No WIM file found!"
}

Write-Host "Using WIM file: $wimFile"

# Buat ISO menggunakan oscdimg (asumsi tersedia di sistem)
$bootData = '2#p0,e,b"{0}\boot\etfsboot.com"#pEF,e,b"{0}\efi\microsoft\boot\efisys.bin"' -f $isoDir
$oscdimgArgs = @(
    "-m",
    "-o",
    "-u2",
    "-udfver102",
    "-bootdata:$bootData",
    $isoDir,
    $OutputPath
)

Start-Process "oscdimg.exe" -ArgumentList $oscdimgArgs -Wait -NoNewWindow

if (Test-Path $OutputPath) {
    Write-Host "ISO created successfully at $OutputPath"
} else {
    throw "ISO creation failed!"
}
