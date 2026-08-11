#!/usr/bin/env bash
set -e

PRESERVE_HISTORY="preserveHistoryFromInstallSh"
HISTORY_SAVE_LINE='Set-PSReadLineOption -HistorySavePath /dc/powershell/history.txt'

if [ "${PRESERVE_HISTORY}" = "true" ]; then
	sudo chown -R "$(id -u):$(id -g)" "/dc/powershell"
		profile_path="$(pwsh -NoProfile -Command '$PROFILE')"
		mkdir -p "$(dirname "$profile_path")"
		touch "$profile_path"

		if ! grep -Fxq "$HISTORY_SAVE_LINE" "$profile_path"; then
				printf '\n%s\n' "$HISTORY_SAVE_LINE" >> "$profile_path"
		fi
fi
