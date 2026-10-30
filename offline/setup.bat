@echo off
rem One-time setup on the offline Windows machine. Run from anywhere:
rem   offline\setup.bat
setlocal EnableExtensions
set "ROOT=%~dp0.."
pushd "%ROOT%"
set "ROOT=%CD%"

echo === [1/5] Reassembling split archives ===
powershell -NoProfile -ExecutionPolicy Bypass -File "offline\join-parts.ps1" || goto :fail

echo === [2/5] Extracting JDK 17 to offline\jdk\ ===
if not exist "offline\jdk\jdk-17\bin\java.exe" (
  powershell -NoProfile -Command "Expand-Archive -Force 'offline\jdk\jdk17-win-x64.zip' 'offline\jdk\tmp'; $d = Get-ChildItem 'offline\jdk\tmp' -Directory | Select-Object -First 1; Move-Item $d.FullName 'offline\jdk\jdk-17'; Remove-Item 'offline\jdk\tmp' -Recurse" || goto :fail
)

echo === [3/5] Installing node packages from offline mirror ===
call node "offline\yarn\yarn-1.22.22.js" install --offline --frozen-lockfile --ignore-engines || goto :fail

echo === [4/5] Writing android\local.properties ===
if not exist "android\local.properties" (
  if defined ANDROID_HOME (set "SDK=%ANDROID_HOME%") else (set "SDK=%LOCALAPPDATA%\Android\Sdk")
  call :writesdk
)
type "android\local.properties"

echo === [5/5] Registering offline Maven repo for Gradle / Android Studio ===
if not defined GRADLE_USER_HOME set "GRADLE_USER_HOME=%USERPROFILE%\.gradle"
if not exist "%GRADLE_USER_HOME%\init.d" mkdir "%GRADLE_USER_HOME%\init.d"
set "INIT=%ROOT:\=/%/offline/gradle/offline-init.gradle"
> "%GRADLE_USER_HOME%\init.d\photo360-offline.gradle" echo apply from: '%INIT%'
echo Created %GRADLE_USER_HOME%\init.d\photo360-offline.gradle

echo.
echo Setup complete. Build with:  offline\build.bat   (or open the android folder in Android Studio)
popd
exit /b 0

:writesdk
set "SDKF=%SDK:\=\\%"
> "android\local.properties" echo sdk.dir=%SDKF%
exit /b 0

:fail
echo.
echo *** Setup FAILED (see messages above) ***
popd
exit /b 1
