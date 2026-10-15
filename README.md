# Snapchat Bulk Unfollow (ADB Automation)

A Windows batch script that automates bulk-unfollowing accounts on Snapchat using `adb` (Android Debug Bridge) and coordinate-based UI taps — no root, no third-party app, no API access required.

Snapchat has no built-in "unfollow all" button and no public API for this action. This project simulates the exact manual steps a human would do (open the Following list → tap the ✕ next to a name → confirm removal) but automates the repetition.

---

## ⚠️ Disclaimer

- This automates actions on **your own account** using standard Android debugging tools. It is not illegal.
- It **does violate Snapchat's Terms of Service**, which prohibit automated/bot-like interaction with the app. Snapchat's systems may detect unusual tap patterns and could rate-limit, flag, or temporarily lock the account.
- Every account removed this way is **instant and irreversible** — there is no bulk "undo." Use with intention.
- This project is not affiliated with, endorsed by, or connected to Snap Inc. in any way.
- Use at your own risk.

---

## How it works

Snapchat's "Manage accounts I follow" screen doesn't expose individual buttons (like the ✕ icon) as distinct, addressable UI elements to accessibility tools — everything in each row is drawn as one flattened view. Because of this, standard automation frameworks (Appium, Selenium-style element-finding) can't reliably target the ✕ button by ID.

Instead, this script uses **fixed-coordinate tapping** via `adb shell input tap X Y`:

1. Tap the ✕ icon position (always the top visible row, since removed rows shift the list up)
2. Wait briefly for the "Remove?" confirmation popup
3. Tap "Yes" to confirm
4. Repeat
5. Every N removals (30 by default), force-close and relaunch Snapchat, then re-navigate back to the Edit screen — this works around occasional in-app glitches/freezes

---

## Requirements

- A Windows PC
- An Android phone with Snapchat installed and logged in
- A USB cable (must support data transfer, not charge-only)
- [Android Platform Tools (adb)](https://developer.android.com/tools/releases/platform-tools) downloaded and extracted

---

## Setup

### 1. Enable Developer Options on your phone
- Settings → About phone → tap **Build number** 7 times

### 2. Enable USB Debugging
- Settings → Developer options → toggle **USB debugging** ON

### 3. Install adb on your PC
- Download platform-tools from the link above
- Extract the ZIP anywhere, e.g. `C:\platform-tools\`

### 4. Connect your phone
- Plug in via USB
- Tap **Allow** on the "Allow USB debugging?" popup on your phone

### 5. Verify the connection
Open Command Prompt inside the `platform-tools` folder and run:
```
adb devices
```
You should see your device listed as `device` (not `unauthorized` or empty).

### 6. Check your screen resolution
```
adb shell wm size
```
The script in this repo is calibrated for **720x1600**. The original version was calibrated for **1080x2400** — those coordinates are listed in the [table below](#calibrating-coordinates-for-your-phone). If your resolution is neither, you'll need to recalibrate.

---

## Usage

### 1. Turn on Airplane Mode
This prevents incoming snap notifications/banners from interrupting taps mid-run.

### 2. Manually navigate to the Edit screen
Open Snapchat → **Stories** tab → **3-dot menu** (top right) → **Manage accounts I follow** → **Edit** (top right)

You should now see the list with ✕ icons next to every account.

### 3. Run the script
Save `unfollow_all.bat` (below) into your `platform-tools` folder, then in Command Prompt:
```
unfollow_all.bat
```

### 4. Let it run
It will remove accounts in batches of 30, restarting the app between batches to avoid glitches, until it reaches the max count or runs out of accounts.

---

## The Script (`unfollow_all.bat`)

Calibrated for **720x1600**.

```bat
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
```

### Tunable settings

| Setting | Value | Notes |
|---|---|---|
| `batchSize` | `30` | Removals per batch before the app is restarted (was 15) |
| `maxTotal` | `500` | Stop threshold, checked after each batch |
| Delay between ✕ tap and "Yes" tap | `1s` | Was 2s. Increase if the popup doesn't appear in time |
| Delay after "Yes" tap | `2s` | Was 4s. Increase if removals are being skipped |

The shorter delays make each batch roughly twice as fast. If your phone is slower, or taps start landing before the UI has updated, raise these values.

---

## Calibrating coordinates for your phone

The script ships with coordinates for **720x1600**. The original version used a **1080x2400** display (Vivo V20). If your phone has a different resolution, screen density, or UI scale, you'll need to recalibrate:

1. Get your resolution: `adb shell wm size`
2. Take a screenshot while on the target screen:
   ```
   adb exec-out screencap -p > screen.png
   ```
3. Open `screen.png` in Paint (or any image viewer that shows pixel coordinates)
4. Hover over the element you want to tap (✕ icon, "Yes" button, Stories tab, 3-dot menu, "Manage accounts I follow" text, "Edit" text) and note the x/y pixel position
5. Replace the corresponding coordinates in the script

| Element | 720x1600 (current) | 1080x2400 (original) |
|---|---|---|
| Stories tab (bottom nav) | `490, 1530` | `735, 2195` |
| 3-dot menu (top right) | `670, 113` | `1000, 160` |
| "Manage accounts I follow" | `360, 1380` | `270, 1975` |
| "Edit" (top right) | `665, 110` | `1004, 150` |
| ✕ icon (top row) | `650, 249` | `985, 357` |
| "Yes" confirm button | `360, 870` | `540, 1320` |

> Coordinates don't always scale linearly between resolutions (layout and density differ between devices), so always verify with a screenshot rather than just multiplying.

---

## Known limitations

- **Coordinate-based, not element-based** — if Snapchat updates its UI layout, these coordinates will break and need recalibration.
- **No confirmation replay** — once removed, the script cannot re-follow accounts. There is no built-in "dry run" mode.
- **Screen must stay on and unlocked** — if the phone locks mid-run, taps will land on the lock screen instead.
- **Notifications can still interfere** even with Airplane Mode if you have other apps generating local alerts — close background apps if issues persist.
- **`maxTotal` is checked per batch** — with a batch size of 30, a limit of 500 means the script stops at 510, not exactly 500.
- **This is UI automation, not an API integration** — it is inherently more fragile than a proper API call would be, because none exists for this action.

---

## License

Do whatever you want with this. No warranty, no liability, use at your own risk.
