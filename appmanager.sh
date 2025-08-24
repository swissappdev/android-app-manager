#!/system/bin/sh
# Android App Manager (no labels; light; colors; confirm; loop; manual package)
# Works in MT Manager or Termux. Requires root (su). POSIX-safe.

# ---- Root check ----
require_root() {
  if [ "$(id -u)" != "0" ]; then
    if command -v su >/dev/null 2>&1; then
      su -mm -c "\"$0\" $*"
      exit $?
    else
      echo "[!] Root required but 'su' not found."
      exit 1
    fi
  fi
}
require_root "$@"

# ---- Colors (set NO_COLOR=1 to disable) ----
if [ -z "$NO_COLOR" ]; then
  C_RESET="$(printf '\033[0m')"
  C_DIM="$(printf '\033[2m')"
  C_RED="$(printf '\033[31m')"
  C_GRN="$(printf '\033[32m')"
  C_YEL="$(printf '\033[33m')"
else
  C_RESET=""; C_DIM=""; C_RED=""; C_GRN=""; C_YEL=""
fi

# ---- Helpers ----
is_installed() { pm list packages --user 0 "$1" 2>/dev/null | grep -q "^package:$1$"; }
is_enabled()   { pm list packages --user 0 -e  "$1" 2>/dev/null | grep -q "^package:$1$"; }
is_disabled()  { pm list packages --user 0 -d  "$1" 2>/dev/null | grep -q "^package:$1$"; }

confirm() {
  printf "%s (y/N): " "$1"
  read -r ans
  case "$ans" in y|Y) return 0 ;; *) echo "[*] Canceled."; return 1 ;; esac
}

# ---- Listing by group ----
# group: user | system
list_packages_by_group() {
  grp="$1"
  if [ "$grp" = "user" ]; then
    pm list packages --user 0 -3 2>/dev/null | sed 's/^package://'
  else
    pm list packages --user 0 -s 2>/dev/null | sed 's/^package://'
  fi
}

# Choose package from group (optional filter) -> SELPKG
choose_package_from_group() {
  GRP="$1"
  printf "\n(%s) Optional filter (leave empty for all): " "$GRP"
  read -r FILTER

  if [ -n "$FILTER" ]; then
    PKGS="$(list_packages_by_group "$GRP" | grep -i "$FILTER")"
  else
    PKGS="$(list_packages_by_group "$GRP")"
  fi

  if [ -z "$PKGS" ]; then
    echo "[!] No packages found."
    return 1
  fi

  printf "\nSelect an app from %s apps:\n" "$GRP"
  idx=1
  echo "$PKGS" | while IFS= read -r p; do
    printf "  %d) %s\n" "$idx" "$p"
    idx=$((idx+1))
  done

  COUNT=$(echo "$PKGS" | wc -l | tr -d ' ')
  printf "  0) Cancel\n"
  printf "App #: "
  read -r pick
  [ "$pick" = "0" ] && { SELPKG=""; return 1; }

  if [ "$pick" -ge 1 ] 2>/dev/null && [ "$pick" -le "$COUNT" ] 2>/dev/null; then
    n=1; SELPKG=""
    echo "$PKGS" | while IFS= read -r p; do
      if [ "$n" = "$pick" ]; then printf "%s" "$p"; break; fi
      n=$((n+1))
    done > /data/local/tmp/.selpkg.$$ 2>/dev/null || true
    [ -f /data/local/tmp/.selpkg.$$ ] && SELPKG="$(cat /data/local/tmp/.selpkg.$$)" && rm -f /data/local/tmp/.selpkg.$$
    [ -n "$SELPKG" ] && return 0 || { echo "[!] Selection failed."; return 1; }
  else
    echo "[!] Invalid selection."
    return 1
  fi
}

# ---- Actions ----
do_enable_pkg() {
  pkg="$1"
  if ! is_installed "$pkg"; then echo "[-] $pkg: not installed"; return 0; fi
  if is_enabled "$pkg"; then echo "[=] $pkg: already enabled"; return 0; fi
  if pm enable --user 0 "$pkg" >/dev/null 2>&1; then
    echo "[+] $pkg: ${C_GRN}ENABLED${C_RESET}"
  else
    echo "[!] $pkg: enable failed"
  fi
}

do_disable_pkg() {
  pkg="$1"
  if ! is_installed "$pkg"; then echo "[-] $pkg: not installed"; return 0; fi
  if is_disabled "$pkg"; then echo "[=] $pkg: already disabled"; return 0; fi
  if pm disable --user 0 "$pkg" >/dev/null 2>&1; then
    [ "$pkg" = "com.facebook.katana" ] && am start --user 0 -a android.intent.action.VIEW -d 'fb://root' >/dev/null 2>&1
    echo "[-] $pkg: ${C_RED}DISABLED${C_RESET}"
  else
    echo "[!] $pkg: disable failed"
  fi
}

do_toggle_pkg() {
  pkg="$1"
  if is_disabled "$pkg"; then do_enable_pkg "$pkg"; else do_disable_pkg "$pkg"; fi
}

print_status_line() {
  pkg="$1"
  if is_enabled "$pkg"; then state="${C_GRN}ENABLED${C_RESET}"
  elif is_disabled "$pkg"; then state="${C_RED}DISABLED${C_RESET}"
  elif is_installed "$pkg"; then state="${C_YEL}UNKNOWN${C_RESET}"
  else state="${C_DIM}NOT INSTALLED${C_RESET}"; fi
  printf "%-65s %s\n" "$pkg" "$state"
}

do_status_group() {
  GRP="$1"
  PKGS="$(list_packages_by_group "$GRP")"
  if [ -z "$PKGS" ]; then echo "[!] No packages found."; return; fi
  echo "$PKGS" | while IFS= read -r p; do print_status_line "$p"; done
}

do_all_user() {
  # $1=enable|disable|toggle (USER apps only)
  PKGS="$(list_packages_by_group user)"
  [ -z "$PKGS" ] && { echo "[!] No user apps found."; return; }
  case "$1" in
    enable)  confirm "Enable ALL USER apps?"  || return ;;
    disable) confirm "Disable ALL USER apps?" || return ;;
    toggle)  confirm "Toggle ALL USER apps?"  || return ;;
  esac
  echo "$PKGS" | while IFS= read -r p; do
    case "$1" in
      enable)  do_enable_pkg "$p" ;;
      disable) do_disable_pkg "$p" ;;
      toggle)  do_toggle_pkg "$p" ;;
    esac
  done
}

# ---- Manual package manager ----
manual_manage_package() {
  printf "\nEnter package name (e.g., com.whatsapp). Empty to cancel: "
  read -r pkg
  [ -z "$pkg" ] && { echo "[*] Canceled."; return; }

  if ! pm list packages --user 0 2>/dev/null | grep -q "^package:$pkg$"; then
    echo "[!] Package not found for user 0: $pkg"
    return
  fi

  print_status_line "$pkg"
  printf "Toggle this package? (y/N): "
  read -r ans
  case "$ans" in y|Y) do_toggle_pkg "$pkg" ;; *) echo "[*] Skipped." ;; esac
}

# ---- CLI (optional): appmanager.sh action target ----
# action: enable|disable|toggle|status ; target: user|system|all|<package>
if [ $# -ge 1 ]; then
  ACT="$1"; TGT="${2:-all}"
  case "$ACT" in enable|disable|toggle|status) ;; *) echo "Usage: $(basename "$0") enable|disable|toggle|status [user|system|all|<package>]"; exit 1;; esac
  case "$TGT" in
    user)
      case "$ACT" in
        status) do_status_group user ;;
        enable) do_all_user enable ;;
        disable) do_all_user disable ;;
        toggle) do_all_user toggle ;;
      esac; exit 0 ;;
    system)
      case "$ACT" in
        status) do_status_group system ;;
        enable|disable|toggle) echo "[!] Bulk actions for SYSTEM apps are disabled."; exit 1 ;;
      esac; exit 0 ;;
    all)
      if [ "$ACT" = "status" ]; then
        echo "=== USER APPS ==="; do_status_group user
        echo "=== SYSTEM APPS ==="; do_status_group system
        exit 0
      else
        echo "[!] For bulk actions, use 'user'. SYSTEM bulk is disabled."
        exit 1
      fi
      ;;
    *)
      case "$ACT" in
        enable)  confirm "Enable $TGT?"  && do_enable_pkg "$TGT" ;;
        disable) confirm "Disable $TGT?" && do_disable_pkg "$TGT" ;;
        status)  print_status_line "$TGT" ;;
        toggle)  if confirm "Toggle $TGT?"; then do_toggle_pkg "$TGT"; fi ;;
      esac; exit 0 ;;
  esac
fi

# ---- Interactive LOOP ----
while :; do
  printf "\n==== Android App Manager ====\n"
  printf "1) USER apps → Enable/Disable/Toggle (pick one)\n"
  printf "2) SYSTEM apps → Enable/Disable/Toggle (pick one)\n"
  printf "3) Status (USER)\n"
  printf "4) Status (SYSTEM)\n"
  printf "5) Enable ALL (USER)\n"
  printf "6) Disable ALL (USER)\n"
  printf "7) Manage a specific package (manual input)\n"
  printf "0) Exit\n"
  printf "Choice: "
  read -r choice

  case "$choice" in
    1)
      printf "\nAction for USER apps: 1) Enable  2) Disable  3) Toggle  (0=Cancel)\n"
      printf "Pick: "
      read -r a
      case "$a" in
        1) if choose_package_from_group user;   then if confirm "Enable $SELPKG?";  then do_enable_pkg "$SELPKG";  fi; fi ;;
        2) if choose_package_from_group user;   then if confirm "Disable $SELPKG?"; then do_disable_pkg "$SELPKG"; fi; fi ;;
        3) if choose_package_from_group user;   then if confirm "Toggle $SELPKG?";  then do_toggle_pkg "$SELPKG";  fi; fi ;;
        0) : ;; *) echo "[!] Invalid" ;;
      esac
      ;;
    2)
      printf "\nAction for SYSTEM apps: 1) Enable  2) Disable  3) Toggle  (0=Cancel)\n"
      printf "Pick: "
      read -r a
      case "$a" in
        1) if choose_package_from_group system; then if confirm "Enable $SELPKG?";  then do_enable_pkg "$SELPKG";  fi; fi ;;
        2) if choose_package_from_group system; then if confirm "Disable $SELPKG?"; then do_disable_pkg "$SELPKG"; fi; fi ;;
        3) if choose_package_from_group system; then if confirm "Toggle $SELPKG?";  then do_toggle_pkg "$SELPKG";  fi; fi ;;
        0) : ;; *) echo "[!] Invalid" ;;
      esac
      ;;
    3) echo "=== USER APPS ===";   do_status_group user ;;
    4) echo "=== SYSTEM APPS ==="; do_status_group system ;;
    5) do_all_user enable ;;
    6) do_all_user disable ;;
    7) manual_manage_package ;;
    0) echo "Bye."; exit 0 ;;
    *) echo "[!] Invalid choice" ;;
  esac

  printf "\n[Press Enter to continue...] "
  read -r _
done