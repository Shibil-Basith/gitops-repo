#!/bin/bash

# Define the services, their images, and their specific ports
declare -A SERVICES=(
  ["front-end"]="weaveworksdemos/front-end:0.3.12:8079"
  ["catalogue"]="weaveworksdemos/catalogue:0.3.5:80"
  ["cart"]="weaveworksdemos/cart:0.3.3:80"
  ["user"]="weaveworksdemos/user:0.3.3:80"
  ["orders"]="weaveworksdemos/orders:0.3.4:80"
  ["payment"]="weaveworksdemos/payment:0.3.3:80"
  ["shipping"]="weaveworksdemos/shipping:0.3.3:80"
  ["queue-master"]="weaveworksdemos/queue-master:0.3.1:80"
)

# Define the databases and their images (all use port 27017 for Mongo)
declare -A DATABASES=(
  ["catalogue-db"]="mongo:3.4"
  ["user-db"]="mongo:3.4"
  ["cart-db"]="mongo:3.4"
  ["orders-db"]="mongo:3.4"
)

BASE_DIR="services/sock-shop"
mkdir -p $BASE_DIR

echo "🚀 Starting Sock Shop Chart Generation..."

# Function to create a clean Helm chart
create_chart() {
  local name=$1
  local image_full=$2
  local port=$3
  local repo=$(echo $image_full | cut -d: -f1)
  local tag=$(echo $image_full | cut -d: -f2)

  echo "📦 Creating chart for: $name"
  mkdir -p "$BASE_DIR/$name"
  helm create "$BASE_DIR/$name" > /dev/null

  # Update values.yaml
  cat <<EOF > "$BASE_DIR/$name/values.yaml"
image:
  repository: $repo
  tag: "$tag"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80
  targetPort: $port

# Custom for Front-end access
nodePort: 30001
EOF

  # Clean up the default deployment.yaml to use our targetPort
  sed -i "s/containerPort: 80/containerPort: $port/g" "$BASE_DIR/$name/templates/deployment.yaml"
}

# 1. Create Microservice Charts
for svc in "${!SERVICES[@]}"; do
  IFS=':' read -r img tag port <<< "${SERVICES[$svc]}"
  create_chart "$svc" "$img:$tag" "$port"
done

# 2. Create Database Charts
for db in "${!DATABASES[@]}"; do
  create_chart "$db" "${DATABASES[$db]}" "27017"
done

# 3. Special Case: Update Front-end to NodePort
sed -i 's/type: ClusterIP/type: NodePort/g' "$BASE_DIR/front-end/values.yaml"
sed -i '/targetPort: 8079/a \  nodePort: 30001' "$BASE_DIR/front-end/values.yaml"

echo "✅ All charts generated in $BASE_DIR"
