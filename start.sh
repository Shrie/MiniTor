#!/bin/bash

HOST=$1

cd /home/mininet/tor/$HOST/etc/tor/
echo DataDirectory /home/mininet/tor/$HOST/bin >> torrc

cd /home/mininet/tor/$HOST/bin
./tor
