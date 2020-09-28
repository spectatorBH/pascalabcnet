@if /i {%PABCNET_VERBOSE%} NEQ {true} echo OFF
@SETLOCAL
pushd "%~dp0"

@echo [%~nx0] Creating FULL installer for WinXP (.NET 4.0)...& echo.
if /i {%PABCNET_VERBOSE%} NEQ {true} (
    "..\utils\NSIS\Unicode\makensis.exe" /V0 PascalABCNETWithDotNet40.nsi 2>&1 || goto ERROR
) else (
    "..\utils\NSIS\Unicode\makensis.exe" /V4 PascalABCNETWithDotNet40.nsi 2>&1 || goto ERROR)
@echo. & echo [%~nx0] Done (in \Release).

popd
@goto :EOF

:ERROR
    @SET exit_code=%ERRORLEVEL%
    @echo. & echo [%~nx0] ***ERROR*** Last command failed with exit code %exit_code%. & echo.
    @popd
    @pause
    @exit /b %exit_code%
