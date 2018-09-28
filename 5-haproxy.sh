# source #1
https://kubernetes.io/docs/setup/independent/high-availability/

cat <<EOF >kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1alpha2
kind: MasterConfiguration
kubernetesVersion: v1.11.x
apiServerCertSANs:
- "LOAD_BALANCER_DNS"
api:
    controlPlaneEndpoint: "LOAD_BALANCER_DNS:LOAD_BALANCER_PORT"
etcd:
  local:
    extraArgs:
      listen-client-urls: "https://127.0.0.1:2379,https://CP0_IP:2379"
      advertise-client-urls: "https://CP0_IP:2379"
      listen-peer-urls: "https://CP0_IP:2380"
      initial-advertise-peer-urls: "https://CP0_IP:2380"
      initial-cluster: "CP0_HOSTNAME=https://CP0_IP:2380"
    serverCertSANs:
      - CP0_HOSTNAME
      - CP0_IP
    peerCertSANs:
      - CP0_HOSTNAME
      - CP0_IP
networking:
    # This CIDR is a Calico default. Substitute or remove for your CNI provider.
    podSubnet: "192.168.0.0/16"
EOF


########################################################################
# Install and configure a multi-master Kubernetes cluster with kubeadm #
########################################################################

# source
https://blog.inkubate.io/install-and-configure-a-multi-master-kubernetes-cluster-with-kubeadm/


# ssh to host
sshpass -p 'AAasdf5asdf5' ssh greg@51.144.86.207    # master-01
sshpass -p 'AAasdf5asdf5' ssh greg@52.136.224.232   # master-02
sshpass -p 'AAasdf5asdf5' ssh greg@23.97.217.247    # centos-load-balancer

# dowload packages
wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64

# run and move
chmod +x cfssl*
mv cfssl_linux-amd64 /usr/local/bin/cfssl
mv cfssljson_linux-amd64 /usr/local/bin/cfssljson

# add alias
cat <<EOF >>~/.bashrc
# set cfssl alias
alias cfssl='/usr/local/bin/cfssl'
EOF

# check version
cfssl version

# Kubernetes configuration
yum install bash-completion -y
cat <<EOF >>~/.bashrc
# Kubernetes completion
alias k='kubectl'
source <(kubectl completion bash)
alias kcd='kubectl config set-context $(kubectl config current-context) --namespace '
EOF

# install HAProxy
yum install -y haproxy

# change haproxy config
cat <<EOF >> /etc/haproxy/haproxy.cfg
# --------------------------------------------------------------------
# kubernetes config
# --------------------------------------------------------------------
frontend kubernetes
    bind 10.10.40.93:6443
    option tcplog
    mode tcp
    default_backend kubernetes-master-nodes

backend kubernetes-master-nodes
    mode tcp
    balance roundrobin
    option tcp-check
    server k8s-master-0 10.10.40.90:6443 check fall 3 rise 2
    server k8s-master-1 10.10.40.91:6443 check fall 3 rise 2
    server k8s-master-2 10.10.40.92:6443 check fall 3 rise 2

EOF

# create certificate authority config
cat <<EOF >ca-config.json
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
}
EOF

# create certificate authority sign request config
cat <<EOF >ca-csr.json
{
  "CN": "Kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
  {
    "C": "IE",
    "L": "Cork",
    "O": "Kubernetes",
    "OU": "CA",
    "ST": "Cork Co."
  }
 ]
}
EOF

# generate the certificate authority certificate and private key
cfssl gencert -initca ca-csr.json | cfssljson -bare ca

# create the certificate signing request configuration file
cat <<EOF >kubernetes-csr.json
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
  {
    "C": "IE",
    "L": "Cork",
    "O": "Kubernetes",
    "OU": "Kubernetes",
    "ST": "Cork Co."
  }
 ]
}
EOF

# generate the certificate and private key
cfssl gencert \
    -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -hostname=10.10.40.90,10.10.40.91,10.10.40.92,10.10.40.93,127.0.0.1,kubernetes.default \
    -profile=kubernetes kubernetes-csr.json | \
    cfssljson -bare kubernetes

# copy certificate to other nodes
scp ca.pem kubernetes.pem kubernetes-key.pem sguyennet@10.10.40.90:~
scp ca.pem kubernetes.pem kubernetes-key.pem sguyennet@10.10.40.91:~
scp ca.pem kubernetes.pem kubernetes-key.pem sguyennet@10.10.40.92:~
scp ca.pem kubernetes.pem kubernetes-key.pem sguyennet@10.10.40.100:~
scp ca.pem kubernetes.pem kubernetes-key.pem sguyennet@10.10.40.101:~
scp ca.pem kubernetes.pem kubernetes-key.pem sguyennet@10.10.40.102:~








########################################################################




# sources
# https://itnext.io/cluster-recipe-external-proxy-for-kubernetes-ingress-or-docker-compose-ingress-with-haproxy-on-f81e3adee5ef

# katacoda
https://www.katacoda.com/courses/kubernetes/playground

# installing kops
https://kubernetes.io/docs/setup/custom-cloud/kops/

# az documentation for zone creation
https://docs.microsoft.com/en-us/cli/azure/network/dns/zone?view=azure-cli-latest
https://docs.microsoft.com/en-us/cli/azure/storage/container?view=azure-cli-latest#az-storage-container-create

# get and install kops
wget https://github.com/kubernetes/kops/releases/download/1.10.0/kops-linux-amd64
chmod +x kops-linux-amd64
mv kops-linux-amd64 /usr/local/bin/kops

cat <<EOF >>~/.bashrc
# Kubernetes ops
alias kops='/usr/local/bin/kops'
EOF

# leave
exit


# Azure commands for dns zone creation (domain name)
ZUSER='z170901@bcc.oebb.at'
ZPASS='ASDF5asdf5'
ACCOUNT='UI_B2B' # "UI_AAM"

RES_GROUP='kube-rg'
DNS_ZONE='www.kube-dns.com'

az login -u $ZUSER -p $ZPASS
az account set -s $ACCOUNT

# In DNS speak, a label is an identifier.
# So for www.example.org the labels are: www example org
az network dns zone create \
    -n $DNS_ZONE \
    -g $RES_GROUP
#   --resource-group -g
#   --name -n
#    [--if-none-match]
#    [--registration-vnets]
#    [--resolution-vnets]
#    [--tags]
#    [--zone-type]




# now check setup with dig
dig NS www.kube-dns.com

# create s3 storage container
# az storage container create \
#     --name kube-s3-store
#     [--account-key]
#     [--account-name]
#     [--connection-string]
#     [--fail-on-exist]
#     [--metadata]
#     [--public-access {blob, container, off}]
#     [--sas-token]
#     [--timeout]

