#!/bin/mksh
printf '%s\n' "HTTP/1.1 200 OK" ""
read -r -t 0.5 -d $'\0' input
./neekshellbot.sh "$(tail -n 2 <<< "$input")" &
