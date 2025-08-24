# Android App Manager (Termux / MT Manager)

Lightweight shell scripts to enable/disable/toggle Android apps per-user (**user 0**).  
Works from **MT Manager** (tap to run) or **Termux** (`sh appmanager.sh`).  
Separates **User apps** and **System apps** (no bulk actions for system).  
Includes confirmation prompts, color output, and a manual package mode.

## Features
- 👥 **User vs System** lists (easy to find user apps)
- ✅ **Enable / Disable / Toggle** any app
- 🔁 **Looping menu** that stays open
- 🛡️ **Confirmations** before changes (prevents accidents)
- 🎨 **Color output** for status (ENABLED / DISABLED / UNKNOWN)
- 🎯 **Manual package mode** (type `com.package.name` directly)
- 🚫 **No bulk actions for System apps** (safer)

## Requirements
- Root access (`su`)
- Android with `pm` and `sh` (standard)
- (Optional) Termux for command line

## Files
- `appmanager.sh` — main interactive manager (user/system groups, colors, confirm, manual mode)
- `suappmanager.sh` — simple “all apps” manager (optional)

## Install (Termux)
```sh
# clone your repo
git clone https://github.com/<YOUR_USERNAME>/<YOUR_REPO_NAME>.git
cd <YOUR_REPO_NAME>

# run (no execute bit required)
sh appmanager.sh
or
su
then
./appmanager.sh
