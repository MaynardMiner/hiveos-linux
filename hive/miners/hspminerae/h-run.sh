#!/usr/bin/env bash

[[ `ps aux | grep "./HSPMinerAE" | grep -v grep | wc -l` != 0 ]] &&
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

cd $MINER_DIR/$MINER_VER

./HSPMinerAE `cat hspminerae.conf` 2>&1
