@if /i {%QUIET_MODE%} EQU {true} echo OFF
@echo. & echo [%~nx0] ################################### STARTED ##################################### & echo.
@SETLOCAL

@echo. & echo [INFO] Creating STANDARD installer for WinXP with .NET 4.0 (incl. Programming Taskbook)... & echo.
pushd "%~dp0"

if /i {%QUIET_MODE%} EQU {true} (
    "..\utils\NSIS\Unicode\makensis.exe" /V0 PascalABCNETWithDotNet40.nsi 2>&1 || goto :ERROR
) else (
    "..\utils\NSIS\Unicode\makensis.exe" /V4 PascalABCNETWithDotNet40.nsi 2>&1 || goto :ERROR)

@popd
@echo. & echo [%~nx0] ################################### FINISHED #################################### & echo.
@goto :EOF

:ERROR
    @SET exit_code=%ERRORLEVEL%
    @echo. & echo [%~nx0] ***ERROR*** Last command failed with exit code %exit_code%. & echo.
    @popd
    @pause
    @exit /b %exit_code%
