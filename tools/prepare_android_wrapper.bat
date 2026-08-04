@echo off
setlocal
where flutter >nul 2>nul || (
  echo Flutter no esta en PATH.
  exit /b 1
)
set ROOT=%~dp0..
set TMP=%TEMP%\haciendo_wrapper_%RANDOM%%RANDOM%
flutter create --platforms=android --org com.enmanuelapp "%TMP%\wrapper_seed" >nul || exit /b 1
copy /Y "%TMP%\wrapper_seed\android\gradlew" "%ROOT%\android\gradlew" >nul
copy /Y "%TMP%\wrapper_seed\android\gradlew.bat" "%ROOT%\android\gradlew.bat" >nul
copy /Y "%TMP%\wrapper_seed\android\gradle\wrapper\gradle-wrapper.jar" "%ROOT%\android\gradle\wrapper\gradle-wrapper.jar" >nul
rmdir /S /Q "%TMP%"
echo Gradle wrapper preparado.
endlocal
