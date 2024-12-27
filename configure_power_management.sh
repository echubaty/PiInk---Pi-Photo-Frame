#!/bin/bash

# Function to check if PiSugar3 is charging using nc and PiSugar server
is_charging() {
    # Query the PiSugar server for charging status
    charging_status=$(echo "get battery_charging" | nc -q 2 127.0.0.1 8423)
    
    # Extract the "battery_charging" value from the response
    if [[ "$charging_status" == *"battery_charging: true"* ]]; then
        # PiSugar is charging
        return 0
    else
        # PiSugar is not charging
        return 1
    fi
}

# Function to check if shutdown is scheduled
is_shutdown_scheduled() {
    # Check if any scheduled job contains the word "shutdown"
    scheduled_shutdowns=$(atq | awk '{print $1}' | xargs -I {} at -c {} | grep -i "shutdown")

    # If shutdown command is found, return true
    if [ -n "$scheduled_shutdowns" ]; then
        return 0
    else
        return 1
    fi
}

# Function to get the next wake-up time from the config
get_next_wakeup_time() {
    # Get the next scheduled wake-up time from the PiSugar config file
    next_wakeup_time=$(jq -r '.auto_wake_time' /etc/pisugar-server/config.json)
    echo $next_wakeup_time
}

# Function to check if shutdown time is after the next wake-up time
is_shutdown_after_wakeup() {
    # Get the next wake-up time
    next_wakeup_time=$(get_next_wakeup_time)
    
    # Extract the shutdown time from the scheduled job (from `atq`)
    shutdown_job_time=$(atq | awk '{print $2, $3, $4, $5, $6}' | head -n 1)
    
    # Convert both the next wake-up time and the shutdown time to timestamps for comparison
    shutdown_timestamp=$(date -d "$shutdown_job_time" +"%s")
    wakeup_timestamp=$(date -d "$next_wakeup_time" +"%s")
    
    # If shutdown is after the wake-up time, return true
    if [[ "$shutdown_timestamp" -gt "$wakeup_timestamp" ]]; then
        return 0
    else
        return 1
    fi
}

# If PiSugar3 is charging, cancel any pending shutdowns
if is_charging; then
    if is_shutdown_scheduled; then
        echo "PiSugar3 is charging. Cancelling any pending shutdowns..."
        # Cancel all scheduled shutdowns
        sudo atrm $(atq | awk '{print $1}')
    else
        echo "PiSugar3 is charging. No shutdown scheduled."
    fi
else
    # If PiSugar3 is not charging and no shutdown is scheduled, schedule one for 10 minutes
    if ! is_shutdown_scheduled; then
        echo "PiSugar3 is not charging. Scheduling shutdown in 10 minutes..."
        echo "sudo shutdown -h now" | at now + 10 minutes  # Schedule shutdown in 10 minutes
        bash /home/eric/PiInk/update_wakeup.sh
    else
        echo "Shutdown already scheduled, no action needed."
    fi
fi

# Check if shutdown time is after the next wake-up time
if is_shutdown_after_wakeup; then
    echo "Shutdown is scheduled after the next wake-up time. Postponing the next wake-up by 30 minutes..."
    
    # Get the current scheduled wake-up time from config
    next_wakeup_time=$(get_next_wakeup_time)

    # Add 30 minutes to the next wake-up time
    new_wakeup_timestamp=$(date -d "$next_wakeup_time" +"%s")
    new_wakeup_timestamp=$((new_wakeup_timestamp + 1800))  # Add 30 minutes (1800 seconds)
    
    # Convert the new timestamp to ISO 8601 format
    new_wakeup_time=$(date -d "@$new_wakeup_timestamp" +"%Y-%m-%dT%H:%M:%S%:z")
    
    # Update the config.json file with the new auto_wake_time
    jq --arg new_time "$new_wakeup_time" '.auto_wake_time = $new_time' /etc/pisugar-server/config.json > temp_config.json && sudo mv temp_config.json /etc/pisugar-server/config.json
    
    echo "auto_wake_time updated to $new_wakeup_time"
    systemctl restart pisugar-server
fi
