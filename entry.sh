#!/bin/bash

# Start the web server in the foreground, so systemd can track it
exec bash /home/eric/PiInk/scripts/start.sh &

# Start the upload task in the background
bash /home/eric/PiInk/update_image_from_nfs.sh &

# Wait for background processes to finish
wait
