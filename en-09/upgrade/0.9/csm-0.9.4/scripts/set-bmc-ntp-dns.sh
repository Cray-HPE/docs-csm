#!/bin/bash
# Copyright (C) 2021 Hewlett Packard Enterprise Development LP
# Sets static NTP, timezone, and DNS entries on a BMC *functionality is vendor-dependent
# Author: Jacob Salmela <jacob.salmela@hpe.com>
set -eo pipefail

# set_vars() sets some global variables used throughout the script
function set_vars() {
  if [[ -z ${USERNAME} ]] || [[ -z ${IPMI_PASSWORD} ]]; then
    echo "\$USERNAME \$IPMI_PASSWORD must be set"
    exit 1
  fi
  
  # Find my current directory
  mydir=$(dirname ${BASH_SOURCE[0]})
  # Set the path to our Python API-call helper script
  make_api_call_py=${mydir}/make_api_call.py
  
  if [[ -z $BMC ]]; then
    VENDOR="$(ipmitool fru | awk '/Board Mfg/ && !/Date/ {print $4}')"
  else
    VENDOR="$(ipmitool -I lanplus -U $USERNAME -E -H $BMC fru | awk '/Board Mfg/ && !/Date/ {print $4}')"
  fi
  # Export VENDOR variable for use by Python API helper script
  export VENDOR

  if [[ "$VENDOR" = *Marvell* ]] || [[ "$VENDOR" = HP* ]] || [[ "$VENDOR" = Hewlett* ]]; then
    manager=1
    interface=1
    # Time to wait before checking if the BMC is back after a reset
    secs=30
  elif [[ "$VENDOR" = *GIGA*BYTE* ]]; then
    manager=Self
    interface=bond0
    # GBs are slow and need more time to reset
    #FIXME: Do a real check here instead of a static sleep
    secs=360
  elif [[ "$VENDOR" = *Intel* ]]; then
    manager=BMC
    interface=3
    secs=30
    # Some ipmitool commands are used to gather info for use with SDPTool so the channel needs to be defined here
    # This channel can vary, but is often 1 for Intel machines
    channel=3
    # this is an internal-only container that runs SDPTool for Intel hardware
    sdptool="cray-sdptool:2.1.0"
    sdptool_repo="ssh://git@stash.us.cray.com:7999/~jsalmela/cray-sdptool.git"
  fi
}

usage() {
  # Generates a usage line
  # Any line starting with with a #/ will show up in the usage line
  grep '^#/' "$0" | cut -c4-
}

#/ Usage: set-bmc-ntp-dns.sh [-h] ilo|gb|intel [-N NTP_SERVERS]|[-D DNS_SERVERS] [-H BMC] [-options]
#/
#/    Sets static NTP and DNS servers on BMCs using data defined in cloud-init (or by providing manual overrides)
#/
#/    $USERNAME and $IPMI_PASSWORD must be set prior to running this script.
#/
#/
#/    options common to 'ilo', 'gb', and 'intel' commands:
#/
#/       [-A]               configure a BMC, running all the necessary tasks (fresh installs only)
#/       [-s]               shows the current configuration of NTP and DNS
#/       [-t]               show the current date/time for the BMC
#/       [-N NTP_SERVERS]   a comma-separated list of NTP servers (manual override when no 1.5 metadata exists)
#/       [-D DNS_SERVERS]   a comma-separated list of DNS servers (manual override when no 1.5 metadata exists)
#/       [-d]               sets static DNS servers using cloud-init data or overrides
#/       [-n]               sets static NTP servers using cloud-init data or overrides (see -S for iLO)
#/       [-r]               gracefully resets the BMC
#/       [-f]               forcefully resets the BMC
#/
#/    options specific to the the 'ilo' command:
#/       [-S]               disables DHCP so static entries can be set
#/       [-z]               show current timezone
#/       [-Z INDEX]         set a new timezone
#/
#/    options specific to the 'gb' command:
#/       [-]                yet to be developed
#/
#/    options specific to the 'intel' command:
#/       [-d IP]            IP of the BMC to configure with static DNS
#/                          *this uses SDPTool, which normally runs from the PIT
#/                          as it is not included in the image(s)
#/
#/    EXAMPLES:
#/
#/       Upgrading 1.4 to 1.5 passing in NTP and DNS entries that do not exist in 1.4 metadata:
#/           set-bmc-ntp-dns.sh ilo -s
#/           set-bmc-ntp-dns.sh ilo -S #(iLO only)
#/           set-bmc-ntp-dns.sh ilo -N time-hmn,time.nist.gov -n
#/           set-bmc-ntp-dns.sh ilo -D 10.92.100.225,172.30.48.1 -d
#/           set-bmc-ntp-dns.sh -r
#/
#/       Fresh install of 1.5 with new metadata already in place:
#/           set-bmc-ntp-dns.sh ilo -A
#/                     or
#/           set-bmc-ntp-dns.sh ilo -s
#/           set-bmc-ntp-dns.sh ilo -S #(iLO only)
#/           set-bmc-ntp-dns.sh ilo -n
#/           set-bmc-ntp-dns.sh ilo -d
#/           set-bmc-ntp-dns.sh -r
#/
#/       Disabling DHCP (iLO only):
#/           set-bmc-ntp-dns.sh ilo -S
#/
#/       Setting just NTP servers (for iLO, DHCP must have been previously disabled):
#/           set-bmc-ntp-dns.sh gb -n
#/
#/       Setting just DNS servers (for iLO, DHCP must have been previously disabled):
#/           set-bmc-ntp-dns.sh gb -d
#/
#/       Setting just DNS servers (on Intel, where you need to pass an IP):
#/           set-bmc-ntp-dns.sh gb -d 10.254.1.12
#/
#/       Gracefully resetting the BMC:
#/           set-bmc-ntp-dns.sh ilo -r
#/
#/       Checking the datetime on all NCN BMCs:
#/          for i in ncn-m00{2..3} ncn-{w,s}00{1..3}; do echo "------$i--------"; ssh $i 'export USERNAME=root; export IPMI_PASSWORD=password; /set-bmc-ntp-dns.sh gb -t'; done
#/
#/       Check the current timezone on an NCN BMC (iLO only):
#/          set-bmc-ntp-dns.sh ilo -z
#/
#/       Set the timezone on an NCN BMC (iLO only):
#/          curl https://$HOSTNAME-mgmt/redfish/v1/Managers/1/DateTime --insecure -u $USERNAME:$IPMI_PASSWORD -L | jq .TimeZoneList
#/          # Pick a desired timezone index number
#/          set-bmc-ntp-dns.sh ilo -Z 7
#/

# pit_die() kills the script if it cannot run on the pit
function pit_die() {
  if [[ $BMC != $HOSTNAME-mgmt ]];then return 0 ; fi

  if [[ -f /var/www/ephemeral/configs/data.json ]] \
    || [[ $BMC == *pit* ]] \
    || [[ $BMC == ncn-m001* ]]; then
      echo "Cannot run this function on the PIT"
      exit 2
  fi
}

# make_api_call() uses Python requests to contact an API endpoint
function make_api_call() {

  pit_die

  local endpoint="$1"
  local method="$2"
  local payload="$3"
  local filter="$4"
  local url="https://${BMC}/${endpoint}"

  # Export variables for use by the make_api_call Python script
  export method
  export payload
  export url

  case "$method" in
    "GET")
        /usr/bin/python3 ${make_api_call_py} | jq ${filter}
        ;;
    "PATCH"|"POST")
        /usr/bin/python3 ${make_api_call_py}
        ;;
    *)
        echo "ERROR: make_api_call: Unrecognized method: $method"
        exit 1
        ;;
  esac
}

# show_current_bmc_datetime() shows the current datetime on the BMC
function show_current_bmc_datetime() {

  echo "Showing current datetime for $BMC..."

  if [[ "$VENDOR" = *Marvell* ]] || [[ "$VENDOR" = HP* ]] || [[ "$VENDOR" = Hewlett* ]] || [[ "$VENDOR" = *GIGA*BYTE* ]] ; then

    make_api_call "redfish/v1/Managers/${manager}/DateTime" \
      "GET" null \
      ".DateTime"

  elif [[ "$VENDOR" = *Intel* ]]; then

    make_api_call "redfish/v1/Managers/${manager}/" \
      "GET" null \
      ".DateTime"

  fi
}

# show_current_bmc_datetime() shows the current datetime on the BMC
function show_current_bmc_timezone() {

  echo "Showing current timezone for $BMC..."

  if [[ "$VENDOR" = *Marvell* ]] || [[ "$VENDOR" = HP* ]] || [[ "$VENDOR" = Hewlett* ]] || [[ "$VENDOR" = *GIGA*BYTE* ]] ; then

        make_api_call "redfish/v1/Managers/${manager}/DateTime" \
      "GET" null \
      ".TimeZone.Name"

  fi
}

# set_bmc_timezone() manually sets the timezone on the BMC using an index number from .TimeZoneList
function set_bmc_timezone() {

  echo "Setting timezone for $BMC..."

  if [[ -z $TIMEZONE ]]; then

    echo "No timezone index provided."
    echo "View available indices at redfish/v1/Managers/${manager}/DateTime | jq .TimeZoneList"
    exit 1

  else

    make_api_call "redfish/v1/Managers/${manager}/DateTime" \
      "PATCH" \
      "{\"TimeZone\": {\"Index\": $TIMEZONE} }" null

    reset_bmc_manager

  fi
}

# show_current_ipmi_lan() shows lan print info from ipmitool
function show_current_ipmi_lan() {

  echo "Showing current ipmitool lan print $channel output for $BMC..."

  # Do not run on the PIT
  pit_die

  local ip_src="" && ip_src=$(ipmitool -I lanplus -U $USERNAME -E -H $BMC lan print $channel \
                              | grep -Ei 'IP Address Source\s+\:')

  local ipaddr="" && ipaddr=$(ipmitool -I lanplus -U $USERNAME -E -H $BMC lan print $channel \
                              | grep -Ei 'IP Address\s+\:')

  local netmask="" && netmask=$(ipmitool -I lanplus -U $USERNAME -E -H $BMC lan print $channel \
                                | grep -Ei 'Subnet Mask\s+\:')

  local defgw="" && defgw=$(ipmitool -I lanplus -U $USERNAME -E -H $BMC lan print $channel \
                            | grep -Ei 'Default Gateway IP\s+\:')

  echo "$ip_src"
  echo "$ipaddr"
  echo "$netmask"
  echo "$defgw"
}

# show_current_bmc_settings() shows the current iLO settings for DNS and NTP
function show_current_bmc_settings() {

  echo "Showing current BMC settings $BMC..."

  if [[ "$VENDOR" = *Marvell* ]] || [[ "$VENDOR" = HP* ]] || [[ "$VENDOR" = Hewlett* ]]; then
    echo ".StaticNTPServers:"
    make_api_call "redfish/v1/Managers/${manager}/DateTime" \
      "GET" null \
      ".StaticNTPServers"

    echo ".Oem.Hpe.IPv4.DNSServers:"
    make_api_call "redfish/v1/Managers/${manager}/ethernetinterfaces/${interface}" \
      "GET" null \
      ".Oem.Hpe.IPv4.DNSServers"

    echo ".Oem.Hpe.DHCPv4s:"
    make_api_call "redfish/v1/Managers/${manager}/ethernetinterfaces/${interface}" \
      "GET" null \
      ".Oem.Hpe.DHCPv4"

    echo ".Oem.Hpe.DHCPv6 status:"
    make_api_call "redfish/v1/Managers/${manager}/ethernetinterfaces/${interface}" \
      "GET" null \
      ".Oem.Hpe.DHCPv6"

    show_current_ipmi_lan

  elif [[ "$VENDOR" = *GIGA*BYTE* ]]; then

    echo ".NTP:"
    make_api_call "redfish/v1/Managers/${manager}/NetworkProtocol" \
      "GET" null \
      ".NTP"

    echo ".NameServers:"
    make_api_call "redfish/v1/Managers/${manager}/EthernetInterfaces/${interface}" \
      "GET" null \
      .NameServers

    echo ".DHCPv4.DHCPEnabled:"
    make_api_call "redfish/v1/Managers/${manager}/EthernetInterfaces/${interface}" \
      "GET" null \
      ".DHCPv4.DHCPEnabled"

    show_current_ipmi_lan

  elif [[ "$VENDOR" = *Intel* ]]; then

    echo ".NameServers:"
    make_api_call "redfish/v1/Managers/${manager}/EthernetInterfaces/${interface}" \
      "GET" null \
      .NameServers

    echo ".DHCPv4.DHCPEnabled:"
    make_api_call "redfish/v1/Managers/${manager}/EthernetInterfaces/${interface}" \
      "GET" null \
      ".DHCPv4.DHCPEnabled"

    show_current_ipmi_lan

  fi
}

# reset_bmc_manager() gracefully restarts the BMC and waits a bit for it to come back
function reset_bmc_manager() {
  echo "Reseting $BMC..."

  if [[ "$1" == all-force ]]; then

      reset_type='{"ResetType": "ForceRestart"}'

  else

    if [[ "$VENDOR" = *Marvell* ]] || [[ "$VENDOR" = HP* ]] || [[ "$VENDOR" = Hewlett* ]]; then

      reset_type='{"ResetType": "GracefulRestart"}'

    elif [[ "$VENDOR" = *GIGA*BYTE* ]] || [[ "$VENDOR" = *Intel* ]]; then

      # GB only have a force restart option
      reset_type='{"ResetType": "ForceRestart"}'

    fi

  fi

  make_api_call "redfish/v1/Managers/${manager}/Actions/Manager.Reset" \
      "POST" \
      "$reset_type" null

  while [ $secs -gt 0 ]; do

    echo -ne "$secs waiting a bit for the BMC to reset...\033[0K\r"
    sleep 1
    : $((secs--))

  done
  
  local total
  total=0
  while ! ping -c 2 $BMC > /dev/null 2>&1 && [ $total -lt 30 ]; do
    echo "Waiting another 5 seconds for the BMC to become pingable..."
    sleep 5
    let total+=5
  done
  if ! ping -c 2 $BMC > /dev/null 2>&1 ; then
    echo "WARNING: BMC $BMC still not pingable" 1>&2
  fi

  echo -e "\n"
}

# disable_ilo_dhcp() disables DHCP on the iLO because ipmitool cannot fully disable it. This requires a restart.
function disable_ilo_dhcp() {
  local method
  local payload
  local url
  export payload="null"
  export method="GET"

  echo "Disabling DHCP on $BMC..."

  if [[ "$VENDOR" = *Marvell* ]] || [[ "$VENDOR" = HP* ]] || [[ "$VENDOR" = Hewlett* ]]; then
    # Check if it is already disabled
    export url="https://${BMC}/redfish/v1/Managers/${manager}/ethernetinterfaces/${interface}"

    dhcpv4_dns_enabled=$(/usr/bin/python3 ${make_api_call_py} | jq .Oem.Hpe.DHCPv4.UseDNSServers)
    dhcpv4_ntp_enabled=$(/usr/bin/python3 ${make_api_call_py} | jq .Oem.Hpe.DHCPv4.UseNTPServers)
    dhcpv6_dns_enabled=$(/usr/bin/python3 ${make_api_call_py} | jq .Oem.Hpe.DHCPv6.UseDNSServers)
    dhcpv6_ntp_enabled=$(/usr/bin/python3 ${make_api_call_py} | jq .Oem.Hpe.DHCPv6.UseNTPServers)

    # Disable DHCPv4
    echo -e "Disabling DHCPv4 on iLO..."
    if [[ "${dhcpv4_dns_enabled}" == true ]] || [[ "${dhcpv4_ntp_enabled}" == true ]] ; then

      make_api_call "redfish/v1/Managers/${manager}/ethernetinterfaces/${interface}" \
        "PATCH" \
        "{\"DHCPv4\":{\"UseDNSServers\": false, \"UseNTPServers\": false}}" null

    elif [[ "${dhcpv4_dns_enabled}" == false ]] && [[ "${dhcpv4_ntp_enabled}" == false ]] ; then

      echo "Already disabled"

    fi

    # Disable DHCPv6
    echo -e "Disabling DHCPv6 on iLO..."
    if [[ "${dhcpv6_dns_enabled}" == true ]] || [[ "${dhcpv6_ntp_enabled}" == true ]] ; then

      make_api_call "redfish/v1/Managers/${manager}/ethernetinterfaces/${interface}" \
        "PATCH" \
        "{\"DHCPv6\":{\"UseDNSServers\": false, \"UseNTPServers\": false}}" null

    elif [[ "${dhcpv6_dns_enabled}" == false ]] && [[ "${dhcpv6_ntp_enabled}" == false ]] ; then

      echo "Already disabled"

    fi

    # if any values were true, we need to reset to apply the changes
    if [[ "${dhcpv6_dns_enabled}" == true ]] || [[ "${dhcpv6_ntp_enabled}" == true ]] || [[ "${dhcpv4_dns_enabled}" == true ]] || [[ "${dhcpv4_ntp_enabled}" == true ]]; then

      echo -e "\nThe BMC will gracefully restart to apply these changes."
      reset_bmc_manager

    fi

  elif [[ "$VENDOR" = *GIGA*BYTE* ]]; then

    #TODO: ipmitool can handle this but it would be good to implement it here as well
    echo "$VENDOR not yet developed."
    exit 1

  elif [[ "$VENDOR" = *Intel* ]]; then

    echo "$VENDOR not yet developed."
    exit 1

  fi
}

# get_ci_ntp_servers() gets NTP servers defined in cloud-init meta-data under the key 'ntp.servers'
function get_ci_ntp_servers() {

  pit_die

  if ! command -v yq &> /dev/null
  then
    echo "yq could not be found in $PATH"
    exit 1
  fi

  if ! [ -f /var/lib/cloud/instance/user-data.txt ]; then
    echo "ERROR: /var/lib/cloud/instance/user-data.txt not found"
    exit 1
  fi

  # get NTP servers from cloud-init
  echo "{\"StaticNTPServers\": $(cat /var/lib/cloud/instance/user-data.txt \
    | yq read - -j \
    | jq .ntp.servers \
    | tr '\n' ' ')}"
}

# set_bmc_ntp() configures the BMC with static NTP servers
function set_bmc_ntp() {
  echo "Setting static NTP servers on ${BMC}..."
  if [[ -n $NTP_SERVERS ]]; then
    local ntp_servers="$NTP_SERVERS"
    ntp_array=(${ntp_servers/,/ })

    # Each vendor has a different name for the key
    if [[ "$VENDOR" = *Marvell* ]] || [[ "$VENDOR" = HP* ]] || [[ "$VENDOR" = Hewlett* ]]; then

      ntp_key=$(echo "{\"StaticNTPServers\": [")
      ntp_close="]}"

    elif [[ "$VENDOR" = *GIGA*BYTE* ]] || [[ "$VENDOR" = *Intel* ]]; then

      echo "$VENDOR not yet developed."
      exit 1

    fi

    # Count how many entries are in the array
    cnt=${#ntp_array[@]}
    # If there is only one, echo the entry
    if [[ $cnt -eq 1 ]]; then
      ntp_json=$(echo "$ntp_key"
        echo "\"${ntp_array[0]}\""
        echo "$ntp_close")
    else
      # otherwise, loop through
      ntp_json=$(echo "$ntp_key"
      for ((i=0 ; i<cnt ; i++)); do
        if [[ i -eq 1 ]]; then
          # no comma for last element
          ntp_array[i]=\"${ntp_array[i]}\"
        else
          ntp_array[i]=\"${ntp_array[i]}\",
        fi
        # and echo each one so it prints as a JSON list
        echo "${ntp_array[i]}"
      done
      # close out the list
      echo "$ntp_close")
    fi
    ntp_servers=$ntp_json
  else
    # otherwise, get it from cloud-init
    local ntp_servers=""
    ntp_servers="$(get_ci_ntp_servers)"
  fi

  if [[ "$VENDOR" = *Marvell* ]] || [[ "$VENDOR" = HP* ]] || [[ "$VENDOR" = Hewlett* ]]; then
    # Static NTP servers cannot be set unless DHCP is completely disabled. See disable_ilo_dhcp()
    # if the user provided an override, use that
    # {"StaticNTPServers": ["<NTP server 1>", "<NTP server 2>"]}
    make_api_call "redfish/v1/Managers/${manager}/DateTime" \
      "PATCH" \
      "$ntp_servers" null

    # See if a change is needed
    configuration_settings=$(make_api_call "redfish/v1/Managers/1/DateTime" "GET" null ".ConfigurationSettings")

    if [[ "${configuration_settings}" == "\"SomePendingReset\"" ]]; then

      echo -e "The BMC will gracefully restart to apply these changes."
      reset_bmc_manager

    fi

  elif [[ "$VENDOR" = *GIGA*BYTE* ]]; then

    ntp_enabled=$(make_api_call "redfish/v1/Managers/${manager}/NetworkProtocol" "GET" null ".NTP.ProtocolEnabled")

    echo "Enabling NTP..."

    if [[ "$ntp_enabled" == false ]]; then

      echo "Use GbtUtility to enable NTP on $VENDOR"
      exit 1

    else

      echo "Already enabled."

    fi

    echo "Setting NTP servers.."

    make_api_call "redfish/v1/Managers/${manager}/NetworkProtocol" \
      "PATCH" \
      "$ntp_servers" null

  elif [[ "$VENDOR" = *Intel* ]]; then

    echo "$VENDOR not yet developed."
    exit 1

  fi
}

# get_ci_dns_servers gets DNS servers defined in cloud-init meta-data under the key 'dns-server'
function get_ci_dns_servers() {
  local dns=""

  # get DNS servers from cloud-init
  if [[ -f /var/www/ephemeral/configs/data.json ]] \
    || [[ $HOSTNAME == *pit ]]; then

    # if we are on the pit, pull from basecamp data
    dns_servers=$(jq '.Global."meta-data"."dns-server"' < /var/www/ephemeral/configs/data.json)

  elif [[ -f /run/cloud-init/instance-data.json ]]; then

    dns_servers=$(jq '.ds.meta_data.Global."dns-server"' < /run/cloud-init/instance-data.json)

  else

    # Sometimes the cloud-init files are not there
    cloud-init init
    dns_servers=$(jq '.ds.meta_data.Global."dns-server"' < /run/cloud-init/instance-data.json)

  fi

  # split DNS on space and put them into an array so we can craft the JSON payload
  local dnslist=(${dns_servers// / })

  if [[ "$VENDOR" = *Marvell* ]] || [[ "$VENDOR" = HP* ]] || [[ "$VENDOR" = Hewlett* ]]; then

    local dns="{\"Oem\" :{\"Hpe\": {\"IPv4\": {\"DNSServers\": [\"${dnslist[0]//'"'}\", \"${dnslist[1]//'"'}\"]} }}}"

  elif [[ "$VENDOR" = *GIGA*BYTE* ]]; then

    local dns="{\"NameServers\": [\"${dnslist[0]//'"'}\", \"${dnslist[1]//'"'}\"]}"

  elif [[ "$VENDOR" = *Intel* ]]; then

    local dns="${dnslist[0]//'"'} ${dnslist[1]//'"'}"

  fi

  echo "${dns}"
}

# set_bmc_dns() configures the BMC with static DNS servers on a per-interface basis
function set_bmc_dns() {
  echo -e "\nSetting ${BMC} static DNS servers..."

  # If manual overrides are detected,
  if [[ -n $DNS_SERVERS ]]; then

    local dns_servers="$DNS_SERVERS"

    if [[ "$VENDOR" = *Marvell* ]] || [[ "$VENDOR" = HP* ]] || [[ "$VENDOR" = Hewlett* ]]; then

      # {"Oem": {"Hpe": {"IPv4": {"DNSServers": ["<DNS server 1>", "<DNS server 2>"]} }}}
      dns_key=$(echo "{\"Oem\" :{\"Hpe\": {\"IPv4\": {\"DNSServers\": [")
      dns_close=$(echo "]}}}}")

    elif [[ "$VENDOR" = *GIGA*BYTE* ]]; then

      echo "Use GbtUtility for $VENDOR."
      exit 1

    fi
    # split them into an array as before with NTP, so we can access each element individually
    dns_array=(${dns_servers/,/ })
    dns_json=$(echo "$dns_key"
      cnt=${#dns_array[@]}
      if [[ $cnt -eq 1 ]]; then
        echo "\"${dns_array[0]}\""
      else
        for ((i=0 ; i<cnt ; i++)); do
          if [[ i -eq 1 ]]; then
            # no comma for last element
            dns_array[i]=\"${dns_array[i]}\"
          else
            dns_array[i]=\"${dns_array[i]}\",
          fi
          echo "${dns_array[i]}"
        done
      fi
      # close out the list
      echo "$dns_close"
    )
    dns_servers=$dns_json
  else
    # otherwise, get it from cloud-init
    local dns_servers=""
    dns_servers="$(get_ci_dns_servers)"
  fi

  if [[ "$VENDOR" = *Marvell* ]] || [[ "$VENDOR" = HP* ]] || [[ "$VENDOR" = Hewlett* ]]; then

    make_api_call "redfish/v1/Managers/${manager}/EthernetInterfaces/${interface}" \
      "PATCH" \
      "$dns_servers" null

    reset_bmc_manager

  # elif [[ "$VENDOR" = **GIGA*BYTE** ]]; then

    # Not possible? This is read-only
    # make_api_call "redfish/v1/Managers/${manager}/EthernetInterfaces/${interface}" \
    #   "PATCH" \
    #   "$dns_servers" null

  elif [[ "$VENDOR" = *Intel* ]]; then

    echo "Checking for SDPTool for use on $VENDOR..."

    if ! eval command -v SDPTool >/dev/null; then

      echo "SDPTool not available..."

      echo "Checking for containerized version..."

      if ! eval podman image ls | grep sdptool >/dev/null; then

        echo "SDPTool container needed for $VENDOR functionality"
        echo "    git clone $sdptool_repo"
        echo "    cd cray-sdptool && podman build -t $sdptool -f Dockerfile ."

        exit 1

      fi

    else

      echo "SDPTool not found. Cannot continue."
      exit 1

    fi

    local ipaddr="" && ipaddr=$(ipmitool -I lanplus -U $USERNAME -E -H $BMC lan print $channel \
                                | grep -Ei 'IP Address\s+\:' \
                                | awk '{print $NF}')
    local netmask="" && netmask=$(ipmitool -I lanplus -U $USERNAME -E -H $BMC lan print $channel \
                                  | grep -Ei 'Subnet Mask\s+\:' \
                                  | awk '{print $NF}')
    local defgw="" && defgw=$(ipmitool -I lanplus -U $USERNAME -E -H $BMC lan print $channel \
                              | grep -Ei 'Default Gateway IP\s+\:' \
                              | awk '{print $NF}')

    local bmc=$(host $BMC | awk '{print $4}')

    # For internal systems only.
    # https://stash.us.cray.com/users/jsalmela/repos/cray-sdptool/browse
    # docker build -t cray-sdptool:2.1.0 -f Dockerfile .
    # You can also install SDPTool manually, but it needs a bunch of Python stuff we do not currently install
    podman run \
      --rm \
      --mount type=bind,source=$PWD,target=/usr/local/log/SDPTool/Logfiles/ \
      "$sdptool" \
      "$bmc" \
      "$USERNAME" \
      "$IPMI_PASSWORD" \
      setlan \
      "$channel" \
      "$ipaddr" \
      "$netmask" \
      "$defgw" \
      ${dns_servers//\'}

  fi
}

# if no arguments are passed, show usage
if [[ "$#" -eq 0 ]];then
  echo "No arguments supplied."
  usage && exit 1
fi

if ! command -v jq &> /dev/null
then
  echo "jq could not be found in $PATH"
  exit 1
fi

while getopts "h" opt; do
  case ${opt} in
    h)
      usage
      exit 0
      ;;
   \? )
     echo "Invalid option: -$OPTARG" 1>&2
     exit 1
     ;;
  esac
done
shift $((OPTIND -1))


subcommand="$1"; shift  # Remove command from the argument list
# Parse options to the install sub command
case "$subcommand" in
  ilo)
    set_vars
    while getopts "H:AsZ:tzSD:N:dnrf" opt; do
      case ${opt} in
        # user-defined hostname
        H) BMC="$OPTARG"
           set_vars
           ;;
        A) show_current_bmc_datetime
           disable_ilo_dhcp
           set_bmc_dns
           set_bmc_ntp
           echo "Run 'chronyc clients' on ncn-m001 to validate that NTP on the BMC is working"
           ;;
        Z) TIMEZONE="$OPTARG"
           set_bmc_timezone
           ;;
        t) show_current_bmc_datetime ;;
        z) show_current_bmc_timezone ;;
        s) show_current_bmc_settings ;;
        S) disable_ilo_dhcp ;;
        D) DNS_SERVERS="$OPTARG"
           ;;
        N) NTP_SERVERS="$OPTARG"
           ;;
        d) set_bmc_dns ;;
        n) set_bmc_ntp ; echo "Run 'chronyc clients' on ncn-m001 to validate that NTP on the BMC is working" ;;
        r) reset_bmc_manager ;;
        f) reset_bmc_manager all-force;;
        \?)
          echo "Invalid Option: -$OPTARG" 1>&2
          exit 1
          ;;
        :)
          echo "Invalid Option: -$OPTARG requires an argument" 1>&2
          exit 1
          ;;
      esac
    done
    shift $((OPTIND -1))
    ;;
  # GIGABYTE-specific flags
  gb)
    set_vars
    while getopts "H:AstD:N:dnrf" opt; do
      case ${opt} in
        # user-defined hostname
        H) BMC="$OPTARG"
           set_vars
           ;;
        A) show_current_bmc_settings
           set_bmc_dns
           set_bmc_ntp
           echo "Run 'chronyc clients' on ncn-m001 to validate that NTP on the BMC is working"
           ;;
        t) show_current_bmc_datetime ;;
        s) show_current_bmc_settings ;;
        D) DNS_SERVERS="$OPTARG"
           ;;
        N) NTP_SERVERS="$OPTARG"
           ;;
        d) set_bmc_dns ;;
        n) set_bmc_ntp ; echo "Run 'chronyc clients' on ncn-m001 to validate that NTP on the BMC is working" ;;
        r) reset_bmc_manager ;;
        f) reset_bmc_manager all-force;;
        \?)
          echo "Invalid Option: -$OPTARG" 1>&2
          exit 1
          ;;
        :)
          echo "Invalid Option: -$OPTARG requires an argument" 1>&2
          exit 1
          ;;
      esac
    done
    shift $((OPTIND -1))
    ;;
  # Intel-specific flags
  intel)
    set_vars
    while getopts "H:tsD:dnr" opt; do
      case ${opt} in
        # user-defined hostname
        H) BMC="$OPTARG"
           set_vars
           ;;
        t) show_current_bmc_datetime ;;
        s) show_current_bmc_settings ;;
        D) DNS_SERVERS="$OPTARG"
           ;;
        d) set_bmc_dns ;;
        n) echo "Invalid Option: -n not supported for Intel" 1>&2 ; exit 1 ;;
        r) reset_bmc_manager ;;
        \?)
          echo "Invalid Option: -$OPTARG" 1>&2
          exit 1
          ;;
        :)
          echo "Invalid Option: -$OPTARG requires an argument" 1>&2
          exit 1
          ;;
      esac
    done
    shift $((OPTIND -1))
    ;;
  *)
    echo "Unknown vendor"
    exit 1
    ;;
esac
