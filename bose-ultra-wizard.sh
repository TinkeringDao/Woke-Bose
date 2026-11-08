#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TUNER="${DIR}/bose-ultra-tuner"

if [[ ! -x "${TUNER}" ]]; then
  echo "[*] Compiling native macOS IOBluetooth BMAP tuner..."
  make -C "${DIR}"
fi

echo "========================================================================"
echo "  Woke Bose — QuietComfort Ultra (0x4066) NVRAM & DSP Calibration Wizard"
echo "========================================================================"
echo "  1) Apply 'Woke' Edition Profile (Recommended)"
echo "       - Hardware EQ [1.7]  : Bass -3 dB | Mid +1 dB | Treble +2 dB"
echo "       - Self Voice  [1.11] : OFF (-78.8 dBFS noise floor / 54.3 dB SNR)"
echo "       - Multipoint  [1.10] : DISABLED (locks 16kHz Wideband mSBC)"
echo "       - DSP Mode #4 [31.6] : 'Woke Studio' (CNC=0, Spatial=Off, WindBlock=Off)"
echo "  2) Read Live Headphone Telemetry & Biquad Status (status)"
echo "  3) Set Custom 3-Band Hardware EQ (-10 to +10 dB)"
echo "  4) Configure Call Mic Sidetone (off | low | med | high)"
echo "  5) Apply macOS High-Bitpool Bluetooth A2DP Tuning (Bitpool 58..80)"
echo "  6) Scan Supported BMAP Function Blocks & Registers (scan)"
echo "  7) Restore Factory Baseline NVRAM Settings (baseline)"
echo "  q) Quit"
echo "========================================================================"
read -rp "Select an option [1-7, q]: " choice

case "${choice}" in
  1)
    "${TUNER}" woke
    ;;
  2)
    "${TUNER}" status
    ;;
  3)
    read -rp "Enter Bass, Mid, Treble in integer dB (e.g. -3 1 2): " b m t
    "${TUNER}" eq "${b:--3}" "${m:-1}" "${t:-2}"
    ;;
  4)
    read -rp "Enter Call Mic Sidetone mode [off/low/med/high]: " cmode
    "${TUNER}" sidetone "${cmode:-off}"
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
    "${TUNER}" scan
    ;;
  7)
    "${TUNER}" baseline
    ;;
  *)
    echo "Exiting."
    ;;
esac
