#!/bin/zsh
set -euo pipefail

project_dir="${0:A:h}"
source_app="$project_dir/dist/QuotaKnot.app"
install_dir="$HOME/Applications"
installed_app="$install_dir/QuotaKnot.app"

if [[ ! -d "$source_app" ]]; then
    "$project_dir/build-app.sh"
fi

running_pids=($(pgrep -x QuotaKnot || true))
if (( ${#running_pids[@]} > 0 )); then
    kill "${running_pids[@]}"
    for running_pid in "${running_pids[@]}"; do
        while kill -0 "$running_pid" 2>/dev/null; do
            sleep 0.1
        done
    done
fi

mkdir -p "$install_dir"
ditto "$source_app" "$installed_app"
open "$installed_app"

echo "$installed_app"
