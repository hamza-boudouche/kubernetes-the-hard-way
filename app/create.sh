#!/bin/bash

source /root/.bashrc

gcloud auth activate-service-account --key-file ./adc.json
gcloud config set project $GCLOUD_PROJECT
gcloud config set compute/region $GCLOUD_REGION
gcloud config set compute/zone $GCLOUD_ZONE

export ETCD_VERSION=v3.4.15
export CNI_VERSION=0.3.1
export CNI_PLUGINS_VERSION=v0.9.1
export CONTAINERD_VERSION=1.4.4

rm -f /root/.ssh/google_compute_engine*
# Here we create a key with no passphrase
ssh-keygen -q -P "" -f /root/.ssh/google_compute_engine

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

cp ../adc.json .

cp ~/.ssh/google_compute_engine.pub .

cp ~/.ssh/google_compute_engine .

terraform init -backend-config="token=$TERRAFORM_TOKEN"

terraform apply --auto-approve 

export bastion_secret_key=$(cat ~/.ssh/google_compute_engine)

scp -o StrictHostKeyChecking=no -i /root/.ssh/google_compute_engine /root/.ssh/google_compute_engine root@$(gcloud compute instances list --filter="(tags.items:bastion)" | grep -v NAME | awk '{ print $5 }'):/root/

cd ../04-certs
bash ./gen-certs.sh

cd ../05-kubeconfig
bash ./gen-conf.sh

cd ../06-encryption
bash ./gen-encrypt.sh

cd ..
# 00-ansible/create-inventory.sh
bash 16-lb/create_private_inventory.sh

ansible-playbook -i private_inventory.ini 07-etcd/etcd-playbook.yml

ansible-playbook -i private_inventory.ini 08-kube-controller/kube-controller-playbook.yml
ansible-playbook -i private_inventory.ini 08-kube-controller/rbac-playbook.yml

KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-easy-way \
  --region $(gcloud config get-value compute/region) \
  --format 'value(name)')
  
#terraform create -var "gce_ip_address=${KUBERNETES_PUBLIC_ADDRESS}" 08-kube-master
gcloud compute target-pools create kubernetes-target-pool

gcloud compute target-pools add-instances kubernetes-target-pool \
  --instances controller-0,controller-1,controller-2

KUBERNETES_PUBLIC_ADDRESS=$(gcloud compute addresses describe kubernetes-the-easy-way \
  --region $(gcloud config get-value compute/region) \
  --format 'value(address)')

gcloud compute forwarding-rules create kubernetes-forwarding-rule \
  --address ${KUBERNETES_PUBLIC_ADDRESS} \
  --ports 6443 \
  --region $(gcloud config get-value compute/region) \
  --target-pool kubernetes-target-pool

ansible-playbook -i private_inventory.ini 09-kubelet/kubelet-playbook.yml

# bash ./10-kubectl/setup-kubectl.sh

ansible-playbook -i private_inventory.ini ./10-kubectl/setup-kubectl.yml

bash ./11-network/network-conf.sh

# bash ./12-kubedns/setup-kubedns.sh

ansible-playbook -i private_inventory.ini ./12-kubedns/setup-kubedns.yml

ansible-playbook -i private_inventory.ini 15-nfs/nfs-playbook.yml

# python 16-lb/render_conf.py > 16-lb/nginx.conf

ansible-playbook -i private_inventory.ini 16-lb/lb-playbook.yml

export nfs_server_ip=$(gcloud compute instances list --filter="(tags.items:nfs)" | grep -v NAME | awk '{ print $4 }')

ansible-playbook -i private_inventory.ini 17-storageclass/storageclass-playbook.yml

ansible-playbook -i private_inventory.ini ./19-cassandra/cassandra-playbook.yml

# ansible-playbook -i private_inventory.ini ./18-kafka/kafka-playbook.yml

ansible-playbook -i private_inventory.ini 20-prometheus/prometheus-playbook.yml

ansible-playbook -i private_inventory.ini 20-prometheus/node-exporter-playbook.yml

ansible-playbook -i private_inventory.ini 20-prometheus/grafana-playbook.yml
