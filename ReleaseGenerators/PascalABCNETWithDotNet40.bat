@if /i {%PABCNET_QUIET_MODE%} EQU {true} echo OFF
@echo. & echo [%~nx0] ------ SCRIPT STARTED ------- & echo.
@SETLOCAL
pushd "%~dp0"

@echo. & echo [INFO] Creating STANDARD installer for WinXP with .NET 4.0 (incl. Programming Taskbook)... & echo.
if /i {%PABCNET_QUIET_MODE%} EQU {true} (
    "..\utils\NSIS\Unicode\makensis.exe" /V0 PascalABCNETWithDotNet40.nsi 2>&1 || goto ERROR
) else (
    "..\utils\NSIS\Unicode\makensis.exe" /V4 PascalABCNETWithDotNet40.nsi 2>&1 || goto ERROR)
@echo. & echo Done -- WinXP (.NET 4.0) installer ready.

popd
@echo. & echo [%~nx0] ------ SCRIPT FINISHED ------ & echo.
@goto :EOF

:ERROR
    @SET exit_code=%ERRORLEVEL%
    @echo. & echo [%~nx0] ***ERROR*** Last command failed with exit code %exit_code%. & echo.
    @popd
    @pause
    @exit /b %exit_code%
