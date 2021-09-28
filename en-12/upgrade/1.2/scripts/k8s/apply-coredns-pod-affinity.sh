#!/bin/bash

echo "Applying pod anti-affinity to coredns pods"

cat > /tmp/coredns-affinity.yaml <<EOF
spec:
  template:
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchExpressions:
                  - key: k8s-app
                    operator: In
                    values:
                      - kube-dns
              topologyKey: kubernetes.io/hostname
EOF

cfile=/tmp/coredns-deployment.yaml
kubectl -n kube-system get deployment coredns -o yaml > $cfile
yq m -i $cfile /tmp/coredns-affinity.yaml
kubectl apply -f $cfile
