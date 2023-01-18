#!/bin/bash

KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-easy-way \
  --region $(gcloud config get-value compute/region) \
  --format 'value(address)')

kubectl config set-cluster kubernetes-the-easy-way \
  --certificate-authority=/var/lib/kubernetes/ca.pem \
  --embed-certs=true \
  --server=https://10.240.0.10:6443

kubectl config set-credentials admin \
  --client-certificate=/var/lib/kubernetes/admin.pem \
  --client-key=/var/lib/kubernetes/admin-key.pem

kubectl config set-context kubernetes-the-easy-way \
  --cluster=kubernetes-the-easy-way \
  --user=admin

kubectl config use-context kubernetes-the-easy-way

# kubectl get componentstatuses

kubectl version

kubectl get nodes
