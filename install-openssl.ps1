# OpenSSL kurulum ve PATH yapilandirma betigi (Windows)
# - winget ile OpenSSL (ShiningLight Win64 Light) kurar
# - bin klasorunu sistem PATH'ine ekler, OPENSSL_CONF degiskenini ayarlar
# - Kurulumdan sonra yeni acilan her cmd penceresinde "openssl" calisir

$ErrorActionPreference = 'Stop'

# Yonetici yetkisi yoksa kendini yonetici olarak yeniden baslat
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host 'Yonetici yetkisi isteniyor...'
    Start-Process powershell.exe -Verb RunAs -ArgumentList @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`""
    )
    exit
}

function Find-OpenSslBin {
    $candidates = @(
        "$env:ProgramFiles\OpenSSL-Win64\bin",
        "$env:ProgramFiles\OpenSSL\bin",
        "${env:ProgramFiles(x86)}\OpenSSL-Win32\bin",
        'C:\OpenSSL-Win64\bin',
        'C:\OpenSSL-Win32\bin'
    )
    foreach ($dir in $candidates) {
        if ($dir -and (Test-Path (Join-Path $dir 'openssl.exe'))) { return $dir }
    }
    return $null
}

try {
    $bin = Find-OpenSslBin
    if ($bin) {
        Write-Host "OpenSSL zaten kurulu: $bin"
    } else {
        if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
            throw 'winget bulunamadi. Microsoft Store''dan "App Installer" uygulamasini kurup tekrar deneyin ' +
                  'veya OpenSSL''i https://slproweb.com/products/Win32OpenSSL.html adresinden elle kurun.'
        }
        Write-Host 'OpenSSL indiriliyor ve kuruluyor (winget)...'
        winget install --id ShiningLight.OpenSSL.Light -e --silent `
            --accept-package-agreements --accept-source-agreements
        $bin = Find-OpenSslBin
        if (-not $bin) { throw 'Kurulum tamamlandi ancak openssl.exe bulunamadi.' }
        Write-Host "Kuruldu: $bin"
    }

    # Sistem PATH'ini ham haliyle oku (%SystemRoot% gibi degiskenler bozulmasin, setx'in 1024 karakter siniri olmasin)
    $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey(
        'SYSTEM\CurrentControlSet\Control\Session Manager\Environment', $true)
    $path = $key.GetValue('Path', '', [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
    $entries = $path -split ';' | Where-Object { $_ -ne '' }

    if ($entries | Where-Object { $_.TrimEnd('\') -ieq $bin.TrimEnd('\') }) {
        Write-Host 'PATH zaten OpenSSL klasorunu iceriyor.'
    } else {
        $key.SetValue('Path', (($entries + $bin) -join ';'), [Microsoft.Win32.RegistryValueKind]::ExpandString)
        Write-Host "PATH'e eklendi: $bin"
    }

    # OpenSSL 3.x yapilandirma dosyasi
    $cnf = Join-Path $bin 'cnf\openssl.cnf'
    if (-not (Test-Path $cnf)) { $cnf = Join-Path (Split-Path $bin) 'bin\cnf\openssl.cnf' }
    if (Test-Path $cnf) {
        $key.SetValue('OPENSSL_CONF', $cnf, [Microsoft.Win32.RegistryValueKind]::String)
        Write-Host "OPENSSL_CONF ayarlandi: $cnf"
    }
    $key.Close()

    # Acik pencerelere ortam degiskenlerinin degistigini bildir (yeni cmd pencereleri hemen gorur)
    Add-Type -Namespace Win32 -Name Native -MemberDefinition @'
[DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam,
    uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
'@
    $result = [UIntPtr]::Zero
    [Win32.Native]::SendMessageTimeout([IntPtr]0xffff, 0x1A, [UIntPtr]::Zero, 'Environment', 2, 5000, [ref]$result) | Out-Null

    Write-Host ''
    & (Join-Path $bin 'openssl.exe') version
    Write-Host ''
    Write-Host 'Tamamlandi. Yeni bir cmd penceresi acip "openssl version" yazarak deneyebilirsiniz.' -ForegroundColor Green
} catch {
    Write-Host "HATA: $($_.Exception.Message)" -ForegroundColor Red
}

Read-Host 'Kapatmak icin Enter''a basin'
