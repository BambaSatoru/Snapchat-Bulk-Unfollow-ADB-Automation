@echo off
setlocal enabledelayedexpansion

set /a total=0
set /a batchSize=30
set /a maxTotal=500

:restart_app
echo Restarting Snapchat to clear any glitches...
adb shell am force-stop com.snapchat.android
timeout /t 2 /nobreak >nul
adb shell monkey -p com.snapchat.android -c android.intent.category.LAUNCHER 1
timeout /t 6 /nobreak >nul

echo Navigating back to Edit screen...
adb shell input tap 490 1530
timeout /t 2 /nobreak >nul
adb shell input tap 670 113
timeout /t 2 /nobreak >nul
adb shell input tap 360 1380
timeout /t 2 /nobreak >nul
adb shell input tap 665 110
timeout /t 2 /nobreak >nul

echo Starting removal batch...
for /L %%i in (1,1,%batchSize%) do (
    adb shell input tap 650 249
    timeout /t 1 /nobreak >nul
    adb shell input tap 360 870
    set /a total+=1
    echo Removed account number !total!
    timeout /t 2 /nobreak >nul
)

if !total! LSS %maxTotal% (
    echo Batch of %batchSize% done, restarting app fresh before next batch...
    timeout /t 5 /nobreak >nul
    goto restart_app
)

echo All done! Total removed: !total!
pause