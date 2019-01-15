# K8s Consul Helm Chart - Consul Connect Demo

## Introduction
This lab is based on the [Connect K8s sidecar](https://www.consul.io/docs/platform/k8s/connect.html) content available from HashiCorp. In this example we will configure a basic server and client, and show mutual authentication between services. 

## Steps
1. Deploy K8s Consul Helm chart

```
./gke-consul-helm.sh
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

4. Add a Consul intention to deny (and delete) the service. 

* from CLI:
```
kubectl exec consul-helm-server-0 -- consul intention create -deny static-client static-server
```
```
kubectl exec consul-helm-server-0 -- consul intention delete static-client static-server
```

5. Test our service again

```
kubectl exec static-client -- curl -s http://127.0.0.1:1234/
command terminated with exit code 52
```

6. Optional - check the container environment variables set by injector

```
kubectl exec -it static-client -- printenv | grep STATIC_SERVER
```

7. Clean-up Helm Chart

```
helm delete --purge consul-helm
``
