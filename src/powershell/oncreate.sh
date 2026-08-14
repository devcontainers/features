#!/usr/bin/env bash
set -e

PRESERVE_HISTORY="preserveHistoryFromInstallSh"
HISTORY_SAVE_LINE='Set-PSReadLineOption -HistorySavePath /dc/powershell/history.txt'

if [ "${PRESERVE_HISTORY}" = "true" ]; then
	if [ "$(stat -c '%u:%g' "/dc/powershell")" = "$(id -u):$(id -g)" ]; then
		echo "Already owned by the current user, nothing to do"
	elif [ "$(id -u)" -eq 0 ]; then
		chown -R "$(id -u):$(id -g)" "/dc/powershell"
	elif command -v sudo >/dev/null 2>&1; then
		sudo chown -R "$(id -u):$(id -g)" "/dc/powershell"
	else
		echo "Warning: unable to chown /dc/powershell (current user not root and no sudo available); history may not persist." >&2
	fi
		profile_path="$(pwsh -NoProfile -Command '$PROFILE')"
		mkdir -p "$(dirname "$profile_path")"
		touch "$profile_path"

		if ! grep -Fxq "$HISTORY_SAVE_LINE" "$profile_path"; then
				printf '\n%s\n' "$HISTORY_SAVE_LINE" >> "$profile_path"
		fi
fi
