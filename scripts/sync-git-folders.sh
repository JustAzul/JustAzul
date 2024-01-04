#!/bin/bash

max_jobs=3

# Function to display progress
bar_size=40
bar_char_done="#"
bar_char_todo="-"
bar_percentage_scale=2

show_progress() {
    current="$1"
    total="$2"
    message="$3"

    percent=$(bc <<<"scale=$bar_percentage_scale; 100 * $current / $total")
    done=$(bc <<<"scale=0; $bar_size * $percent / 100")
    todo=$(bc <<<"scale=0; $bar_size - $done")

    done_sub_bar=$(printf "%${done}s" | tr " " "${bar_char_done}")
    todo_sub_bar=$(printf "%${todo}s" | tr " " "${bar_char_todo}")

    # Clear the line
    echo -ne "\r\033[K"

    # Print the new line
    echo -ne "\r ${percent}% [${done_sub_bar}${todo_sub_bar}] > ${current}/${total} - ${message}"
}

# Find all git directories and store their parent directories
git_dirs=$(find "$1" -name .git -type d 2>&1 | grep -v "Permission denied" | xargs -I {} dirname "{}")
total_dirs=$(echo "$git_dirs" | wc -l)
count=0

pipe=$(mktemp -u)
mkfifo "$pipe"

pull_and_gc() {
    dir=$1
    message=""

    # Get the parent directory name
    parent_dir=$(basename "$(dirname "$dir")")

    # Get the basename of the repository
    repo_name=$(basename "$dir")

    display_path="${parent_dir}/${repo_name}"

    if [ -d "$dir" ]; then
        cd "$dir" && {
            if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
                git fetch --prune 2>&1

                git_output="$(git pull 2>&1)"

                branches_to_delete=$(git branch --merged | grep -E -v "(^\*|master|main|dev|develop)" || :)
                if [ -n "$branches_to_delete" ]; then
                    for branch in $branches_to_delete; do
                        git branch -d "$branch" 2>&1
                    done
                fi

                git gc --auto 2>&1
                message="$display_path: $git_output"
            else
                message="$display_path is not a Git repository"
            fi
        } || message="$display_path: Failed to change directory"
    else
        message="$display_path is not a directory"
    fi

    echo "$message" >&3
}

export -f pull_and_gc

echo "$git_dirs" | xargs -P $max_jobs -n 1 -I {} bash -c 'pull_and_gc "$@"' _ {} 3>"$pipe" &

while IFS= read -r line; do
    count=$((count + 1))
    show_progress $count "$total_dirs" "$line"
done <"$pipe"

rm "$pipe"

printf "\nFinished syncing repositories.\n"
