@if /i {%QUIET_MODE%} EQU {true} echo OFF
@echo. & echo [%~nx0]
@echo ####################################### STARTED ########################################

:: Making sure batch file would run properly regardless of where it was launched from (due to usage of relative paths)
@SETLOCAL EnableExtensions
@rem @SET launched_from=%CD%
@rem @SET project_root=%~dp0
:: DEBUG: Alternative lines: @pushd "%~dp0" OR @pushd "%project_root%"
pushd "%~dp0"

@echo. & echo [%~nx0]
@echo +======================================================================== Step 1/16 ===+
@echo !  Incrementing revision (build number) in sources:                                    !
@echo +======================================================================================+
@echo.
@rem @cd /d "%project_root%"
:: This step is optional and gets executed ONLY if there exists env. variable 'BUMP_REVISION=true' AND no any optional argument is provided for the run
@if /i {%BUMP_REVISION%} NEQ {true} (echo *** Skipping -- No revision update & goto :SKIP1)
@if    {%1}              NEQ {}     (echo *** Skipping -- No revision update & goto :SKIP1)
:: ToDo: fix filename spelling error for 'IncrementVresion.exe' -> 'IncrementVersion.exe';
:: ToDo: implement basic error handling in the tools below:
utils\IncrementVresion\IncrementVresion.exe Configuration\Version.defs REVISION 1                                                                             2>&1 || goto :ERROR
utils\ReplaceInFiles\ReplaceInFiles.exe Configuration\Version.defs Configuration\GlobalAssemblyInfo.cs.tmpl Configuration\GlobalAssemblyInfo.cs               2>&1 || goto :ERROR
utils\ReplaceInFiles\ReplaceInFiles.exe Configuration\Version.defs ReleaseGenerators\PascalABCNET_version.nsh.tmpl ReleaseGenerators\PascalABCNET_version.nsh 2>&1 || goto :ERROR
utils\ReplaceInFiles\ReplaceInFiles.exe Configuration\Version.defs Configuration\pabcversion.txt.tmpl Release\pabcversion.txt                                 2>&1 || goto :ERROR
@echo [INFO] Done.
:SKIP1

@echo. & echo [%~nx0]
@echo +======================================================================== Step 2/16 ===+
@echo !  Making a clean copy of \bin directory for later use:                                !
@echo +======================================================================================+
@echo.
@rem @cd /d "%project_root%"
@rmdir /S /Q bin_copy          1>nul 2>nul 
xcopy /I /E /Q /Y bin bin_copy 2>&1 || goto :ERROR
@echo [INFO] Done.

@echo. & echo [%~nx0]
@echo +======================================================================== Step 3/16 ===+
@echo !  Generating default language resource file:                                          !
@echo +======================================================================================+
@echo.
@rem @cd /d "%project_root%\utils\DefaultLanguageResMaker" 2>&1 || goto :ERROR
@cd utils\DefaultLanguageResMaker 2>&1 || goto :ERROR
:: ToDo: implement basic error handling in the 'LanguageResMaker.exe' tool
LanguageResMaker.exe              2>&1 || goto :ERROR
@echo [INFO] Done.

@echo. & echo [%~nx0] 
@echo +======================================================================== Step 4/16 ===+
@echo !  Building project using .NET 4.7.1 as target (for Win7+ platforms):                  !
@echo +======================================================================================+
@echo.
@rem @cd /d "%project_root%"
@cd ..\..
call Studio.bat /m /t:Rebuild "/p:Configuration=Release" "/p:Platform=Any CPU" PascalABCNET.sln 2>&1 || goto :ERROR
@rem call Studio.bat /m /t:Rebuild "/p:Configuration=Debug" "/p:Platform=Any CPU" PascalABCNET.sln 2>&1 || goto :ERROR
@echo [INFO] Done.

@echo. & echo [%~nx0]
@echo +======================================================================== Step 5/16 ===+
@echo !  Building PABCRtl.dll -- Pascal special standalone runtime library for IDE:          !
@echo +======================================================================================+
@echo.
@rem @cd /d "%project_root%\ReleaseGenerators\PABCRtl"               2>&1 || goto :ERROR
@cd ReleaseGenerators\PABCRtl                                        2>&1 || goto :ERROR
@if /i {%QUIET_MODE%} EQU {true} (
    ..\..\bin\pabcnetc PABCRtl.pas /rebuildnodebug /noconsole 1>nul 2>nul || goto :ERROR
) else (
    ..\..\bin\pabcnetc PABCRtl.pas /rebuildnodebug /noconsole        2>&1 || goto :ERROR)
@echo. & echo [INFO] PABCRtl.dll successfully built.

@echo. 
@echo [%~nx0]
@echo +======================================================================== Step 6/16 ===+
@echo !  Signing and registering fresh PABCRtl.dll in GAC:                                   !
@echo +======================================================================================+
@echo.
@rem @cd /d "%project_root%\ReleaseGenerators\PABCRtl"    2>&1 || goto :ERROR
..\sn.exe -Vr PABCRtl.dll                            2>&1 || goto :ERROR
..\sn.exe -R  PABCRtl.dll KeyPair.snk                2>&1 || goto :ERROR
..\sn.exe -Vu PABCRtl.dll                            2>&1 || goto :ERROR
copy /Y PABCRtl.dll ..\..\bin\Lib\                   2>&1 || goto :ERROR
@echo [INFO] PABCRtl.dll copied to \bin\Lib
:: DEBUG: Saving a copy of PABCRtl.dll for retrieval as artifact later
copy /Y PABCRtl.dll ..\..\Release\                   2>&1 || goto :ERROR
@cd ..
gacutil.exe /nologo /u PABCRtl                1>nul 2>nul || goto :ERROR
gacutil.exe /f /i ..\bin\Lib\PABCRtl.dll             2>&1 || goto :ERROR
@echo [INFO] Done.

@echo. & echo [%~nx0]
@echo +======================================================================== Step 7/16 ===+
@echo !  Building all Pascal standard units:                                                 !
@echo +======================================================================================+
@echo.
@rem @cd /d "%project_root%\ReleaseGenerators"                                   2>&1 || goto :ERROR
@if /i {%QUIET_MODE%} EQU {true} (
    ..\bin\pabcnetc RebuildStandartModules.pas /rebuildnodebug /noconsole 1>nul 2>nul || goto :ERROR
) else (
    ..\bin\pabcnetc RebuildStandartModules.pas /rebuildnodebug /noconsole        2>&1 || goto :ERROR)
@rem ..\bin\pabcnetcclear /Debug:0 RebuildStandartModules.pas ..\bin\Temp        2>&1 || goto :ERROR
@echo. & echo [INFO] Standard units successfully built.

@echo. & echo [%~nx0]
@echo +======================================================================== Step 8/16 ===+
@echo !  Performing compilation, unit and functional tests:                                  !
@echo +======================================================================================+
@echo.
:: This step is optional and gets executed ONLY if there exists env. variable 'RUN_TESTS=true' AND no any optional argument is provided for the run
@if /i {%RUN_TESTS%} NEQ {true} (echo *** Skipping -- Tests will not be run & goto :SKIP8)
@if {%1}             NEQ {}     (echo *** Skipping -- Tests will not be run & goto :SKIP8)
@rem @cd /d "%project_root%\bin"      2>&1 || goto :ERROR
@cd ..\bin                            2>&1 || goto :ERROR
:: DEBUG: fixing CR/LF line-endings for *.pas files in \TestSuite\formatter_tests
call ..\Utils\fix-CRLF-for-TestRunner.bat  || goto :ERROR
:: ToDo: add compilation tests to TestRunner for bundled demo samples;
:: ToDo: research possibility of running some tests in parallel (improve TestRunner or job refactoring within GitHub Actions?);
@echo [INFO] Compiling TestRunner.pas...
@rem pabcnetc TestRunner.pas /noconsole 2>&1 || goto :ERROR
pabcnetcclear /Debug:0 TestRunner.pas 2>&1 || goto :ERROR
@echo [INFO] Launching TestRunner.exe...& echo.
@rem TestRunner.exe 3                      2>&1 || goto :ERROR
@rem TestRunner.exe 1                      2>&1 || goto :ERROR
@rem TestRunner.exe 2                      2>&1 || goto :ERROR
@rem TestRunner.exe 4                      2>&1 || goto :ERROR
@rem TestRunner.exe 5                      2>&1 || goto :ERROR
@rem TestRunner.exe 6                      2>&1
TestRunner.exe                   2>&1 || goto :ERROR
:SKIP8

@echo. & echo [%~nx0]
@echo +======================================================================== Step 9/16 ===+
@echo !  Preparing Pascal bundled code samples and library sources for packaging:            !
@echo +======================================================================================+
@echo.
@rem @cd /d "%project_root%\ReleaseGenerators"    2>&1 || goto :ERROR
@cd ..\ReleaseGenerators                     2>&1 || goto :ERROR
:: ToDo: Where to better keep \LibSource dir: inside \ReleaseGenerators or \bin dir?
@rmdir /S /Q LibSource                       1>nul 2>nul 
xcopy /I /Q /Y ..\bin\Lib\*.pas LibSource    2>&1 || goto :ERROR
mklink /D Samples\Pas ..\..\InstallerSamples 2>&1 || goto :ERROR
@echo [INFO] Done.

@echo. & echo [%~nx0]
@echo +======================================================================== Step 10/16 ==+
@echo !  Generating Win7+ compatible installers and packages (not for XP!):                  !
@echo +======================================================================================+
@echo.
@rem @cd /d "%project_root%\ReleaseGenerators" 2>&1 || goto :ERROR
call PascalABCNET_ALL.bat 2>&1 || goto :ERROR
@echo [INFO] Done.

@echo. & echo [%~nx0]
@echo +======================================================================== Step 11/16 ==+
@echo !  Temporary saving current \bin directory with .NET 4.7.1 Pascal binaries as \bin2:   !
@echo +======================================================================================+
@echo.
@rem @cd /d "%project_root%"
@cd ..
@rmdir /S /Q bin2 1>nul 2>nul
rename bin\ bin2  2>&1 || goto :ERROR
@echo [INFO] Done.

@echo. & echo [%~nx0]
@echo +======================================================================== Step 12/16 ==+
@echo !  Preparing new \bin directory from \bin_copy and \bin2\Lib                           !
@echo +======================================================================================+
@echo.
@rem @cd /d "%project_root%"
rename bin_copy\ bin                  2>&1 || goto :ERROR
@rem copy /Y bin2\Lib\*.pcu bin\Lib\  2>&1 || goto :ERROR
copy /Y bin2\Lib\PABCRtl.dll bin\Lib\ 2>&1 || goto :ERROR
@echo [INFO] PABCRtl.dll copied to \bin\Lib

@echo. & echo [%~nx0]
@echo +======================================================================== Step 13/16 ==+
@echo !  Re-Building project using .NET 4.0 as target (for WinXP compatibility):             !
@echo +======================================================================================+
@echo.
@rem @cd /d "%project_root%"
call Studio.bat /m /t:Rebuild "/p:Configuration=Release" "/p:Platform=Any CPU" PascalABCNET_40.sln 2>&1 || goto :ERROR
@rem call Studio.bat /m /t:Rebuild "/p:Configuration=Debug" "/p:Platform=Any CPU" PascalABCNET_40.sln 2>&1 || goto :ERROR
@echo [INFO] Done.

@echo. & echo [%~nx0]
@echo +======================================================================== Step 14/16 ==+
@echo !  Re-Building Pascal standard units (for WinXP):                                      !
@echo +======================================================================================+
@echo.
@rem @cd /d "%project_root%\ReleaseGenerators"                                   2>&1 || goto :ERROR
@cd ReleaseGenerators                                                            2>&1 || goto :ERROR
@if /i {%QUIET_MODE%} EQU {true} (
    ..\bin\pabcnetc RebuildStandartModules.pas /rebuildnodebug /noconsole 1>nul 2>nul || goto :ERROR
) else (
    ..\bin\pabcnetc RebuildStandartModules.pas /rebuildnodebug /noconsole        2>&1 || goto :ERROR)
@rem ..\bin\pabcnetcclear /Debug:0 RebuildStandartModules.pas ..\bin\Temp        2>&1 || goto :ERROR
@echo [INFO] Standard units successfully built.

@echo. & echo [%~nx0]
@echo +======================================================================== Step 15/16 ==+
@echo !  Generating WinXP compatible installer:                                              !
@echo +======================================================================================+
@echo.
@rem @cd /d "%project_root%\ReleaseGenerators" 2>&1 || goto :ERROR
call PascalABCNETWithDotNet40.bat 2>&1 || goto :ERROR
@echo [INFO] Done.

@echo. & echo [%~nx0]
@echo +======================================================================== Step 16/16 ==+
@echo !  Final cleanup -- removing temporary symlinks and restoring \bin dir:                !
@echo +======================================================================================+
@echo.
:: 1) restoring previous \bin directory with .NET 4.7.1 pascal binaries from bin2\
:: 2) removing all temporary sample dirs created before for packaging
@rem @cd /d "%project_root%"
@cd ..
rmdir /S /Q bin && rename bin2\ bin       2>&1 || goto :ERROR
rmdir /S /Q ReleaseGenerators\LibSource   2>&1 || goto :ERROR
rmdir /S /Q ReleaseGenerators\Samples\Pas 2>&1 || goto :ERROR
@echo [INFO] Done.

@popd
@echo. & echo [%~nx0]
@echo ####################################### FINISHED #######################################
@echo.
@goto :EOF

:ERROR
    @SET exit_code=%ERRORLEVEL%
    :: In case of error Pascal binaries for Win7+ (.NET 4.7.1 target) could remain laying in \bin2 (if it exists)
    :: In that case \bin dir would contain Pascal binaries compiled for XP (.NET 4.0 target)
    :: If desired, uncomment next line to always restore Win7+ compatible binaries (if they were compiled at all) to \bin dir in case of any error
    @if exist "%project_root%\bin2" (
        rmdir /S /Q "%project_root%\bin"                        1>nul 2>nul && ^
        move "%project_root%\bin2" "%project_root%\bin"         1>nul 2>nul)
    @rmdir /S /Q "%project_root%\bin_copy"                      1>nul 2>nul
    @rmdir /S /Q "%project_root%\ReleaseGenerators\LibSource"   1>nul 2>nul
    @rmdir /S /Q "%project_root%\ReleaseGenerators\Samples\Pas" 1>nul 2>nul
    @echo. & echo [%~nx0] ***ERROR*** Last command failed with exit code %exit_code%. & echo.
    :: DEBUG: Alternative line: @popd
    @popd
    @pause
    @exit /B %exit_code%
