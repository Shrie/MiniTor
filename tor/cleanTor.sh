#!/bin/bash
# This script will remove all previous instance data of Tor for 3 directories, 9 nodes, 1 client and 1 server

echo "Directories"
for i in `seq 1 3`; do
	cd /home/mininet/tor/directory$i/bin
	rm -rvf cached-certs cached-consensus cached-descriptors cached-descriptors.new cached-extrainfo cached-extrainfo.new cached-microdesc-consensus cached-microdescs.new lock router-stability state v3-status-votes 
done

echo "Nodes"
for i in `seq 1 9`; do
	cd /home/mininet/tor/node$i/bin
	rm -rvf cached-certs cached-consensus cached-descriptors cached-descriptors.new cached-extrainfo cached-extrainfo.new cached-microdesc-consensus cached-microdescs.new fingerprint keys/ lock router-stability state v3-status-votes 
done

echo "Client"
cd /home/mininet/tor/client/bin
	rm -rvf cached-certs cached-consensus cached-descriptors cached-descriptors.new cached-extrainfo cached-extrainfo.new cached-microdesc-consensus cached-microdescs.new fingerprint keys/ lock router-stability state v3-status-votes NUL

echo "Server"
cd /home/mininet/tor/server/bin
	rm -rvf cached-certs cached-consensus cached-descriptors cached-descriptors.new cached-extrainfo cached-extrainfo.new cached-microdesc-consensus cached-microdescs.new fingerprint keys/ lock router-stability state v3-status-votes NUL
