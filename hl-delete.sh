# Kubernetes Delete Script to delete a Hyperledger Fabric
# Date : 25-10-2016
# Version 0.2
# Author : James Buckett (james.buckett@au1.ibm.com)
# Commissioned by ANZ Bank under direction of Ben Smillie (Ben.Smillie@anz.com)

#!/bin/bash -x

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

echo "Deleting Services"
kubectl delete -f svc-hl-vp0.yml
sleep 5
kubectl delete -f svc-hl-vp1.yml
sleep 5
kubectl delete -f svc-hl-vp2.yml
sleep 5
kubectl delete -f svc-hl-vp3.yml
sleep 5
kubectl delete -f svc-hl-vp-lb.yml
sleep 5
# kubectl delete -f svc-hl-nvp3.yml
# sleep 5
# kubectl delete -f svc-hl-nvp2.yml
# sleep 5
# kubectl delete -f svc-hl-nvp1.yml
# sleep 5
# kubectl delete -f svc-hl-nvp-lb.yml
# sleep 5

echo "Deleting hyperleger namespace"
kubectl delete -f ns-hl.yml

kubectl get services
kubectl get pods 
kubectl get replicasets

echo "Done"
