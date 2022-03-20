#!/bin/mksh
printf '%s\n' "HTTP/1.1 200 OK" ""
./neekshellbot.sh "$(cat | tail -n 2)" &
