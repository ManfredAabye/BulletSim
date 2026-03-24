#!/usr/bin/env bash
# Cleanup script for BulletSim build artifacts on Linux/macOS.

# cd /opt/opensim
# rm -rf  /opt/opensim/BulletSim

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REMOVED=0

ECHOLINE="____________________________________________________________________________________________"

# Farben für bessere Lesbarkeit
COLOR_INFO='\033[1;36m'    # Cyan
COLOR_SUCCESS='\033[1;32m'  # Grün
COLOR_RESET='\033[0m'       # Zurücksetzen

echo "$ECHOLINE"
echo -e "${COLOR_INFO}=== Cleanup: Lösche BulletSim Build Artefakte in ${SCRIPT_DIR}${COLOR_RESET}"
echo "$ECHOLINE"

remove_dir() {
	local target="$1"
	if [[ -d "$target" ]]; then
		echo "[DIR ] $target"
		rm -rf "$target"
		REMOVED=$((REMOVED + 1))
	fi
}

remove_file() {
	local target="$1"
	if [[ -e "$target" ]]; then
		echo "[FILE] $target"
		rm -f "$target"
		REMOVED=$((REMOVED + 1))
	fi
}

delete_pattern() {
	local target_dir="$1"
	local target_pattern="$2"
	local matches=()
	while IFS= read -r f; do
		matches+=("$f")
	done < <(find "$target_dir" -maxdepth 1 -type f -name "$target_pattern" -print)

	local f
	for f in "${matches[@]}"; do
		if [[ -e "$f" ]]; then
			echo "[FILE] $f"
			rm -f "$f"
			REMOVED=$((REMOVED + 1))
		fi
	done
}

remove_dir "$SCRIPT_DIR/bullet3/bullet-build"
remove_dir "$SCRIPT_DIR/bullet3"
remove_dir "$SCRIPT_DIR/lib"
remove_dir "$SCRIPT_DIR/include"
remove_dir "$SCRIPT_DIR/logs"
remove_dir "$SCRIPT_DIR/x64"

remove_file "$SCRIPT_DIR/logsbuildBulletCMake.log"
remove_file "$SCRIPT_DIR/BulletSimVersionInfo"

delete_pattern "$SCRIPT_DIR" "libBulletSim-*.so"
delete_pattern "$SCRIPT_DIR" "libBulletSim-*.dylib"
delete_pattern "$SCRIPT_DIR" "BulletSim.dll"
delete_pattern "$SCRIPT_DIR" "BulletSim.lib"
delete_pattern "$SCRIPT_DIR" "BulletSim.pdb"

echo "$ECHOLINE"
echo -e "${COLOR_SUCCESS}✓ Cleanup fertig. Gelöschte Elemente: $REMOVED${COLOR_RESET}"
echo "$ECHOLINE"
