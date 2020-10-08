@echo. & echo [%~nx0]
@echo ############################ MAIN SCRIPT STARTED #######################################
@SETLOCAL EnableExtensions
@if /i {%PABCNET_VERBOSE%} NEQ {true} echo OFF
@if /i {%PABCNET_BUILD_MODE%} EQU {Release} (set "_BUILD_MODE=Release") else (set "_BUILD_MODE=Debug")
@if /i {%~1} EQU {Release} (set "_BUILD_MODE=Release")
@if /i {%~1} EQU {Debug}   (set "_BUILD_MODE=Debug")
@echo. & echo [INFO] Using %_BUILD_MODE%-mode configuration...
:: Making sure batch file would run properly regardless of where it was launched from (due to usage of relative paths)
@SET launched_from=%CD%
@SET project_root=%~dp0
pushd "%project_root%"
@rem pushd "%~dp0"

@echo. & echo [%~nx0]
@echo +======================================================================== Step 1/16 ===+
@echo !  Incrementing current Build No. (aka Revision) in various places:                    !
@echo +======================================================================================+
cd /d "%project_root%"
@if /i {%PABCNET_INC_BUILD%} NEQ {true} (echo. & echo [INFO] *** Skipping -- No build/revision update... & goto SKIP1)
:: ToDo: fix filename spelling error for 'IncrementVresion.exe' -> 'IncrementVersion.exe';
:: ToDo: implement reporting of processed files & basic error handling in the tools below:
utils\IncrementVresion\IncrementVresion.exe Configuration\Version.defs REVISION 1                                                                             2>&1 || goto ERROR
utils\ReplaceInFiles\ReplaceInFiles.exe Configuration\Version.defs Configuration\GlobalAssemblyInfo.cs.tmpl Configuration\GlobalAssemblyInfo.cs               2>&1 || goto ERROR
utils\ReplaceInFiles\ReplaceInFiles.exe Configuration\Version.defs ReleaseGenerators\PascalABCNET_version.nsh.tmpl ReleaseGenerators\PascalABCNET_version.nsh 2>&1 || goto ERROR
utils\ReplaceInFiles\ReplaceInFiles.exe Configuration\Version.defs Configuration\pabcversion.txt.tmpl Release\pabcversion.txt                                 2>&1 || goto ERROR
@echo. & echo [INFO] Done step #1.
:SKIP1

@echo. & echo [%~nx0]
@echo +======================================================================== Step 2/16 ===+
@echo !  Making a working copy of \bin directory for later usage:                            !
@echo +======================================================================================+
@echo.
cd /d "%project_root%"
@rmdir /S /Q bin_copy         >nul 2>&1
@if /i {%PABCNET_VERBOSE%} NEQ {true} (
    xcopy /I /E /Q /Y bin bin_copy 2>&1 || goto ERROR
) else (
    xcopy /I /E /F /Y bin bin_copy 2>&1 || goto ERROR)
@echo. & echo [INFO] Done step #2 -- Created \bin_copy from \bin.

@echo. & echo [%~nx0]
@echo +======================================================================== Step 3/16 ===+
@echo !  Generating default language resource file:                                          !
@echo +======================================================================================+
@echo.
@rem cd utils\DefaultLanguageResMaker                2>&1 || goto ERROR
cd /d "%project_root%\utils\DefaultLanguageResMaker" 2>&1 || goto ERROR
:: ToDo: implement basic error handling in the 'LanguageResMaker.exe' tool
LanguageResMaker.exe                                 2>&1 || goto ERROR
@echo. & echo [INFO] Done step #3.

@echo. & echo [%~nx0]
@echo +======================================================================== Step 4/16 ===+
@echo !  Building project using .NET 4.7.1 as target (for Win7+ platforms):                  !
@echo +======================================================================================+
@echo.
@rem cd ..\..
cd /d "%project_root%"
call Studio.bat /m /t:Rebuild "/p:Configuration=%_BUILD_MODE%" "/p:Platform=Any CPU" PascalABCNET.sln 2>&1 || goto ERROR
@echo. & echo [INFO] Done step #4.

@echo. & echo [%~nx0]
@echo +======================================================================== Step 5/16 ===+
@echo !  Building PABCRtl.dll -- Pascal special standalone runtime library for IDE:          !
@echo +======================================================================================+
@rem cd ReleaseGenerators\PABCRtl                                            2>&1 || goto ERROR
cd /d "%project_root%\ReleaseGenerators\PABCRtl"                             2>&1 || goto ERROR
if /i {%_BUILD_MODE%} EQU {Release} (echo. & if /i {%PABCNET_VERBOSE%} NEQ {true} (
            ..\..\bin\pabcnetc PABCRtl.pas /rebuildnodebug /noconsole  1>nul 2>&1 || goto ERROR
    ) else (..\..\bin\pabcnetc PABCRtl.pas /rebuildnodebug /noconsole        2>&1 || goto ERROR)
) else (echo. & if /i {%PABCNET_VERBOSE%} NEQ {true} (
            ..\..\bin\pabcnetc PABCRtl.pas /rebuild /noconsole         1>nul 2>&1 || goto ERROR
    ) else (..\..\bin\pabcnetc PABCRtl.pas /rebuild /noconsole               2>&1 || goto ERROR))
@echo. & dir | find "PABCRtl.dll"
@echo. & echo [INFO] Done step #5 -- PABCRtl.dll successfully built.

@echo.
@echo [%~nx0]
@echo +======================================================================== Step 6/16 ===+
@echo !  Signing and registering fresh PABCRtl.dll in GAC:                                   !
@echo +======================================================================================+
@echo.
cd /d "%project_root%\ReleaseGenerators\PABCRtl"  2>&1 || goto ERROR
@if /i {%PABCNET_VERBOSE%} NEQ {true} (
    ..\sn.exe -q -Vr PABCRtl.dll                  2>&1 || goto ERROR
    ..\sn.exe -q -R  PABCRtl.dll KeyPair.snk      2>&1 || goto ERROR
    ..\sn.exe -q -Vu PABCRtl.dll                  2>&1 || goto ERROR
    echo. & echo [INFO] Copying PABCRtl.dll to \bin\Lib...
    xcopy /Q /Y PABCRtl.dll ..\..\bin\Lib\        2>&1 || goto ERROR
) else (
    ..\sn.exe -Vr PABCRtl.dll                     2>&1 || goto ERROR
    ..\sn.exe -R  PABCRtl.dll KeyPair.snk         2>&1 || goto ERROR
    ..\sn.exe -Vu PABCRtl.dll                     2>&1 || goto ERROR
    echo. & echo [INFO] Copying PABCRtl.dll to \bin\Lib...
    xcopy /F /Y PABCRtl.dll ..\..\bin\Lib\        2>&1 || goto ERROR)
echo.
cd ..
gacutil.exe /nologo /u PABCRtl              1>nul 2>&1 || goto ERROR
gacutil.exe /nologo /f /i ..\bin\Lib\PABCRtl.dll  2>&1 || goto ERROR
@echo. & echo [INFO] Done step #6 -- PABCRtl.dll (\bin\Lib) signed and registered in GAC.

@echo. & echo [%~nx0]
@echo +======================================================================== Step 7/16 ===+
@echo !  Building all Pascal standard units:                                                 !
@echo +======================================================================================+
cd /d "%project_root%\ReleaseGenerators"                                                 2>&1 || goto ERROR
@if /i {%_BUILD_MODE%} EQU {Release} (if /i {%PABCNET_VERBOSE%} NEQ {true} (
            ..\bin\pabcnetc RebuildStandartModules.pas /rebuildnodebug /noconsole  1>nul 2>&1 || goto ERROR
    ) else (..\bin\pabcnetc RebuildStandartModules.pas /rebuildnodebug /noconsole        2>&1 || goto ERROR)
) else (if /i {%PABCNET_VERBOSE%} NEQ {true} (
            ..\bin\pabcnetc RebuildStandartModules.pas /rebuild /noconsole         1>nul 2>&1 || goto ERROR
    ) else (..\bin\pabcnetc RebuildStandartModules.pas /rebuild /noconsole               2>&1 || goto ERROR))
@echo. & echo [INFO] Done step #7 -- Standard units successfully built.

@echo. & echo [%~nx0]
@echo +======================================================================== Step 8/16 ===+
@echo !  Performing compilation, unit and functional tests:                                  !
@echo +======================================================================================+
@if /i {%PABCNET_RUN_TESTS%} NEQ {true} (echo. & echo [INFO] *** Skipping -- Tests will NOT be run... & goto SKIP8)
@rem cd ..\bin                     2>&1 || goto ERROR
cd /d "%project_root%\bin"         2>&1 || goto ERROR
:: DEBUG: fixing CR/LF line-endings for *.pas files in \TestSuite\formatter_tests (useful only in GitHub VM sessions)
:: https://github.com/pascalabcnet/pascalabcnetide/issues/196
@rem set GITHUB_
@rem if defined GITHUB_ACTIONS (
@rem     echo [INFO] Calling fix-CRLF-for-TestRunner.bat script as a workaround for IDE bug #196...
@rem     call ..\Utils\fix-CRLF-for-TestRunner.bat    || goto ERROR)
:: ToDo: add compilation tests to TestRunner for bundled demo samples;
:: ToDo: research possibility of running some tests in parallel (improve TestRunner or refactor GitHub Actions config);
@echo [INFO] Compiling fresh TestRunner_orig.pas...
pabcnetcclear TestRunner_orig.pas  2>&1 || goto ERROR
@echo [INFO] Launching TestRunner_orig.exe...
TestRunner_orig.exe 6              2>&1 || goto ERROR
@rem TestRunner_orig.exe                2>&1 || goto ERROR
@echo [INFO] Compiling fresh TestRunner.pas...
pabcnetcclear TestRunner.pas       2>&1 || goto ERROR
@echo [INFO] Launching TestRunner.exe...
TestRunner.exe 5                   2>&1 || goto ERROR
REM TestRunner.exe                     2>&1 || goto ERROR
@if /i {%PABCNET_NOT_VERBOSE%} NEQ {true} type TestRunner_log.txt
@echo. & echo [INFO] Done step #8 -- All tests successfully accomplished.
:SKIP8

@echo. & echo [%~nx0]
@echo +======================================================================== Step 9/16 ===+
@echo !  Preparing Pascal demo samples and library sources for packaging:                    !
@echo +======================================================================================+
@echo.
@rem cd ..\ReleaseGenerators                          2>&1 || goto ERROR
cd /d "%project_root%\ReleaseGenerators"              2>&1 || goto ERROR
@rmdir /S /Q LibSource                           >nul 2>&1
@if /i {%PABCNET_VERBOSE%} NEQ {true} (
    xcopy /I /Q /Y ..\bin\Lib\*.pas LibSource         2>&1 || goto ERROR
    mklink /D Samples\Pas ..\..\InstallerSamples >nul 2>&1 || goto ERROR
) else (
    xcopy /I /F /Y ..\bin\Lib\*.pas LibSource         2>&1 || goto ERROR
    mklink /D Samples\Pas ..\..\InstallerSamples      2>&1 || goto ERROR)
@echo. & echo [INFO] Done step #9 -- \LibSource and \Samples ready.

@echo. & echo [%~nx0]
@echo +======================================================================== Step 10/16 ==+
@echo !  Generating Win7+ compatible installers and packages (not for XP!):                  !
@echo +======================================================================================+
@echo.
cd /d "%project_root%\ReleaseGenerators" 2>&1 || goto ERROR
call PascalABCNET_ALL.bat                2>&1 || goto ERROR
@echo. & echo [INFO] Done step #10.

@echo. & echo [%~nx0]
@echo +======================================================================== Step 11/16 ==+
@echo !  Saving updated \bin directory with fresh .NET 4.7.1 Pascal binaries as \bin2:       !
@echo +======================================================================================+
@rem cd .. >nul
cd /d "%project_root%"
@rmdir /S /Q bin2  >nul 2>&1
rename bin\ bin2        2>&1 || goto ERROR
@echo. & echo [INFO] Done step #11 -- Renamed \bin to \bin2

@echo. & echo [%~nx0]
@echo +======================================================================== Step 12/16 ==+
@echo !  Making new isolated \bin directory from saved \bin_copy and fresh PABCRtl.dll       !
@echo +======================================================================================+
@echo.
cd /d "%project_root%"
rename bin_copy\ bin                          2>&1 || goto ERROR
:: ToDo: Is it really necessary to rebuild Pascal standard units again for use with .NET 4.0? (see step 14)
@if /i {%PABCNET_VERBOSE%} NEQ {true} (
    xcopy /Q /Y bin2\Lib\*.pcu bin\Lib\       2>&1 || goto ERROR
    xcopy /Q /Y bin2\Lib\PABCRtl.dll bin\Lib\ 2>&1 || goto ERROR
) else (
    xcopy /L /F bin2\Lib\*.pcu bin\Lib\       2>&1 || goto ERROR
    xcopy /L /F bin2\Lib\PABCRtl.dll bin\Lib\ 2>&1 || goto ERROR)
@echo. & echo [INFO] Done step #12 -- Renamed \bin_copy to \bin, copied prebuilt *.pcu modules + PABCRtl.dll to \bin\Lib

@echo. & echo [%~nx0]
@echo +======================================================================== Step 13/16 ==+
@echo !  Re-Building project using .NET 4.0 as target (for WinXP compatibility):             !
@echo +======================================================================================+
@echo.
cd /d "%project_root%"
call Studio.bat /m /t:Rebuild "/p:Configuration=%_BUILD_MODE%" "/p:Platform=Any CPU" PascalABCNET_40.sln 2>&1 || goto ERROR
@echo. & echo [INFO] Done step #13.

@echo. & echo [%~nx0]
@echo +======================================================================== Step 14/16 ==+
@echo !  Re-Building Pascal standard units (for WinXP):                                      !
@echo +======================================================================================+
:: ToDo: Is it really necessary to rebuild Pascal standard units again for use with .NET 4.0?
@echo. & echo [INFO] *** Skipping -- Will use prebuilt units and dll from step #12
@goto SKIP14
cd /d "%project_root%\ReleaseGenerators"                                                2>&1 || goto ERROR
cd ReleaseGenerators                                                                    2>&1 || goto ERROR
@if /i {%_BUILD_MODE%} EQU {Release} (if /i {%PABCNET_VERBOSE%} NEQ {true} (
            ..\bin\pabcnetc RebuildStandartModules.pas /rebuildnodebug /noconsole  >nul 2>&1 || goto ERROR
    ) else (..\bin\pabcnetc RebuildStandartModules.pas /rebuildnodebug /noconsole       2>&1 || goto ERROR)
) else (if /i {%PABCNET_VERBOSE%} NEQ {true} (
            ..\bin\pabcnetc RebuildStandartModules.pas /rebuild /noconsole         >nul 2>&1 || goto ERROR
    ) else (..\bin\pabcnetc RebuildStandartModules.pas /rebuild /noconsole              2>&1 || goto ERROR))
@echo. & echo [INFO] Done step #14 -- Standard units successfully re-built.
:SKIP14

@echo. & echo [%~nx0]
@echo +======================================================================== Step 15/16 ==+
@echo !  Generating WinXP compatible installer:                                              !
@echo +======================================================================================+
@echo.
@rem cd ReleaseGenerators                 2>&1 || goto ERROR
cd /d "%project_root%\ReleaseGenerators"  2>&1 || goto ERROR
call PascalABCNETWithDotNet40.bat         2>&1 || goto ERROR
@echo. & echo [INFO] Done step #15.

@echo. & echo [%~nx0]
@echo +======================================================================== Step 16/16 ==+
@echo !  Final cleanup -- removing temporary symlinks and restoring \bin dir:                !
@echo +======================================================================================+
:: 1) restoring previous \bin directory with .NET 4.7.1 pascal binaries from bin2\
:: 2) removing all temporary sample dirs created before for packaging
@rem cd .. >nul
cd /d "%project_root%"
rmdir /S /Q bin && rename bin2\ bin        2>&1 || goto ERROR
rmdir /S /Q ReleaseGenerators\LibSource    2>&1 || goto ERROR
rmdir /S /Q ReleaseGenerators\Samples\Pas  2>&1 || goto ERROR
@echo. & echo [INFO] Done step #16 -- restored \bin with Pascal binaries for .NET 4.7.1 target (Win7+).

popd
@echo. & echo [%~nx0]
@echo ############################ MAIN SCRIPT FINISHED ######################################
@echo.
@goto :EOF

:ERROR
    @SET exit_code=%ERRORLEVEL%
    :: In case of error Pascal binaries for Win7+ (.NET 4.7.1 target) could remain laying in \bin2 (if it exists)
    :: In that case \bin dir would contain Pascal binaries compiled for XP (.NET 4.0 target)
    :: If desired, uncomment next line to always restore Win7+ compatible binaries (if they were compiled at all) to \bin dir in case of any error
    @if exist "%project_root%\bin2" (
        rmdir /S /Q "%project_root%\bin"                        1>nul 2>&1 && ^
        move /Y "%project_root%\bin2" "%project_root%\bin"      1>nul 2>&1)
    @rmdir /S /Q "%project_root%\bin_copy"                      1>nul 2>&1
    @rmdir /S /Q "%project_root%\ReleaseGenerators\LibSource"   1>nul 2>&1
    @rmdir /S /Q "%project_root%\ReleaseGenerators\Samples\Pas" 1>nul 2>&1
    @echo. & echo [%~nx0] ***ERROR*** Last command failed with exit code %exit_code%. & echo.
    @popd
    @pause
    @exit /B %exit_code%
