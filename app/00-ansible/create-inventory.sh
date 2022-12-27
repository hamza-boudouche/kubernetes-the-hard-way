#!/bin/sh

cat > inventory.ini <<EOF
[all]
$(gcloud compute instances list | grep -v NAME | awk '{ print $5 }')
[workers]
$(gcloud compute instances list --filter="(tags.items:worker)" | grep -v NAME | awk '{ print $5 }')
[controllers]
$(gcloud compute instances list --filter="(tags.items:controller)" | grep -v NAME | awk '{ print $5 }')
[controller-0]
$(gcloud compute instances list --filter="(name:controller-0)" | grep -v NAME | awk '{ print $5 }')
[loadbalancer]
$(gcloud compute instances list --filter="(tags.items:loadbalancer)" | grep -v NAME | awk '{ print $5 }')
[nfs]
$(gcloud compute instances list --filter="(tags.items:nfs)" | grep -v NAME | awk '{ print $5 }')
EOF
