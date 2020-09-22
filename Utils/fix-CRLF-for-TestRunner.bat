@echo off
echo [%~nx0] --------------------------------------------------------------------------------
echo Trying to convert line-endings in all '*.pas' files under 'TestSuite\formatter_tests' to CR/LF standard
echo.
findstr /e /i "VBS-line" "%~0" > "%temp%\~rewrite-lines.vbs" || goto ERROR

forfiles /m *.pas /s /p "%~dp0..\TestSuite\formatter_tests" /c "cmd /c echo Rewriting -- @path && cscript //NoLogo """%temp%\~rewrite-lines.vbs""" <@path >@path.CRLF && move /Y @path.CRLF @path 1>nul"
if %ERRORLEVEL% NEQ 0 (goto ERROR)

del /q %temp%\~rewrite-lines.vbs > nul
echo.
echo [%~nx0] FINISHED -----------------------------------------------------------------------
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
