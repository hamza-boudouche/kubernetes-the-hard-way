#!/bin/sh

cat > private_inventory.ini <<EOF
[proxy]
$(gcloud compute instances list --filter="(tags.items:bastion)" | grep -v NAME | awk '{ print $5 }')
[all]
$(gcloud compute instances list | grep -v NAME | awk '{ print $4 }')
[workers]
$(gcloud compute instances list --filter="(tags.items:worker)" | grep -v NAME | awk '{ print $4 }')
[controllers]
$(gcloud compute instances list --filter="(tags.items:controller)" | grep -v NAME | awk '{ print $4 }')
[controller-0]
$(gcloud compute instances list --filter="(name:controller-0)" | grep -v NAME | awk '{ print $4 }')
[loadbalancer]
$(gcloud compute instances list --filter="(tags.items:loadbalancer)" | grep -v NAME | awk '{ print $4 }')
[nfs]
$(gcloud compute instances list --filter="(tags.items:nfs)" | grep -v NAME | awk '{ print $4 }')
[cassandra]
$(gcloud compute instances list --filter="(tags.items:cassandra)" | grep -v NAME | awk '{ print $4 }')
[cassandra-0]
$(gcloud compute instances list --filter="(name:cassandra-0)" | grep -v NAME | awk '{ print $4 }')
[all:vars]
ansible_ssh_common_args='-o ProxyCommand="ssh -o StrictHostKeyChecking=no -i /root/.ssh/google_compute_engine -W %h:%p -q root@$(gcloud compute instances list --filter="(tags.items:bastion)" | grep -v NAME | awk '{ print $5 }')"'
EOF
