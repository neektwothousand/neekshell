#!/bin/mksh
socat -T 0.1 tcp-l:14112,reuseaddr,fork system:./getinput.sh
