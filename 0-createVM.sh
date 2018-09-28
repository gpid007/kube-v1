#!/bin/bash
https://docs.microsoft.com/en-us/azure/networking/scripts/load-balancer-linux-cli-sample-nlb
https://docs.microsoft.com/en-us/cli/azure/vm?view=azure-cli-latest#az-vm-resize
https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt?view=azure-cli-latest


# account var
ACCOUNT='UI_B2B' # "UI_AAM"
az login
az account set -s $ACCOUNT


# resource group var
RG='kube-rg-00'
LOC='westeurope'

# vnet var
VNET_NAME='kube-vnet'
SUBNET_NAME='kube-subnet'

# ip var
PUB_IP_NAME='kube-public-ip-0'
PRV_IP_NAME='kube-private-ip-0'
DNS_NAME='kube-dns-0'

# probe var
PROBE_NAME='kube-probe'

# rule var
RULE_NAME='kube-rule'

# load balancer var
LB_NAME='kube-lb'
FRONT_POOL='kube-front'
BACK_POOL='kube-pool'

# network interface var
NIC_NAME='kube-nic-0'

# availability set var
AV_SET='kube-av'

# VM var
NVM=5 # number of vms including zero
VM_NAME='centos-0'
IMAGE='OpenLogic:CentOS:7.5:latest' #'Canonical:UbuntuServer:16.04-LTS:latest' #OpenLogic:CentOS:7.5:7.5.20180626
SIZE='Standard_B4ms' #'Standard_B2ms' #'Standard_B4ms' #'Standard_DS2_v2'
USER_NAME='greg'
USER_PASS='AAasdf5asdf5' #12 char


# create resource group
az group create \
    --name $RG \
    --location $LOC

# create vnet
az network vnet create \
    --resource-group $RG \
    --name $VNET_NAME \
    --location $LOC \
    --subnet-name $SUBNET_NAME

# create public IP
for i in `seq 0 $(( NVM + 1 ))`; do
az network public-ip create \
    --resource-group $RG \
    --name $PUB_IP_NAME$i \
    --dns-name $DNS_NAME$i
done

# create load balancer
az network lb create \
    --resource-group $RG \
    --name $LB_NAME \
    --vnet-name $VNET_NAME \
    --frontend-ip-name $FRONT_POOL \
    --backend-pool-name $BACK_POOL \
    --public-ip-address $PUB_IP_NAME \
    --private-ip-address $PRV_IP_NAME

# create lb probe
az network lb probe create \
    --resource-group $RG \
    --lb-name $LB_NAME \
    --name $PROBE_NAME \
    --protocol tcp \
    --port 80

# create lb rule
az network lb rule create \
    --resource-group $RG \
    --lb-name $LB_NAME \
    --name $RULE_NAME \
    --protocol tcp \
    --frontend-port 80 \
    --backend-port 80 \
    --frontend-ip-name $FRONT_POOL \
    --backend-pool-name $BACK_POOL \
    --probe-name $PROBE_NAME \
    --public-ip-address $PUB_IP_NAME

# create network cards
for i in `seq 0 $NVM`; do
az network nic create \
    --resource-group $RG \
    --name $NIC_NAME$i \
    --vnet-name $VNET_NAME \
    --subnet $SUBNET_NAME \
    --lb-name $LB_NAME \
    --lb-address-pools $BACK_POOL
done

# create availability set
az vm availability-set create \
    --resource-group $RG \
    --name $AV_SET


# create VM
for i in `seq 0 $NVM`; do
    echo -e "\n\t Creating $VM_NAME$i"
    az vm create \
        --resource-group $RG \
        --name $VM_NAME$i \
        --image $IMAGE \
        --size $SIZE \
        --admin-username $USER_NAME \
        --admin-password $USER_PASS \
        --authentication-type password
done

#         --nics $NIC_NAME$i \
#         --availability-set $AV_SET \
#         --public-ip-address $XXXX
# done

# show results
az network lb show \
    --name $LB_NAME \
    --resource-group $RG


## EOF ##


# source
https://github.com/kubernetes-incubator/kubespray
https://kubernetes.io/docs/setup/independent/high-availability/
https://docs.ansible.com/ansible/2.5/user_guide/intro_getting_started.html
https://docs.microsoft.com/en-us/azure/load-balancer/load-balancer-get-started-ilb-arm-cli



PROBE_NAME='kube-probe'
RULE_NAME='kube-rule-00'

az network public-ip create \
    --resource-group $RG \
    --name $LB_NAME'-ip'


# create probe
az network lb probe create \
    --resource-group $RG \
    --lb-name $LB_NAME \
    --name $PROBE_NAME \
    --protocol tcp \
    --port 80

# create rule
az network lb rule create \
    --resource-group $RG \
    --lb-name $LB_NAME \
    --name 'kube-master' \
    --protocol tcp \
    --frontend-port 6443 \
    --backend-port 6443 \
    --frontend-ip-name $FRONT_POOL \
    --backend-pool-name $BACK_POOL \
    --probe-name $PROBE_NAME

# create network interface
az network nic create \
    --resource-group $RG \
    --name $NIC \
    --vnet-name $VNET_NAME \
    --subnet $SUBNET_NAME \
    --lb-name $LB_NAME \
    --lb-address-pools $FRONT_IP

# show config
az network lb show \
    --name $LB_NAME \
    --resource-group $RG




# Show disk space
for i in `seq 0 2`; do
    echo "$RG $VM_NAME$i"
    az disk show --resource-group $RG --name $VM_NAME$i
    sleep 3
done



# Attach disk space
DISK_NAME='myDataDisk'

for i in `seq 0 2`; do
    az vm disk attach \
        -g $RG \
        --vm-name $VM_NAME$i \
        --disk $DISK_NAME \
        --new \
        --size-gb 50
        sleep 3
done



# Show VM locations, distros, sizes
az account list-locations
az vm list-sizes --location $LOC --output table
az vm image list --offer $DISTRO --publisher $PUBLISHER --all --output table
az vm list-sizes --location $LOC --output table

# Delete resource group
az group delete --name $RG --yes --no-wait


# Get VM info
az vm list
az vm list-usage --location $LOC
az vm show --resource-group $RG --name $VM_NAME


# Create individual machine
MY_NAME='centos-0X'
az vm create \
    --resource-group $RG \
    --name $MY_NAME \
    --image $IMAGE \
    --size $SIZE \
    --admin-username $USER_NAME \
    --admin-password $USER_PASS \
    --authentication-type password

