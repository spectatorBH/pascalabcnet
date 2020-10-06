@if /i {%PABCNET_NOT_VERBOSE%} EQU {true} echo OFF
@SETLOCAL
pushd "%~dp0"

:: ToFix: fix filename spelling error for PascalABCNETStandar[d].nsi
@echo. & echo [%~nx0] Creating FULL installer for Win7+... & echo.
if /i {%PABCNET_NOT_VERBOSE%} EQU {true} (
    "..\utils\NSIS\Unicode\makensis.exe" /V0 PascalABCNETStandart.nsi 2>&1 || goto ERROR
) else (
    "..\utils\NSIS\Unicode\makensis.exe" /V4 PascalABCNETStandart.nsi 2>&1 || goto ERROR)
@echo. & echo [%~nx0] Done (in \Release).

@echo. & echo [%~nx0] Creating MINI installer for Win7+... & echo.
if /i {%PABCNET_NOT_VERBOSE%} EQU {true} (
    "..\utils\NSIS\Unicode\makensis.exe" /V0 PascalABCNETMini.nsi 2>&1 || goto ERROR
) else (
    "..\utils\NSIS\Unicode\makensis.exe" /V4 PascalABCNETMini.nsi 2>&1 || goto ERROR)
@echo. & echo [%~nx0] Done (in \Release).

@echo. & echo [%~nx0] Creating CONSOLE zip-package for Win/Mac/Linux (Mono-compatible)...
@call PascalABCNETConsoleZIP.bat 2>&1 || goto ERROR
@echo. & echo [%~nx0] Done (in \Release).

:: ToDo: Still incomplete and officially unsupported option?
@echo. & echo [%~nx0] Creating special zip-package for Mono platform...
@call PascalABCNETMonoZIP.bat 2>&1 || goto ERROR
@echo. & echo [%~nx0] Done (in \Release).

popd
@goto :EOF

:ERROR
    @SET exit_code=%ERRORLEVEL%
    @echo. & echo [%~nx0] ***ERROR*** Last command failed with exit code %exit_code%. & echo.
    @popd
    @pause
    @exit /b %exit_code%
