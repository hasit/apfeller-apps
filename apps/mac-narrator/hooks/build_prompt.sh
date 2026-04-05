#!/bin/sh

set -eu

print_section() {
  label=$1
  value=$2

  printf '\n%s:\n' "$label"
  if [ -n "$value" ]; then
    printf '%s\n' "$value"
  else
    printf '%s\n' "unavailable"
  fi
}

time_now=$(date +%H:%M:%S)
top_processes=$(ps -eo pid,%cpu,%mem,comm -r 2>/dev/null | head -8 || true)
memory_info=$(memory_pressure 2>/dev/null | head -3 || true)
disk_info=$(df -h / 2>/dev/null | tail -1 || true)
battery_info=$(pmset -g batt 2>/dev/null | tail -1 || true)
uptime_info=$(uptime 2>/dev/null || true)

printf '%s\n' "Narrate what is happening on this Mac right now."
printf '%s\n' "Use this exact timestamp prefix at the start of the response: [$time_now]"
print_section "Top processes" "$top_processes"
print_section "Memory pressure" "$memory_info"
print_section "Disk usage" "$disk_info"
print_section "Battery" "$battery_info"
print_section "Uptime" "$uptime_info"
