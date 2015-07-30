@ECHO OFF
REM Copyright 2015 Ben Vanik. All Rights Reserved.

SET DIR=%~dp0

SET VS14_VCVARSALL="C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat"
SET VS15_VCVARSALL="C:\Program Files (x86)\Microsoft Visual Studio 15.0\VC\vcvarsall.bat"

ECHO.
REM ============================================================================
REM Environment Validation
REM ============================================================================
REM To make life easier we just require everything before we try running.

CALL :check_git
IF %_RESULT% NEQ 0 (
  ECHO ERROR:
  ECHO git must be installed and on PATH.
  EXIT /b 1
)

CALL :check_python
IF %_RESULT% NEQ 0 (
  ECHO ERROR:
  ECHO Python 2.7 must be installed and on PATH:
  ECHO https://www.python.org/ftp/python/2.7.9/python-2.7.9.msi
  EXIT /b 1
)

CALL :check_msvc
IF %_RESULT% NEQ 0 (
  ECHO ERROR:
  ECHO Visual Studio 2015 must be installed.
  ECHO.
  ECHO The Community Edition is free and can be downloaded here:
  ECHO https://www.visualstudio.com/downloads/visual-studio-2015-downloads-vs
  ECHO Make sure to install the Windows SDK.
  ECHO.
  ECHO Once installed, launch the 'Developer Command Prompt for VS2015' and run
  ECHO this script again.
  EXIT /b 1
)
1>NUL 2>NUL CMD /c where devenv
IF %ERRORLEVEL% NEQ 0 (
  CALL %VS14_VCVARSALL% amd64
)

REM ============================================================================
REM Fetch Everything
REM ============================================================================
ECHO Fetching submodules and other resources...

ECHO.
ECHO ^> git submodule update --init --recursive
PUSHD %DIR%
git submodule update --init --recursive
IF %ERRORLEVEL% NEQ 0 (
  ECHO.
  ECHO ERROR: failed to initialize git submodules
  EXIT /b 1
)
POPD

ECHO.
REM ============================================================================
REM Build Premake
REM ============================================================================
ECHO Building premake...

ECHO.
ECHO ^> nmake -f Bootstrap.mak windows
PUSHD %DIR%\third_party\premake-core\
nmake -f Bootstrap.mak windows
SET _RESULT=%ERRORLEVEL%
POPD

IF %_RESULT% NEQ 0 (
  EXIT /b 1
)

ECHO.
ECHO ^> copy third_party\premake-core\bin\release\premake5.exe bin\
COPY %DIR%\third_party\premake-core\bin\release\premake5.exe %DIR%\bin\

EXIT /b 0


REM ============================================================================
REM Utilities
REM ============================================================================

:check_python
SETLOCAL
1>NUL 2>NUL CMD /c where python
IF %ERRORLEVEL% NEQ 0 (
  ENDLOCAL & SET _RESULT=1
  GOTO :eof
)
CMD /c python -c "import sys; sys.exit(1 if not sys.version_info[:2] == (2, 7) else 0)"
IF %ERRORLEVEL% NEQ 0 (
  ENDLOCAL & SET _RESULT=1
  GOTO :eof
)
ENDLOCAL & SET _RESULT=0
GOTO :eof

:check_git
1>NUL 2>NUL CMD /c where git
SET _RESULT=%ERRORLEVEL%
GOTO :eof

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
