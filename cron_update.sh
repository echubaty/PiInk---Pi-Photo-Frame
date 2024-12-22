#!/bin/bash


# Get the system uptime in minutes (using grep to extract the uptime in minutes)
UPTIME=$(uptime -p | grep -oP '\d+(?= min)' | head -n 1)

# Check if the system has been up for more than 3 minutes
if [ "$UPTIME" -gt 3 ]; then
 cd /home/eric/PiInk/scripts
 bash /home/eric/PiInk/entry.sh  
fi


