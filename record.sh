#!/bin/bash

# var
: "${ZONE_ID:?Environment variable ZONE_ID is required}"
: "${DNS_RECORD_ID:?Environment variable DNS_RECORD_ID is required}"
: "${CLOUDFLARE_API_TOKEN:?Environment variable CLOUDFLARE_API_TOKEN is required}"
POLL_INTERVAL="${POLL_INTERVAL:-60}"
addr=""

# set global IP
while true
do
    # get global IP
    addr_now=$(curl -s --max-time 10 https://checkip.amazonaws.com)

    if [ $? -ne 0 ] || [ -z "$addr_now" ]; then
        echo "Failed to retrieve public IP. Retrying in ${POLL_INTERVAL}s..." >&2
        sleep "$POLL_INTERVAL"
        continue
    fi

    # IP update
    if [ "$addr" != "$addr_now" ]; then
        addr="$addr_now"
        response=$(curl -s -w "\n%{http_code}" \
             https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$DNS_RECORD_ID \
             -X PUT \
             -H 'Content-Type: application/json' \
             -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
             -d "{
                       \"name\": \"yourdomain\",
                       \"ttl\": 3600,
                       \"type\": \"A\",
                       \"comment\": \"Domain verification record\",
                       \"content\": \"$addr\",
                       \"proxied\": true
             }")
        http_code=$(echo "$response" | tail -n1)
        if [ "$http_code" != "200" ]; then
            echo "DNS update failed (HTTP $http_code). Retrying in ${POLL_INTERVAL}s..." >&2
            addr=""
        else
            echo "DNS record updated to $addr"
        fi
    fi

    sleep "$POLL_INTERVAL"
done
