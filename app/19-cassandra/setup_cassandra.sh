#!/bin/sh

kubectl apply -f /root/app/19-cassandra/crds.yaml

kubectl apply -f /root/app/19-cassandra/bundle.yaml

kubectl apply -f /root/app/19-cassandra/cluster.yaml