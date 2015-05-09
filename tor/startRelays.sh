#!/bin/bash

for i in `seq 2 9` ; do
    curl http://localhost:8888/startTor/h0$i
done

for i in `seq 10 50` ; do
    curl http://localhost:8888/startTor/h$i
done
