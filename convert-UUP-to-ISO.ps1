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
$wimFiles = Get-ChildItem -Path $SourcePath -Filter *.wim -ErrorAction SilentlyContinue
if (-not $wimFiles) {
    throw "No WIM files found!"
}

# Gunakan file WIM terbesar
$wimFile = $wimFiles | Sort-Object Length -Descending | Select-Object -First 1 -ExpandProperty FullName
Write-Host "Using WIM file: $wimFile"

# Buat ISO menggunakan oscdimg
$bootData = '2#p0,e,b"{0}\boot\etfsboot.com"#pEF,e,b"{0}\efi\microsoft\boot\efisys.bin"' -f $isoDir
$oscdimgArgs = @(
    "-m",
    "-o",
    "-u2",
    "-udfver102",
    "-bootdata:$bootData",
    "`"$isoDir`"",
    "`"$OutputPath`""
)

try {
    Start-Process "oscdimg.exe" -ArgumentList $oscdimgArgs -Wait -NoNewWindow
    
    if (Test-Path $OutputPath) {
        Write-Host "ISO created successfully at $OutputPath"
        return
    }
}
catch {
    Write-Warning "OSCDIMG failed: $($_.Exception.Message)"
}

# Fallback: Gunakan mkisofs jika oscdimg gagal
try {
    Write-Host "Trying fallback with mkisofs..."
    & mkisofs -o $OutputPath -b "boot/etfsboot.com" -no-emul-boot -boot-load-size 8 -iso-level 2 -udf -N -J -joliet-long -relaxed-filenames $isoDir
    
    if (Test-Path $OutputPath) {
        Write-Host "ISO created successfully with mkisofs"
    } else {
        throw "ISO creation failed with both methods"
    }
}
catch {
    throw "ISO creation failed: $($_.Exception.Message)"
}
