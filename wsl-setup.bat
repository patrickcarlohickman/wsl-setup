@ECHO off

REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
REM :: Some nice startup stuff
REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SETLOCAL EnableExtensions
SET ME=%~n0
SET PARENT=%~dp0

REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
REM :: Define the exit codes for the script. Powers of 2 for bitwise work.
REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SET /A ERRNO=0
SET /A MUST_BE_ADMIN=1
SET /A SETUP_MISSING_FILES=2
SET /A WSL_NOT_ENABLED=4

REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
REM :: Define main variables for the script.
REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SET INSTALLERS_DIRECTORY=%PARENT%setup\installers
SET RESOURCES_DIRECTORY=%PARENT%setup\resources
SET ENV_FILE=%PARENT%setup\.env

REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
REM :: Sanity checks.
REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
Dism >NUL 2>&1
IF %ERRORLEVEL% EQU 740 (
    ECHO %ME%: Error: Script must be run with admin rights. Please run as administrator. 1>&2
    SET /A ERRNO^|=%MUST_BE_ADMIN%
)

IF NOT EXIST "%INSTALLERS_DIRECTORY%" (
    ECHO %ME%: Error: Installers directory "%INSTALLERS_DIRECTORY%" does not exist. 1>&2
    SET /A ERRNO^|=%SETUP_MISSING_FILES%
) ELSE (
    IF NOT EXIST "%RESOURCES_DIRECTORY%" (
        ECHO %ME%: Error: Resources directory "%RESOURCES_DIRECTORY%" does not exist. 1>&2
        SET /A ERRNO^|=%SETUP_MISSING_FILES%
    ) ELSE (
        IF NOT EXIST "%ENV_FILE%" (
            ECHO %ME%: Error: Environment file "%ENV_FILE%" does not exist. 1>&2
            SET /A ERRNO^|=%SETUP_MISSING_FILES%
        )
    )
)

IF %ERRNO% NEQ 0 (
    ECHO %ME%: Sanity checks failed. Stopping script. 1>&2
    GOTO done
)

REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
REM :: Main script logic.
REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

ECHO Loading environment variables...
FOR /F "tokens=*" %%A IN ('TYPE %ENV_FILE%') DO SET %%A
ECHO Environment loaded.

IF NOT EXIST "%WSL_DIRECTORY%" (
    MKDIR "%WSL_DIRECTORY%"
)

curl.exe -L -o ubuntu-1804.appx https://aka.ms/wsl-ubuntu-1804
powershell -Command "Add-AppPackage -Path """"C:\WSL\working\ubuntu-1804.appx"""""
ubuntu1804
..\Tools\LxRunOffline\LxRunOffline.exe d -n Ubuntu-18.04 -d C:\WSL\ubuntu-dev -N ubuntu-dev
powershell -Command "Remove-AppxPackage -Package """"CanonicalGroupLimited.Ubuntu18.04onWindows_1804.2018.817.0_x64__79rhkp1fndgsc"""""

ECHO Checking if WSL is enabled...
CALL :check_wsl_enabled
IF %ERRORLEVEL% GTR 0 (
    ECHO %ME%: Error: The Windows Subsystem for Linux feature must be enabled. The script will now exit. 1>&2
    SET /A ERRNO^|=%WSL_NOT_ENABLED%
    GOTO done
)
ECHO WSL is enabled.

REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
REM :: Exit paths should point to here.
REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:done
IF %ERRNO% NEQ 0 (
    ECHO %ME%: Script completed with errors.
)
PAUSE
EXIT /B %ERRNO%

REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
REM :: Function definitions.
REM :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:check_wsl_enabled
    Dism /Online /Get-Featureinfo /FeatureName:Microsoft-Windows-Subsystem-Linux | findstr /C:"State : Enabled" >NUL 2>&1
    IF %ERRORLEVEL% EQU 0 (
        EXIT /B 0
    )

    CALL :prompt_enable
    IF %ERRORLEVEL% GTR 0 (
        EXIT /B %ERRORLEVEL%
    )

    CALL :enable_wsl
EXIT /B %ERRORLEVEL%

:prompt_enable
    ECHO Windows Subsystem for Linux feature is not enabled. It must be enabled to continue.
    SET /P enable="Would you like to enable it now (Y/N)? [N] "
    ECHO.%enable% | findstr /I "^y" >NUL 2>NUL
EXIT /B %ERRORLEVEL%

:enable_wsl
    Dism /Online /Enable-Feature /FeatureName:Microsoft-Windows-Subsystem-Linux /Quiet /NoRestart
    ECHO Windows Subsystem for Linux feature is not enabled. It must be enabled to continue.
    SET /P enable="Would you like to enable it now (Y/N)? [N] "
    ECHO.%enable% | findstr /I "^y" >NUL 2>NUL
EXIT /B %ERRORLEVEL%