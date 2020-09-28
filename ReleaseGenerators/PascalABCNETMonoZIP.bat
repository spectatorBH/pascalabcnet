@if /i {%PABCNET_VERBOSE%} NEQ {true} echo OFF
@SETLOCAL
pushd "%~dp0\..\bin" 2>&1 || goto ERROR

@echo [%~nx0] Creating temporary symlinks for packaging Pascal library sources, samples and docs...
mklink /D LibSource Lib                                2>&1 || goto ERROR
mklink /D Samples ..\ReleaseGenerators\Samples\Pas     2>&1 || goto ERROR
mklink /D Doc ..\doc                                   2>&1 || goto ERROR
:: ToDo: Where's to better keep PascalABCNET.chm: under 'root' dir or inside \Doc folder?
mklink ..\doc\PascalABCNET.chm ..\bin\PascalABCNET.chm 2>&1 || goto ERROR

@echo [%~nx0] Putting pre-selected set of files into zip-package...
@del /Q ..\Release\PascalABCNETMono.zip  >nul 2>&1
if /i {%PABCNET_VERBOSE%} NEQ {true} (
    ..\utils\7zip\7za.exe a -mx8 -sse -bse1 -bd -sccUTF-8 ..\Release\PascalABCNETMono.zip -ir0@..\ReleaseGenerators\files2zip_mono.txt -i!LibSource\*.pas 2>&1 || goto ERROR
) else (
    ..\utils\7zip\7za.exe a -mx8 -sse -bse1 -bb -sccUTF-8 ..\Release\PascalABCNETMono.zip -ir0@..\ReleaseGenerators\files2zip_mono.txt -i!LibSource\*.pas 2>&1 || goto ERROR)

@echo [%~nx0] Cleaning up: removing temporary symlinks...
rmdir /S /Q LibSource          2>&1 || goto ERROR
rmdir /S /Q Samples            2>&1 || goto ERROR
rmdir /S /Q Doc                2>&1 || goto ERROR
del /Q ..\doc\PascalABCNET.chm 2>&1 || goto ERROR

popd
@echo [%~nx0] Done.
@goto :EOF

:ERROR
    @SET exit_code=%ERRORLEVEL%
    @rmdir /S /Q LibSource           >nul 2>&1
    @rmdir /S /Q Samples             >nul 2>&1
    @rmdir /S /Q Doc                 >nul 2>&1
    @del /Q ..\doc\PascalABCNET.chm  >nul 2>&1
    @echo. & echo [%~nx0] ***ERROR*** Last command failed with exit code %exit_code%. & echo.
    @popd
    @pause
    @exit /B %exit_code%
