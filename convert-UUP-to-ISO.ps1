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
New-Item -ItemType Directory -Path "$SourcePath\ISO" -Force

# Salin semua file ke folder ISO
Copy-Item -Path "$SourcePath\*" -Destination "$SourcePath\ISO" -Recurse -Exclude "*.cab"

# Cari file WIM utama
$wimFile = Get-ChildItem -Path $SourcePath -Filter *.wim | 
            Sort-Object Length -Descending | 
            Select-Object -First 1 -ExpandProperty FullName

if (-not $wimFile) {
    throw "No WIM file found!"
}

Write-Host "Using WIM file: $wimFile"

# Buat ISO menggunakan oscdimg (asumsi oscdimg tersedia)
$bootData = '2#p0,e,b"{0}\boot\etfsboot.com"#pEF,e,b"{0}\efi\microsoft\boot\efisys.bin"' -f "$SourcePath\ISO"
$oscdimgArgs = @(
    "-m",
    "-o",
    "-u2",
    "-udfver102",
    "-bootdata:$bootData",
    "$SourcePath\ISO",
    $OutputPath
)

Start-Process "oscdimg.exe" -ArgumentList $oscdimgArgs -Wait -NoNewWindow

if (Test-Path $OutputPath) {
    Write-Host "ISO created successfully at $OutputPath"
} else {
    throw "ISO creation failed!"
}
