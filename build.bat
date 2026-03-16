@echo off
setlocal
title TableMax - Build, Deploy and Sign
echo ============================================
echo   TableMax Build + Deploy + Sign
echo   Publisher: vanixjnk
echo ============================================
echo.

set BUILD_DIR=%~dp0build
set EXE=%BUILD_DIR%\tablemax.exe
set CERT_SUBJECT=CN=vanixjnk
set CERT_FILE=%~dp0vanixjnk.cer
set WINDEPLOYQT=C:\Qt\6.10.2\mingw_64\bin\windeployqt.exe
set QML_DIR=%~dp0qml

:: ── Step 1: Build Release ──
echo [1/5] Building Release...
cmake --build "%BUILD_DIR%" --config Release
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Build failed!
    pause
    exit /b 1
)
echo [OK] Build succeeded.
echo.

:: ── Step 2: Deploy Qt DLLs ──
echo [2/5] Deploying Qt dependencies...
"%WINDEPLOYQT%" --qmldir "%QML_DIR%" "%EXE%"
echo [OK] Qt DLLs deployed.
echo.

:: ── Step 3: Check/Create certificate ──
echo [3/5] Checking code-signing certificate...
powershell -Command "$c = Get-ChildItem 'Cert:\CurrentUser\My' -CodeSigningCert | Where-Object { $_.Subject -eq '%CERT_SUBJECT%' } | Select-Object -First 1; if ($c) { Write-Host 'Certificate found:' $c.Thumbprint } else { Write-Host 'Creating new certificate...'; $c = New-SelfSignedCertificate -Type CodeSigningCert -Subject '%CERT_SUBJECT%' -CertStoreLocation 'Cert:\CurrentUser\My' -NotAfter (Get-Date).AddYears(5); Write-Host 'Created:' $c.Thumbprint }"
echo.

:: ── Step 4: Trust certificate (first time only) ──
echo [4/5] Ensuring certificate is trusted...
powershell -Command "$c = Get-ChildItem 'Cert:\CurrentUser\My' -CodeSigningCert | Where-Object { $_.Subject -eq '%CERT_SUBJECT%' } | Select-Object -First 1; $trusted = Get-ChildItem 'Cert:\LocalMachine\Root' -ErrorAction SilentlyContinue | Where-Object { $_.Thumbprint -eq $c.Thumbprint }; if ($trusted) { Write-Host 'Already trusted.' } else { Export-Certificate -Cert $c -FilePath '%CERT_FILE%' -Type CERT | Out-Null; Write-Host 'Importing to LocalMachine\Root (needs Admin)...'; Start-Process powershell -ArgumentList '-Command', ('Import-Certificate -FilePath ''{0}'' -CertStoreLocation ''Cert:\LocalMachine\Root'' | Out-Null; Write-Host ''Trusted OK''; pause' -f '%CERT_FILE%') -Verb RunAs -Wait; Write-Host 'Done.' }"
echo.

:: ── Step 5: Sign exe ──
echo [5/5] Signing %EXE%...
powershell -Command "$c = Get-ChildItem 'Cert:\CurrentUser\My' -CodeSigningCert | Where-Object { $_.Subject -eq '%CERT_SUBJECT%' } | Select-Object -First 1; $r = Set-AuthenticodeSignature -FilePath '%EXE%' -Certificate $c -TimestampServer 'http://timestamp.digicert.com'; Write-Host 'Status:' $r.Status; if ($r.Status -ne 'Valid') { Write-Host 'StatusMessage:' $r.StatusMessage }"

echo.
echo ============================================
echo   Done! Signed exe: %EXE%
echo   Publisher: vanixjnk
echo ============================================
echo.
pause
