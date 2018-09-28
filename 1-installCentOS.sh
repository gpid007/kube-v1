#!/bin/bash

https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/
https://kubernetes.io/docs/setup/independent/install-kubeadm/

# machines
centos-00   kube-rg-00    10.0.0.4    51.137.104.239
centos-01   kube-rg-00    10.0.0.5    40.114.237.129
centos-02   kube-rg-00    10.0.0.6    13.69.51.94

# Connect ssh
sshpass -p 'xxxxxxxx' ssh greg@51.137.104.239   # centos-00
sshpass -p 'xxxxxxxx' ssh greg@40.114.237.129   # centos-01
sshpass -p 'xxxxxxxx' ssh greg@13.69.51.94      # centos-02

####

# Set .bashrc
cat <<EOF >>~/.bashrc
PS1='\[\033[01;34m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
EOF

#####

sudo -i

# Set .bashrc
cat <<EOF >>~/.bashrc
PS1='\[\e[01;31m\]$PS1\[\e[00m\]'
EOF

cat <<EOF >>/etc/sudoers
greg ALL=(ALL) NOPASSWD: ALL
EOF

####

# Enable bridges
cat <<EOF >>/etc/sysctl.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

# Disable security linux
setenforce 0
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux

# Enable kernel module
modprobe br_netfilter
echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables

# Turn swap off && comment out line including 'swap'
swapoff -a

# Install package dependencies && install docker-ce
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce


# Add the kubernetes repository
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
        https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

# Install kubeadm kubelet kubectl
yum install -y kubelet kubeadm kubectl

# Login and start services
systemctl start docker && systemctl enable docker && reboot



# Start kubelet
systemctl start kubelet && systemctl enable kubelet

# Check driver; must equal 'cgroupfs'
docker info | grep -i cgroup

# Reload systemd system and restart kubelet
systemctl daemon-reload
systemctl restart kubelet


###############
# Master Only #
###############

# CANAL documentation
https://docs.projectcalico.org/v3.1/getting-started/kubernetes/installation/calico
https://docs.projectcalico.org/v2.6/getting-started/kubernetes/installation/hosted/canal/

# Start kube network with CANAL
kubeadm init --pod-network-cidr=10.244.0.0/16 #192.168.0.0/16 calico #10.244.0.0/16 canal

#
echo -e "
Expect return like this to run on workers for joining them:
kube-rg

kubeadm join 10.0.0.4:6443 --token k6mi79.3o3x4oo9nawl6cwx --discovery-token-ca-cert-hash sha256:fd9ca098f382131a746532b17d23ed996a6bfccb2f739a2a490e9f98ea12703b
"

# Create new '.kube' configuration directory and copy configuration 'admin.conf'
mkdir -p $HOME/.kube
cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
# kubectl can be installed on every node with the above saved certificate in $HOME/.kube/config

kubectl apply -f https://docs.projectcalico.org/v3.1/getting-started/kubernetes/installation/hosted/canal/rbac.yaml
kubectl apply -f https://docs.projectcalico.org/v3.1/getting-started/kubernetes/installation/hosted/canal/canal.yaml

# Check config
kubectl get nodes
kubectl get services
kubectl get pods --all-namespaces


################
# Workers Only #
################

# Join workers to master

# kube-rg
kubeadm join 10.0.0.4:6443 --token k6mi79.3o3x4oo9nawl6cwx --discovery-token-ca-cert-hash sha256:fd9ca098f382131a746532b17d23ed996a6bfccb2f739a2a490e9f98ea12703b
# label workers
kubectl label node centos-01 node-role.kubernetes.io/worker=worker
kubectl label node centos-02 node-role.kubernetes.io/worker=worker

#########
# Addon #
#########

# Kubernetes configuration
yum install bash-completion -y
#
cat <<EOF >>~/.bashrc
# Kubernetes completion
alias k='kubectl'
source <(kubectl completion bash)
alias kcd='kubectl config set-context $(kubectl config current-context) --namespace '
EOF



# SETUP MULTI MASTER #

# Setup etcd cluster installing  cfssl and cfssljson
curl -o /usr/local/bin/cfssl https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
curl -o /usr/local/bin/cfssljson https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
chmod +x /usr/local/bin/cfssl*
export PATH=$PATH:/usr/local/bin

# Generate certificates on master-0
mkdir -p /etc/kubernetes/pki/etcd
cd /etc/kubernetes/pki/etcd

# Create configs
cat <<EOF >/etc/kubernetes/pki/etcd/config.json
{
    "signing": {
        "default": {
            "expiry": "43800h"
        },
        "profiles": {
            "server": {
                "expiry": "43800h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth",
                    "client auth"
                ]
            },
            "client": {
                "expiry": "43800h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "client auth"
                ]
            },
            "peer": {
                "expiry": "43800h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth",
                    "client auth"
                ]
            }
        }
    }
}
EOF
#
cat <<EOF >/etc/kubernetes/pki/etcd/ca-csr.json
{
    "CN": "etcd",
    "key": {
        "algo": "rsa",
        "size": 2048
    }
}
EOF
#
cat <<EOF >/etc/kubernetes/pki/etcd/client.json
{
    "CN": "client",
    "key": {
        "algo": "ecdsa",
        "size": 256
    }
}
EOF
#
cfssl gencert -initca ca-csr.json | cfssljson -bare ca -
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client client.json | cfssljson -bare client