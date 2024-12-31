#!/bin/bash

# Set the timezone to Pacific Time (PST/PDT) before performing the date calculation
export TZ="America/Los_Angeles"

# Convert the current time (ISO 8601 format) to a timestamp
current_timestamp=$(date +"%s")

# Get the current hour and minute
current_hour=$(date -d "@$current_timestamp" +"%H")
current_minute=$(date -d "@$current_timestamp" +"%M")

echo "current_hour=$current_hour"
echo "current_minute=$current_minute"

# Check if current time is between midnight and 5:58 AM
if [ "$current_hour" -ge "00" ] && [ "$current_hour" -lt "06" ] && [ "$current_minute" -lt "58" ]; then
    # If it's between midnight and 5:58 AM, set the next wake time to 5:58 AM today
    next_time=$(date -d "today 05:58" +"%Y-%m-%dT05:58:00%:z")
else
    # If it's after 5:58 AM, set the next wake time to the current hour's 58th minute
    next_time=$(date -d "today $current_hour:58" +"%Y-%m-%dT%H:58:00%:z")
fi

# Set the repeat schedule (e.g., 127 means Monday to Sunday, all days)
repeat_schedule=127

# Call the rtc_alarm_set API using netcat (nc)
echo "rtc_alarm_set $next_time $repeat_schedule" 
echo "rtc_alarm_set $next_time $repeat_schedule" | nc -q 2 127.0.0.1 8423

echo "RTC alarm set to $next_time with repeat schedule $repeat_schedule"
