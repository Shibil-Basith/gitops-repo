# Sock Shop GitOps Deployment

A complete GitOps deployment of the [Weaveworks Sock Shop](https://microservices-demo.github.io/) microservices demo using **Helm Charts** and **ArgoCD**.

## Architecture

```
sock-shop-gitops/
├── argocd/                    # ArgoCD bootstrap & AppProject
│   ├── namespace.yaml
│   ├── appproject.yaml
│   └── app-of-apps.yaml       # App of Apps pattern
├── apps/                      # ArgoCD Application manifests (one per service)
│   ├── front-end.yaml
│   ├── catalogue.yaml
│   ├── catalogue-db.yaml
│   ├── carts.yaml
│   ├── carts-db.yaml
│   ├── orders.yaml
│   ├── orders-db.yaml
│   ├── shipping.yaml
│   ├── payment.yaml
│   ├── user.yaml
│   ├── user-db.yaml
│   ├── queue-master.yaml
│   ├── rabbitmq.yaml
│   └── session-db.yaml
└── charts/                    # Individual Helm charts per microservice
    ├── front-end/
    ├── catalogue/
    ├── catalogue-db/
    ├── carts/
    ├── carts-db/
    ├── orders/
    ├── orders-db/
    ├── shipping/
    ├── payment/
    ├── user/
    ├── user-db/
    ├── queue-master/
    ├── rabbitmq/
    └── session-db/
```

## Microservices

| Service        | Language   | Port  | Description                    |
|---------------|------------|-------|-------------------------------|
| front-end      | Node.js    | 8079  | Web UI                        |
| catalogue      | Go         | 80    | Product catalogue API          |
| catalogue-db   | MySQL      | 3306  | Catalogue database             |
| carts          | Java       | 80    | Shopping cart service          |
| carts-db       | MongoDB    | 27017 | Cart database                  |
| orders         | Java       | 80    | Order service                  |
| orders-db      | MongoDB    | 27017 | Orders database                |
| shipping       | Java       | 80    | Shipping service               |
| payment        | Go         | 80    | Payment service                |
| user           | Go         | 80    | User management service        |
| user-db        | MongoDB    | 27017 | User database                  |
| queue-master   | Java       | 80    | Queue consumer                 |
| rabbitmq       | RabbitMQ   | 5672  | Message queue                  |
| session-db     | Redis      | 6379  | Session store                  |

## Prerequisites

- Kubernetes cluster (v1.24+)
- ArgoCD installed (`kubectl create namespace argocd && kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml`)
- Helm 3.x
- kubectl configured

## Quick Start

### 1. Bootstrap ArgoCD Namespace & Project

```bash
kubectl apply -f argocd/namespace.yaml
kubectl apply -f argocd/appproject.yaml
```

### 2. Deploy App of Apps

```bash
kubectl apply -f argocd/app-of-apps.yaml
```

This will trigger ArgoCD to deploy all microservice Applications automatically.

### 3. Access the UI

```bash
# Port-forward the front-end
kubectl port-forward svc/front-end 8080:80 -n sock-shop

# Or get the LoadBalancer IP
kubectl get svc front-end -n sock-shop
```

### 4. Access ArgoCD UI

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Default admin password:
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## GitOps Workflow

1. Make changes to values in `charts/<service>/values.yaml`
2. Commit and push to Git
3. ArgoCD detects drift and syncs automatically (or manually via UI/CLI)

## Manual Helm Install (without ArgoCD)

```bash
kubectl create namespace sock-shop

for chart in charts/*/; do
  name=$(basename $chart)
  helm upgrade --install $name $chart -n sock-shop
done
```
