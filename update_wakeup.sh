#!/bin/bash

# Path to the config file
config_file="/etc/pisugar-server/config.json"

# Set the timezone to Pacific Time (PST/PDT) before performing the date calculation
export TZ="America/Los_Angeles"

# Convert the current_time (ISO 8601 format) to a timestamp
current_timestamp=$(date +"%s")

# Extract the current minute
current_minute=$(date -d "@$current_timestamp" +"%M")

# Calculate the next wake time
if [ "$current_minute" -lt "58" ]; then
    # If it's before the 58th minute, set the next time to this hour's 58th minute
    next_time=$(date -d "@$(( (current_timestamp / 3600) * 3600 + 58 * 60 ))" +"%Y-%m-%dT%H:58:00%:z")
else
    # If it's after the 58th minute, set the next wake time to the next hour's 58th minute
    next_time=$(date -d "@$(( (current_timestamp / 3600 + 1) * 3600 + 58 * 60 ))" +"%Y-%m-%dT%H:58:00%:z")
fi

# Update the config.json file with the new auto_wake_time
jq --arg new_time "$next_time" '.auto_wake_time = $new_time' $config_file > temp_config.json && sudo mv temp_config.json $config_file

echo "auto_wake_time updated to $next_time"
systemctl restart pisugar-server
