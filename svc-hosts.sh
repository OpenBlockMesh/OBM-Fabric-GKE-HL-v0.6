# Host update script to create a "core-vm-endpoint" hosts file
# Date : 22-08-2016
# Version 0.1
# Author : Jacky Huang
# Commissioned by ANZ Bank under direction of Ben Smillie (Ben.Smillie@anz.com)

#!/bin/bash -x

gcloud compute --project "ubernetes-144200" ssh --zone "asia-east1-a" "core-vm-endpoint" "sed -i -e 's|.*svc-.*||g' /etc/hosts"

export CONTEXT=$(kubectl config view | awk '/current-context/ {print $2}')

kubectl config set-context $CONTEXT --namespace=hyperledger-05

kubectl get svc -n hyperledger-06 | awk '{print $3, $1".hyperledger-06.svc.cluster.local"}'|grep svc- > /tmp/svc-hosts

gcloud compute --project "ubernetes-144200" copy-files --zone "asia-east1-a" /tmp/svc-hosts core-vm-endpoint:.

gcloud compute --project "ubernetes-144200" ssh --zone "asia-east1-a" "core-vm-endpoint" "cat svc-hosts >>/etc/hosts"