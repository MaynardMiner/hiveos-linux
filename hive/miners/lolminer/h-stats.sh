#!/usr/bin/env bash


stats_raw=`curl --connect-timeout 2 --max-time ${API_TIMEOUT} --silent --noproxy '*' http://127.0.0.1:${MINER_API_PORT}/summary`
if [[ $? -ne 0 || -z $stats_raw ]]; then
	echo -e "${YELLOW}Failed to read $miner from localhost:${MINER_API_PORT}${NOCOLOR}"
else
	khs=`echo $stats_raw | jq -r '.Session.Performance_Summary' | awk '{ print $1/1000 }'`
	local fan=$(jq -c "[.fan$amd_indexes_array]" <<< $gpu_stats)
	local temp=$(jq -c "[.temp$amd_indexes_array]" <<< $gpu_stats)
	local ver=`echo $stats_raw | jq -c -r ".Software" | sed 's/lolMiner //'`
	local bus_numbers=$(echo $stats_raw | jq -r ".GPUs[].PCIE_Address" | cut -f 1 -d ':' | jq -sc .)
	local algo=""
	case "$(echo $stats_raw | jq -r '.Mining.Coin')" in
		BEAM)
			algo="equihash 150/5"
			;;
		default)
			algo=$(echo $stats_raw | jq -r '.Mining.Algorithm')
			;;
	esac
	stats=$(jq 	--argjson temp "$temp" \
			--argjson fan "$fan" \
			--arg ver "$ver" \
			--argjson bus_numbers "$bus_numbers" \
			--arg algo "$algo" \
			'{hs: [.GPUs[].Performance], hs_units: "hs", $temp, $fan, uptime: .Session.Uptime, ar: [.Session.Accepted, .Session.Submitted - .Session.Accepted ], $bus_numbers, algo: $algo, ver: $ver}' <<< "$stats_raw")
fi

[[ -z $khs ]] && khs=0
[[ -z $stats ]] && stats="null"

