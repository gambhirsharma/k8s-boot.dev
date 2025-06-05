#!/bin/bash

# List of namespaces to back up
namespaces=("default" "crawler")

# List of resource types to back up
resources=(deploy svc pod configmap secret pvc ingress)

for ns in "${namespaces[@]}"; do
  BACKUP_DIR="backup-$ns"
  mkdir -p "$BACKUP_DIR"

  echo "📦 Backing up namespace: $ns"
  for resource in "${resources[@]}"; do
    echo "  - $resource"
    kubectl get "$resource" --namespace="$ns" -o yaml > "$BACKUP_DIR/$resource.yaml" 2>/dev/null
  done
done

echo "✅ Backup completed for: ${namespaces[*]}"
