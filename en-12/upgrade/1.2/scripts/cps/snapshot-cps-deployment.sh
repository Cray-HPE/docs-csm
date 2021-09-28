# Take cps deployment snapshot (if cps installed)
set +e
trap - ERR
kubectl get pod -n services | grep -q cray-cps
if [ "$?" -eq 0 ]; then
  cps_deployment_snapshot=$(cray cps deployment list --format json | jq -r \
    '.[] | select(."podname" != "NA" and ."podname" != "") | .node' || true)
  echo $cps_deployment_snapshot > /etc/cray/upgrade/csm/${CSM_RELEASE}/cp.deployment.snapshot
fi
trap 'err_report' ERR
set -e