#!/bin/sh

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
        kill -15 "$pid" 2>/dev/null
    done
}

kill_1password_relay_pids() {
    kill_pids "$(get_socat_npiperelay_pids)"
    kill_pids "$(get_npiperelay_pids)"
}

is_socket_running() {
    if [ -S "$SSH_AUTH_SOCK" ]; then
        echo 0
        return
    else
        echo 1
        return
    fi
}

kill_socket_file() {
    if [ "$(is_socket_running)" -eq 0 ]; then
        rm -f "$SSH_AUTH_SOCK"
    fi
}

start_relay_process() {
    (setsid socat UNIX-LISTEN:"$SSH_AUTH_SOCK",fork EXEC:"npiperelay.exe -ei -s //./pipe/openssh-ssh-agent",nofork &) 2>&1
}

should_start_agent() {
    # always start agent as a temporary hotfix. npiperelay.exe isnt always available
    echo 0
    return
    
    socat_running=$(is_process_running "socat_npiperelay")
    npiperelay_running=$(is_process_running "npiperelay")

    if [ "$(is_socket_running)" -eq 1 ] || [ "$socat_running" -eq 1 ] || [ "$npiperelay_running" -eq 1 ]; then
        echo 0
        return
    else
        echo 1
        return
    fi
}

if [ "$(should_start_agent)" -eq 0 ]; then
    kill_socket_file
    kill_1password_relay_pids
    start_relay_process
fi
