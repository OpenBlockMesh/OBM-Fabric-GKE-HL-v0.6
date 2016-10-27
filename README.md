**DRAFT**

# The Open Block Mesh Project

The objective of this project is to run Hyperledger 0.6 under the control of Kubernetes to provide Production-Grade Container Orchestration for Hyperledger containers.

* [Kubernetes](https://github.com/kubernetes/kubernetes)
* [Hyperledger](https://github.com/hyperledger)

This work was commissioned by ANZ Bank which is a member of the Hyperledger Project under the direction of 
* [Ben Smillie](https://github.com/benksmillie) (Ben.Smillie@anz.com)
* Technical Manager - Emerging Technology
* [ANZ Bank](http://www.anz.com)

The goal of this project is to provide a rapid platform to stand up a Hyperledger peer fabric for development purposes under the control of Kubernetes.

The standup of the entire platform should take about six minutes and the tear down about one minute. 

A majority of the time taken to stand up the fabric is GKE assigning external IP addresses.



## Assumptions

This project assumes Kubernetes to be at version 1.4 or later.

This project assumes the hosting environment is Google Container Engine and Google Compute Engine.

All of the work detailed should be performed on a system with the correct version of gcloud and kubectl and has access to GKE and GCE.

As the Hyperledger project currently only supports build from source, this project built two images from source.

See : https://github.com/hyperledger/fabric/issues/2336

These images are currently stored on [Docker Hub](https://hub.docker.com/u/jackyhuang/) under : 
* `jackyhuang/fabric-peer`
* `jackyhuang/fabric-baseimage`

The metadate label : version: `0.6` is used to version these images.

These images are used in this project to build the fabric and run the chain code.



## Technical End State Objectives

The fabric will be installed into a `hyperledger-06` namespace to provide soft multi-tenancy and isolation.

![Overview](https://github.com/OpenBlockMesh/OBM-Fabric-GKE-HL-v0.6/blob/master/obm-overview.png)

Four Validating Peers Pods are built so a single failure can be tolerated in the Fabric.

These Validating Peers are shown as Kubernetes Pods in the diagram above.

They are identified as : `vp0 (root node), vp1, vp2 and vp3`

This fabric uses pbft (Practical Byzantine Fault Tolerance) protocol.


Four Validating Peer Kubernetes Services are installed.

These services are identified by a `svc` prefix.

They are : 
* `svc-hl-vp0 - vp0 hyperledger kubernetes service`
* `svc-hl-vp1 - vp1 hyperledger  kubernetes service` 
* `svc-hl-vp2 - vp2 hyperledger  kubernetes service`
* `svc-hl-vp3 - vp3 hyperledger  kubernetes service`
* `svc-hl-vp-lb - vp loadbalancer hyperledger  kubernetes service`

The Validating Peer loadbalancer service (svc-hl-vp-lb) provides a way to interact with the fabric via a service loadbalancer instead of directly interacting with any of the peers in the fabric.

The Kubernetes Services provide stable service addresses for the Validating Peer Kubernetes Deployments running behind them.

The following lables have been used in this project :
* `version: "0.6"` to support upgrades
* `environment: development` to support different environments
* `provider: gke` to denote the platform provider
* `city: "melbourne"` to support geographic distributed installations


This project uses `kind: Deployment` Replica Sets to support upgrades moving forward. 

The metadata label : version: `0.6` is to support future upgrades.



## Files Provided

Hyperledger Namespace Manifest File :
* `ns-hl.yml` - hyperledger namespace definition

Kubernetes Services Manifest Files : 
* `svc-hl-vp0..vp3.yml` - Validating Peers Kubernetes Service definition files
* `svc-hl-vp-lb.yml` - Validating Peers Kubernetes Loadbalancer Service definition file

Kubernetes Deployment Manifest Files : 
* `dep-hl-vp0..vp3.yml` - vp0 Kubernetes Deployment definition files

Install/Delete scripts : 
* `hl-install.sh` - Hyperledger create fabric
* `hl-delete.sh` - Hyperledger tear down fabric

CORE_VM_ENDPOINT call back IP update script:
* `svc-hosts.sh` - core-vm-endpoint is not part of the Kubernetes DNS and needs to know the call back IP of the fabric.



## Kubernete Cluster Setup

This guide is build using 
* GKE [Google Container Engine](https://cloud.google.com/container-engine)
* GCE [Google Compute Engine](https://cloud.google.com/compute/)



## Kubernete Project Quotas
Request the following additional quotas:

* Up to 30 In-use IP addresses


### Container Fabric Setup

Sign in to Google Cloud Platform

Create a Project
* `hyperledger`

Setup a GKE (Google Container Engine) cluster with four nodes 

Under the Compute tab..Container Engine
* Create a Container Cluster.
* Give your cluster a meaniful name such as : `hyperledger-cluster`
* Type in a Description : `Development hyperledger cluster`
* Select a zone geographically close to your location to ensure low network latency.
* The default machine type of 1vCPU  and 3.75 GB RAM is sufficient for initial development.
* Consider larger systems if you encounter resource constraints.
* Select `4` under Size, this equates to 4 VM instances.
* One VM Instance (node) for each Validating Peer.

If you have the gcloud already setup you can use the CLI to provision the container cluster with :

`gcloud container clusters create gce-asia-east1 --scopes cloud-platform --zone asia-east1-b --num-nodes 4`

Click on the cluster.

Select Connect to the cluster to get access details.
Copy the value it should be similar to this : 
* `gcloud container clusters get-credentials hyperledger-cluster --zone asia-east1-a --project hyperledger-xxxxxx`

Install gcloud on the linux system you wish to access your cluster from.
* `sudo apt-get -y install python`
* `wget https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-131.0.0-linux-x86_64.tar.gz`
* `sudo apt-get -y install python`
* `tar -zxvf google-cloud-sdk-131.0.0-linux-x86_64.tar.gz`
* `cd google-cloud-sdk`
* .`/install.sh`

Logout and login for profile changes to take effect.

Setup gcloud : 
* `gcloud auth login`
* Enter the verification code
* `gcloud beta auth application-default login`
* `gcloud components install kubectl`
* `gcloud container clusters get-credentials hyperledger-cluster --zone asia-east1-a --project hyperledger-xxxxxx`

Once kubectl is installed use this command to get a list of your nodes `kubectl get nodes`

```
root@ubuntu-512mb-sgp1-01:~# kubectl get nodes
NAME                                                 STATUS    AGE
gke-hyperledger-cluster-default-pool-214902e7-kezx   Ready     2d
gke-hyperledger-cluster-default-pool-214902e7-l6y5   Ready     2d
gke-hyperledger-cluster-default-pool-214902e7-vi6e   Ready     2d
gke-hyperledger-cluster-default-pool-214902e7-vtyp   Ready     2d
```

Label each node to ensure each validating peer runs on a separate node and can tolerate a hardware failure in the fabric.

One Lable on each separate node :
* `node=node-vp0`
* `node=node-vp1`
* `node=node-vp2`
* `node=node-vp3`

Using each node from the kubectl get nodes command above label the nodes on your cluster.

Sample output from kubectl label nodes command.

```
kubectl label nodes gke-hyperledger-cluster-default-pool-214902e7-kezx node=node-vp0
kubectl label nodes gke-hyperledger-cluster-default-pool-214902e7-l6y5 node=node-vp1
kubectl label nodes gke-hyperledger-cluster-default-pool-214902e7-vi6e node=node-vp2
kubectl label nodes gke-hyperledger-cluster-default-pool-214902e7-vtyp node=node-vp3
```

Acces your Kubernetes UI by running these commands

* `kubectl cluster-info` - Get the UI URL
* `kubectl config view` - username and password for UI near the bottom

Note the following values you will need them later for the svc-hosts.sh script :
* project name
* zone 



### CORE_VM_ENDPOINT Setup

Setup a single GCE (Google Compute Engine) instance to run the chain code

This is the CORE_VM_ENDPOINT instance

Under the Compute tab..Compute Engine

* Create Instance
* Instance Name : `core-vm-endpoint`
* Select the same zone as selected above for the hyperledger-cluster cluster.
* The default machine type of 1vCPU  and 3.75 GB RAM is sufficient for initial development.
* Boot Disk :  Ubuntu 16.04 LTS
* Boot Disk Type : Standard Persistent disk
* Size : 20 GB

Install docker on the GCE instance :

Connect to the GCE instance via 
* `gcloud compute --project "hyperledger-xxxxxx" ssh --zone "asia-east1-a" "core-vm-endpoint"`


Use this site for instructions to setup Docker on Ubuntu : 
* https://docs.docker.com/engine/installation/linux/ubuntulinux/

```
sudo apt-get update
sudo apt-get install apt-transport-https ca-certificates
sudo apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
```

`vi /etc/apt/sources.list.d/docker.list`

```
deb https://apt.dockerproject.org/repo ubuntu-xenial main
```

```
sudo apt-get update
sudo apt-get install linux-image-extra-$(uname -r) linux-image-extra-virtual -y
shutdown -r 0
sudo apt-get install docker
systemctl stop docker
```

Edit the docker unit file to start the docker service with : 
* `ExecStart=/usr/bin/docker daemon --api-cors-header="*" -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock`

`vi /lib/systemd/system/docker.service`

```
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network.target docker.socket
Requires=docker.socket

[Service]
Type=notify
# the default is not to use systemd for cgroups because the delegate issues still
# exists and systemd currently does not support the cgroup feature set required
# for containers run by docker
# ExecStart=/usr/bin/docker daemon -H fd://
ExecStart=/usr/bin/docker daemon --api-cors-header="*" -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock
MountFlags=slave
LimitNOFILE=1048576
LimitNPROC=1048576
LimitCORE=infinity
TimeoutStartSec=0
# set delegate yes so that systemd does not reset the cgroups of docker containers
Delegate=yes

[Install]
WantedBy=multi-user.target
```


Start docker on the GCE instance with :

```
systemctl daemon-reload
systemctl start docker.service
```

Check the status of the Docker Service via `systemctl status docker.service`
```
root@core-vm-endpoint:~# systemctl status docker.service
● docker.service - Docker Application Container Engine
   Loaded: loaded (/lib/systemd/system/docker.service; enabled; vendor preset: enabled)
   Active: active (running) since Mon 2016-10-24 01:57:34 UTC; 2 days ago
     Docs: https://docs.docker.com
 Main PID: 5894 (docker)
    Tasks: 27
   Memory: 1.3G
      CPU: 4min 11.995s
   CGroup: /system.slice/docker.service
           ├─5894 /usr/bin/docker daemon --api-cors-header=* -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock
           └─5899 docker-containerd -l /var/run/docker/libcontainerd/docker-containerd.sock --runtime docker-runc --start-timeout 2m

Oct 26 05:00:29 core-vm-endpoint docker[5894]: time="2016-10-26T05:00:29.259277376Z" level=error msg="Handler for DELETE /containers/dev-vp2-95c0c
Oct 26 05:00:29 core-vm-endpoint docker[5894]: time="2016-10-26T05:00:29.321571117Z" level=warning msg="Your kernel does not support swap limit ca
Oct 26 05:00:29 core-vm-endpoint docker[5894]: time="2016-10-26T05:00:29.588258162Z" level=error msg="Handler for POST /containers/dev-vp0-95c0caa
Oct 26 05:00:29 core-vm-endpoint docker[5894]: time="2016-10-26T05:00:29.594690224Z" level=error msg="Handler for POST /containers/dev-vp0-95c0caa
Oct 26 05:00:29 core-vm-endpoint docker[5894]: time="2016-10-26T05:00:29.665574158Z" level=error msg="Handler for POST /containers/dev-vp1-95c0caa
Oct 26 05:00:29 core-vm-endpoint docker[5894]: time="2016-10-26T05:00:29.666538198Z" level=error msg="Handler for DELETE /containers/dev-vp0-95c0c
Oct 26 05:00:29 core-vm-endpoint docker[5894]: time="2016-10-26T05:00:29.667418280Z" level=error msg="Handler for POST /containers/dev-vp1-95c0caa
Oct 26 05:00:29 core-vm-endpoint docker[5894]: time="2016-10-26T05:00:29.669471098Z" level=error msg="Handler for DELETE /containers/dev-vp1-95c0c
Oct 26 05:00:29 core-vm-endpoint docker[5894]: time="2016-10-26T05:00:29.670552788Z" level=warning msg="Your kernel does not support swap limit ca
Oct 26 05:00:29 core-vm-endpoint docker[5894]: time="2016-10-26T05:00:29.673117324Z" level=warning msg="Your kernel does not support swap limit ca
```

If you have trouble starting the Docker process you may have to run `sudo usermod -aG docker $(whoami)`


Pull the required images for the chaincode to execute on CORE_VM_ENDPOINT 
```
docker pull jackyhuang/fabric-baseimage
docker tag jackyhuang/fabric-baseimage:latest hyperledger/fabric-baseimage:latest
```

Check the images are present via docker images : 
```
root@core-vm-endpoint:~# docker images
REPOSITORY                     TAG                 IMAGE ID            CREATED             SIZE
jackyhuang/fabric-peer         latest              1079af7bc4d4        5 weeks ago         1.422 GB
hyperledger/fabric-baseimage   latest              6aaba0c2554b        5 weeks ago         1.365 GB
jackyhuang/fabric-baseimage    latest              6aaba0c2554b        5 weeks ago         1.365 GB
```

This GCE instance becomes the CORE_VM_ENDPOINT to execute chaincode.

Record the Private IP Address of your GCE instance to use with the CORE_VM_ENDPOINT environmental variable.

Use the `ip a` command to get the IP Address of the `ens4` interface.

Once you have cloned the project in the next section update  the CORE_VM_ENDPOINT value pair with the GCE Instance IP address in the following files.
* `dep-hl-vp0.yml`
* `dep-hl-vp1.yml`
* `dep-hl-vp2.yml`
* `dep-hl-vp3.yml`

Sample sed command replace x.x.x.x with your GCE address.
```
sed -i 's|value.*2375"|value: "http://x.x.x.x:2375"|g' *yml
```

Replace this value in the yml files.
```
          - name: CORE_VM_ENDPOINT
            value: "http://x.x.x.x:2375"
```

Place your `ens4` interface value in the x.x.x.x in each file.



## Installation

Go to the system running gcloud and kubectl and clone the OBM-Fabric project.

```
git clone https://github.com/OpenBlockMesh/OBM-Fabric-GKE-HL-v0.6.git
cd OBM-Fabric-GKE-HL-v0.6
chmod +x hl-install.sh hl-delete.sh svc-hosts.sh
```

Edit the `svc-hosts.sh` and update with your "your_project" and "your_zone" details

`vi svc-hosts.sh`

```
gcloud compute --project "your_project" ssh --zone "your_zone" "core-vm-endpoint" "sed -i -e 's|.*svc-.*||g' /etc/hosts"
gcloud compute --project "your_project" copy-files --zone "your_zone" /tmp/svc-hosts core-vm-endpoint:.
gcloud compute --project "your_project" ssh --zone "your_zone" "core-vm-endpoint" "cat svc-hosts >>/etc/hosts"
```



### hl-install.sh

Run `hl-install.sh` to create the hyperledger fabric.

Watch the fabric being built with this command : 
* watch kubectl get --namespace=hyperledger ns,pods,ds,rs,rc,svc

Sample output from `hl-install.sh`

```
Create hyperleder namespace
namespace "hyperledger-06" created
context "gke_ubernetes-144200_asia-east1-a_hyperledger-cluster" set.
Installing Fabric Services
The wait is for GKE to assign EXTERNAL-IP
service "svc-hl-vp0" created
service "svc-hl-vp1" created
service "svc-hl-vp2" created
service "svc-hl-vp3" created
service "svc-hl-vp-lb" created
NAME           CLUSTER-IP       EXTERNAL-IP       PORT(S)                               AGE
svc-hl-vp-lb   10.119.242.101   104.199.236.67    7051/TCP,7052/TCP,7073/TCP,7050/TCP   5m
svc-hl-vp0     10.119.254.28    104.155.205.104   7051/TCP,7052/TCP,7053/TCP,7050/TCP   5m
svc-hl-vp1     10.119.254.203   104.199.229.188   7051/TCP,7052/TCP,7053/TCP,7050/TCP   5m
svc-hl-vp2     10.119.243.126   104.199.221.124   7051/TCP,7052/TCP,7053/TCP,7050/TCP   5m
svc-hl-vp3     10.119.254.59    104.155.235.112   7051/TCP,7052/TCP,7053/TCP,7050/TCP   5m
Installing Validating Peer 0
deployment "dep-pod-hl-vp0" created
Installing Validating Peer 1
deployment "dep-pod-hl-vp1" created
Installing Validating Peer 2
deployment "dep-pod-hl-vp2" created
Installing Validating Peer 3
deployment "dep-pod-hl-vp3" created
svc-hosts                                                                                                       100%  518     0.5KB/s   00:00
Done
```



### hl-delete.sh

Run `hl-delete.sh` to tear down the fabric.

Sample output from `hl-delete.sh`

```
context "gke_ubernetes-144200_asia-east1-a_hyperledger-cluster" set.
Deleting Validating Peer - vp3
deployment "dep-pod-hl-vp3" deleted
Deleting Validating Peer - vp2
deployment "dep-pod-hl-vp2" deleted
Deleting Validating Peer - vp1
deployment "dep-pod-hl-vp1" deleted
Deleting Validating Peer - vp0
deployment "dep-pod-hl-vp0" deleted
Deleting Services
service "svc-hl-vp0" deleted
service "svc-hl-vp1" deleted
service "svc-hl-vp2" deleted
service "svc-hl-vp3" deleted
service "svc-hl-vp-lb" deleted
Deleting hyperleger namespace
namespace "hyperledger-06" deleted
Done
```


Change to `hyperledger-06` namespace
```
export CONTEXT=$(kubectl config view | awk '/current-context/ {print $2}')
kubectl config set-context $CONTEXT --namespace=hyperledger-06
```

## Verify Operation

Obtain the name of a running pod
```
kubectl get pods
```

Exec into the pod (use a pod name from kubectl get pods) 
```
kubectl exec -it dep-pod-hl-vp0-2714057407-02d8h bash -n hyperledger-06
```

Verify that the peer nodes are found via Service Discovery
```
root@dep-pod-hl-vp0-2714057407-02d8h:/opt/gopath/src/github.com/hyperledger/fabric# peer network list
{"Peers":[
{"ID":{"name":"vp1"},"address":"svc-hl-vp1.hyperledger-06.svc.cluster.local:7051","type":1},
{"ID":{"name":"vp2"},"address":"svc-hl-vp2.hyperledger-06.svc.cluster.local:7051","type":1},
{"ID":{"name":"vp3"},"address":"svc-hl-vp3.hyperledger-06.svc.cluster.local:7051","type":1}]}
13:45:07.929 [main] main -> INFO 001 Exiting.....
```

### Deploy Chain Code Example

During `peer chaincode deploy` the chain code is submitted to the ledger in a form of transaction and distributed to all nodes in the network.
Each node creates a new Docker container with this chaincode embedded.
After that container will be started and Init method will be executed.

```
peer chaincode deploy -p github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02 -c '{"Function":"init", "Args": ["a","100", "b", "200"]}'
```

It may take up to a minute for the chain code containers to start on `core-vm-endpoint'

You can check that the chaincode containers are running by `docker ps -a` on the `core-vm-endpoint`

`watch docker ps -a`

Intitial chaincode images will come up

```
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
19804977b0e3        6aaba0c2554b        "/bin/sh -c '#(nop) C"   3 seconds ago       Created                                 dreamy_hamilton
b2ff2470c67e        6aaba0c2554b        "/bin/sh -c '#(nop) C"   4 seconds ago       Created                                 distracted_wilson
4f8946b18d72        6aaba0c2554b        "/bin/sh -c '#(nop) C"   4 seconds ago       Created                                 jovial_jones
f2f47dd45338        6aaba0c2554b        "/bin/sh -c '#(nop) C"   4 seconds ago       Created                                 gloomy_kirch
```

These containers will terminate and be replaced with the following types of containers.

```
CONTAINER ID        IMAGE
             COMMAND                  CREATED             STATUS              PORTS               NAMES
94ced668c6fc        dev-vp1-ee5b24a1f17c356dd5f6e37307922e39ddba12e5d2e203ed93401d7d05eb0dd194fb9070549c5dc31eb63f4e654dbd5a1d86cbb30c48e3ab181259
0cd0f78539   "/opt/gopath/bin/ee5b"   14 seconds ago      Up 13 seconds                           dev-vp1-ee5b24a1f17c356dd5f6e37307922e39ddba12e5
d2e203ed93401d7d05eb0dd194fb9070549c5dc31eb63f4e654dbd5a1d86cbb30c48e3ab1812590cd0f78539
59dd8356bf3e        dev-vp2-ee5b24a1f17c356dd5f6e37307922e39ddba12e5d2e203ed93401d7d05eb0dd194fb9070549c5dc31eb63f4e654dbd5a1d86cbb30c48e3ab181259
0cd0f78539   "/opt/gopath/bin/ee5b"   14 seconds ago      Up 14 seconds                           dev-vp2-ee5b24a1f17c356dd5f6e37307922e39ddba12e5
d2e203ed93401d7d05eb0dd194fb9070549c5dc31eb63f4e654dbd5a1d86cbb30c48e3ab1812590cd0f78539
6dc6fc719086        dev-vp3-ee5b24a1f17c356dd5f6e37307922e39ddba12e5d2e203ed93401d7d05eb0dd194fb9070549c5dc31eb63f4e654dbd5a1d86cbb30c48e3ab181259
0cd0f78539   "/opt/gopath/bin/ee5b"   14 seconds ago      Up 14 seconds                           dev-vp3-ee5b24a1f17c356dd5f6e37307922e39ddba12e5
d2e203ed93401d7d05eb0dd194fb9070549c5dc31eb63f4e654dbd5a1d86cbb30c48e3ab1812590cd0f78539
2da9439f696b        dev-vp0-ee5b24a1f17c356dd5f6e37307922e39ddba12e5d2e203ed93401d7d05eb0dd194fb9070549c5dc31eb63f4e654dbd5a1d86cbb30c48e3ab181259
0cd0f78539   "/opt/gopath/bin/ee5b"   15 seconds ago      Up 15 seconds                           dev-vp0-ee5b24a1f17c356dd5f6e37307922e39ddba12e5
d2e203ed93401d7d05eb0dd194fb9070549c5dc31eb63f4e654dbd5a1d86cbb30c48e3ab1812590cd0f78539
```



### Query Chain Code Example

During “Query” - chain code will read the current state and send it back to user.
This transaction is not saved in blockchain.

```
peer chaincode query -n ee5b24a1f17c356dd5f6e37307922e39ddba12e5d2e203ed93401d7d05eb0dd194fb9070549c5dc31eb63f4e654dbd5a1d86cbb30c48e3ab1812590cd0f78539  -c '{"Function": "query", "Args": ["a"]}'
```

Sample Output

```
21:01:54.733 [chaincodeCmd] chaincodeInvokeOrQuery -> INFO 001 Successfully queried transaction: chaincodeSpec:<type:GOLANG chaincodeID:<name:"ee5b24a1f17c356dd5f6e37307922e39ddba12e5d2e203ed93401d7d05eb0dd194fb9070549c5dc31eb63f4e654dbd5a1d86cbb30c48e3ab1812590cd0f78539" > ctorMsg:<args:"query" args:"a" > >
Query Result: 100
21:01:54.734 [main] main -> INFO 002 Exiting.....
```



## Troubleshooting 

If you experience any issues please check the hosts file on the core-vm-endpoint.

If there was a delay in assigning external IP addresses sometimes there will be "PENDING" entries in the hosts file as opposed to the correct IP entries.

Execute `kubectl get svc -n hyperledger-06` to a list of the correct IP addresses to place in the `/etc/hosts` file



# End of Section

