upgrade_ntp_timezone_metadata() {
  local ntp_query
  local ntp_payload
  local timezone_query
  local timezone_payload
  local upgrade_file
  # jq -r '.["b8:59:9f:fe:49:f1"]["user-data"]["ntp"]' ntp.json
  for k in $(jq -r 'to_entries[] | "\(.key)"' data.json)
  do
    # if it is not the global key, it is one of the host records we need to manipulate
    if ! [[ "$k" == "Global" ]]; then
      # shellcheck disable=SC2089
      ntp_query=".[\"$k\"][\"user-data\"][\"ntp\"]"
      # shellcheck disable=SC2090
      ntp_payload="$(jq $ntp_query data.json)"

      # shellcheck disable=SC2089
      timezone_query=".[\"$k\"][\"user-data\"][\"timezone\"]"
      # shellcheck disable=SC2090
      timezone_payload="$(jq $timezone_query data.json)"

      # save the payload to a unique file
      upgrade_file="upgrade-metadata-${k//:}.json"
      cat <<EOF>"$upgrade_file"
{
  "user-data": {
    "ntp": $ntp_payload,
    "timezone": $timezone_payload
  }
}
EOF
    fi
  done
}

upgrade_ntp_timezone_metadata
