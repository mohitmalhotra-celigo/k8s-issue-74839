# Reproduction of k8s issue #74839

## How to deploy ?

1. Create a cluster with at least 2 nodes.
1. Deploy the app.
```console
kubectl apply -f deploy.yaml
```

1. Check if the server crashed
```console
$ kubectl get pods
NAME                           READY   STATUS             RESTARTS   AGE
boom-server-59945555cd-8rwqk   0/1     CrashLoopBackOff   4          2m
startup-script                 1/1     Running            0          2m
```

**Note : Replace the image name incase you want to use ECR or some other registry as images needs to be
available on different nodes.**

## How to setup locally ?

Use the setup script in order to deploy K8S components using MiniKube.
Script adds dependencies necessary to run it locally such as kubectl, minikube and go.

```console
./setup.sh
```

## Reference

Repository is forked from : https://github.com/kubernetes/kubernetes/issues/74839


