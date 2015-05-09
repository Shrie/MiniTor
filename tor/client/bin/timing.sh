#!/bin/bash
# This script will run wget n times 

echo -n "Number of times to request website: "
read NUM
echo -n "Seconds to wait between requests: "
read TIME

TOR=/home/mininet/tor/client/bin/torsocks
WGET=/usr/bin/wget
URL="10.0.0.14"
WGET_OPTS='-O NULL'
CHECK=NUM-1

for ((i=0; i<$NUM; i++)); do
	$TOR $WGET $WGET_OPTS $URL
	if ((i < $CHECK)); then
		for ((j=0; j<TIME; j++)); do
			echo -n '.'
			sleep 1
		done
		echo ''
	fi
done