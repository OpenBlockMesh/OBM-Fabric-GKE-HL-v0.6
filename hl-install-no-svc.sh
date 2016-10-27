# Install script assuming The Services have been created
# Date : 25-10-2016
# Version 0.2
# Author : James Buckett (james.buckett@au1.ibm.com)
# Commissioned by ANZ Bank under direction of Ben Smillie (Ben.Smillie@anz.com)

#!/bin/bash -x

# Script to install the fabric and leave the Kubernetes Services in place if already existing.

clear

export CONTEXT=$(kubectl config view | awk '/current-context/ {print $2}')
kubectl config set-context $CONTEXT --namespace=hyperledger-06

echo "Installing Validating Peer - vp0"
kubectl create -f dep-hl-vp0.yml
sleep 60

echo "Installing Validating Peer - vp1"
kubectl create -f dep-hl-vp1.yml
sleep 05

echo "Installing Validating Peer - vp2"
kubectl create -f dep-hl-vp2.yml
sleep 05

echo "Installing Validating Peer - vp3"
kubectl create -f dep-hl-vp3.yml
sleep 05

echo "Done"