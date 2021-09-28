#!/bin/bash

# MIT License
#
# (C) Copyright 2025 Hewlett Packard Enterprise Development LP
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
# When upgrading from Istio 1.19.10 to 1.26.0, Istio Upstream recommends
# running the istioctl cli to translate charts from 1.19.10 to 1.26.0.
# The command `istioctl manifest translate -f istiooperator.yaml` generates
# two files :
#            install-base.sh
#            install-pilot.sh
# The script is a rearrangement of the two generated scripts to suit the CSM
# cray-istio upgrade for CSM 1.7 release. This labels and annotates existing
# Kubernetes resources to mark them as part of cray-istio-base,
# cray-istio-pilot and cray-istio-ingress Helm charts before the upgrade,
# ensuring proper Helm management.

set -x

# Function to label/annotate resources for cray-istio-base chart
label_cray_istio_base() {
  echo "Labeling/Annotating resources for cray-istio-base chart..."

  # Label/Annotate resources to mark them a part of the Helm release.
  kubectl annotate --overwrite CustomResourceDefinition.apiextensions.k8s.io wasmplugins.extensions.istio.io meta.helm.sh/release-name=cray-istio-base meta.helm.sh/release-namespace=istio-system
  kubectl label CustomResourceDefinition.apiextensions.k8s.io wasmplugins.extensions.istio.io app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite CustomResourceDefinition.apiextensions.k8s.io destinationrules.networking.istio.io meta.helm.sh/release-name=cray-istio-base meta.helm.sh/release-namespace=istio-system
  kubectl label CustomResourceDefinition.apiextensions.k8s.io destinationrules.networking.istio.io app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite CustomResourceDefinition.apiextensions.k8s.io envoyfilters.networking.istio.io meta.helm.sh/release-name=cray-istio-base meta.helm.sh/release-namespace=istio-system
  kubectl label CustomResourceDefinition.apiextensions.k8s.io envoyfilters.networking.istio.io app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite CustomResourceDefinition.apiextensions.k8s.io gateways.networking.istio.io meta.helm.sh/release-name=cray-istio-base meta.helm.sh/release-namespace=istio-system
  kubectl label CustomResourceDefinition.apiextensions.k8s.io gateways.networking.istio.io app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite CustomResourceDefinition.apiextensions.k8s.io proxyconfigs.networking.istio.io meta.helm.sh/release-name=cray-istio-base meta.helm.sh/release-namespace=istio-system
  kubectl label CustomResourceDefinition.apiextensions.k8s.io proxyconfigs.networking.istio.io app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite CustomResourceDefinition.apiextensions.k8s.io serviceentries.networking.istio.io meta.helm.sh/release-name=cray-istio-base meta.helm.sh/release-namespace=istio-system
  kubectl label CustomResourceDefinition.apiextensions.k8s.io serviceentries.networking.istio.io app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite CustomResourceDefinition.apiextensions.k8s.io sidecars.networking.istio.io meta.helm.sh/release-name=cray-istio-base meta.helm.sh/release-namespace=istio-system
  kubectl label CustomResourceDefinition.apiextensions.k8s.io sidecars.networking.istio.io app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite CustomResourceDefinition.apiextensions.k8s.io virtualservices.networking.istio.io meta.helm.sh/release-name=cray-istio-base meta.helm.sh/release-namespace=istio-system
  kubectl label CustomResourceDefinition.apiextensions.k8s.io virtualservices.networking.istio.io app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite CustomResourceDefinition.apiextensions.k8s.io workloadentries.networking.istio.io meta.helm.sh/release-name=cray-istio-base meta.helm.sh/release-namespace=istio-system
  kubectl label CustomResourceDefinition.apiextensions.k8s.io workloadentries.networking.istio.io app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite CustomResourceDefinition.apiextensions.k8s.io workloadgroups.networking.istio.io meta.helm.sh/release-name=cray-istio-base meta.helm.sh/release-namespace=istio-system
  kubectl label CustomResourceDefinition.apiextensions.k8s.io workloadgroups.networking.istio.io app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite CustomResourceDefinition.apiextensions.k8s.io authorizationpolicies.security.istio.io meta.helm.sh/release-name=cray-istio-base meta.helm.sh/release-namespace=istio-system
  kubectl label CustomResourceDefinition.apiextensions.k8s.io authorizationpolicies.security.istio.io app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite CustomResourceDefinition.apiextensions.k8s.io peerauthentications.security.istio.io meta.helm.sh/release-name=cray-istio-base meta.helm.sh/release-namespace=istio-system
  kubectl label CustomResourceDefinition.apiextensions.k8s.io peerauthentications.security.istio.io app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite CustomResourceDefinition.apiextensions.k8s.io requestauthentications.security.istio.io meta.helm.sh/release-name=cray-istio-base meta.helm.sh/release-namespace=istio-system
  kubectl label CustomResourceDefinition.apiextensions.k8s.io requestauthentications.security.istio.io app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite CustomResourceDefinition.apiextensions.k8s.io telemetries.telemetry.istio.io meta.helm.sh/release-name=cray-istio-base meta.helm.sh/release-namespace=istio-system
  kubectl label CustomResourceDefinition.apiextensions.k8s.io telemetries.telemetry.istio.io app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite ServiceAccount --namespace=istio-system istio-reader-service-account meta.helm.sh/release-name=cray-istio-base meta.helm.sh/release-namespace=istio-system
  kubectl label ServiceAccount --namespace=istio-system istio-reader-service-account app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite ValidatingWebhookConfiguration.admissionregistration.k8s.io istiod-default-validator meta.helm.sh/release-name=cray-istio-base meta.helm.sh/release-namespace=istio-system
  kubectl label ValidatingWebhookConfiguration.admissionregistration.k8s.io istiod-default-validator app.kubernetes.io/managed-by=Helm
}

# Function to label/annotate resources for cray-istio-pilot chart
label_cray_istio_pilot() {
  echo "Labeling/Annotating resources for cray-istio-pilot chart..."

  # Label/Annotate resources to mark them a part of the Helm release.
  kubectl annotate --overwrite HorizontalPodAutoscaler.autoscaling --namespace=istio-system istiod meta.helm.sh/release-name=cray-istio-pilot meta.helm.sh/release-namespace=istio-system
  kubectl label HorizontalPodAutoscaler.autoscaling --namespace=istio-system istiod app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite ClusterRole.rbac.authorization.k8s.io istiod-clusterrole-istio-system meta.helm.sh/release-name=cray-istio-pilot meta.helm.sh/release-namespace=istio-system
  kubectl label ClusterRole.rbac.authorization.k8s.io istiod-clusterrole-istio-system app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite ClusterRole.rbac.authorization.k8s.io istiod-gateway-controller-istio-system meta.helm.sh/release-name=cray-istio-pilot meta.helm.sh/release-namespace=istio-system
  kubectl label ClusterRole.rbac.authorization.k8s.io istiod-gateway-controller-istio-system app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite ClusterRoleBinding.rbac.authorization.k8s.io istiod-clusterrole-istio-system meta.helm.sh/release-name=cray-istio-pilot meta.helm.sh/release-namespace=istio-system
  kubectl label ClusterRoleBinding.rbac.authorization.k8s.io istiod-clusterrole-istio-system app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite ClusterRoleBinding.rbac.authorization.k8s.io istiod-gateway-controller-istio-system meta.helm.sh/release-name=cray-istio-pilot meta.helm.sh/release-namespace=istio-system
  kubectl label ClusterRoleBinding.rbac.authorization.k8s.io istiod-gateway-controller-istio-system app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite ConfigMap --namespace=istio-system istio meta.helm.sh/release-name=cray-istio-pilot meta.helm.sh/release-namespace=istio-system
  kubectl label ConfigMap --namespace=istio-system istio app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite Deployment.apps --namespace=istio-system istiod meta.helm.sh/release-name=cray-istio-pilot meta.helm.sh/release-namespace=istio-system
  kubectl label Deployment.apps --namespace=istio-system istiod app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite ConfigMap --namespace=istio-system istio-sidecar-injector meta.helm.sh/release-name=cray-istio-pilot meta.helm.sh/release-namespace=istio-system
  kubectl label ConfigMap --namespace=istio-system istio-sidecar-injector app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite MutatingWebhookConfiguration.admissionregistration.k8s.io istio-sidecar-injector meta.helm.sh/release-name=cray-istio-pilot meta.helm.sh/release-namespace=istio-system
  kubectl label MutatingWebhookConfiguration.admissionregistration.k8s.io istio-sidecar-injector app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite PodDisruptionBudget.policy --namespace=istio-system istiod meta.helm.sh/release-name=cray-istio-pilot meta.helm.sh/release-namespace=istio-system
  kubectl label PodDisruptionBudget.policy --namespace=istio-system istiod app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite ClusterRole.rbac.authorization.k8s.io istio-reader-clusterrole-istio-system meta.helm.sh/release-name=cray-istio-pilot meta.helm.sh/release-namespace=istio-system
  kubectl label ClusterRole.rbac.authorization.k8s.io istio-reader-clusterrole-istio-system app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite ClusterRoleBinding.rbac.authorization.k8s.io istio-reader-clusterrole-istio-system meta.helm.sh/release-name=cray-istio-pilot meta.helm.sh/release-namespace=istio-system
  kubectl label ClusterRoleBinding.rbac.authorization.k8s.io istio-reader-clusterrole-istio-system app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite Role.rbac.authorization.k8s.io --namespace=istio-system istiod meta.helm.sh/release-name=cray-istio-pilot meta.helm.sh/release-namespace=istio-system
  kubectl label Role.rbac.authorization.k8s.io --namespace=istio-system istiod app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite RoleBinding.rbac.authorization.k8s.io --namespace=istio-system istiod meta.helm.sh/release-name=cray-istio-pilot meta.helm.sh/release-namespace=istio-system
  kubectl label RoleBinding.rbac.authorization.k8s.io --namespace=istio-system istiod app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite Service --namespace=istio-system istiod meta.helm.sh/release-name=cray-istio-pilot meta.helm.sh/release-namespace=istio-system
  kubectl label Service --namespace=istio-system istiod app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite ServiceAccount --namespace=istio-system istiod meta.helm.sh/release-name=cray-istio-pilot meta.helm.sh/release-namespace=istio-system
  kubectl label ServiceAccount --namespace=istio-system istiod app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite ValidatingWebhookConfiguration.admissionregistration.k8s.io istio-validator-istio-system meta.helm.sh/release-name=cray-istio-pilot meta.helm.sh/release-namespace=istio-system
  kubectl label ValidatingWebhookConfiguration.admissionregistration.k8s.io istio-validator-istio-system app.kubernetes.io/managed-by=Helm
}

# Function to label/annotate resources for cray-istio-ingress chart
label_cray_istio_ingress() {
  echo "Labeling/Annotating resources for cray-istio-ingress chart..."

  # Label/Annotate resources to mark them a part of the Helm release.
  kubectl annotate --overwrite HorizontalPodAutoscaler.autoscaling --namespace=istio-system istio-ingressgateway meta.helm.sh/release-name=cray-istio-ingress meta.helm.sh/release-namespace=istio-system
  kubectl label HorizontalPodAutoscaler.autoscaling --namespace=istio-system istio-ingressgateway app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite HorizontalPodAutoscaler.autoscaling --namespace=istio-system istio-ingressgateway-customer-admin meta.helm.sh/release-name=cray-istio-ingress meta.helm.sh/release-namespace=istio-system
  kubectl label HorizontalPodAutoscaler.autoscaling --namespace=istio-system istio-ingressgateway-customer-admin app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite HorizontalPodAutoscaler.autoscaling --namespace=istio-system istio-ingressgateway-customer-user meta.helm.sh/release-name=cray-istio-ingress meta.helm.sh/release-namespace=istio-system
  kubectl label HorizontalPodAutoscaler.autoscaling --namespace=istio-system istio-ingressgateway-customer-user app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite HorizontalPodAutoscaler.autoscaling --namespace=istio-system istio-ingressgateway-hmn meta.helm.sh/release-name=cray-istio-ingress meta.helm.sh/release-namespace=istio-system
  kubectl label HorizontalPodAutoscaler.autoscaling --namespace=istio-system istio-ingressgateway-hmn app.kubernetes.io/managed-by=Helm

  kubectl annotate --overwrite Deployment.apps --namespace=istio-system istio-ingressgateway meta.helm.sh/release-name=cray-istio-ingress meta.helm.sh/release-namespace=istio-system
  kubectl label Deployment.apps --namespace=istio-system istio-ingressgateway app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite Deployment.apps --namespace=istio-system istio-ingressgateway-customer-admin meta.helm.sh/release-name=cray-istio-ingress meta.helm.sh/release-namespace=istio-system
  kubectl label Deployment.apps --namespace=istio-system istio-ingressgateway-customer-admin app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite Deployment.apps --namespace=istio-system istio-ingressgateway-customer-user meta.helm.sh/release-name=cray-istio-ingress meta.helm.sh/release-namespace=istio-system
  kubectl label Deployment.apps --namespace=istio-system istio-ingressgateway-customer-user app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite Deployment.apps --namespace=istio-system istio-ingressgateway-hmn meta.helm.sh/release-name=cray-istio-ingress meta.helm.sh/release-namespace=istio-system
  kubectl label Deployment.apps --namespace=istio-system istio-ingressgateway-hmn app.kubernetes.io/managed-by=Helm

  kubectl annotate --overwrite PodDisruptionBudget.policy --namespace=istio-system istio-ingressgateway meta.helm.sh/release-name=cray-istio-ingress meta.helm.sh/release-namespace=istio-system
  kubectl label PodDisruptionBudget.policy --namespace=istio-system istio-ingressgateway app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite PodDisruptionBudget.policy --namespace=istio-system istio-ingressgateway-customer-admin meta.helm.sh/release-name=cray-istio-ingress meta.helm.sh/release-namespace=istio-system
  kubectl label PodDisruptionBudget.policy --namespace=istio-system istio-ingressgateway-customer-admin app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite PodDisruptionBudget.policy --namespace=istio-system istio-ingressgateway-customer-user meta.helm.sh/release-name=cray-istio-ingress meta.helm.sh/release-namespace=istio-system
  kubectl label PodDisruptionBudget.policy --namespace=istio-system istio-ingressgateway-customer-user app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite PodDisruptionBudget.policy --namespace=istio-system istio-ingressgateway-hmn meta.helm.sh/release-name=cray-istio-ingress meta.helm.sh/release-namespace=istio-system
  kubectl label PodDisruptionBudget.policy --namespace=istio-system istio-ingressgateway-hmn app.kubernetes.io/managed-by=Helm

  kubectl annotate --overwrite ClusterRole.rbac.authorization.k8s.io cray-istio-jobs-role meta.helm.sh/release-name=cray-istio-ingress meta.helm.sh/release-namespace=istio-system
  kubectl label ClusterRole.rbac.authorization.k8s.io cray-istio-jobs-role app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite ClusterRoleBinding.rbac.authorization.k8s.io cray-istio-jobs-role-binding meta.helm.sh/release-name=cray-istio-ingress meta.helm.sh/release-namespace=istio-system
  kubectl label ClusterRoleBinding.rbac.authorization.k8s.io cray-istio-jobs-role-binding app.kubernetes.io/managed-by=Helm

  kubectl label Role.rbac.authorization.k8s.io --namespace=istio-system istio-ingressgateway-customer-admin-sds app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite Role.rbac.authorization.k8s.io --namespace=istio-system istio-ingressgateway-customer-admin-sds meta.helm.sh/release-name=cray-istio-ingress meta.helm.sh/release-namespace=istio-system
  kubectl label Role.rbac.authorization.k8s.io --namespace=istio-system istio-ingressgateway-customer-user-sds app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite Role.rbac.authorization.k8s.io --namespace=istio-system istio-ingressgateway-customer-user-sds meta.helm.sh/release-name=cray-istio-ingress meta.helm.sh/release-namespace=istio-system
  kubectl label Role.rbac.authorization.k8s.io --namespace=istio-system istio-ingressgateway-hmn-sds app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite Role.rbac.authorization.k8s.io --namespace=istio-system istio-ingressgateway-hmn-sds meta.helm.sh/release-name=cray-istio-ingress meta.helm.sh/release-namespace=istio-system
  kubectl label Role.rbac.authorization.k8s.io --namespace=istio-system istio-ingressgateway-sds app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite Role.rbac.authorization.k8s.io --namespace=istio-system istio-ingressgateway-sds meta.helm.sh/release-name=cray-istio-ingress meta.helm.sh/release-namespace=istio-system

  kubectl label RoleBinding.rbac.authorization.k8s.io --namespace=istio-system istio-ingressgateway-customer-admin-sds app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite RoleBinding.rbac.authorization.k8s.io --namespace=istio-system istio-ingressgateway-customer-admin-sds meta.helm.sh/release-name=cray-istio-ingress meta.helm.sh/release-namespace=istio-system
  kubectl label RoleBinding.rbac.authorization.k8s.io --namespace=istio-system istio-ingressgateway-customer-user-sds app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite RoleBinding.rbac.authorization.k8s.io --namespace=istio-system istio-ingressgateway-customer-user-sds meta.helm.sh/release-name=cray-istio-ingress meta.helm.sh/release-namespace=istio-system
  kubectl label RoleBinding.rbac.authorization.k8s.io --namespace=istio-system istio-ingressgateway-hmn-sds app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite RoleBinding.rbac.authorization.k8s.io --namespace=istio-system istio-ingressgateway-hmn-sds meta.helm.sh/release-name=cray-istio-ingress meta.helm.sh/release-namespace=istio-system
  kubectl label RoleBinding.rbac.authorization.k8s.io --namespace=istio-system istio-ingressgateway-sds app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite RoleBinding.rbac.authorization.k8s.io --namespace=istio-system istio-ingressgateway-sds meta.helm.sh/release-name=cray-istio-ingress meta.helm.sh/release-namespace=istio-system

  kubectl label Certificate --namespace=istio-system dvs-mqtt-cert app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite Certificate --namespace=istio-system dvs-mqtt-cert meta.helm.sh/release-name=cray-istio-ingress meta.helm.sh/release-namespace=istio-system
  kubectl label Certificate --namespace=istio-system ingress-gateway-cert app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite Certificate --namespace=istio-system ingress-gateway-cert meta.helm.sh/release-name=cray-istio-ingress meta.helm.sh/release-namespace=istio-system

  kubectl label PeerAuthentication.security.istio.io --namespace=istio-system istio-ingressgateway-authn app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite PeerAuthentication.security.istio.io --namespace=istio-system istio-ingressgateway-authn meta.helm.sh/release-name=cray-istio-ingress meta.helm.sh/release-namespace=istio-system

  kubectl label DestinationRule.networking.istio.io --namespace=istio-system cluster-kafka-bootstrap-rule app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite DestinationRule.networking.istio.io --namespace=istio-system cluster-kafka-bootstrap-rule meta.helm.sh/release-name=cray-istio-ingress meta.helm.sh/release-namespace=istio-system
  kubectl label DestinationRule.networking.istio.io --namespace=services cluster-kafka-brokers-rule app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite DestinationRule.networking.istio.io --namespace=services cluster-kafka-brokers-rule meta.helm.sh/release-name=cray-istio-ingress meta.helm.sh/release-namespace=istio-system

  kubectl label Gateways.networking.istio.io --namespace=services customer-admin-gateway app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite Gateways.networking.istio.io --namespace=services customer-admin-gateway meta.helm.sh/release-name=cray-istio-ingress meta.helm.sh/release-namespace=istio-system
  kubectl label Gateways.networking.istio.io --namespace=services customer-user-gateway app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite Gateways.networking.istio.io --namespace=services customer-user-gateway meta.helm.sh/release-name=cray-istio-ingress meta.helm.sh/release-namespace=istio-system
  kubectl label Gateways.networking.istio.io --namespace=services hmn-gateway app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite Gateways.networking.istio.io --namespace=services hmn-gateway meta.helm.sh/release-name=cray-istio-ingress meta.helm.sh/release-namespace=istio-system
  kubectl label Gateways.networking.istio.io --namespace=services services-gateway app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite Gateways.networking.istio.io --namespace=services services-gateway meta.helm.sh/release-name=cray-istio-ingress meta.helm.sh/release-namespace=istio-system

  kubectl annotate --overwrite Service --namespace=istio-system istio-ingressgateway meta.helm.sh/release-name=cray-istio-ingress meta.helm.sh/release-namespace=istio-system
  kubectl label Service --namespace=istio-system istio-ingressgateway app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite Service --namespace=istio-system istio-ingressgateway-can meta.helm.sh/release-name=cray-istio-ingress meta.helm.sh/release-namespace=istio-system
  kubectl label Service --namespace=istio-system istio-ingressgateway-can app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite Service --namespace=istio-system istio-ingressgateway-chn meta.helm.sh/release-name=cray-istio-ingress meta.helm.sh/release-namespace=istio-system
  kubectl label Service --namespace=istio-system istio-ingressgateway-chn app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite Service --namespace=istio-system istio-ingressgateway-cmn meta.helm.sh/release-name=cray-istio-ingress meta.helm.sh/release-namespace=istio-system
  kubectl label Service --namespace=istio-system istio-ingressgateway-cmn app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite Service --namespace=istio-system istio-ingressgateway-hmn meta.helm.sh/release-name=cray-istio-ingress meta.helm.sh/release-namespace=istio-system
  kubectl label Service --namespace=istio-system istio-ingressgateway-hmn app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite Service --namespace=istio-system istio-ingressgateway-local meta.helm.sh/release-name=cray-istio-ingress meta.helm.sh/release-namespace=istio-system
  kubectl label Service --namespace=istio-system istio-ingressgateway-local app.kubernetes.io/managed-by=Helm

  kubectl annotate --overwrite ServiceAccount --namespace=istio-system cray-istio-jobs meta.helm.sh/release-name=cray-istio-ingress meta.helm.sh/release-namespace=istio-system
  kubectl label ServiceAccount --namespace=istio-system cray-istio-jobs app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite ServiceAccount --namespace=istio-system istio-ingressgateway-customer-admin-service-account meta.helm.sh/release-name=cray-istio-ingress meta.helm.sh/release-namespace=istio-system
  kubectl label ServiceAccount --namespace=istio-system istio-ingressgateway-customer-admin-service-account app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite ServiceAccount --namespace=istio-system istio-ingressgateway-customer-user-service-account meta.helm.sh/release-name=cray-istio-ingress meta.helm.sh/release-namespace=istio-system
  kubectl label ServiceAccount --namespace=istio-system istio-ingressgateway-customer-user-service-account app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite ServiceAccount --namespace=istio-system istio-ingressgateway-hmn-service-account meta.helm.sh/release-name=cray-istio-ingress meta.helm.sh/release-namespace=istio-system
  kubectl label ServiceAccount --namespace=istio-system istio-ingressgateway-hmn-service-account app.kubernetes.io/managed-by=Helm
  kubectl annotate --overwrite ServiceAccount --namespace=istio-system istio-ingressgateway-service-account meta.helm.sh/release-name=cray-istio-ingress meta.helm.sh/release-namespace=istio-system
  kubectl label ServiceAccount --namespace=istio-system istio-ingressgateway-service-account app.kubernetes.io/managed-by=Helm
}

if [ $# -eq 0 ]; then
  echo "Error: No chart name provided"
  echo "Available charts: cray-istio-base, cray-istio-pilot, cray-istio-ingress"
  exit 1
fi

case "$1" in
  "cray-istio-base")
    label_cray_istio_base
    ;;
  "cray-istio-pilot")
    label_cray_istio_pilot
    ;;
  "cray-istio-ingress")
    label_cray_istio_ingress
    ;;
  *)
    echo "Error: Unknown chart name '$1'"
    echo "Available charts: cray-istio-base, cray-istio-pilot, cray-istio-ingress"
    exit 1
    ;;
esac

echo "Completed labeling/annotating resources for $1"
