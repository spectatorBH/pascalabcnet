::============================================================================================
::#  Written by spectatorBH for PascalABC.NET project. Published as public domain, Sep-2020  #
::============================================================================================
::
@echo on
SETLOCAL
echo.
echo [%~nx0] ------ SCRIPT STARTED -------
echo.
echo [INFO] Converting line-endings in all '*.pas' files under 'TestSuite\formatter_tests' to CR/LF standard:
findstr /e /i "VBS-line" "%~0" > "%temp%\~rewrite-lines.vbs" 
set _err_code=%ERRORLEVEL% & echo ERRORLEVEL = %ERRORLEVEL%
if %_err_code% NEQ 0 goto ERROR
@rem || goto ERROR
dir "%temp%"
type "%temp%\~rewrite-lines.vbs"


set "_dir=%~dp0..\TestSuite\formatter_tests"
forfiles /m *.pas /s /p "%_dir%" /c "cmd /c echo Rewriting -- @path && cscript //NoLogo """%temp%\~rewrite-lines.vbs""" <@path >@path.CRLF && move /Y @path.CRLF @path 1>nul"

if %ERRORLEVEL% NEQ 0 (goto ERROR)
del /q %temp%\~rewrite-lines.vbs > nul
echo.
echo [%~nx0] ------ SCRIPT FINISHED ------
echo.
goto :EOF

:ERROR
echo.
echo *** ERROR: Command exited with error code %ERRORLEVEL%
echo.
goto :EOF

:: Embedded VBS script BEGIN: +++++++++++++++++++++++++++++
Do Until WScript.StdIn.AtEndOfStream              'VBS-line
  WScript.StdOut.WriteLine WScript.StdIn.ReadLine 'VBS-line
Loop                                              'VBS-line
:: Embedded VBS script END: +++++++++++++++++++++++++++++++
