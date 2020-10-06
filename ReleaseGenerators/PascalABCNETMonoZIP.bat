@echo. & echo [%~nx0] ################################### STARTED ##################################### & echo.
@if /i {%QUIET_MODE%} EQU {true} echo OFF
@SETLOCAL

pushd "%~dp0\..\bin"                                   2>&1 || goto :ERROR
mklink /D LibSource Lib                                2>&1 || goto :ERROR
mklink /D Samples ..\ReleaseGenerators\Samples\Pas     2>&1 || goto :ERROR
mklink /D Doc ..\doc                                   2>&1 || goto :ERROR
:: ToDo: Where to better keep PascalABCNET.chm: under 'root' dir or inside \Doc folder?
mklink ..\doc\PascalABCNET.chm ..\bin\PascalABCNET.chm 2>&1 || goto :ERROR

@del /Q ..\Release\PascalABCNETMono.zip 2>nul
if /i {%QUIET_MODE%} EQU {true} (
    ..\utils\7zip\7za.exe a -mx8 -sse -bse1 -bd ..\Release\PascalABCNETMono.zip -ir0@..\ReleaseGenerators\files2zip_mono.txt -i!LibSource\*.pas 2>&1 || goto :ERROR
) else (
    ..\utils\7zip\7za.exe a -mx8 -sse -bse1 -bb ..\Release\PascalABCNETMono.zip -ir0@..\ReleaseGenerators\files2zip_mono.txt -i!LibSource\*.pas 2>&1 || goto :ERROR)

rmdir /S /Q LibSource          2>&1 || goto :ERROR
rmdir /S /Q Samples            2>&1 || goto :ERROR
rmdir /S /Q Doc                2>&1 || goto :ERROR
del /Q ..\doc\PascalABCNET.chm 2>&1 || goto :ERROR

@popd
@echo. & echo [%~nx0] ################################### FINISHED #################################### & echo.
@goto :EOF

:ERROR
    @SET exit_code=%ERRORLEVEL%
    @rmdir /S /Q LibSource          2>nul
    @rmdir /S /Q Samples            2>nul
    @rmdir /S /Q Doc                2>nul
    @del /Q ..\doc\PascalABCNET.chm 2>nul
    @echo. & echo [%~nx0] ***ERROR*** Last command failed with exit code %exit_code%. & echo.
    @popd
    @pause
    @exit /B %exit_code%
