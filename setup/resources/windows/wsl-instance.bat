@ECHO off

REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
REM :: Some nice startup stuff
REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SETLOCAL EnableExtensions
SET me=%~n0
SET parent=%~dp0

REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
REM :: Define the exit codes for the script. Powers of 2 for bitwise work.
REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SET /A errno=0
SET /A WSL_EXE_DOES_NOT_EXIST=1
SET /A DISTRIBUTION_NOT_FOUND=2
SET /A INVALID_COMMAND=4

REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
REM :: Define main variables for the script.
REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SET wsl_exe=C:\Windows\System32\wsl.exe
SET registry_parent=HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Lxss
SET distribution_name=%1

REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
REM :: Sanity checks.
REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
IF NOT EXIST "%wsl_exe%" (
    ECHO %me%: Error: WSL executable "%wsl_exe%" does not exist. 1>&2
    SET /A errno^|=%WSL_EXE_DOES_NOT_EXIST%
)

IF %errno% NEQ 0 (
    ECHO %me%: Sanity checks failed. Stopping script. 1>&2
    GOTO done
)

REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
REM :: Main script logic.
REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

FOR /F "usebackq delims=\ tokens=7" %%K IN (`reg query %registry_parent% /s /f "%distribution_name%" /e /d ^| findstr "%registry_parent%"`) DO SET key=%%K
IF NOT "%key:~0,1%" == "{" (
    ECHO %me%: Error: Registry entry for DistributionName "%distribution_name%" not found. 1>&2
    SET /A errno^|=%DISTRIBUTION_NOT_FOUND%
    GOTO done
)

REM :: Parse any arguments passed to the original script. We can't do
REM :: everything the original launcher.exe can, but we can support
REM :: the "run" command and the tilde (~) argument.

FOR /F "tokens=1,2,* delims= " %%A IN ("%*") DO (
    SET command=%%B
    SET args=%%C
)

IF "%command%"=="" (
    SET command=run
    SET args=
)

IF "%command%"=="~" (
    SET command=run
    SET args=~
)

IF NOT "%command%"=="run" (
    ECHO %me%: Error: Only "run" command or "~" argument allowed. 1>&2
    SET /A errno^|=%INVALID_COMMAND%
    GOTO done
)

%wsl_exe% %key% %args%

REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
REM :: Exit paths should point to here.
REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:done
IF %errno% NEQ 0 (
  ECHO %me%: Script completed with errors.
)
EXIT /B %errno%

REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
REM :: Function definitions.
REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
