#!/bin/bash
# Wait for the server to be ready
bash /home/eric/PiInk/wait_for_server.sh

# Fetch the list of .JPG files once and store it in a variable
image_list=$(find /home/eric/nfs/ -name '*.JPG')

# Loop until a landscape image is found
while true; do
    # Pick a random image from the pre-fetched list
    random_image=$(echo "$image_list" | shuf -n 1)
    
    # Get the image's width, height, and orientation using exiftool
    image_dimensions=$(exiftool -s -s -s -ImageWidth -ImageHeight -Orientation "$random_image")
   
    #echo "Raw exiftool output: $image_dimensions"

    # Check if exiftool returned valid values for width, height, and orientation
    if [[ ! "$image_dimensions" =~ ([0-9]+)[[:space:]]+([0-9]+)[[:space:]]*(Horizontal\ \(normal\)) ]]; then
        # If not valid, skip this image and try another one
        echo "Dimensions invalid or not landscape, skipping to the next."
        continue
    fi
    
    # Extract width, height, and orientation
    image_width=${BASH_REMATCH[1]}
    image_height=${BASH_REMATCH[2]}
    image_orientation=${BASH_REMATCH[3]}

    echo "Width: $image_width, Height: $image_height, Orientation: $image_orientation"

    # Check if the image is landscape (i.e., it's horizontally oriented)
    if [[ "$image_orientation" == "Horizontal (normal)" ]]; then
        # If it's landscape, send it via curl
        echo "Uploading file: $random_image"
        curl -X POST -F file=@"$random_image" 0.0.0.0
        break  # Exit the loop after sending the landscape image
    fi

    # If not landscape, continue the loop to find another random image
done
