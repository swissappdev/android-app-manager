# Android App Manager (Termux / MT Manager)

Lightweight shell script to enable/disable/toggle Android apps per-user (**user 0**).  
Works from **MT Manager** (tap to run) or **Termux** (`su` → `./appmanager.sh`).  
Separates **User apps** and **System apps** (no bulk actions for system).  
Includes confirmation prompts, color output, and a manual package mode.

---

## Features
- 👥 **User vs System** lists (easy to find user apps)
- ✅ **Enable / Disable / Toggle** any app
- 🔁 **Looping menu** that stays open after each action
- 🛡️ **Confirmations** before changes (prevents accidents)
- 🎨 **Color output** for status (ENABLED / DISABLED / UNKNOWN)
- 🎯 **Manual package mode** (type `com.package.name` directly)
- 🚫 **No bulk actions for System apps** (safer by default)

---

## Requirements
- Root access (`su`)
- Android with `pm` and `sh` (standard on most ROMs)
- (Optional) Termux for command line

---

## Files
- `appmanager.sh` — main interactive manager (user/system groups, colors, confirm, manual mode)
- `suappmanager.sh` — simple “all apps” manager (optional)

---

## Install (Termux)
```sh
# clone your repo
git clone https://github.com/swissappdev/android-app-manager.git
cd android-app-manager

# allow script to run
chmod +x appmanager.sh

# IMPORTANT: enter root shell first
su
./appmanager.sh
