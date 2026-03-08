#!/bin/bash

# --- CONFIGURATION ---
REPO_URL="https://github.com/Shibil-Basith/gitops-repo.git"
BASE_DIR="services/sock-shop"
APP_DIR="argocd-apps"
NAMESPACE="sock-shop"
ARGOCD_NS="argocd"

echo "🧹 Cleaning local workspace..."
rm -rf services argocd-apps
mkdir -p $BASE_DIR $APP_DIR

# --- 1. GENERATE HELM CHARTS ---
echo "📦 Generating 13 Microservice Charts..."
declare -A SVC=( ["front-end"]="0.3.12:8079" ["catalogue"]="0.3.5:80" ["cart"]="0.3.3:80" ["user"]="0.3.3:80" ["orders"]="0.3.4:80" ["payment"]="0.3.3:80" ["shipping"]="0.3.3:80" ["queue-master"]="0.3.1:80" ["rabbitmq"]="3.6.8-management:5672" )
DB=("catalogue-db" "user-db" "cart-db" "orders-db")

for s in "${!SVC[@]}"; do
  IFS=':' read -r tag port <<< "${SVC[$s]}"
  helm create "$BASE_DIR/$s" > /dev/null
  # Update image and port settings
  sed -i "s/repository: .*/repository: weaveworksdemos\/$s/" "$BASE_DIR/$s/values.yaml"
  [[ "$s" == "rabbitmq" ]] && sed -i "s/repository: .*/repository: rabbitmq/" "$BASE_DIR/$s/values.yaml"
  sed -i "s/tag: .*/tag: \"$tag\"/" "$BASE_DIR/$s/values.yaml"
  sed -i "s/targetPort: 80/targetPort: $port/" "$BASE_DIR/$s/values.yaml"
  sed -i "s/containerPort: 80/containerPort: $port/" "$BASE_DIR/$s/templates/deployment.yaml"
done

for d in "${DB[@]}"; do
  helm create "$BASE_DIR/$d" > /dev/null
  sed -i "s/repository: .*/repository: mongo/" "$BASE_DIR/$d/values.yaml"
  sed -i "s/tag: .*/tag: \"3.4\"/" "$BASE_DIR/$d/values.yaml"
  sed -i "s/targetPort: 80/targetPort: 27017/" "$BASE_DIR/$d/values.yaml"
  sed -i "s/containerPort: 80/containerPort: 27017/" "$BASE_DIR/$d/templates/deployment.yaml"
done

# Set Front-end to NodePort 30001 for AWS access
sed -i 's/type: ClusterIP/type: NodePort/' $BASE_DIR/front-end/values.yaml
echo "  nodePort: 30001" >> $BASE_DIR/front-end/values.yaml

# --- 2. CREATE ARGO CD MANIFEST ---
echo "📄 Creating Argo CD Parent Application..."
cat <<EOF > $APP_DIR/sock-shop-stack.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: sock-shop
  namespace: $ARGOCD_NS
spec:
  project: default
  source:
    repoURL: $REPO_URL
    targetRevision: HEAD
    path: services/sock-shop
    directory:
      recurse: true
  destination:
    server: https://kubernetes.default.svc
    namespace: $NAMESPACE
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
EOF

# --- 3. GIT PUSH ---
echo "📤 Pushing to GitHub..."
git add .
git commit -m "feat: automated rebuild of sock-shop stack"
git push origin main

# --- 4. ARGO CD SYNC ---
echo "🔄 Registering and Syncing with Argo CD..."
kubectl apply -f $APP_DIR/sock-shop-stack.yaml
argocd app sync sock-shop --core --argocd-namespace $ARGOCD_NS

echo "✅ Automation Complete! Check status with: kubectl get pods -n $NAMESPACE"
