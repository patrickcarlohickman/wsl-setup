@ECHO off

REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
REM :: Some nice startup stuff
REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

SETLOCAL ENABLEEXTENSIONS
SET me=%~n0
SET parent=%~dp0

REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
REM :: Define the exit codes for the script. Powers of 2 for bitwise work.
REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

SET /A errno=0

REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
REM :: Define main variables for the script.
REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

SET ps_script="%me%.ps1"

REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
REM :: Main script logic.
REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -Verb RunAs powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -NoLogo -File \"%parent%\%ps_script%\"'"

REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
REM :: Exit paths should point to here.
REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:done
IF %errno% NEQ 0 (
  ECHO %me%: Script complete with errors.
  PAUSE
) ELSE (
  ECHO %me%: Script completed successfully.
)

EXIT /B %errno%
