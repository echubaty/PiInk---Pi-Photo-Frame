#!/bin/bash

# Set the server's IP address or domain
SERVER="0.0.0.0:80"

until curl --silent --head --fail "$SERVER" &> /dev/null
do
  echo "Waiting for $SERVER to become available..."
  sleep 1  # Wait for 1 second before trying again
done

echo "$SERVER is now available!"
