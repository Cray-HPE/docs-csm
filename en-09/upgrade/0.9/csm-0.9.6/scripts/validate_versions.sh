#!/bin/bash
#
# Copyright 2021 Hewlett Packard Enterprise Development LP
#

validated=true
# Confirm the version of istio pilot image is 1.6.13-cray2
ver=$(kubectl describe pod istiod- -n istio-system | grep Image: | cut -d':' -f3 | uniq)
if [ "$ver" != "1.6.13-cray2" ]; then
  echo "Error: istio pilot image version $ver is unexpected."
  validated=false
fi

# Confirm the version of cray-spire-tokens image is 0.4.1
ver=$(kubectl describe pod spire-server-0 -n spire | grep Image | grep spire-tokens: | cut -d':' -f3)
if [ "$ver" != "0.4.1" ]; then
  echo "ERROR: cray-spire-tokens image version $ver is unexpected."
  validated=false
fi

# Confirm the version of hms-redfish-translation-service image is 1.8.8
ver=$(kubectl describe pod cray-hms-rts- -n services | grep Image: | grep hms | cut -d':' -f3 | uniq)
if [ "$ver" != "1.8.8" ]; then
  echo "ERROR: hms-redfish-translation-service image version $ver is unexpected."
  validated=false
fi

if [ "$validated" = "true" ]; then
  echo "OK"
else
  echo "Failed!"
  exit 1
fi
