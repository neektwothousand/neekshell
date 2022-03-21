#!/bin/mksh
printf '%s\n' "HTTP/1.1 204 No Content" ""
input=$(tail -n 2)
./neekshellbot.sh "$input" &
