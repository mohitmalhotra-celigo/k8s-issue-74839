# Reproduction of k8s issue #74839

## How to rename image name in project ?

Replace the image name incase you want to use ECR or some other registry. Search for `k8s-issue-74839:latest`, and replace it
using some IDE

**OR**

Use following command

MacOS
```console
find . -type f \( -name "*.yaml" -o -name "*.yml" -o -name "*.sh" -o -name "*.go" -o -name "Makefile" \) -exec sed -i '' 's/k8s-issue-74839:latest/<image-name:tag>/g' {} +
```
Linux
```console
find . -type f \( -name "*.yaml" -o -name "*.yml" -o -name "*.sh" -o -name "*.go" -o -name "Makefile" \) -exec sed -i 's/k8s-issue-74839:latest/<image-name:tag>/g' {} +
```

Verify once after running the commands above for the desired changes.

---

## How to build the image ?

Docker
```console
docker build . -t <image-name:tag>
```
Podman
```console
podman build . -t <image-name:tag>
```

OR 

use Makefile after replacing image name
```
make image
```

Later push this image to any artifactory like ECR or docker registry from where nodes
can access this image.

## How to deploy ?

1. Create a cluster with at least 2 nodes.
1. Deploy the app.
```console
kubectl apply -f deploy.yaml
```

OR

```console
make deploy
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

---

## How to setup locally ?

Use the setup script in order to deploy K8S components using MiniKube.
Script adds dependencies necessary to run it locally such as kubectl, minikube and go.
Current script use podman as default driver for setup. 

```console
./setup.sh
```

## FAQ

**What if boom-server fails in local setup with Minikube ?**

Script will create 3 node cluster, hence ensure custom images are properly available on each node.
Manual fix is available below
```console
podman save <image-name:tag> | minikube image load -
```

**How to build binary from Go code locally ?**

You can also locally build the binary from Go source code
1. Install golang latest version
2. Install deps and build with following commands
```console
make setup
make build
```

---

## Reference

Repository is forked from : https://github.com/kubernetes/kubernetes/issues/74839


