#!/bin/bash

source ../vars.sh
source ../scripts/utils.sh

echo "stamp,usernum,groupnum,event,status"

group_size=$((NUM_APPS / NUM_GROUPS))

for ((group = 0 ; group < $NUM_GROUPS ; group++)); do
  for ((count = 0; count < $group_size; count++)); do
    ./../scripts/user.sh $count $group &
  done
done

>&2 wlog "user factory closing"
wait
>&2 wlog "user factory done waiting"
