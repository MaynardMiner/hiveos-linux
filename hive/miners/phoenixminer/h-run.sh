#!/usr/bin/env bash

[[ `ps aux | grep "./PhoenixMiner" | grep -v grep | wc -l` != 0 ]] &&
	echo -e "${RED}$MINER_NAME miner is already running${NOCOLOR}" &&
	exit 1

#try to release TIME_WAIT sockets
while true; do
	for con in `netstat -anp | grep TIME_WAIT | grep $MINER_API_PORT | awk '{print $5}'`; do
		killcx $con lo
	done
	netstat -anp | grep TIME_WAIT | grep $MINER_API_PORT &&
		continue ||
		break
done

export GPU_MAX_HEAP_SIZE=100
export GPU_MAX_ALLOC_PERCENT=100
export GPU_USE_SYNC_OBJECTS=1

cd $MINER_DIR/$MINER_VER

./PhoenixMiner
