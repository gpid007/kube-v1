#!/bin/bash

# source
https://github.com/NetAppEMEA/kubernetes-netapp/tree/master/spark-s3
https://github.com/eBay/Kubernetes/tree/master/examples/spark
https://github.com/eBay/Kubernetes/tree/master/docs/getting-started-guides#on-premises-vms

# explanation
http://www.noqcks.io/notes/2018/02/03/understanding-kubernetes-resources/

# global setup
SPARK_DIR='/root/spark/'
cd $SPARK_DIR


# replication controller
cat <<EOF >spark-master-controller.yaml
kind: ReplicationController
apiVersion: v1
metadata:
  name: spark-master-controller
spec:
  replicas: 1
  selector:
    component: spark-master
  template:
    metadata:
      labels:
        component: spark-master
    spec:
      containers:
        - name: spark-master
          image: gcr.io/google_containers/spark-master:1.5.1_v2
          ports:
            - containerPort: 7077
            - containerPort: 8080
          resources:
            requests:
              cpu: 100m
EOF

kubectl create -f spark-master-controller.yaml


# stateless service
cat <<EOF >spark-master-service.yaml
kind: Service
apiVersion: v1
metadata:
  name: spark-master
spec:
  ports:
    - port: 7077
      targetPort: 7077
  selector:
    component: spark-master
EOF

kubectl create -f spark-master-service.yaml

# check state
kubectl get pods
kubectl logs spark-master-controller-wcv8d
kubectl exec spark-master-controller-wcv8d -it spark-shell


# declare workers cpu: 100m = 100 milli cores = 10% per CPU
cat <<EOF >spark-worker-controller.yaml
kind: ReplicationController
apiVersion: v1
metadata:
  name: spark-worker-controller
spec:
  replicas: 3
  selector:
    component: spark-worker
  template:
    metadata:
      labels:
        component: spark-worker
    spec:
      containers:
        - name: spark-worker
          image: gcr.io/google_containers/spark-worker:1.5.1_v2
          ports:
            - containerPort: 8081
          resources:
            requests:
              cpu: 100m
EOF

kubectl create -f spark-worker-controller.yaml

# start spark shell
kubectl exec spark-master-controller-j6x9n -it spark-shell

var myVar : Int = 0;

