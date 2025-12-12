#!/usr/bin/env bash
# Ambxst CLI - Main entry point for Ambxst desktop environment

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Use environment variables if set by flake, otherwise fall back to PATH
QS_BIN="${AMBXST_QS:-qs}"
NIXGL_BIN="${AMBXST_NIXGL:-}"

show_help() {
  cat <<EOF
Ambxst CLI - Desktop Environment Control

Usage: ambxst [COMMAND]

Commands:
    (none)                            Launch Ambxst desktop shell
    update                            Update Ambxst
    refresh                           Refresh local/dev profile (for developers)
    lock                              Activate lockscreen
    brightness <percent> [monitor]    Set brightness (0-100)
    brightness +/-<delta> [monitor]   Adjust brightness relatively
    brightness -s [monitor]           Save current brightness
    brightness -r [monitor]           Restore saved brightness
    brightness -l                     List monitors and their brightness
    help                              Show this help message

Examples:
    ambxst brightness 75              Set all monitors to 75%
    ambxst brightness 50 HDMI-A-1     Set HDMI-A-1 to 50%
    ambxst brightness +10             Increase brightness by 10%
    ambxst brightness -5 HDMI-A-1     Decrease HDMI-A-1 brightness by 5%
    ambxst brightness 10 -s           Save current, then set all to 10%
    ambxst brightness -s HDMI-A-1     Save current brightness of HDMI-A-1
    ambxst brightness -r              Restore saved brightness

EOF
}

find_ambxst_pid() {
  # Try to find QuickShell process running shell.qml
  # First try with full path (production/flake mode)
  local pid
  pid=$(pgrep -f "quickshell.*${SCRIPT_DIR}/shell.qml" 2>/dev/null | head -1)
  
  # If not found, try with relative path (development mode)
  if [ -z "$pid" ]; then
    pid=$(pgrep -f "quickshell.*shell.qml" 2>/dev/null | head -1)
  fi
  
  # Last resort: find any quickshell process in this directory
  if [ -z "$pid" ]; then
    pid=$(pgrep -a quickshell 2>/dev/null | grep -F "$SCRIPT_DIR" | awk '{print $1}' | head -1)
  fi
  
  echo "$pid"
}

case "${1:-}" in
update)
  echo "Updating Ambxst..."
  exec curl -fsSL get.axeni.de/ambxst | bash
  ;;
refresh)
  echo "Refreshing Ambxst profile..."
  exec nix profile upgrade --impure Ambxst
  ;;
lock)
  # Trigger lockscreen via quickshell-ipc
  PID=$(find_ambxst_pid)
  if [ -z "$PID" ]; then
    echo "Error: Ambxst is not running"
    exit 1
  fi
  qs ipc --pid "$PID" call lockscreen lock 2>/dev/null || {
    echo "Error: Could not activate lockscreen"
    exit 1
  }
  ;;
brightness)
  PID=$(find_ambxst_pid)
  if [ -z "$PID" ]; then
    echo "Error: Ambxst is not running"
    exit 1
  fi
  
  BRIGHTNESS_SAVE_FILE="/tmp/ambxst_brightness_saved.txt"
  
  # Parse arguments
  ARG2="${2:-}"
  ARG3="${3:-}"
  ARG4="${4:-}"
  
  # Handle list flag
  if [ "$ARG2" = "-l" ] || [ "$ARG2" = "--list" ]; then
    echo "Monitors:"
    if command -v hyprctl &> /dev/null; then
      hyprctl monitors -j 2>/dev/null | jq -r '.[] | "  \(.name)"' || {
        echo "Error: Could not list monitors"
        exit 1
      }
    else
      echo "Error: hyprctl not found"
      exit 1
    fi
    exit 0
  fi
  
  # Handle restore flag
  if [ "$ARG2" = "-r" ] || [ "$ARG2" = "--restore" ]; then
    if [ ! -f "$BRIGHTNESS_SAVE_FILE" ]; then
      echo "Error: No saved brightness found. Use -s to save first."
      exit 1
    fi
    
    MONITOR="${ARG3:-}"
    
    if [ -z "$MONITOR" ]; then
      # Restore all monitors
      while IFS=: read -r name value; do
        if [ -n "$name" ] && [ -n "$value" ]; then
          NORMALIZED=$(awk "BEGIN {printf \"%.2f\", $value / 100}")
          qs ipc --pid "$PID" call brightness set "$NORMALIZED" "$name" 2>/dev/null || {
            echo "Warning: Could not restore brightness for $name"
          }
        fi
      done < "$BRIGHTNESS_SAVE_FILE"
      echo "Restored brightness for all monitors"
    else
      # Restore specific monitor
      VALUE=$(grep "^${MONITOR}:" "$BRIGHTNESS_SAVE_FILE" | cut -d: -f2)
      if [ -z "$VALUE" ]; then
        echo "Error: No saved brightness for monitor $MONITOR"
        exit 1
      fi
      NORMALIZED=$(awk "BEGIN {printf \"%.2f\", $VALUE / 100}")
      qs ipc --pid "$PID" call brightness set "$NORMALIZED" "$MONITOR" 2>/dev/null || {
        echo "Error: Could not restore brightness for $MONITOR"
        exit 1
      }
      echo "Restored brightness for $MONITOR to ${VALUE}%"
    fi
    exit 0
  fi
  
  # Parse value and monitor/flags
  VALUE=""
  MONITOR=""
  SAVE_FLAG=false
  RELATIVE_MODE=false
  RELATIVE_DELTA=0
  
  if [[ "$ARG2" =~ ^[0-9]+$ ]]; then
    VALUE="$ARG2"
    if [ "$ARG3" = "-s" ] || [ "$ARG3" = "--save" ]; then
      SAVE_FLAG=true
    elif [ -n "$ARG3" ] && [ "$ARG3" != "-s" ] && [ "$ARG3" != "--save" ]; then
      MONITOR="$ARG3"
      if [ "$ARG4" = "-s" ] || [ "$ARG4" = "--save" ]; then
        SAVE_FLAG=true
      fi
    fi
  elif [[ "$ARG2" =~ ^[+-][0-9]+$ ]]; then
    # Relative mode: +10 or -5
    RELATIVE_MODE=true
    RELATIVE_DELTA="$ARG2"
    if [ -n "$ARG3" ] && [ "$ARG3" != "-s" ] && [ "$ARG3" != "--save" ]; then
      MONITOR="$ARG3"
      if [ "$ARG4" = "-s" ] || [ "$ARG4" = "--save" ]; then
        SAVE_FLAG=true
      fi
    elif [ "$ARG3" = "-s" ] || [ "$ARG3" = "--save" ]; then
      SAVE_FLAG=true
    fi
  elif [ "$ARG2" = "-s" ] || [ "$ARG2" = "--save" ]; then
    # Just save, no value change
    MONITOR="${ARG3:-}"
    if [ -z "$MONITOR" ]; then
      # Save all monitors
      bash "${SCRIPT_DIR}/scripts/brightness_list.sh" > "${BRIGHTNESS_SAVE_FILE}.tmp" 2>/dev/null || {
        echo "Warning: Could not query current brightness"
      }
      if [ -f "${BRIGHTNESS_SAVE_FILE}.tmp" ]; then
        while IFS=: read -r name bright method; do
          if [ -n "$name" ] && [ -n "$bright" ]; then
            echo "${name}:${bright}"
          fi
        done < "${BRIGHTNESS_SAVE_FILE}.tmp" > "$BRIGHTNESS_SAVE_FILE"
        rm -f "${BRIGHTNESS_SAVE_FILE}.tmp"
        echo "Saved current brightness for all monitors"
      fi
    else
      # Save specific monitor
      CURRENT_LINE=$(bash "${SCRIPT_DIR}/scripts/brightness_list.sh" 2>/dev/null | grep "^${MONITOR}:")
      if [ -z "$CURRENT_LINE" ]; then
        echo "Error: Monitor $MONITOR not found"
        exit 1
      fi
      CURRENT=$(echo "$CURRENT_LINE" | cut -d: -f2)
      if [ -f "$BRIGHTNESS_SAVE_FILE" ]; then
        grep -v "^${MONITOR}:" "$BRIGHTNESS_SAVE_FILE" > "${BRIGHTNESS_SAVE_FILE}.tmp" 2>/dev/null || true
        echo "${MONITOR}:${CURRENT}" >> "${BRIGHTNESS_SAVE_FILE}.tmp"
        mv "${BRIGHTNESS_SAVE_FILE}.tmp" "$BRIGHTNESS_SAVE_FILE"
      else
        echo "${MONITOR}:${CURRENT}" > "$BRIGHTNESS_SAVE_FILE"
      fi
      echo "Saved current brightness for $MONITOR (${CURRENT}%)"
    fi
    exit 0
  else
    echo "Error: Invalid brightness value. Must be 0-100 or +/-delta."
    echo "Run 'ambxst help' for usage information"
    exit 1
  fi
  
  # Handle relative mode - calculate absolute value from current
  if [ "$RELATIVE_MODE" = true ]; then
    if [ -z "$MONITOR" ]; then
      # Get first monitor's brightness as reference for all
      CURRENT_LINE=$(bash "${SCRIPT_DIR}/scripts/brightness_list.sh" 2>/dev/null | head -1)
      if [ -z "$CURRENT_LINE" ]; then
        echo "Error: Could not get current brightness"
        exit 1
      fi
      CURRENT=$(echo "$CURRENT_LINE" | cut -d: -f2)
    else
      # Get specific monitor's brightness
      CURRENT_LINE=$(bash "${SCRIPT_DIR}/scripts/brightness_list.sh" 2>/dev/null | grep "^${MONITOR}:")
      if [ -z "$CURRENT_LINE" ]; then
        echo "Error: Monitor $MONITOR not found"
        exit 1
      fi
      CURRENT=$(echo "$CURRENT_LINE" | cut -d: -f2)
    fi
    # Calculate new value
    VALUE=$((CURRENT + RELATIVE_DELTA))
    # Clamp to 0-100
    if [ "$VALUE" -lt 0 ]; then
      VALUE=0
    elif [ "$VALUE" -gt 100 ]; then
      VALUE=100
    fi
  fi
  
  # Validate brightness range
  if [ "$VALUE" -lt 0 ] || [ "$VALUE" -gt 100 ]; then
    echo "Error: Brightness must be between 0 and 100"
    exit 1
  fi
  
  # Save current brightness if requested
  if [ "$SAVE_FLAG" = true ]; then
    if [ -z "$MONITOR" ]; then
      # Save all monitors - we need to get current brightness
      # For simplicity, we'll use a helper script to query current brightness
      bash "${SCRIPT_DIR}/scripts/brightness_list.sh" > "${BRIGHTNESS_SAVE_FILE}.tmp" 2>/dev/null || {
        echo "Warning: Could not query current brightness"
      }
      # Convert format from name:brightness:method to name:brightness
      if [ -f "${BRIGHTNESS_SAVE_FILE}.tmp" ]; then
        while IFS=: read -r name bright method; do
          if [ -n "$name" ] && [ -n "$bright" ]; then
            echo "${name}:${bright}"
          fi
        done < "${BRIGHTNESS_SAVE_FILE}.tmp" > "$BRIGHTNESS_SAVE_FILE"
        rm -f "${BRIGHTNESS_SAVE_FILE}.tmp"
        echo "Saved current brightness for all monitors"
      fi
    else
      # Save specific monitor
      CURRENT_LINE=$(bash "${SCRIPT_DIR}/scripts/brightness_list.sh" 2>/dev/null | grep "^${MONITOR}:")
      if [ -z "$CURRENT_LINE" ]; then
        echo "Error: Monitor $MONITOR not found"
        exit 1
      fi
      CURRENT=$(echo "$CURRENT_LINE" | cut -d: -f2)
      # Update or append to save file
      if [ -f "$BRIGHTNESS_SAVE_FILE" ]; then
        grep -v "^${MONITOR}:" "$BRIGHTNESS_SAVE_FILE" > "${BRIGHTNESS_SAVE_FILE}.tmp" 2>/dev/null || true
        echo "${MONITOR}:${CURRENT}" >> "${BRIGHTNESS_SAVE_FILE}.tmp"
        mv "${BRIGHTNESS_SAVE_FILE}.tmp" "$BRIGHTNESS_SAVE_FILE"
      else
        echo "${MONITOR}:${CURRENT}" > "$BRIGHTNESS_SAVE_FILE"
      fi
      echo "Saved current brightness for $MONITOR (${CURRENT}%)"
    fi
  fi
  
  # Set brightness
  NORMALIZED=$(awk "BEGIN {printf \"%.2f\", $VALUE / 100}")
  
  if [ -z "$MONITOR" ]; then
    # Set all monitors
    qs ipc --pid "$PID" call brightness set "$NORMALIZED" "" 2>/dev/null || {
      echo "Error: Could not set brightness"
      exit 1
    }
    echo "Set brightness to ${VALUE}% for all monitors"
  else
    # Set specific monitor
    qs ipc --pid "$PID" call brightness set "$NORMALIZED" "$MONITOR" 2>/dev/null || {
      echo "Error: Could not set brightness for $MONITOR"
      exit 1
    }
    echo "Set brightness to ${VALUE}% for $MONITOR"
  fi
  ;;
help | --help | -h)
  show_help
  ;;
"")
  # Run daemon priority script to kill conflicting processes and start hypridle
  bash "${SCRIPT_DIR}/scripts/daemon_priority.sh"
  
  # Kill any existing easyeffects and start it as a service
  pkill -x easyeffects 2>/dev/null || true
  nohup easyeffects --gapplication-service >/dev/null 2>&1 &
  
  # Launch QuickShell with the main shell.qml
  if [ -n "$NIXGL_BIN" ]; then
    exec "$NIXGL_BIN" "$QS_BIN" -p "${SCRIPT_DIR}/shell.qml"
  else
    exec "$QS_BIN" -p "${SCRIPT_DIR}/shell.qml"
  fi
  ;;
*)
  echo "Error: Unknown command '$1'"
  echo "Run 'ambxst help' for usage information"
  exit 1
  ;;
esac
