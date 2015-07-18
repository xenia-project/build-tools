@ECHO OFF
REM Copyright 2015 Ben Vanik. All Rights Reserved.

SET DIR=%~dp0

SET VS14_VCVARSALL="C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat"
SET VS15_VCVARSALL="C:\Program Files (x86)\Microsoft Visual Studio 15.0\VC\vcvarsall.bat"

SET PREMAKE_PATH=%DIR%\third_party\premake-core\
SET PREMAKE_BIN=%PREMAKE_PATH%\bin\release\premake5.exe

CALL :check_msvc
IF %_RESULT% NEQ 0 (
  ECHO ERROR:
  ECHO Visual Studio 2015 must be installed.
  ECHO.
  ECHO The Community Edition is free and can be downloaded here:
  ECHO https://www.visualstudio.com/downloads/visual-studio-2015-downloads-vs
  ECHO.
  ECHO Once installed, launch the 'Developer Command Prompt for VS2015' and run
  ECHO this script again.
  GOTO :exit_error
)

IF NOT EXIST %PREMAKE_BIN% (
  ECHO premake5.exe not found - bootstrapping...
  CALL %DIR%\bootstrap.bat
  IF %ERRORLEVEL% NEQ 0 (
    ECHO Unable to boostrap. You're boned.
    EXIT /b 1
  )
)

%PREMAKE_BIN% --scripts=%PREMAKE_PATH% %*
EXIT /b %ERRORLEVEL%



:check_msvc
SETLOCAL EnableDelayedExpansion
1>NUL 2>NUL CMD /c where devenv
IF %ERRORLEVEL% NEQ 0 (
  IF EXIST %VS15_VCVARSALL% (
    REM VS2015
    ECHO Sourcing Visual Studio settings from %VS15_VCVARSALL%...
    CALL %VS15_VCVARSALL% amd64
  ) ELSE (
    IF EXIST %VS14_VCVARSALL% (
      REM VS2015 CTP/RC
      ECHO Sourcing Visual Studio settings from %VS14_VCVARSALL%...
      CALL %VS14_VCVARSALL% amd64
    )
  )
)
1>NUL 2>NUL CMD /c where devenv
IF %ERRORLEVEL% NEQ 0 (
  REM Still no devenv!
  ENDLOCAL & SET _RESULT=1
  GOTO :eof
)
SET HAVE_TOOLS=0
IF "%VS140COMNTOOLS%" NEQ "" (
  IF EXIST "%VS140COMNTOOLS%" (
    REM VS2015 CTP/RC
    SET HAVE_TOOLS=1
  )
)
IF "%VS150COMNTOOLS%" NEQ "" (
  IF EXIST "%VS150COMNTOOLS%" (
    REM VS2015
    SET HAVE_TOOLS=1
  )
)
IF %HAVE_TOOLS% NEQ 1 (
  ENDLOCAL & SET _RESULT=1
  GOTO :eof
)
ENDLOCAL & SET _RESULT=0
GOTO :eof
