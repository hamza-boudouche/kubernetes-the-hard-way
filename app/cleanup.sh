#!/bin/bash

source /root/.bashrc

#destroy web firewall
gcloud -q compute firewall-rules delete \
  kubernetes-the-easy-way-allow-web || true

#terraform destroy 11-network
gcloud -q compute routes delete \
  kubernetes-route-10-200-0-0-24 \
  kubernetes-route-10-200-1-0-24 \
  kubernetes-route-10-200-2-0-24

KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-easy-way \
  --region $(gcloud config get-value compute/region) \
  --format 'value(name)')
#terraform destroy -var "gce_ip_address=${KUBERNETES_PUBLIC_ADDRESS}" 08-kube-master

gcloud -q compute forwarding-rules delete --region $(gcloud config get-value compute/region) kubernetes-forwarding-rule
gcloud -q compute target-pools delete kubernetes-target-pool

rm 07-etcd/*.retry

rm 06-encryption/encryption-config.yaml

rm 05-kubeconfig/*.kubeconfig

rm 04-certs/*.pem
rm 04-certs/*.csr

cd ./03-provisioning

# test if TERRAFORM_TOKEN env var is set, if not prompt the user to enter it and then export its value
if [ -z "$TERRAFORM_TOKEN" ]; then
  if [ "$GITLAB_CI" = "true" ]; then
    # Running in a GitLab CI runner
    echo "You forgot to add the TERRAFORM_TOKEN secret"
    exit 1
  else
    # Not running in a GitLab CI runner
    # TERRAFORM_TOKEN is not set, prompt the user to enter a value
    read -p "There is no registered Terraform token, please insert a valid one: " TERRAFORM_TOKEN
    export TERRAFORM_TOKEN
  fi
fi

terraform init -backend-config="token=$TERRAFORM_TOKEN"

terraform destroy --auto-approve 
