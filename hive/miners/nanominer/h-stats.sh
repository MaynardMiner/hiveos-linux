#!/usr/bin/env bash

get_cores_hs(){
  local i=0
  local l_khs=$1
  local l_num_cores=$2
  local l_hs=()
  for (( i=0; i < ${l_num_cores}; i++ )); do
    l_hs+=`echo $l_khs | awk '{ printf($1/'$l_num_cores') }'`" "
  done
  echo $l_hs
}

get_cpu_temps(){
  local i=0
  local tcore=
  local l_num_cores=$1
  local l_temp
  local coretemp0=`cat /sys/devices/platform/coretemp.0/hwmon/hwmon*/temp*_input 2>/dev/null`
  [[ ! -z $coretemp0 ]] && #may not work with AMD cpous
    tcore=$((`cat /sys/devices/platform/coretemp.0/hwmon/hwmon*/temp*_input | head -n 1`/1000)) ||
    tcore=`cat /sys/class/hwmon/hwmon0/temp*_input | head -n 1 | awk '{print $1/1000}'` #maybe we will need to detect AMD cores

  if [[ ! -z tcore ]]; then
    for (( i=0; i < ${l_num_cores}; i++ )); do
      l_temp+="$tcore "
    done
    echo $l_temp
  fi
}


local temp=()
local fan=()
local tfcounter=0
local hs=
local algo=
local ac=0
local rj=0
local ver=
local uptime=0
local t_hs=0
local bus_id=
local bus_ids=()
local t_khs=0
local algo_count=0
local gpu_count=0
local nom=0
local num_cores=0

stats_raw=`curl --connect-timeout 2 --max-time ${API_TIMEOUT} --silent --noproxy '*' http://127.0.0.1:${MINER_API_PORT}/stats`
if [[ $? -ne 0  || -z $stats_raw ]]; then
  echo -e "${YELLOW}Failed to read $miner stats_raw from localhost:${MINER_API_PORT}${NOCOLOR}"
else
  stats={}
  algo_count=`echo $stats_raw | jq '."Algorithms"[] | length'`
   for (( n = 1; n <= $algo_count; n++ )); do
     [[ n -eq 1 ]] && nom='' || nom=$n

     temp=()
     fan=()
     tfcounter=0
     hs=''
     algo=
     ac=0
     rj=0
     ver=
     uptime=0
     t_hs=0
     bus_ids=()
     t_khs=0
     num_cores=0

     algo=`echo $stats_raw | jq -r '."Algorithms"[] | keys' | jq .[$n-1]`

     t_khs=`echo $stats_raw | jq -rc '."Algorithms"[].'$algo'."Total"."Hashrate"'`
     t_khs=`printf "%.0f\n" $t_khs | awk '{print $1/1000}'`
     eval "khs$nom=\$t_khs"
     if [[ ${algo,,} == "\"randomhash\"" ]]; then
       [[ $uptime -lt 60 ]] && head -n 50 $MINER_LOG_BASENAME.log > ${MINER_LOG_BASENAME}_head.log
       num_cores=`cat ${MINER_LOG_BASENAME}_head.log | grep "<info> Using CPU threads:" | awk '{print $7}'`
       hs=`get_cores_hs "$t_khs" "$num_cores"`
       temp=`get_cpu_temps "$num_cores"`
     else
       gpu_count=`echo $stats_raw | jq -r '."Algorithms"[].'$algo' | length'`
       let "gpu_count = gpu_count - 3"
       #loop by GPUs
       for (( j = 0; j < $gpu_count; j++ )); do
         #gpu element name = echo $stats_raw | jq -rc '."Algorithms"[].'$algo' | keys' | jq .[1]
         t_hs=`echo $stats_raw | jq -rc '."Algorithms"[].'$algo'."GPU '$j'"."Hashrate"'`
         t_hs=`printf "%.0f\n" $t_hs`
         hs+=$t_hs" "
         fan+=`echo $stats_raw | jq -rc '."Devices"[]."GPU '$j'"."Fan"'`" "
         temp+=`echo $stats_raw | jq -rc '."Devices"[]."GPU '$j'"."Temperature"'`" "
         bus_ids+=`echo $stats_raw | jq -rc '."Devices"[]."GPU '$j'"."Pci"' | awk '{printf("%d\n", "0x"$1)}'`" "
       done
     fi

     hs=`echo ${hs[@]} | tr " " "\n" | jq -cs '.'`
     fan=`echo ${fan[@]} | tr " " "\n" | jq -cs '.'`
     temp=`echo ${temp[@]} | tr " " "\n" | jq -cs '.'`
     bus_ids=`echo ${bus_ids[@]} | tr " " "\n" | jq -cs '.'`

     ac=`echo $stats_raw | jq -rc '."Algorithms"[].'$algo'."Total"."Accepted"'`
     rj=`echo $stats_raw | jq -rc '."Algorithms"[].'$algo'."Total"."Denied"'`

     uptime=`echo $stats_raw | jq -rc '."WorkTime"'`

     algo=${algo#\"}; algo=${algo%\"};      

     eval "t_stats=\$(jq -n \
     --arg uptime \"\$uptime\" --arg ver \`miner_ver\` \
     --arg total_khs$nom \"\$t_khs\" \
     --arg hs_units$nom \"hs\" \
     --argjson hs$nom \"\$hs\" --argjson temp$nom \"\$temp\" --argjson fan$nom \"\$fan\" \
     --arg ac \"\$ac\" --arg rj \"\$rj\" \
     --arg algo$nom \${algo,,} \
     '{\$total_khs$nom, \$hs$nom, \$hs_units$nom, \$temp$nom, \$fan$nom, \$uptime, \$algo$nom, ar$nom: [\$ac, \$rj], \$ver}')"

     stats=$(jq -s '.[0] * .[1]' <<< "$stats $t_stats")
   done
fi

[[ -z $khs ]] && khs=0
[[ -z $stats ]] && stats="null"


# {
#   "Algorithms": [
#     {
#       "Ethash": {
#         "CurrentPool": "eu-eth.hiveon.net:4444",
#         "GPU 0": {
#           "Accepted": 25,
#           "Denied": 0,
#           "Hashrate": "1.136852e+07"
#         },
#         "GPU 1": {
#           "Accepted": 23,
#           "Denied": 0,
#           "Hashrate": "1.139410e+07"
#         },
#         "ReconnectionCount": 3,
#         "Total": {
#           "Accepted": 48,
#           "Denied": 0,
#           "Hashrate": "2.276262e+07"
#         }
#       },
#       "RandomHash": {
#         "CPU": {
#           "Accepted": 29,
#           "Denied": 0,
#           "Hashrate": "1.967431e+02"
#         },
#         "CurrentPool": "pasc-eu2.nanopool.org:15556",
#         "ReconnectionCount": 0,
#         "Total": {
#           "Accepted": 29,
#           "Denied": 0,
#           "Hashrate": "1.967431e+02"
#         }
#       }
#     }
#   ],
#   "Devices": [
#     {
#       "CPU": {
#         "Name": "AMD Dual-Core Processor",
#         "Platform": "CPU"
#       },
#       "GPU 0": {
#         "Name": "GeForce GTX 1050 Ti",
#         "Platform": "CUDA",
#         "Pci": "01:00.0",
#         "Fan": 29,
#         "Temperature": 39
#       },
#       "GPU 1": {
#         "Name": "GeForce GTX 1050 Ti",
#         "Platform": "CUDA",
#         "Pci": "02:00.0",
#         "Fan": 29,
#         "Temperature": 45
#       }
#     }
#   ],
#   "WorkTime": 9078
# }
