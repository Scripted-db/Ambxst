#!/usr/bin/env bash

LOCKFILE="/tmp/ambxst_loginlock.lock"
exec 9>"$LOCKFILE"
if ! flock -n 9; then
	exit 0
fi
echo $$ 1>&9

cleanup() {
	pkill -P $$ >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/ambxst/config/system.json"

get_lock_cmd() {
	if [ -f "$CONFIG_FILE" ]; then
		jq -r '.idle.general.lock_cmd // "ambxst lock"' "$CONFIG_FILE"
	else
		echo "ambxst lock"
	fi
}

while IFS= read -r line; do
	case "$line" in
	*"member=Lock"*)
		COMMAND=$(get_lock_cmd)
		if [ -n "$COMMAND" ]; then
			eval "$COMMAND" &
		fi
		;;
	esac
done < <(dbus-monitor --system "type='signal',interface='org.freedesktop.login1.Session',member='Lock'")
