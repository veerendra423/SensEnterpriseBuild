#!/bin/bash
  
# This script runs algorithm 20 times.

i="0"

echo "---------------------" >> 20runs.log
while [ $i -lt 20 ]
do
#	pushd algorithmowner
	docker-compose run algorithm
#	popd
	i=$[$i+1]
	echo "Algorithm Run $i done" >> 20runs.log
done


