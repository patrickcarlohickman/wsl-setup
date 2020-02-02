@ECHO off

SETLOCAL EnableExtensions
SET me=%~n0

CALL wsl-instance.bat %me% %*