@echo off
rem Offline Android build. Usage:
rem   offline\build.bat                 -> assembleDebug
rem   offline\build.bat assembleRelease
rem   offline\build.bat installDebug    (device connected via adb)
setlocal
set "ROOT=%~dp0.."
pushd "%ROOT%"
set "ROOT=%CD%"
if exist "offline\jdk\jdk-17\bin\java.exe" set "JAVA_HOME=%ROOT%\offline\jdk\jdk-17"
set "TASKS=%*"
if "%TASKS%"=="" set "TASKS=assembleDebug"
cd android
call gradlew.bat --offline --init-script "%ROOT%\offline\gradle\offline-init.gradle" %TASKS%
set "RC=%ERRORLEVEL%"
popd
exit /b %RC%
