#!/bin/bash
bash /home/eric/PiInk/wait_for_server.sh && curl -X POST -F file=@$(find  /home/eric/nfs/Photos/ -name '*.JPG' | shuf -n 1) 0.0.0.0
