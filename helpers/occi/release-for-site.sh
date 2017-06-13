#!/bin/bash

#
#
#

if [ -n "$DEBUG" -a "$DEBUG" = 1 ]; then
  set -x
fi

set -o pipefail

if [ -z "$1" ]; then
  printf "You have to provide a site name!\n" >&2
  exit 1
fi

if [ -z "$2" ]; then
  printf "You have to provide network ID!\n" >&2
  exit 3
fi

BASE_DIR="$(readlink -m $(dirname $0))/../../"
PROXY_PATH="$(voms-proxy-info -path)"
ENDPOINT=`$BASE_DIR/helpers/appdb/get-endpoint-for-site.sh $1`
if [ "$?" -ne 0 ]; then
  printf "Couldn't get an endpoint for $1!\n" >&2
  exit 4
fi

LINK_TARGET=$(occi --auth x509 --user-cred "$PROXY_PATH" --voms \
                   --endpoint "$ENDPOINT" \
                   --action describe --resource "$2" \
                   --output-format json_extended | jq -r .[0].target)

LINK_TARGET_KIND=$(occi --auth x509 --user-cred "$PROXY_PATH" --voms \
                   --endpoint "$ENDPOINT" \
                   --action describe --resource "$LINK_TARGET" \
                   --output-format json_extended | jq -r .[0].kind)


occi --auth x509 --user-cred "$PROXY_PATH" --voms \
     --endpoint "$ENDPOINT" \
     --action delete --resource "$2"

if [ "$LINK_TARGET_KIND" == "http://schemas.ogf.org/occi/infrastructure#ipreservation" ]; then
  occi --auth x509 --user-cred "$PROXY_PATH" --voms \
       --endpoint "$ENDPOINT" \
       --action delete --resource "$LINK_TARGET"
fi
