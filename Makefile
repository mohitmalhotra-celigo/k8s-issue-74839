.PHONY: image

setup:
	go mod init k8s-issue-74839 && go mod tidy

build:
	CGO_ENABLED=0 GOOS=linux go build

image:
	podman build . -t k8s-issue-74839:latest

deploy:
	kubectl apply -f deploy.yaml

clean:
	rm -f k8s-issue-74839
	kubectl delete -f deploy.yaml
	podman rmi k8s-issue-74839:latest