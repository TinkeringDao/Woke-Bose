#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TUNER="${DIR}/bose-ultra-tuner"

if [[ ! -x "${TUNER}" ]]; then
  echo "[*] Compiling native macOS IOBluetooth BMAP tuner..."
  make -C "${DIR}"
fi

echo "========================================================================"
echo "  Bose QuietComfort Ultra (0x4066 Lonestarr) — 'Woke' NVRAM & DSP Wizard"
echo "========================================================================"
echo "  1) Flash 'Woke' Edition Profile (Recommended)"
echo "       - Hardware EQ [1.7]  : Bass -3 dB | Mid +1 dB | Treble +2 dB"
echo "       - Self Voice  [1.11] : OFF (-78.8 dBFS noise floor / 54.3 dB SNR)"
echo "       - Multipoint  [1.10] : DISABLED (locks 16kHz mSBC / 32kHz aptX Voice)"
echo "       - DSP Mode #4 [31.6] : 'Woke Studio' (CNC=0, Spatial=Off, WindBlock=Off)"
echo "  2) Read Live Headphone Telemetry & NVRAM Status (status)"
echo "  3) Switch Audio EQ Preset (harman | vocal | warm | flat)"
echo "  4) Configure Call Mic Mode (off | low | med | high | strict)"
echo "  5) Apply macOS High-Bitpool Bluetooth A2DP Tuning (Bitpool 58..80)"
echo "  6) Clean USB Firmware Recovery (1.6.7+g6ebabd2 via BoseUpdater)"
echo "  7) Restore Factory Baseline NVRAM Settings (baseline)"
echo "  q) Quit"
echo "========================================================================"
read -rp "Select an option [1-7, q]: " choice

case "${choice}" in
  1)
    "${TUNER}" woke
    echo ""
    "${TUNER}" status
    ;;
  2)
    "${TUNER}" status
    ;;
  3)
    read -rp "Enter EQ preset [harman/vocal/warm/flat]: " preset
    "${TUNER}" pimp-audio "${preset:-harman}"
    ;;
  4)
    read -rp "Enter Call Mic Sidetone mode [off/low/med/high/strict]: " cmode
    "${TUNER}" pimp-call "${cmode:-off}"
    ;;
  5)
    defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Max (editable)" 80
    defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" 58
    defaults write com.apple.BluetoothAudioAgent "Apple Initial Bitpool (editable)" 64
    defaults write com.apple.BluetoothAudioAgent "Apple Initial Bitpool Min (editable)" 58
    defaults write com.apple.BluetoothAudioAgent "Negotiated Bitpool" 64
    defaults write com.apple.BluetoothAudioAgent "Negotiated Bitpool Max" 80
    defaults write com.apple.BluetoothAudioAgent "Negotiated Bitpool Min" 58
    echo "[+] macOS BluetoothAudioAgent configured for maximum A2DP bitpool (58..80)."
    defaults read com.apple.BluetoothAudioAgent
    ;;
  6)
    echo "[*] Checking BoseUpdater service on 127.0.0.1:49312..."
    if [[ -d "/Applications/Bose Updater.app" ]]; then
      open -a "/Applications/Bose Updater.app"
      sleep 2
    fi
    python3 -c '
import urllib.request, urllib.parse, re, time
TOK = "T987654321abc"
URL = "https://ota.cdn.bose.io/f840a774-76ba-41be-b51e-e04848ff638a.bin/f840a774-76ba-41be-b51e-e04848ff638a.bin"
VER = urllib.parse.quote("1.6.7+g6ebabd2")
CRC = "0XAF34965B"
SIZE = "7075178"
def req(path):
    r = urllib.request.Request("http://127.0.0.1:49312/updater/" + path, headers={"Origin": "https://btu.bose.com"})
    return urllib.request.urlopen(r).read().decode().strip()
req(f"startUpdaterSession?userAgent=Mozilla/5.0&token={TOK}")
time.sleep(1.5)
devs = req(f"getCurrentDevicesConnected?pids=-1&token={TOK}")
m = re.search(r"\"ID\"\s*:\s*\"([^\"]+)\"", devs)
if not m:
    print("[!] No USB-connected Bose QC Ultra detected by BoseUpdater. Plug in via USB-C and retry.")
else:
    did = m.group(1)
    print(f"[+] Detected USB Device ID: {did}")
    print("[*] Starting official 1.6.7+g6ebabd2 firmware recovery:", req(f"updateUsingEndpointUrl?deviceID={did}&url={URL}&version={VER}&fileCrc={CRC}&fileSize={SIZE}&callback=BoseUpdater.remoteCallback&token={TOK}"))
'
    ;;
  7)
    "${TUNER}" baseline
    ;;
  *)
    echo "Exiting."
    ;;
esac
