FROM golang:1.23-bookworm as builder

WORKDIR /app

COPY . .
RUN make setup
RUN make build

FROM ubuntu:22.04
COPY --from=builder /app/k8s-issue-74839 /
RUN chmod +x /k8s-issue-74839

ENTRYPOINT ["/k8s-issue-74839"]

