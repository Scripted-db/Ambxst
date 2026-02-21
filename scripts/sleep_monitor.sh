#!/usr/bin/env bash

LOCKFILE="/tmp/ambxst_sleep_monitor.lock"
exec 9>"$LOCKFILE"
if ! flock -n 9; then
	exit 0
fi
echo $$ 1>&9

cleanup() {
	pkill -P $$ >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

# Sleep Monitor - Executes commands before and after sleep
CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/ambxst/config/system.json"

get_cmd() {
	local type=$1
	if [ -f "$CONFIG_FILE" ]; then
		if [ "$type" == "before" ]; then
			jq -r '.idle.general.before_sleep_cmd // "loginctl lock-session"' "$CONFIG_FILE"
		else
			jq -r '.idle.general.after_sleep_cmd // "ambxst screen on"' "$CONFIG_FILE"
		fi
	else
		if [ "$type" == "before" ]; then
			echo "loginctl lock-session"
		else
			echo "ambxst screen on"
		fi
	fi
}

# Monitor logind's PrepareForSleep signal and parse boolean state directly.
while IFS= read -r line; do
	case "$line" in
	*"boolean true"*)
		# Going to sleep
		echo "SUSPEND"
		CMD=$(get_cmd "before")
		if [ -n "$CMD" ]; then
			eval "$CMD" &
		fi
		;;
	*"boolean false"*)
		# Waking up
		echo "WAKE"
		CMD=$(get_cmd "after")
		if [ -n "$CMD" ]; then
			eval "$CMD" &
		fi
		;;
	esac
done < <(dbus-monitor --system "type='signal',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'")
