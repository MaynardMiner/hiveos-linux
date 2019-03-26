#!/usr/bin/env bash

function miner_ver() {
	local MINER_VER=$TREX_VER
	[[ -z $MINER_VER ]] && MINER_VER=$MINER_LATEST_VER
	echo $MINER_VER
}

function miner_config_echo() {
        local MINER_VER=`miner_ver`
        miner_echo_config_file "$MINER_DIR/$MINER_VER/config.json"
}

function miner_config_gen() {
	local MINER_CONFIG="$MINER_DIR/$MINER_VER/config.json"
	local TREX_GLOBAL_CONFIG="$MINER_DIR/$MINER_VER/config_global.json"
	mkfile_from_symlink $MINER_CONFIG

	#[[ -z $TREX_ALGO ]] && echo -e "${YELLOW}TREX_ALGO is empty${NOCOLOR}" && return 1
	[[ -z $TREX_TEMPLATE ]] && echo -e "${YELLOW}TREX_TEMPLATE is empty${NOCOLOR}" && return 1
	[[ -z $TREX_URL ]] && echo -e "${YELLOW}TREX_URL is empty${NOCOLOR}" && return 1
	[[ -z $TREX_PASS ]] && TREX_PASS="x"

	pools='[]'
	local line=""
	local url=""
	for line in $TREX_URL; do
	    local url=`head -n 1 <<< "$line"`
	    grep -q "://" <<< $url
	    [[ $? -ne 0 ]] && url="stratum+tcp://${url}"

	    pool=$(cat <<EOF
		{"user": "$TREX_TEMPLATE", "url": "$url", "pass": "$TREX_PASS" }
EOF
)

		pools=`jq --null-input --argjson pools "$pools" --argjson pool "$pool" '$pools + [$pool]'`
	done

	conf=`jq --argfile f1 $TREX_GLOBAL_CONFIG --argjson f2 "$pools" --arg algo "$TREX_ALGO" -n '$f1 | .pools = $f2 | .algo = $algo'`

	# User defined configuration
	if [[ ! -z $TREX_USER_CONFIG ]]; then
		while read -r line; do
			[[ -z $line ]] && continue
			conf=`jq --null-input --argjson conf "$conf" --argjson line "{$line}" '$conf + $line'`
		done <<< "$TREX_USER_CONFIG"
	fi

	notes=`echo Generated at $(date)`
	conf=`jq --null-input --argjson conf "$conf" --arg notes "$notes" -n '$conf | ._notes = $notes'`
	echo "$conf" > $MINER_CONFIG
}

