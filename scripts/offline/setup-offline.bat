@echo off
setlocal EnableExtensions EnableDelayedExpansion
title NetControl - Offline Build Setup

echo ============================================================
echo   NetControl - Offline Build Setup (Windows)
echo   This prepares an offline PC to build the APK fully offline.
echo ============================================================
echo.

set "KIT=%~dp0"
if "%KIT:~-1%"=="\" set "KIT=%KIT:~0,-1"

if not exist "%KIT%\pub-cache" (
  echo [ERROR] "%KIT%\pub-cache" not found.
  echo Run this script from inside the extracted offline-kit folder.
  exit /b 1
)

rem ── 1) Project directory ─────────────────────────────────────
set "PROJECT=%~1"
if "%PROJECT%"=="" (
  set /p PROJECT="Path to the WiFi project folder (contains pubspec.yaml): "
)
if not exist "%PROJECT%\pubspec.yaml" (
  echo [ERROR] pubspec.yaml not found in "%PROJECT%"
  exit /b 1
)
for %%I in ("%PROJECT%") do set "PROJECT=%%~fI"
echo [OK] Project: %PROJECT%

rem ── 2) Locate Flutter SDK ────────────────────────────────────
set "FLUTTER_CMD="
where flutter >nul 2>&1
if not errorlevel 1 (
  for /f "delims=" %%F in ('where flutter') do (
    if not defined FLUTTER_CMD set "FLUTTER_CMD=%%F"
  )
)
if not defined FLUTTER_CMD (
  echo Flutter not found on PATH.
  set /p FLUTTER_BIN="Full path to flutter.bat of the Flutter SDK: "
  set "FLUTTER_CMD=!FLUTTER_BIN!"
)
if not exist "%FLUTTER_CMD%" (
  echo [ERROR] flutter.bat not found at "%FLUTTER_CMD%"
  exit /b 1
)
for %%I in ("%FLUTTER_CMD%") do set "FLUTTER_DIR=%%~dpI"
for %%I in ("%FLUTTER_DIR%.") do set "FLUTTER_SDK=%%~fI"
echo [OK] Flutter SDK: %FLUTTER_SDK%
"%FLUTTER_CMD%" --version 2>nul | findstr /i "3.24.5" >nul
if errorlevel 1 echo [WARN] Kit was built with Flutter 3.24.5 - other versions may mismatch.
set "DART_CMD=%FLUTTER_SDK%\bin\dart.bat"

rem ── 3) Install Dart packages cache (offline) ─────────────────
if defined PUB_CACHE (set "PUBDIR=%PUB_CACHE%") else (set "PUBDIR=%LOCALAPPDATA%\Pub\Cache")
echo [..] Copying Dart packages cache to: %PUBDIR%
robocopy "%KIT%\pub-cache" "%PUBDIR%" /E /NFL /NDL /NJH /NJS /NP >nul
if errorlevel 8 (
  echo [ERROR] Failed to copy pub cache. Close editors and retry.
  exit /b 1
)
echo [OK] Dart packages cache installed.

rem ── 4) Lock file + offline pub get ───────────────────────────
copy /Y "%KIT%\pubspec.lock" "%PROJECT%\pubspec.lock" >nul
pushd "%PROJECT%"
echo [..] flutter pub get --offline
call "%FLUTTER_CMD%" pub get --offline
if errorlevel 1 (
  echo [ERROR] Offline pub get failed.
  popd & exit /b 1
)

rem ── 5) Code generation (repo ships no *.g.dart files) ────────
echo [..] build_runner (generates *.g.dart / *.freezed.dart)
call "%DART_CMD%" run build_runner build --delete-conflicting-outputs
if errorlevel 1 (
  echo [ERROR] build_runner failed.
  popd & exit /b 1
)
popd

rem ── 6) Gradle 8.4 distribution + Maven artifacts ─────────────
set "GH=%USERPROFILE%\.gradle"
echo [..] Copying Gradle 8.4 distribution...
robocopy "%KIT%\gradle\wrapper-dists" "%GH%\wrapper\dists" /E /NFL /NDL /NJH /NJS /NP >nul
if errorlevel 8 (echo [ERROR] wrapper-dists copy failed & exit /b 1)
echo [..] Copying Maven artifacts ^(takes a few minutes^)...
robocopy "%KIT%\gradle\modules-2" "%GH%\caches\modules-2" /E /NFL /NDL /NJH /NJS /NP >nul
if errorlevel 8 (echo [ERROR] modules-2 copy failed & exit /b 1)
echo [OK] Gradle caches installed.

rem ── 7) Gradle offline mode (project-local) ───────────────────
findstr /C:"org.gradle.offline=true" "%PROJECT%\android\gradle.properties" >nul 2>&1
if errorlevel 1 (
  echo.>> "%PROJECT%\android\gradle.properties"
  echo # Added by offline setup - remove this line to build online>> "%PROJECT%\android\gradle.properties"
  echo org.gradle.offline=true>> "%PROJECT%\android\gradle.properties"
)
echo [OK] Gradle offline mode enabled for this project.

rem ── 8) Android SDK licenses ──────────────────────────────────
set "ANDROID_SDK="
if defined ANDROID_HOME set "ANDROID_SDK=%ANDROID_HOME%"
if not defined ANDROID_SDK if defined ANDROID_SDK_ROOT set "ANDROID_SDK=%ANDROID_SDK_ROOT%"
if not defined ANDROID_SDK if exist "%LOCALAPPDATA%\Android\Sdk\platform-tools" set "ANDROID_SDK=%LOCALAPPDATA%\Android\Sdk"
if defined ANDROID_SDK (
  if exist "%KIT%\licenses" (
    robocopy "%KIT%\licenses" "%ANDROID_SDK%\licenses" /E /NFL /NDL /NJH /NJS /NP >nul
    echo [OK] SDK licenses installed.
  )
)

rem ── 9) local.properties (sdk.dir + flutter.sdk) ──────────────
if not defined ANDROID_SDK (
  set /p ANDROID_SDK="Android SDK path (e.g. C:\Users\me\AppData\Local\Android\Sdk): "
)
if not exist "%ANDROID_SDK%" (
  echo [ERROR] Android SDK not found at "%ANDROID_SDK%"
  echo Install Android Studio + SDK 34 first, then re-run this script.
  exit /b 1
)
set "SDKFWD=!ANDROID_SDK:\=/!"
set "FLUTFWD=!FLUTTER_SDK:\=/!"
(
  echo sdk.dir=!SDKFWD!
  echo flutter.sdk=!FLUTFWD!
) > "%PROJECT%\android\local.properties"
echo [OK] Wrote android\local.properties

rem ── 10) Java 17 for Gradle (if not on PATH) ──────────────────
if defined JAVA_HOME (
  echo [OK] JAVA_HOME=!JAVA_HOME!
) else (
  if exist "%ProgramFiles%\Android\Android Studio\jbr\bin\java.exe" (
    echo # Added by offline setup>> "%PROJECT%\android\gradle.properties"
    set "JBRFWD=%ProgramFiles:\=/%/Android/Android Studio/jbr"
    echo org.gradle.java.home=!JBRFWD!>> "%PROJECT%\android\gradle.properties"
    echo [OK] Using Android Studio bundled JDK ^(jbr^).
  ) else (
    echo [WARN] No JAVA_HOME and no Android Studio JBR found - Gradle needs Java 17.
  )
)

echo.
echo [..] Running a full offline build to verify everything works
echo      (first build takes 5-15 minutes)...
echo.
pushd "%PROJECT%"
call "%FLUTTER_CMD%" build apk --release
if errorlevel 1 (
  echo.
  echo [ERROR] Offline build failed - read the messages above.
  echo Common causes: missing Android SDK platform 34 / build-tools.
  popd & exit /b 1
) else (
  echo.
  echo ============================================================
  echo   SUCCESS - APK built fully offline at:
  echo   build\app\outputs\flutter-apk\app-release.apk
  echo.
  echo   You can now open the project in Android Studio too.
  echo ============================================================
)
popd
endlocal
