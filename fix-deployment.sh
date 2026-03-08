#!/bin/bash
for dir in services/sock-shop/*; do
  if [ -d "$dir/templates" ]; then
    cat << 'INNER_EOF' > "$dir/templates/deployment.yaml"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "$(basename $dir).fullname" . | default (basename $dir) }}
  labels:
    {{- include "$(basename $dir).labels" . | nindent 4 | default "app: sock-shop" }}
spec:
  replicas: {{ .Values.replicaCount | default 1 }}
  selector:
    matchLabels:
      app: {{ basename $dir }}
  template:
    metadata:
      labels:
        app: {{ basename $dir }}
    spec:
      containers:
        - name: {{ basename $dir }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          ports:
            - containerPort: {{ .Values.service.targetPort }}
INNER_EOF
    # Correct the dynamic naming inside the heredoc
    sed -i "s/\$(basename \$dir)/$(basename $dir)/g" "$dir/templates/deployment.yaml"
  fi
done
