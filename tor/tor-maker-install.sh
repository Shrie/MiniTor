#!/bin/bash
# Code to prep tor-maker

cd /home/mininet/tor/tor-maker/
make all -C "/home/mininet/tor/tor-maker/"
make install -C "/home/mininet/tor/tor-maker/"
