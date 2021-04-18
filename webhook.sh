#!/bin/mksh
socat tcp-l:14112,reuseaddr,fork system:./getinput.sh
