#!/bin/bash
# Starts a tor node and logs output

if [ -e /home/mininet/tor/$1 ]; then
    /home/mininet/tor/$1/bin/tor > /home/mininet/tor/tmp/$1
fi

