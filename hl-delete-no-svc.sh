# Delete script assuming The Services have been created
# Date : 25-10-2016
# Version 0.2
# Author : James Buckett (james.buckett@au1.ibm.com)
# Commissioned by ANZ Bank under direction of Ben Smillie (Ben.Smillie@anz.com)

#!/bin/bash -x

# Script to delete the fabric and leave the Kubernetes Services in place if already existing.

clear

export CONTEXT=$(kubectl config view | awk '/current-context/ {print $2}')
kubectl config set-context $CONTEXT --namespace=hyperledger-06

echo "Deleting Validating Peer - vp3"
kubectl delete -f dep-hl-vp3.yml

echo "Deleting Validating Peer - vp2"
kubectl delete -f dep-hl-vp2.yml

echo "Deleting Validating Peer - vp1"
kubectl delete -f dep-hl-vp1.yml

echo "Deleting Validating Peer - vp0"
kubectl delete -f dep-hl-vp0.yml

kubectl get services
kubectl get pods 
kubectl get replicasets

echo "Done"