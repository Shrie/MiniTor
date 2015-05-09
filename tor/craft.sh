#!/bin/bash
    for i in `seq 0 9` ; do
        curl http://localhost:8888/torconfig/h0$i/d
    done

    curl http://localhost:8888/dirsync

    for i in `seq 10 50` ; do
    	curl http://localhost:8888/torconfig/h$i/r
    done
