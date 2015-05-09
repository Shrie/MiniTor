#!/bin/bash

for i in `seq 1 10` ; do
    ./torsocks nc -z 10.0.0.53 8000
done
