#!/data/data/com.termux/files/usr/bin/bash

========== CONFIG ==========

TRUSTED_DNS=("1.1.1.1" "8.8.8.8") TRUSTED_WIFI=("YourHomeWiFi" "OfficeNet") TRUSTED_FINGERPRINTS=("M-KOPA_X2/MKOPA_X2/MKOPA_X2:10/QP1A.190711.020/1716885387:user/release-keys") BLACKLISTED_APPS=("com.spy.app" "com.keylogger") EXPECTED_BATTERY_VENDOR="Scud" ALERT_LOG=~/watchdog_pro/logs/alerts.log

========== COLOR CODES ==========

RED='\033[1;31m' GREEN='\033[1;32m' YELLOW='\033[1;33m' MAGENTA='\033[1;35m' RESET='\033[0m'

========== HEADER ==========

START_TIME=$(date '+%Y-%m-%d_%H-%M-%S') echo -e "${MAGENTA}\n[Watchdog Pro Started at $START_TIME]${RESET}" mkdir -p ~/watchdog_pro/logs

SCORE=0 TOTAL=9

========== 1. Internet Check ==========

if ping -c 1 google.com > /dev/null 2>&1; then ((SCORE++)) else echo -e "${RED}[$(date)] ❌ ALERT: Internet connectivity lost!${RESET}" | tee -a "$ALERT_LOG" fi

========== 2. VPN Check ==========

IPINFO=$(curl -s https://ifconfig.me) if [[ "$IPINFO" == "Kenya" ]]; then echo -e "${YELLOW}[$(date)] 🚧 VPN not active!${RESET}" | tee -a "$ALERT_LOG" else ((SCORE++)) fi

========== 3. DNS Leak Check ==========

DNS_USED=$(getprop net.dns1) if [ -z "$DNS_USED" ]; then DNS_USED=$(getprop | grep dns | grep -oE '\b([0-9]{1,3}.){3}[0-9]{1,3}\b' | head -n1) fi if [[ " ${TRUSTED_DNS[*]} " =~ " $DNS_USED " ]]; then ((SCORE++)) else echo -e "${RED}[$(date)] 🛑 ALERT: DNS leak or untrusted DNS detected! ($DNS_USED)${RESET}" | tee -a "$ALERT_LOG" fi

========== 4. Wi-Fi Trust Check ==========

SSID=$(termux-wifi-connectioninfo | grep -oP '"ssid":\s*"\K[^"]+') if [ -z "$SSID" ] || [ "$SSID" == "<unknown ssid>" ]; then SSID="mobile_data" fi if [[ "$SSID" == "mobile_data" || " ${TRUSTED_WIFI[*]} " =~ " $SSID " ]]; then ((SCORE++)) else echo -e "${YELLOW}[$(date)] ⚠️ Connected to untrusted Wi-Fi: $SSID${RESET}" | tee -a "$ALERT_LOG" fi

========== 5. Device Fingerprint ==========

FP=$(getprop ro.build.fingerprint) if [[ " ${TRUSTED_FINGERPRINTS[*]} " =~ "$FP" ]]; then ((SCORE++)) else echo -e "${RED}[$(date)] 🧪 Device fingerprint mismatch!${RESET}" | tee -a "$ALERT_LOG" fi

========== 6. Battery Vendor Check ==========

BAT_VENDOR=$(dumpsys battery | grep -i 'vendor' | awk '{print $2}') if [[ "$BAT_VENDOR" == "$EXPECTED_BATTERY_VENDOR" ]]; then ((SCORE++)) else echo -e "${YELLOW}[$(date)] ⚠️ Unexpected battery vendor: $BAT_VENDOR${RESET}" | tee -a "$ALERT_LOG" fi

========== 7. Emulator Detection ==========

EMU_CHECK=$(getprop ro.kernel.qemu) if [[ "$EMU_CHECK" == "1" ]]; then echo -e "${RED}[$(date)] 🚨 Emulator environment detected!${RESET}" | tee -a "$ALERT_LOG" else ((SCORE++)) fi

========== 8. Unauthorized App Detection ==========

INSTALLED=$(pm list packages) for BADAPP in "${BLACKLISTED_APPS[@]}"; do echo "$INSTALLED" | grep -q "$BADAPP" && { echo -e "${RED}[$(date)] 🚫 Suspicious app installed: $BADAPP${RESET}" | tee -a "$ALERT_LOG" } || ((SCORE++)) done

========== 9. Camera/Mic/Location Logs ==========

echo -e "\n[🎙️ Mic Check]" MIC_LOGS=$(logcat -d | grep -i -E 'AudioRecord.*start|startRecording' | tail -n 3) if [ ! -z "$MIC_LOGS" ]; then echo -e "${YELLOW}[$(date)] 🎙️ Mic access detected${RESET}" | tee -a "$ALERT_LOG" else ((SCORE++)) fi

echo -e "\n[📷 Camera Check]" CAM_LOGS=$(logcat -d | grep -i -E 'CameraService:.*openCamera' | tail -n 3) if [ ! -z "$CAM_LOGS" ]; then echo -e "${YELLOW}[$(date)] 📷 Camera access detected${RESET}" | tee -a "$ALERT_LOG" else ((SCORE++)) fi

echo -e "\n[📍 Location Check]" LOC_LOGS=$(logcat -d | grep -i 'LocationManagerService.*request' | tail -n 3) if [ ! -z "$LOC_LOGS" ]; then echo -e "${MAGENTA}[$(date)] 📍 Location access detected${RESET}" | tee -a "$ALERT_LOG" else ((SCORE++)) fi

========== Final Security Score ==========

echo -e "\n${GREEN}[SECURITY STATUS] $SCORE/$TOTAL ✅${RESET}" if [[ $SCORE -lt $TOTAL ]]; then termux-notification --title "Watchdog Score: $SCORE/$TOTAL" --content "Some checks failed. Review alerts." --priority high else termux-notification --title "Watchdog Pro" --content "Device secure ($SCORE/$TOTAL)" --priority low fi

