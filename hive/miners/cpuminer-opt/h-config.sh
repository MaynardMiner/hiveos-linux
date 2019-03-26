#!/usr/bin/env bash

function miner_ver() {
	local MINER_VER=$CPUMINER_OPT_VER
	[[ -z $MINER_VER ]] && MINER_VER=$MINER_LATEST_VER
	echo $MINER_VER
}


function miner_config_echo() {
	local MINER_VER=`miner_ver`
	miner_echo_config_file "$MINER_DIR/$MINER_VER/cpuminer.conf"
}


function miner_config_gen() {
	local MINER_CONFIG="$MINER_DIR/$MINER_VER/cpuminer.conf"
	mkfile_from_symlink $MINER_CONFIG

	conf=`cat $MINER_DIR/$MINER_VER/config_global.json | envsubst`

	[[ ! -z $CPUMINER_OPT_TEMPLATE ]] &&
		conf=`jq --null-input --argjson conf "$conf" --arg user "$CPUMINER_OPT_TEMPLATE" '$conf + {$user}'`

	[[ ! -z $CPUMINER_OPT_ALGO ]] &&
		conf=`jq --null-input --argjson conf "$conf" --arg algo "$CPUMINER_OPT_ALGO" '$conf + {$algo}'`

	[[ ! -z $CPUMINER_OPT_URL ]] &&
		conf=`jq --null-input --argjson conf "$conf" --arg url "$CPUMINER_OPT_URL" '$conf + {$url}'`

	[[ ! -z $CPUMINER_OPT_PASS ]] &&
		conf=`jq --null-input --argjson conf "$conf" --arg pass "$CPUMINER_OPT_PASS" '$conf + {$pass}'`

	#merge user config options into main config
	if [[ ! -z $CPUMINER_OPT_USER_CONFIG ]]; then
		while read -r line; do
			[[ -z $line ]] && continue
			conf=$(jq -s '.[0] * .[1]' <<< "$conf {$line}")
		done <<< "$CPUMINER_OPT_USER_CONFIG"
	fi

	echo $conf | jq . > $MINER_CONFIG
}
