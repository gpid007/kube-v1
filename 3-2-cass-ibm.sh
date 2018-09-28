#!/bin/bash

sshpass -p 'xxxxxxx' ssh greg@13.80.135.169


# source
https://github.com/IBM/Scalable-Cassandra-deployment-on-Kubernetes
https://cloud.google.com/kubernetes-engine/docs/concepts/persistent-volumes


# make directory
sudo -i
mkdir cassandra
cd cassandra


# cassandra service yaml
cat <<EOF >cassandra-service.yaml
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: cassandra
  name: cassandra
spec:
  clusterIP: None
  ports:
    - port: 9042
  selector:
    app: cassandra
EOF

kubectl create -f cassandra-service.yaml
kubectl get svc cassandra


# persistent volumes yaml
cat <<EOF >local-volumes.yaml
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-cassandra-00
  labels:
    type: local
    app: cassandra
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /tmp/data/pv-cassandra-00
  persistentVolumeReclaimPolicy: Retain
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-cassandra-01
  labels:
    type: local
    app: cassandra
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /tmp/data/pv-cassandra-01
  persistentVolumeReclaimPolicy: Retain
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-cassandra-02
  labels:
    type: local
    app: cassandra
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /tmp/data/pv-cassandra-02
  persistentVolumeReclaimPolicy: Retain
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-cassandra-03
  labels:
    type: local
    app: cassandra
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /tmp/data/pv-cassandra-03
  persistentVolumeReclaimPolicy: Retain
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-cassandra-04
  labels:
    type: local
    app: cassandra
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /tmp/data/pv-cassandra-04
  persistentVolumeReclaimPolicy: Retain
EOF

kubectl create -f local-volumes.yaml


# stateful service expanded
# value: "{{- range $i, $e := until $seed_size }}{{ template "cassandra.fullname" $global }}-{{ $i }}.{{ template "cassandra.fullname" $global }}.{{ $global.Release.Namespace }}.svc.cluster.local,{{- end }}"
# value: cassandra-0.cassandra.default.svc.cluster.local
cat <<EOF >cassandra-statefulset.yaml
---
apiVersion: "apps/v1beta1"
kind: StatefulSet
metadata:
  name: cassandra
spec:
  serviceName: cassandra
  replicas: 1
  template:
    metadata:
      labels:
        app: cassandra
    spec:
      containers:
        - name: cassandra
          image: cassandra:3.11
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 7000
              name: intra-node
            - containerPort: 7001
              name: tls-intra-node
            - containerPort: 7199
              name: jmx
            - containerPort: 9042
              name: cql
          env:
            - name: CASSANDRA_SEEDS
              value: cassandra-0.cassandra.default.svc.cluster.local
            - name: MAX_HEAP_SIZE
              value: 256M
            - name: HEAP_NEWSIZE
              value: 100M
            - name: CASSANDRA_CLUSTER_NAME
              value: "Cassandra"
            - name: CASSANDRA_DC
              value: "DC1"
            - name: CASSANDRA_RACK
              value: "Rack1"
            - name: CASSANDRA_ENDPOINT_SNITCH
              value: GossipingPropertyFileSnitch
          volumeMounts:
            - name: pv-cassandra
              mountPath: /var/lib/cassandra/data
  volumeClaimTemplates:
    - metadata:
        name: pv-cassandra
        annotations:  # comment line if you want to use a StorageClass
          # or specify which StorageClass
          volume.beta.kubernetes.io/storage-class: ""   # comment line if you
          # want to use a StorageClass or specify which StorageClass
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 1Gi
EOF

kubectl create -f cassandra-statefulset.yaml


# check status
kubectl get statefulsets
kubectl get sts
kubectl get pods

kubectl get pods -o wide
kubectl exec -ti cassandra-0 -- nodetool status

# scaling
kubectl scale --replicas=5 statefulset/cassandra
kubectl get statefulsets --watch

# kubectl exec cqlsh
kubectl exec -ti cassandra-0 -- nodetool status

kubectl exec -it cassandra-0 cqlsh cassandra-0

cat <<EOF >CQL-commands.sql
CREATE KEYSPACE "ks_one" WITH REPLICATION = {
    'class': 'NetworkTopologyStrategy',
    'DC1': 3  -- use datacenter name from nodetool status and integer for replication factor
};

CREATE TABLE ks_one.t_one (
    c_int int,
    c_text text,
    PRIMARY KEY (c_int)
);

insert into
    ks_one.t_one (c_int, c_text)
    values (1, 'one')
;

insert into
    ks_one.t_one (c_int, c_text)
    values (2, 'two')
;

insert into
    ks_one.t_one (c_int, c_text)
    values (3, 'three')
;

select * from ks_one.t_one;
EOF

# stopping and deleting
kubectl get nodes
kubectl get namespaces
kubectl get pods
kubectl get services
kubectl get statefulsets
kubectl get pv

kubectl delete -f <file.yaml>
kubectl delete statefulsets <statefulset-name>
kubectl delete service cassandra
kubectl delete pods cassandra-1 cassandra-2 cassandra-3 cassandra-4

kubectl create -f persistentVolume.yaml
kubectl get pv task-pv-volume
kubectl delete pv task-pv-volume

# create new pod
kubectl run -it --rm --restart=Never busybox --image=busybox sh


kubectl create -f cassandra-statefulset; sleep 480; kubectl scale --replicas=2 statefulset/cassandra; sleep 480; kubectl scale --replicas=3 statefulset/cassandra;