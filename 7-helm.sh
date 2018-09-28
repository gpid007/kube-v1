#!/bin/bash

# source
https://docs.helm.sh/using_helm/#installing-helm
https://www.digitalocean.com/community/tutorials/how-to-install-software-on-kubernetes-clusters-with-the-helm-package-manager
https://github.com/fnproject/fn-helm/issues/21

# download
wget https://storage.googleapis.com/kubernetes-helm/helm-v2.10.0-linux-amd64.tar.gz
tar -zxvf helm*
mv linux-*/helm /usr/local/bin/helm

# add alias
cat <<EOF >>.bashrc
alias helm='/usr/local/bin/helm'
EOF

# create tiller service account
kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'

# initialize helm
helm init --service-account tiller
helm install stable/kubernetes-dashboard --name dashboard-demo

# helm check
helm list
kubectl get services





git clone https://github.com/MySocialApp/kubernetes-helm-chart-cassandra

