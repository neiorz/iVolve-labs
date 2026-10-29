#!/usr/bin/env bash
# Rebuilds the state left by labs 10-14 and deploys lab 15.
# Run from the controlplane node, in the folder that holds the yaml files.
set -euo pipefail

# Lab 10: isolate node01 (taint) and mark it for the project (label)
kubectl taint nodes node01 workload=ivolveApp:NoSchedule --overwrite
kubectl label node node01 project=ivolve --overwrite

# Labs 11, 12, 13: namespace, quota, ConfigMap, Secret, PV and PVC
kubectl apply -f prereqs.yaml

# Lab 14: MySQL StatefulSet behind a headless Service
kubectl apply -f mysql.yaml
kubectl rollout status statefulset/ivolvedb -n ivolve --timeout=240s

# Lab 15: the Node.js Deployment and its ClusterIP Service
kubectl apply -f app.yaml
kubectl rollout status deployment/ivolveapp -n ivolve --timeout=240s

kubectl get pods,pvc,svc -n ivolve
