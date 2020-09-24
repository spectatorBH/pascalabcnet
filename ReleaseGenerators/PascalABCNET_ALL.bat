@if /i {%PABCNET_NOT_VERBOSE%} EQU {true} echo OFF
@echo. & echo [%~nx0] ------ SCRIPT STARTED ------- & echo.
@SETLOCAL
pushd "%~dp0"

:: ToFix: fix filename spelling error for PascalABCNETStandar[d].nsi
@echo. & echo [%~nx0] -------- Step #1/3 -----------
@echo [INFO] Creating STANDARD multilingual (ENG/RUS/UKR) distro for Win7+ with .NET 4.7.1 (incl. Programming Taskbook)... & echo.
if /i {%PABCNET_NOT_VERBOSE%} EQU {true} (
    "..\utils\NSIS\Unicode\makensis.exe" /V0 PascalABCNETStandart.nsi 2>&1 || goto ERROR
) else (
    "..\utils\NSIS\Unicode\makensis.exe" /V4 PascalABCNETStandart.nsi 2>&1 || goto ERROR)
@echo. & echo [INFO] Done #1/3 -- FULL installer for Win7+ ready.

@echo. & echo [%~nx0] -------- Step #2/3 -----------
@echo [INFO] Creating MINI (RUS-only) distro for Win7+ with .NET 4.7.1 (w/o Programming Taskbook)... & echo.
if /i {%PABCNET_NOT_VERBOSE%} EQU {true} (
    "..\utils\NSIS\Unicode\makensis.exe" /V0 PascalABCNETMini.nsi 2>&1 || goto ERROR
) else (
    "..\utils\NSIS\Unicode\makensis.exe" /V4 PascalABCNETMini.nsi 2>&1 || goto ERROR)
@echo. & echo [INFO] Done #2/3 -- MINI installer for Win7+ ready.

@echo. & echo [%~nx0] -------- Step #3/3 -----------
@echo [INFO] Creating minimal CONSOLE distro (Mono-compatible):
@echo. & echo [INFO] Calling PascalABCNETConsoleZIP.bat script...& echo.
@call PascalABCNETConsoleZIP.bat 2>&1 || goto ERROR
@echo. & echo [INFO] Done #3/3 -- Console zip-package for Win/Mac/Linux ready.

:: ToDo: Still incomplete and officially unsupported option?
@rem @echo. & echo [%~nx0] -------- Step #4/4 -----------
@rem @echo. & echo [INFO] Creating CUSTOM distro for use exclusively on Mono platform...
@rem @echo. [INFO] Calling PascalABCNETMonoZIP.bat script...
@rem echo. & call PascalABCNETMonoZIP.bat 2>&1 || goto ERROR
@rem @echo. & echo Done #4/4 -- Special zip-package for Mono platform ready.

popd
@echo. & echo [%~nx0] ------ SCRIPT FINISHED ------ & echo.
@goto :EOF

:ERROR
    @SET exit_code=%ERRORLEVEL%
    @echo. & echo [%~nx0] ***ERROR*** Last command failed with exit code %exit_code%. & echo.
    @popd
    @pause
    @exit /b %exit_code%
