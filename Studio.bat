@echo off
echo. & echo [%~nx0] ------ SCRIPT STARTED ------- & echo.
SETLOCAL EnableExtensions

if /i {%PABCNET_NOT_VERBOSE%} EQU {true} (
    SET params=%* -v:quiet   -p:WarningLevel=1 -noLogo -noWarn:CS0108;CS0114;CS0162;CS0168;CS0184;CS0219;CS0414;CS0649;CS0675;CS0809;CS1717
) else (
    SET params=%* -v:minimal -p:WarningLevel=2)

if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2017\Community\MSBuild\15.0\Bin\msbuild.exe" (
    echo [%~nx0] Found VS2017 Community Edition --> Building project..     & echo.
    "%ProgramFiles(x86)%\Microsoft Visual Studio\2017\Community\MSBuild\15.0\Bin\msbuild.exe"       %params% 2>&1 || goto BUILD_FAILED

) else if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2017\Professional\MSBuild\15.0\Bin\msbuild.exe" (
    echo [%~nx0] Found VS2017 Professional Edition --> Building project... & echo.
    "%ProgramFiles(x86)%\Microsoft Visual Studio\2017\Professional\MSBuild\15.0\Bin\msbuild.exe"    %params% 2>&1 || goto BUILD_FAILED

) else if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2017\Enterprise\MSBuild\15.0\Bin\msbuild.exe" (
    echo [%~nx0] Found VS2017 Enterprise Edition --> Building project...   & echo.
    "%ProgramFiles(x86)%\Microsoft Visual Studio\2017\Enterprise\MSBuild\15.0\Bin\msbuild.exe"      %params% 2>&1 || goto BUILD_FAILED

) else if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\msbuild.exe" (
    echo [%~nx0] Found VS2019 Community Edition --> Building project...    & echo. 
    "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\msbuild.exe"    %params% 2>&1 || goto BUILD_FAILED

) else if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Professional\MSBuild\Current\Bin\msbuild.exe" (
    echo [%~nx0] Found VS2019 Professional Edition --> Building project... & echo.
    "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Professional\MSBuild\Current\Bin\msbuild.exe" %params% 2>&1 || goto BUILD_FAILED

) else if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Enterprise\MSBuild\Current\Bin\msbuild.exe" (
    echo [%~nx0] Found VS2019 Enterprise Edition --> Building project...   & echo.
    "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Enterprise\MSBuild\Current\Bin\msbuild.exe"   %params% 2>&1 || goto BUILD_FAILED

) else (
	echo. & echo [%~nx0] ***ERROR*** MS Visual Studio 2017/2019 not found! & echo.
	pause
	exit /b 2017
)

echo. & echo [INFO] Project build successfully completed (C# part).
echo. & echo [%~nx0] ------ SCRIPT FINISHED ------ & echo.
goto :EOF

:BUILD_FAILED
    SET exit_code=%ERRORLEVEL%
    echo. & echo [%~nx0] ***ERROR*** MSBuild failed with exit code %exit_code% & echo.
    pause
    exit /b %exit_code%
