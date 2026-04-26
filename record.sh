!/bin/bash

# var
ZONE_ID="XXX"
DNS_RECORD_ID="XXX"
CLOUDFLARE_API_TOKEN="XXX"
addr=""

# set global IP
while true
do
    # get global IP
    addr_now=$(curl -s https://checkip.amazonaws.com)

    # IP update
    if [ "$addr" != "$addr_now" ]; then
        export addr=$addr_now
        curl https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$DNS_RECORD_ID \
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
             }"
    fi
    sleep 1

done