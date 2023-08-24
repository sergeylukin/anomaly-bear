#!/bin/bash

TIMERANGE=5 # in seconds, 5 is optimal for quick tests

function do_work(){
    CHARTDIR=./charts
    if [ ! -d "$CHARTDIR" ]; then
      mkdir -p $CHARTDIR
    fi
    CHARTFILE=$CHARTDIR/$TIMERANGE.json
    if [ ! -f $CHARTFILE ]; then
      echo "{ \"data\": [] }" > $CHARTFILE
    fi

  for timestamp in $(ls -ABtl1 ./hits | head -n $TIMERANGE); do
    DIR="./hits/${timestamp}"
    round="seconds"
    timestamp_step=$timestep
    if [[ $TIMERANGE -gt 6400 ]]; then
      round="minutes"
      timestamp_step=$(TZ=GMT date -j -f "%Y-%m-%dT%H:%M:%S%z" "${timestamp%.*}+0000" +%Y-%m-%dT%H:%M:00.000%z    )
    elif [[ $TIMERANGE -gt 14400 ]]; then
      round="hours"
      timestamp_step=$(TZ=GMT date -j -f "%Y-%m-%dT%H:%M:%S%z" "${timestamp%.*}+0000" +%Y-%m-%dT%H:00:00.000%z    )
    fi
    find "${DIR}" -type f -print0 |  while IFS= read -r -d $'\0' file; do
      row=$(cat $file)
      _jq() {
        echo "${row}" | jq -r "${1}"
      }
      id=$(_jq '._id')
      geoIp=$(_jq '.Geo_Ip')
      botName=$(_jq '.Bot_Name')
      botId="${botName}-${geoIp}"
        count=$(jq --arg botId "$botId" 'try (.data[] | select (.bot == $botId).count) // -1' $CHARTFILE)
        if [[ "$count" -eq "-1" ]]; then
          echo $(jq '.data += [{"timestamp": "'$timestamp_step'", "bot": "'$botId'", "count": 1}]' $CHARTFILE) > $CHARTFILE
        else
          echo $(jq --arg botId "$botId" '(.data[] | select (.bot == $botId)).count += 1' $CHARTFILE) > $CHARTFILE
        fi

    done
  done;
}

do_work
