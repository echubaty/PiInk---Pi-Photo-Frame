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


get_next_wakeup_time() {
    # Get the current scheduled wake-up time from the PiSugar server
    next_wakeup_time=$(echo "get rtc_alarm_time" | nc -q 2 127.0.0.1 8423)
    
    # Extract the alarm time from the response
    next_wakeup_time=$(echo $next_wakeup_time | grep -oP 'rtc_alarm_time: \K.*')

    # Parse current date and time
    current_time=$(date +%Y-%m-%dT%H:%M:%S)
    
    # Extract the wake-up time (hour and minute) from the PiSugar server response
    wake_up_time=$(echo $next_wakeup_time | cut -d'T' -f2 | sed 's/\.[0-9]*//')

    # Get the current time's hour and minute
    current_hour=$(date +%H)
    current_minute=$(date +%M)

    # Get the wake-up time's hour and minute
    wake_up_hour=$(echo $wake_up_time | cut -d':' -f1)
    wake_up_minute=$(echo $wake_up_time | cut -d':' -f2)

    # Get the current date
    current_date=$(date +%Y-%m-%d)

    # Compare the current time with the wake-up time to adjust the date
    if [[ "$current_hour" -gt "$wake_up_hour" ]] || { [[ "$current_hour" -eq "$wake_up_hour" ]] && [[ "$current_minute" -gt "$wake_up_minute" ]]; }; then
        # If the current time is past the wake-up time, set the wake-up date to tomorrow
        next_wakeup_date=$(date -d "$current_date + 1 day" +%Y-%m-%d)
    else
        # Otherwise, set the wake-up date to today
        next_wakeup_date=$current_date
    fi
    
    # Combine the corrected date with the wake-up time
    corrected_wakeup_time="${next_wakeup_date}T${wake_up_time}"

    echo $corrected_wakeup_time
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
    echo "shutdown time $shutdown_job_time"
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
    # If PiSugar3 is not charging and no shutdown is scheduled, schedule one
    if ! is_shutdown_scheduled; then
        echo "PiSugar3 is not charging. Scheduling shutdown in 10 minutes..."
        echo "sudo shutdown -h now" | at now + 10 minutes
        bash /home/eric/PiInk/update_wakeup.sh
    else
        echo "Shutdown already scheduled, no action needed."
    fi
fi

# Check if shutdown time is after the next wake-up time
if is_shutdown_after_wakeup; then
    echo "Shutdown is scheduled after the next wake-up time. Postponing the next wake-up by 30 minutes..."
    #exit 0
    # Get the current scheduled wake-up time from PiSugar server
    next_wakeup_time=$(get_next_wakeup_time)
    echo "next wakeup = $next_wakeup_time"
    # Add 30 minutes to the next wake-up time
    new_wakeup_timestamp=$(date -d "$next_wakeup_time + 30 minutes" +"%s")
    
    # Convert the new timestamp to ISO 8601 format
    new_wakeup_time=$(date -d "@$new_wakeup_timestamp" +"%Y-%m-%dT%H:%M:%S%:z")
    
    # Set the new wake-up time via the PiSugar server
    echo "rtc_alarm_set $new_wakeup_time 127" | nc -q 2 127.0.0.1 8423
    
    echo "Wake-up time updated to $new_wakeup_time"
fi
