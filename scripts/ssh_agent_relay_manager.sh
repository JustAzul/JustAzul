#!/bin/sh

# Configure ssh forwarding
export SSH_AUTH_SOCK="$HOME/.1password-agent.sock"

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
        echo 0 # 0 for true
        return
    else
        echo 1 # 1 for false
        return
    fi
}

# Function to kill each PID from a given list
kill_pids() {
    kill_pids_pids="$1"
    if [ -z "$kill_pids_pids" ]; then
        return
    fi

    echo "$kill_pids_pids" | while IFS= read -r pid; do
        # First, try with SIGTERM
        kill -15 "$pid" 2>/dev/null
        sleep 1
        if kill -0 "$pid" 2>/dev/null; then
            kill -9 "$pid" 2>/dev/null && echo "Forcefully killed PID: $pid" || echo "Failed to kill PID: $pid"
        else
            echo "Gracefully killed PID: $pid"
        fi
    done
}

kill_1password_relay_pids() {
    kill_pids "$(get_socat_npiperelay_pids)"
    kill_pids "$(get_npiperelay_pids)"
}

is_socket_running() {
    if [ -S "$SSH_AUTH_SOCK" ]; then
        echo 1 # 1 for true
        return
    else
        echo 0 # 0 for false
        return
    fi
}

kill_socket_file() {
    if [ -S "$SSH_AUTH_SOCK" ]; then
        echo "removing previous socket..."
        rm -f "$SSH_AUTH_SOCK"
    fi
}

start_relay_process() {
    echo "Starting SSH-Agent relay..."
    (setsid socat UNIX-LISTEN:"$SSH_AUTH_SOCK",fork EXEC:"npiperelay.exe -ei -s //./pipe/openssh-ssh-agent",nofork &) >>~/socat.log 2>&1

    if [ $? -ne 0 ]; then
        echo "Error starting socat relay process."
    fi
}

should_start_agent() {
    socat_running=$(is_process_running "socat_npiperelay")
    npiperelay_running=$(is_process_running "npiperelay")

    if [ "$socat_running" -eq 1 ] || [ "$npiperelay_running" -eq 1 ]; then
        echo 1
        return
    else
        echo 0
        return
    fi
}

if [ "$(should_start_agent)" -eq 1 ]; then
    kill_socket_file
    kill_1password_relay_pids
    start_relay_process
fi
