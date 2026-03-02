# 🚀 GitOps Kubernetes Platform on AWS

This project demonstrates a complete **GitOps-based Kubernetes platform** deployed on AWS using ArgoCD, Helm, and lightweight observability tools.
It showcases automated deployments, infrastructure reproducibility, and monitoring in a real cloud environment.

---

## 🧭 Project Overview

The platform implements a modern DevOps workflow where:

* GitHub acts as the **single source of truth**
* ArgoCD continuously syncs cluster state with Git
* Applications are deployed using Helm charts
* Monitoring is enabled via Prometheus + Grafana
* Everything runs on an AWS EC2-hosted Kubernetes cluster

This setup reflects real-world production patterns used in cloud-native infrastructure.

---

## 🏗️ Architecture Components

### ☁️ Infrastructure

* AWS EC2 instance hosting Kubernetes cluster (K3s)
* Public access for dashboards and services
* Persistent storage and networking configured

### 🔄 GitOps Engine

* ArgoCD for declarative deployments
* Auto-sync enabled with self-healing
* All application configs stored in Git

### 📦 Application Deployment

* Sample containerized application deployed via Helm
* Version-controlled manifests
* Automatic rollout on Git updates

### 📊 Monitoring Stack

* Prometheus for metrics collection
* Grafana for dashboards and visualization
* NodePort exposure for remote access

---

## 📁 Repository Structure

```
gitops-repo/
│
├── sample-app/              # Example application Helm manifests
├── lightweight-monitoring/  # Monitoring configuration
├── prometheus-app.yaml      # ArgoCD app for Prometheus
├── grafana-app.yaml         # ArgoCD app for Grafana
└── README.md
```

---

## ⚙️ Deployment Workflow

1. Push configuration changes to GitHub
2. ArgoCD detects the update automatically
3. Kubernetes cluster syncs to desired state
4. Application and monitoring update without manual intervention

This ensures repeatable, auditable deployments.

---

## 📊 Observability

The platform includes:

* Prometheus metrics scraping
* Grafana dashboards
* Real-time visibility into pods, nodes, and workloads

This demonstrates how monitoring integrates into GitOps-driven systems.

---

## 🎯 Key DevOps Concepts Demonstrated

* GitOps workflow and declarative infrastructure
* Kubernetes application lifecycle management
* Helm-based deployments
* Continuous reconciliation with ArgoCD
* Cloud-hosted Kubernetes architecture
* Monitoring and observability integration

---

## 🚀 Why This Project Matters

This project simulates how modern DevOps teams manage:

* environment consistency
* automated deployments
* infrastructure recovery
* scalable monitoring

It reflects real platform engineering practices used in production cloud environments.

---

## 👨‍💻 Author

**Shibil Basith CP**
Cloud & DevOps Enthusiast

---

## ⭐ If you found this useful

Give the repo a star and feel free to connect on LinkedIn!
