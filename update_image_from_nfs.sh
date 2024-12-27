#!/bin/bash
#bash /home/eric/PiInk/wait_for_server.sh && curl -X POST -F file=@$(find  /home/eric/nfs/ -name '*.JPG' | shuf -n 1) 0.0.0.0

# Wait for the server to be ready
bash /home/eric/PiInk/wait_for_server.sh

# Fetch the list of .JPG files once and store it in a variable
image_list=$(find /home/eric/nfs/ -name '*.JPG')

# Loop until a landscape image is found
while true; do
    # Pick a random image from the pre-fetched list
    random_image=$(echo "$image_list" | shuf -n 1)

    # Get the image's width and height using exiftool
    image_dimensions=$(exiftool -s -s -s -ImageWidth -ImageHeight "$random_image")

    # Check if exiftool returned valid values for width and height
    if [[ ! "$image_dimensions" =~ ([0-9]+)[[:space:]]+([0-9]+) ]]; then
        # If not valid, skip this image and try another one
        continue
    fi

    # Extract width and height from the regex match
    image_width=${BASH_REMATCH[1]}
    image_height=${BASH_REMATCH[2]}

    # Check if the image is landscape (width > height)
    if [ "$image_width" -gt "$image_height" ]; then
        # If it's landscape, send it via curl
        curl -X POST -F file=@"$random_image" 0.0.0.0
        break  # Exit the loop after sending the landscape image
    fi

    # If not landscape, continue the loop to find another random image
done
