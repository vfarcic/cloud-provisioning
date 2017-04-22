# Terraform - Azure

Based on the "Docker for Azure" configuration, as can be seen at [ACS Engine](https://github.com/Azure/acs-engine).

ACS stands Azure Container Services, and just another name for Azure for Docker.

The ACS setup is a bit of a straitjacket.
You're stuck with the configuration of the ACS blueprint, and the manager vm size is fixed to a D2.

Thats why there's this separate configuration, it requires more manual work but can be tuned in detail.

## Scripts

I have not found the time yet to embed the docker swarm initialization into a extension script.

So for now the following steps still have to be performed:

* adjust the variables to your taste
* create the infrastructure with terraform
* add your key location to the deploy-swarmmode.sh
* add the loadbalancer ip to the deploy-swarmmode.sh
* configure the loadbalancer: azurerm in terraform doesn't provide the ability to create the loadbalance rules or properly configure the backendpool sets
* run deploy-swarmmode.sh

## Configure the loadbalancer

The things we need to configure:

* Add VM's to the BackendPool configurations
* Add Load Balancer Rules for port forwarding to these backend pools

This requires a bit of clicking in the Azure portal, but can be done quickly.


#### BackendPool AVSET

Go to the Load Balancer and open the Backend Pools.

This pool is for rules such as port 443, for any docker (swarm) service.

* **Associate** with **Availability Set**, and select **drovetfavset**
* Add each VM with its primary NIC (they should only have one)

#### BackendPool Manager1

Go to the Load Balancer and open the Backend Pools.

This pool is for being able to connect to the Manager1 VM with SSH.

Assuming you've configured the AVSET backendpool above, the Load Balancer should already be associated with the AVSET.

* Add the Manager1 VM

#### Load Balance Rule 443
 
Go to the Load Balancer and open the Load balancing rules.

* Create new rule 
* Enter name LBRule443
* Port: 443
* Backend port: 443
* Backend pool: LBBackendPoolAVSET
* Health probe: LBProbe443
* Session persistence: none

#### Load Balance Rule 22
 
Go to the Load Balancer and open the Load balancing rules.

* Create new rule 
* Enter name LBRule22
* Port: 2200
* Backend port: 22
* Backend pool: LBBackendPoolManager1
* Health probe: LBProve22
* Session persistence: none