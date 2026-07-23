#!/usr/bin/env bash
# shellcheck disable=SC1091

# Inspired by https://gist.github.com/Tras2/cba88201b17d765ec065ccbedfb16d9a

# @describe A bash script to update a Cloudflare DNS A record with the external IP of the source machine.
# Needs the DNS record pre-created on Cloudflare
# @meta version 0.0.1
# @meta require-tools curl
# @meta require-tools grep
# @meta require-tools host
# @meta require-tools jq
# @flag -f --force Force update.
# @option -k --api-token! $CF_DNS_API_TOKEN API token.
# @arg dns-record! DNS record to update.

set -euo pipefail

_this_dir="$(cd -P "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" >/dev/null 2>&1 && pwd)"

# shellcheck source=utils.mod/io.sh
source "$_this_dir/utils.mod/io.sh"

_entry() {
  local force cf_api_token dns_record
  force=${argc_force:-0}
  # shellcheck disable=SC2154
  cf_api_token=${argc_api_token}
  # shellcheck disable=SC2154
  dns_record=$argc_dns_record

  # FIXME: delete
  # zone="$(echo "$dns_record" | sed 's/^[^.]*\.//')"
  zone="${dns_record#*.}"

  cf_base_url="https://api.cloudflare.com/client/v4"

  # Get the current external IP address
  current_ext_ip=$(curl -s -X GET https://checkip.amazonaws.com)
  Mbs:Io:print "Current IP is $current_ext_ip"

  if [ "$force" != "1" ]; then
    if host "$dns_record" 1.1.1.1 | grep "has address" | grep "$current_ext_ip"; then
      Mbs:Io:print "$dns_record is currently set to $current_ext_ip; no changes needed"
      exit 0
    fi
  else
    Mbs:Io:print "Force mode enabled, updating DNS record"
  fi

  # if here, the dns record needs updating
  Mbs:Io:print "Updating zone $zone, DNS record $dns_record"

  # get the zone id for the requested zone
  zone_id=$(curl -f -s -X GET "${cf_base_url}/zones?name=$zone&status=active" \
    -H "Authorization: Bearer $cf_api_token" \
    -H "Content-Type: application/json" | jq -r '{"result"}[] | .[0] | .id')
  Mbs:Io:print "Zone id for $zone is $zone_id"

  # get the dns record id
  dns_record_id=$(curl -f -s -X GET "${cf_base_url}/zones/$zone_id/dns_records?type=A&name=$dns_record" \
    -H "Authorization: Bearer $cf_api_token" \
    -H "Content-Type: application/json" | jq -r '{"result"}[] | .[0] | .id')
  Mbs:Io:print "DNS record id for $dns_record is $dns_record_id"

  # update the record
  curl -f -s -X PUT "${cf_base_url}/zones/$zone_id/dns_records/$dns_record_id" \
    -H "Authorization: Bearer $cf_api_token" \
    -H "Content-Type: application/json" \
    --data "{\"type\":\"A\",\"name\":\"$dns_record\",\"content\":\"$current_ext_ip\",\"ttl\":1,\"proxied\":false}" | jq
  Mbs:Io:print "DNS record updated"
}

eval "$(argc --argc-eval "$0" "$@")"

_entry
