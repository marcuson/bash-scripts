#!/usr/bin/env bash

# Inspired by https://gist.github.com/Tras2/cba88201b17d765ec065ccbedfb16d9a

# A bash script to update a Cloudflare DNS A record with the external IP of the source machine
# Needs the DNS record pre-creating on Cloudflare

set -e

fsource=${BASH_SOURCE[0]}
while [ -L "$fsource" ]; do # resolve $SOURCE until the file is no longer a symlink
  fdir=$( cd -P "$( dirname "$fsource" )" >/dev/null 2>&1 && pwd )
  fdir=$(readlink "$fsource")
  [[ $fsource != /* ]] && fsource=$fdir/$fsource # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the syml>
done
scriptDir=$( cd -P "$( dirname "$fsource" )" >/dev/null 2>&1 && pwd )

OPTSTRING=":k:f"

while getopts ${OPTSTRING} opt; do
  case ${opt} in
    f)
      force="true"
      ;;
    k)
      cfApiToken="${OPTARG}"
      ;;
    ?)
      >&2 echo "Invalid option: -$OPTARG"
      exit 1
      ;;
    :)
      >&2 echo "Option -$OPTARG requires an argument."
      exit 1
      ;;
  esac
done

shift $((OPTIND-1))

force=${force:-false}
cfApiToken=${cfApiToken:-$CF_DNS_API_TOKEN}

if [ -z "$cfApiToken" ]; then
  >&2 echo "Missing Cloudflare API token."
  exit 1
fi

dnsRecord=$1
zone="$(echo "$dnsRecord" | sed 's/^[^.]*\.//')"

cfBaseUrl="https://api.cloudflare.com/client/v4"

echo "--- cloudflare-ddns-update (start) ---"

# Get the current external IP address
ip=$(curl -s -X GET https://checkip.amazonaws.com)
echo "Current IP is $ip"

if [ "$force" != "true" ]; then
  if host $dnsRecord 1.1.1.1 | grep "has address" | grep "$ip"; then
    echo "$dnsRecord is currently set to $ip; no changes needed"
    exit 0
  fi
else
  echo "Force mode enabled, updating DNS record"
fi

# if here, the dns record needs updating
echo "Updating zone $zone, DNS record $dnsRecord"

# get the zone id for the requested zone
zoneId=$(curl -f -s -X GET "${cfBaseUrl}/zones?name=$zone&status=active" \
  -H "Authorization: Bearer $cfApiToken" \
  -H "Content-Type: application/json" | jq -r '{"result"}[] | .[0] | .id')
echo "Zone id for $zone is $zoneId"

# get the dns record id
dnsRecordId=$(curl -f -s -X GET "${cfBaseUrl}/zones/$zoneId/dns_records?type=A&name=$dnsRecord" \
  -H "Authorization: Bearer $cfApiToken" \
  -H "Content-Type: application/json" | jq -r '{"result"}[] | .[0] | .id')
echo "DNS record id for $dnsRecord is $dnsRecordId"

# update the record
curl -f -s -X PUT "${cfBaseUrl}/zones/$zoneId/dns_records/$dnsRecordId" \
  -H "Authorization: Bearer $cfApiToken" \
  -H "Content-Type: application/json" \
  --data "{\"type\":\"A\",\"name\":\"$dnsRecord\",\"content\":\"$ip\",\"ttl\":1,\"proxied\":false}" | jq
echo "DNS record updated"

echo "--- cloudflare-ddns-update (done) ---"
set +e