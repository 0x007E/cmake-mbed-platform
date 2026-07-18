#!/bin/sh
# avr_size_wrapper.sh
#
# Usage:
#   avr_size_wrapper.sh \
#     --avr-size /path/to/avr-size \
#     --mcu atmega16a \
#     --flash 16384 \
#     --ram 1024 \
#     --eeprom 512 \
#     --elf /path/to/firmware.elf
#
# Notes:
# - Program/Flash usage is calculated as: .text + .data
# - SRAM usage is calculated as: .data + .bss (+ .noinit if present)
# - EEPROM usage is taken from: .eeprom
#
# This wrapper is intended for avr-size versions that do NOT support:
#   -C
#   --mcu=<device>

set -eu

die() {
    echo "Error: $*" >&2
    exit 1
}

usage() {
    cat >&2 <<'EOF'
Usage:
  avr_size_wrapper.sh
    --avr-size <path-to-avr-size>
    --mcu <mcu-name>
    --flash <flash-bytes>
    --ram <ram-bytes>
    --eeprom <eeprom-bytes>
    --elf <elf-file>

Example:
  avr_size_wrapper.sh \
    --avr-size /opt/avr/bin/avr-size \
    --mcu atmega16a \
    --flash 16384 \
    --ram 1024 \
    --eeprom 512 \
    --elf build/foo.elf
EOF
    exit 1
}

AVR_SIZE=""
MCU=""
FLASH_TOTAL=""
RAM_TOTAL=""
EEPROM_TOTAL=""
ELF=""

while [ "$#" -gt 0 ]; do
    case "$1" in
        --avr-size)
            [ "$#" -ge 2 ] || usage
            AVR_SIZE="$2"
            shift 2
            ;;
        --mcu)
            [ "$#" -ge 2 ] || usage
            MCU="$2"
            shift 2
            ;;
        --flash)
            [ "$#" -ge 2 ] || usage
            FLASH_TOTAL="$2"
            shift 2
            ;;
        --ram)
            [ "$#" -ge 2 ] || usage
            RAM_TOTAL="$2"
            shift 2
            ;;
        --eeprom)
            [ "$#" -ge 2 ] || usage
            EEPROM_TOTAL="$2"
            shift 2
            ;;
        --elf)
            [ "$#" -ge 2 ] || usage
            ELF="$2"
            shift 2
            ;;
        --help|-h)
            usage
            ;;
        *)
            die "Unknown argument: $1"
            ;;
    esac
done

[ -n "$AVR_SIZE" ] || die "--avr-size missing"
[ -n "$MCU" ] || die "--mcu missing"
[ -n "$FLASH_TOTAL" ] || die "--flash missing"
[ -n "$RAM_TOTAL" ] || die "--ram missing"
[ -n "$EEPROM_TOTAL" ] || die "--eeprom missing"
[ -n "$ELF" ] || die "--elf missing"

[ -x "$AVR_SIZE" ] || die "avr-size not executable: $AVR_SIZE"
[ -f "$ELF" ] || die "ELF file not found: $ELF"

case "$FLASH_TOTAL" in ''|*[!0-9]*) die "--flash must be an integer" ;; esac
case "$RAM_TOTAL" in ''|*[!0-9]*) die "--ram must be an integer" ;; esac
case "$EEPROM_TOTAL" in ''|*[!0-9]*) die "--eeprom must be an integer" ;; esac

BERKELEY_OUT="$("$AVR_SIZE" "$ELF")"
SYSV_OUT="$("$AVR_SIZE" -A "$ELF")"

TEXT="$(printf '%s\n' "$BERKELEY_OUT" | awk 'NR==2 {print $1}')"
DATA="$(printf '%s\n' "$BERKELEY_OUT" | awk 'NR==2 {print $2}')"
BSS="$(printf '%s\n' "$BERKELEY_OUT" | awk 'NR==2 {print $3}')"

[ -n "$TEXT" ] || die "Could not parse .text from avr-size output"
[ -n "$DATA" ] || die "Could not parse .data from avr-size output"
[ -n "$BSS" ] || die "Could not parse .bss from avr-size output"

case "$TEXT" in ''|*[!0-9]*) die "Parsed .text is not an integer: $TEXT" ;; esac
case "$DATA" in ''|*[!0-9]*) die "Parsed .data is not an integer: $DATA" ;; esac
case "$BSS" in ''|*[!0-9]*) die "Parsed .bss is not an integer: $BSS" ;; esac

NOINIT="$(printf '%s\n' "$SYSV_OUT" | awk '$1==".noinit" {print $2; found=1} END {if(!found) print 0}')"
EEPROM_USED="$(printf '%s\n' "$SYSV_OUT" | awk '$1==".eeprom" {print $2; found=1} END {if(!found) print 0}')"

case "$NOINIT" in ''|*[!0-9]*) die "Parsed .noinit is not an integer: $NOINIT" ;; esac
case "$EEPROM_USED" in ''|*[!0-9]*) die "Parsed .eeprom is not an integer: $EEPROM_USED" ;; esac

FLASH_USED=$((TEXT + DATA))
RAM_USED=$((DATA + BSS + NOINIT))

FLASH_PCT="$(awk -v u="$FLASH_USED" -v t="$FLASH_TOTAL" 'BEGIN { if (t>0) printf "%.1f", (u*100.0)/t; else printf "0.0" }')"
RAM_PCT="$(awk -v u="$RAM_USED" -v t="$RAM_TOTAL" 'BEGIN { if (t>0) printf "%.1f", (u*100.0)/t; else printf "0.0" }')"
EEPROM_PCT="$(awk -v u="$EEPROM_USED" -v t="$EEPROM_TOTAL" 'BEGIN { if (t>0) printf "%.1f", (u*100.0)/t; else printf "0.0" }')"

echo "AVR Memory Usage"
echo "----------------"
echo "Device: $MCU"
printf 'Program: %d bytes (%s%% Full)\n' "$FLASH_USED" "$FLASH_PCT"
echo "(.text + .data)"

if [ "$NOINIT" -gt 0 ]; then
    printf 'Data: %d bytes (%s%% Full)\n' "$RAM_USED" "$RAM_PCT"
    echo "(.data + .bss + .noinit)"
else
    printf 'Data: %d bytes (%s%% Full)\n' "$RAM_USED" "$RAM_PCT"
    echo "(.data + .bss)"
fi

printf 'EEPROM: %d bytes (%s%% Full)\n' "$EEPROM_USED" "$EEPROM_PCT"
echo "(.eeprom)"