#!/usr/bin/env bash

err() {
	echo "(!) $*" >&2
}

die() {
	err "$@"
	exit 1
}

is_true() {
	case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
		true|1|yes)
			return 0
			;;
		*)
			return 1
			;;
	esac
}

trim() {
	local value="$1"
	value="${value#${value%%[![:space:]]*}}"
	value="${value%${value##*[![:space:]]}}"
	echo "${value}"
}

resolve_target_username() {
	local configured_username
	local possible_users
	local current_user

	configured_username="${USERNAME:-${_REMOTE_USER:-automatic}}"

	if [ "${configured_username}" = "auto" ] || [ "${configured_username}" = "automatic" ]; then
		possible_users=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
		for current_user in "${possible_users[@]}"; do
			if [ -n "${current_user}" ] && id -u "${current_user}" > /dev/null 2>&1; then
				echo "${current_user}"
				return
			fi
		done

		echo "root"
		return
	fi

	if [ "${configured_username}" = "none" ] || ! id -u "${configured_username}" > /dev/null 2>&1; then
		echo "root"
		return
	fi

	echo "${configured_username}"
}