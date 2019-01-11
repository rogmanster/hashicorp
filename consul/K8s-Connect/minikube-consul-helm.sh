#!/bin/bash
#Run script start minikube and consul helm chart
#Clean up running 'minikube delete'

#Start Minikube
minikube start

#Init Helm
helm init

#wait for helm to be ready
sleep 30

#Add our admin
kubectl create clusterrolebinding add-on-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:default

#Get the chart
#git clone https://github.com/hashicorp/consul-helm.git

#Install the chart
helm install -f values.yaml ./consul-helm --name consul-minikube

#wait for helm chart to be ready
sleep 10

#Apply patch to remove Consul stateful set requirement
kubectl patch statefulset.apps consul-minikube-server --patch '{"spec":{"template":{"spec":{"affinity":null}}}}'
kubectl delete pod -l "app=consul" -l "component=server"
kubectl delete pod -l "app=consul" -l "component=client"

#wait for ui to be ready
sleep 40

#Start minikube ui
minikube service consul-minikube-ui
