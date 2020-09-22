@echo. & echo [%~nx0] ################################### STARTED ##################################### & echo.
@if /i {%QUIET_MODE%} EQU {true} echo OFF
@SETLOCAL

:: ToFix: fix filename spelling error for PascalABCNETStandar[d].nsi
@echo. & echo [%~nx0] =================================== Step 1/3 ====================================
@echo Creating STANDARD multilingual (ENG/RUS/UKR) distro for Win7+ with .NET 4.7.1 (incl. Programming Taskbook)... & echo.
pushd "%~dp0"
if /i {%QUIET_MODE%} EQU {true} (
    "..\utils\NSIS\Unicode\makensis.exe" /V0 PascalABCNETStandart.nsi 2>&1 || goto :ERROR
) else (
    "..\utils\NSIS\Unicode\makensis.exe" /V4 PascalABCNETStandart.nsi 2>&1 || goto :ERROR)


@echo. & echo [%~nx0] =================================== Step 2/3 ====================================
@echo Creating MINI (RUS-only) distro for Win7+ with .NET 4.7.1 (w/o Programming Taskbook)... & echo.
if /i {%QUIET_MODE%} EQU {true} (
    "..\utils\NSIS\Unicode\makensis.exe" /V0 PascalABCNETMini.nsi 2>&1 || goto :ERROR
) else (
    "..\utils\NSIS\Unicode\makensis.exe" /V4 PascalABCNETMini.nsi 2>&1 || goto :ERROR)


@echo. & echo [%~nx0] =================================== Step 3/3 ====================================
@echo Creating minimal CONSOLE distro (Mono-compatible)... & echo.
CALL PascalABCNETConsoleZIP.bat 2>&1 || goto :ERROR

:: ToDo: Still incomplete and officially unsupported option?
@rem @echo. & echo [%~nx0] =================================== Step 4/4 ====================================
@rem @echo Creating CUSTOM distro for use exclusively on Mono platform...
@rem CALL PascalABCNETMonoZIP.bat 2>&1 || goto :ERROR

@popd
@echo. & echo [%~nx0] ################################### FINISHED #################################### & echo.
@goto :EOF

:ERROR
    @SET exit_code=%ERRORLEVEL%
    @echo. & echo [%~nx0] ***ERROR*** Last command failed with exit code %exit_code%. & echo.
    @popd
    @pause
    @exit /b %exit_code%
