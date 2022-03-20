#!/bin/mksh
printf '%s\n' "HTTP/1.1 200 OK" ""
input=$(tail -n 2)
./neekshellbot.sh "$input" &
