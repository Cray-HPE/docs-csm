#!/bin/bash
#
# MIT License
#
# (C) Copyright 2022 Hewlett Packard Enterprise Development LP
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#

function check_k8s_service() {
  printf "Checking check_k8s_service $1\n"

	service_check=$(kubectl get services -n services -o wide | grep $1 | grep -i Pending | wc -l)

	if [[ $service_check -gt 0 ]]; then
		printf "Failed service check for $1\n\n"
		kubectl get services -n services -o wide | grep $1 | grep Pending
	else
	  printf "Pass service check for $1\n\n"
	fi
}

function check_k8s_pods() {
  printf "Checking check_k8s_pods $1\n"
	pod_check=$(kubectl get pods -n services -o wide | grep $1 | grep -v  Running | grep -v manager |grep -v coredns| wc -l)

	if [[ $pod_check -gt 0 ]]; then
		printf "Failed pod check for $1\n\n"
		kubectl get pods -n services -o wide | grep $1 | grep -v  Running | grep -v manager
	else
	  printf "Pass pod check for $1\n\n"
	fi
}

function check_unbound_manager() {
  printf "Checking check_unbound_manager\n"
	cronjob_check=$(kubectl get cronjob -n services -l app.kubernetes.io/instance=cray-dns-unbound | grep cray-dns-unbound | awk '{ print $9 }' |grep h |wc -l)
  cronjob_lastrun=$(kubectl get cronjob -n services -l app.kubernetes.io/instance=cray-dns-unbound|grep cray-dns-unbound | awk '{ print $9 }')

	if [[ cronjob_check -gt 0 ]]; then
		printf "Failed cronjob for cray-dns-unbound has not been run for over an hour.  Last run $cronjob_lastrun\n\n"
		kubectl get cronjob -n services -l app.kubernetes.io/instance=cray-dns-unbound|grep cray-dns-unbound | awk '{ print $9 }'
	else
	  printf "Pass cronjob for cray-dns-unbound last run $cronjob_lastrun\n\n"
	fi
}

function check_unbound_coredns() {
  printf "Checking check_unbound_coredns\n"
	job_exist_check=$(kubectl get job -n services -l app.kubernetes.io/instance=cray-dns-unbound |  wc -l)

	if [[ job_exist_check -gt 0 ]]; then
		job_check=$(kubectl get job -n services -l app.kubernetes.io/instance=cray-dns-unbound| grep cray-dns-unbound| awk '{ print $2 }')

		if [[ "$job_check" != "1/1" ]]; then
			printf "Failed job for cray-dns-unbound has not completed.\n\n"
			kubectl get job -n services -l app.kubernetes.io/instance=cray-dns-unbound
		else
		  printf "Pass job for cray-dns-unbound has completed.\n\n"
		fi
	fi
}

function check_unbound_forwarder() {
  printf "Checking check_unbound_forwarder\n"
	forward_ips=$(kubectl get cm -n services cray-dns-unbound -o yaml |grep forward-addr | awk '{ print $2 }')

	for ip in $forward_ips; do
		dns_forwarder_test=$(nslookup google.com $ip | grep -e "server can't find" -e "connection timed out" | wc -l)
		if [[ $dns_forwarder_test -gt 0 ]]; then
			printf "Failed DNS forwarder test.\n\n"
			dns_forwarder_test=$(nslookup google.com $ip)
		else
		  printf "Pass DNS forwarder test.\n\n"
		fi
	done
}

function checking_kea_dhcp_helper() {
  printf "Checking checking_kea_dhcp_helper\n"

  kea_pod=$(kubectl get pods -n services | grep cray-dhcp-kea| awk '{ print $1 }')
  dhcp_helper_check=$(kubectl exec -n services $kea_pod -c cray-dhcp-kea -- /srv/kea/dhcp-helper.py)

  if [[ ! -z "$dhcp_helper_check" ]]; then
    printf "Failed cray-dhcp-kiea dhcp-helper.py if not running cleanly.\n"
    printf "dhcp-helper.py output\n"
    printf "$dhcp_helper_check\n\n"
  else
    printf "Pass cray-dhcp-kea dhcp-helper.py is running cleanly.\n\n"
  fi

}

service_list="cray-dhcp-kea cray-dns-unbound"

for service in $service_list; do
  check_k8s_pods $service
  check_k8s_service $service
done

check_unbound_manager
check_unbound_coredns
check_unbound_forwarder
checking_kea_dhcp_helper

