#!/bin/sh

# Configure ssh forwarding
export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"

# Get PIDs for npiperelay.exe
get_npiperelay_pids() {
    pgrep -f "npiperelay.exe -ei -s //./pipe/openssh-ssh-agent"
}

# Get PIDs for socat command with npiperelay.exe
get_socat_npiperelay_pids() {
    pgrep -f "socat UNIX-LISTEN:$SSH_AUTH_SOCK,fork EXEC:npiperelay.exe -ei -s //./pipe/openssh-ssh-agent,nofork"
}

# Check if any processes are running for a given command
is_process_running() {
    if [ "$1" = "npiperelay" ]; then
        is_process_running_pids=$(get_npiperelay_pids)
    elif [ "$1" = "socat_npiperelay" ]; then
        is_process_running_pids=$(get_socat_npiperelay_pids)
    else
        echo "is_process_running(): Invalid command name provided." >&2
        echo 2 # Indicates an error due to invalid command
        return
    fi

    # Check if there's at least one PID in the list
    if [ -n "$is_process_running_pids" ]; then
        # echo "$1 is running. PIDs: $is_process_running_pids" >&2
        echo 0 # 0 for true
        return
    else
        # echo "$1 is not running." >&2
        echo 1 # 1 for false
        return
    fi
}

# Function to kill each PID from a given list
kill_pids() {
    kill_pids_pids="$1"

    # Check if there are any PIDs to kill
    if [ -z "$kill_pids_pids" ]; then
        echo "No processes found to kill."
        return
    fi

    echo "$kill_pids_pids" | while IFS= read -r pid; do
        kill -9 "$pid" 2>/dev/null && echo "Killed PID: $pid" || echo "Failed to kill PID: $pid"
    done
}

# Assigning the result to the variable
socat_running=$(is_process_running "socat_npiperelay")
npiperelay_running=$(is_process_running "npiperelay")

# If both are running, set SHOULD_START_AGENT to 1 (false). Otherwise, set it to 0 (true).
SHOULD_START_AGENT=$((socat_running == 0 && npiperelay_running == 0 ? 1 : 0))

if [ "$SHOULD_START_AGENT" = 0 ]; then
    # If the socket file exists, remove it
    if [ -S "$SSH_AUTH_SOCK" ]; then
        echo "removing previous socket..."
        rm -f "$SSH_AUTH_SOCK"
    fi

    # To kill socat_npiperelay processes
    kill_pids "$(get_socat_npiperelay_pids)"

    # To kill npiperelay processes
    kill_pids "$(get_npiperelay_pids)"

    echo "Starting SSH-Agent relay..."
    # Start the relay process
    (setsid socat UNIX-LISTEN:"$SSH_AUTH_SOCK",fork EXEC:"npiperelay.exe -ei -s //./pipe/openssh-ssh-agent",nofork &) >/dev/null 2>&1

    # Wait for the socket to appear (max 5 seconds)
    SOCKET_WAIT_TIME=0
    while [ ! -S "$SSH_AUTH_SOCK" ] && [ "$SOCKET_WAIT_TIME" -lt 5 ]; do
        # Wait for 1 second before checking again
        sleep 1
        SOCKET_WAIT_TIME=$((SOCKET_WAIT_TIME + 1))
    done

    # If the socket does not exist after waiting
    if [ ! -S "$SSH_AUTH_SOCK" ]; then
        echo "Error: SSH_AUTH_SOCK does not exist after starting the relay process."
        exit 1
    fi
fi
