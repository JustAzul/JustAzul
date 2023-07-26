#!/bin/bash

max_jobs=10

# Function to display progress
bar_size=40
bar_char_done="#"
bar_char_todo="-"
bar_percentage_scale=2

show_progress() {
    current="$1"
    total="$2"
    verbose="$3"

    # calculate the progress in percentage 
    percent=$(bc <<< "scale=$bar_percentage_scale; 100 * $current / $total" )
    # The number of done and todo characters
    done=$(bc <<< "scale=0; $bar_size * $percent / 100" )
    todo=$(bc <<< "scale=0; $bar_size - $done" )

    # build the done and todo sub-bars
    done_sub_bar=$(printf "%${done}s" | tr " " "${bar_char_done}")
    todo_sub_bar=$(printf "%${todo}s" | tr " " "${bar_char_todo}")

    # output the bar
    echo -ne "\r ${percent}% [${done_sub_bar}${todo_sub_bar}] > ${current}/${total}"
}

# Find all git directories and store them
git_dirs=$(find $1 -name .git 2>&1 | grep -v "Permission denied")

# Get parent of each .git directory
git_dirs=$(dirname $git_dirs)

# Count total number of directories
total_dirs=$(echo "$git_dirs" | wc -l)

# Initialize counter
count=0

# Create named pipe
pipe=$(mktemp -u)
mkfifo $pipe

# Function to pull and gc
pull_and_gc() {
    dir=$1
    cd $dir

    output=$(git pull 2>&1 && git gc --auto 2>&1)

    # Print status
    echo $dir: $output
}

# Export it so it's available to parallel jobs
export -f pull_and_gc

# Loop through each git directory
echo "$git_dirs" | xargs -P $max_jobs -n 1 -I {} bash -c 'pull_and_gc "$@"' _ {} > $pipe &

# Handle output
while IFS= read -r line
do
    # Calculate percentage
    count=$((count + 1))

    # Show progress
    show_progress $count $total_dirs $line
done < $pipe

rm $pipe

printf "\nFinished syncing repositories.\n"
