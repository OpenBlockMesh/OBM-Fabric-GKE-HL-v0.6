# Kubernetes Install Script to create a Hyperledger Fabric
# Date : 25-10-2016
# Version 0.1
# Author : James Buckett (james.buckett@au1.ibm.com)
# Commissioned by ANZ Bank under direction of Ben Smillie (Ben.Smillie@anz.com)

#!/bin/bash -x

clear

echo "Create hyperleder namespace"
kubectl create -f ns-hl.yml
sleep 5

export CONTEXT=$(kubectl config view | awk '/current-context/ {print $2}')
kubectl config set-context $CONTEXT --namespace=hyperledger-06

echo "Installing Fabric Services"
echo "The wait is for GKE to assign EXTERNAL-IP"
kubectl create -f svc-hl-vp0.yml
sleep 5
kubectl create -f svc-hl-vp1.yml
sleep 5
kubectl create -f svc-hl-vp2.yml
sleep 5
kubectl create -f svc-hl-vp3.yml
sleep 5
kubectl create -f svc-hl-vp-lb.yml

sleep 300

kubectl get services

echo "Installing Validating Peer 0"
kubectl create -f dep-hl-vp0.yml
sleep 120

echo "Installing Validating Peer 1"
kubectl create -f dep-hl-vp1.yml
sleep 5

echo "Installing Validating Peer 2"
kubectl create -f dep-hl-vp2.yml
sleep 5

echo "Installing Validating Peer 3"
kubectl create -f dep-hl-vp3.yml
sleep 5

# echo "Installing Non Validating Peer 1"
# kubectl create -f dep-hl-nvp1.yml
# sleep 5

# echo "Installing Non Validating Peer 2"
# kubectl create -f dep-hl-nvp2.yml
# sleep 5

# echo "Installing Non Validating Peer 3"
# kubectl create -f dep-hl-nvp3.yml
# sleep 5

./svc-hosts.sh

echo "Done"
