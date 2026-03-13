@echo off
setlocal
title TableMax - Build and Sign
echo ============================================
echo   TableMax Build + Sign (publisher: vanixjnk)
echo ============================================
echo.

set BUILD_DIR=%~dp0build
set EXE=%BUILD_DIR%\tablemax.exe
set CERT_SUBJECT=CN=vanixjnk
set CERT_FILE=%~dp0vanixjnk.cer

:: ── Step 1: Build Release ──
echo [1/4] Building Release...
cmake --build "%BUILD_DIR%" --config Release
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Build failed!
    pause
    exit /b 1
)
echo [OK] Build succeeded.
echo.

:: ── Step 2: Check/Create certificate ──
echo [2/4] Checking code-signing certificate...
powershell -Command "$c = Get-ChildItem 'Cert:\CurrentUser\My' -CodeSigningCert | Where-Object { $_.Subject -eq '%CERT_SUBJECT%' } | Select-Object -First 1; if ($c) { Write-Host 'Certificate found:' $c.Thumbprint } else { Write-Host 'Creating new certificate...'; $c = New-SelfSignedCertificate -Type CodeSigningCert -Subject '%CERT_SUBJECT%' -CertStoreLocation 'Cert:\CurrentUser\My' -NotAfter (Get-Date).AddYears(5); Write-Host 'Created:' $c.Thumbprint }"
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Certificate creation failed!
    pause
    exit /b 1
)
echo.

:: ── Step 3: Trust certificate (first time only) ──
echo [3/4] Ensuring certificate is trusted...
powershell -Command "$c = Get-ChildItem 'Cert:\CurrentUser\My' -CodeSigningCert | Where-Object { $_.Subject -eq '%CERT_SUBJECT%' } | Select-Object -First 1; $trusted = Get-ChildItem 'Cert:\CurrentUser\Root' | Where-Object { $_.Thumbprint -eq $c.Thumbprint }; if ($trusted) { Write-Host 'Already trusted.' } else { Export-Certificate -Cert $c -FilePath '%CERT_FILE%' -Type CERT | Out-Null; Import-Certificate -FilePath '%CERT_FILE%' -CertStoreLocation 'Cert:\CurrentUser\Root' | Out-Null; Write-Host 'Trusted OK (you may see a Windows popup - click Yes)' }"
echo.

:: ── Step 4: Sign exe ──
echo [4/4] Signing %EXE%...
powershell -Command "$c = Get-ChildItem 'Cert:\CurrentUser\My' -CodeSigningCert | Where-Object { $_.Subject -eq '%CERT_SUBJECT%' } | Select-Object -First 1; $r = Set-AuthenticodeSignature -FilePath '%EXE%' -Certificate $c -TimestampServer 'http://timestamp.digicert.com'; Write-Host 'Status:' $r.Status; if ($r.Status -ne 'Valid') { Write-Host 'StatusMessage:' $r.StatusMessage }"
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Signing failed!
    pause
    exit /b 1
)

echo.
echo ============================================
echo   Done! Signed exe: %EXE%
echo   Publisher: vanixjnk
echo ============================================
echo.
pause
