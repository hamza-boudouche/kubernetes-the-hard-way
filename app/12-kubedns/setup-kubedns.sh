#!/bin/bash

kubectl create -f /root/kubedns.yml

kubectl get pods -l k8s-app=kube-dns -n kube-system