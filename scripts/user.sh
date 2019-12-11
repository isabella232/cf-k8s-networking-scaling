#!/bin/bash

source ../vars.sh
source ../scripts/utils.sh

echo "$(udate),$1,STARTED,"
TARGET_URL=httpbin-$1-g0.example.com

if [ $NAMESPACES -eq 1 ]; then namespace=ns-0; else namespace=default; fi

kubetpl render ../yaml/gateway.yaml ../yaml/virtualservice.yaml -s NAME=httpbin-$1-g0 -s NAMESPACE=$namespace | kubectl apply -f -

until [ $(curl -s -o /dev/null -w "%{http_code}" -HHost:$TARGET_URL http://$INGRESS_HOST:$INGRESS_PORT/status/200) -eq 200 ]; do true; done

echo "$(udate),$1,SUCCESS,"
>&2 wlog "SUCCESS $1"

lastfail=$(udate)
secondsToWait=120
for ((i=$secondsToWait; i>0; i--)); do
  sleep 1 &
  status=$(curl -s -o /dev/null -w "%{http_code}" -HHost:$TARGET_URL http://$INGRESS_HOST:$INGRESS_PORT/status/200)
  if [ $status -ne 200 ]; then
    lastfail=$(udate)
    echo "$(udate),$1,FAILURE,$status"
  fi
  wait
done

echo "$lastfail,$1,COMPLETED,"
>&2 wlog "Completed $1"

