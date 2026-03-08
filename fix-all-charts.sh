#!/bin/bash
for dir in services/sock-shop/*; do
  if [ -d "$dir" ]; then
    SVC_NAME=$(basename "$dir")
    echo "🛠️ Fixing $SVC_NAME..."

    # 1. Overwrite Deployment with valid indentation
    cat << INNER_EOF > "$dir/templates/deployment.yaml"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $SVC_NAME
  labels:
    app: $SVC_NAME
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $SVC_NAME
  template:
    metadata:
      labels:
        app: $SVC_NAME
    spec:
      containers:
        - name: $SVC_NAME
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          ports:
            - containerPort: {{ .Values.service.targetPort }}
INNER_EOF

    # 2. Overwrite Service with valid indentation
    cat << INNER_EOF > "$dir/templates/service.yaml"
apiVersion: v1
kind: Service
metadata:
  name: $SVC_NAME
spec:
  type: {{ .Values.service.type | default "ClusterIP" }}
  ports:
  - port: {{ .Values.service.port }}
    targetPort: {{ .Values.service.targetPort }}
    {{- if .Values.service.nodePort }}
    nodePort: {{ .Values.service.nodePort }}
    {{- end }}
  selector:
    app: $SVC_NAME
INNER_EOF
  fi
done
