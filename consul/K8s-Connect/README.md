# K8s Consul Helm Chart - Consul Connect Demo

## Introduction
This lab is based on the [Connect K8s sidecar](https://www.consul.io/docs/platform/k8s/connect.html) content available from HashiCorp. In this example we will configure a basic server and client, and show mutual authentication between services. This lab is run using Minikube with [Consul Helm](https://gist.github.com/anubhavmishra/0877081b43ca9d0353e547da05ec2e3f) chart instructions.

## Steps
1. Deploy K8s Consul Helm chart

```
./minikube-consul-helm.sh
```

2. Deploy our application

```
kubectl apply -f server.yml
kubectl apply -f client.yml
```

3. Test our service

```
kubectl exec static-client -c static-client -- curl -s http://127.0.0.1:1234/
"hello world"
```

4. Add a Consul intention to deny the service. 

  From UI:
```
minikube service consul-minikube-ui
```
  From CLI:
```
kubectl exec consul-minikube-server-0 consul intention create -deny static-client static-server
```

5. Test our service again

```
kubectl exec static-client -- curl -s http://127.0.0.1:1234/
command terminated with exit code 52
```

6. Clean-up

```
minikube delete
```
