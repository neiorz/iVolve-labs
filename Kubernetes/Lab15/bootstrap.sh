#!/usr/bin/env bash
# Fresh Killercoda session (controlplane + node01).
# Rebuilds labs 10-15 in one pass. Paste the whole file, or run: bash bootstrap.sh
set -euo pipefail

mkdir -p ~/lab15
cd ~/lab15

cat > prereqs.yaml <<'YAML'
apiVersion: v1
kind: Namespace
metadata:
  name: ivolve
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: ivolvequota
  namespace: ivolve
spec:
  hard:
    pods: "3"
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: ivolvecm
  namespace: ivolve
data:
  DB_HOST: ivolvedbsvc
  DB_USER: ivolve
---
apiVersion: v1
kind: Secret
metadata:
  name: ivolvesecret
  namespace: ivolve
type: Opaque
data:
  MYSQL_ROOT_PASSWORD: Um9vdFBhc3MxMjM=
  DB_PASSWORD: aXZvbHZlMTIz
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ivolve-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: ""
  hostPath:
    path: /mnt/app-logs
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ivolve-pvc
  namespace: ivolve
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: ""
  resources:
    requests:
      storage: 1Gi
YAML

cat > mysql.yaml <<'YAML'
apiVersion: v1
kind: Service
metadata:
  name: ivolvedbsvc
  namespace: ivolve
spec:
  clusterIP: None
  selector:
    app: ivolve-mysql
  ports:
    - name: mysql
      port: 3306
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: ivolvedb
  namespace: ivolve
spec:
  serviceName: ivolvedbsvc
  replicas: 1
  selector:
    matchLabels:
      app: ivolve-mysql
  template:
    metadata:
      labels:
        app: ivolve-mysql
    spec:
      nodeSelector:
        project: ivolve
      tolerations:
        - key: workload
          operator: Equal
          value: ivolveApp
          effect: NoSchedule
      containers:
        - name: mysql
          image: mysql:8.0
          envFrom:
            - configMapRef:
                name: ivolvecm
            - secretRef:
                name: ivolvesecret
          ports:
            - name: mysql
              containerPort: 3306
          readinessProbe:
            exec:
              command:
                - sh
                - -c
                - mysqladmin ping -h 127.0.0.1 -uroot -p"$MYSQL_ROOT_PASSWORD"
            initialDelaySeconds: 10
            periodSeconds: 5
          volumeMounts:
            - name: mysql-data
              mountPath: /var/lib/mysql
  volumeClaimTemplates:
    - metadata:
        name: mysql-data
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 1Gi
YAML

cat > app.yaml <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ivolveapp
  namespace: ivolve
  labels:
    app: ivolveapp
spec:
  replicas: 2
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 0
      maxUnavailable: 1
  selector:
    matchLabels:
      app: ivolveapp
  template:
    metadata:
      labels:
        app: ivolveapp
    spec:
      nodeSelector:
        project: ivolve
      tolerations:
        - key: workload
          operator: Equal
          value: ivolveApp
          effect: NoSchedule
      initContainers:
        - name: init-db
          image: mysql:8.0
          envFrom:
            - configMapRef:
                name: ivolvecm
            - secretRef:
                name: ivolvesecret
          command:
            - /bin/sh
            - -c
          args:
            - |
              until mysql -h "$DB_HOST" -uroot -p"$MYSQL_ROOT_PASSWORD" -e "SELECT 1" >/dev/null 2>&1; do
                echo "waiting for MySQL at $DB_HOST ..."
                sleep 3
              done
              mysql -h "$DB_HOST" -uroot -p"$MYSQL_ROOT_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS ivolve; CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD'; ALTER USER '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD'; GRANT ALL PRIVILEGES ON ivolve.* TO '$DB_USER'@'%'; FLUSH PRIVILEGES;"
              echo "ivolve database and privileges are ready"
      containers:
        - name: app
          image: nourz1/ivolve-app:latest
          imagePullPolicy: Always
          ports:
            - name: http
              containerPort: 3000
          envFrom:
            - configMapRef:
                name: ivolvecm
            - secretRef:
                name: ivolvesecret
          volumeMounts:
            - name: app-logs
              mountPath: /app/logs
          readinessProbe:
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 5
            periodSeconds: 10
      volumes:
        - name: app-logs
          persistentVolumeClaim:
            claimName: ivolve-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: ivolveappsvc
  namespace: ivolve
spec:
  type: ClusterIP
  selector:
    app: ivolveapp
  ports:
    - name: http
      port: 80
      targetPort: 3000
YAML

cat > networkpolicy.yaml <<'YAML'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: ivolvenp
  namespace: ivolve
spec:
  podSelector:
    matchLabels:
      app: ivolve-mysql
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: ivolveapp
      ports:
        - protocol: TCP
          port: 3306
YAML

echo "==> lab 10: node01 taint and label"
kubectl taint nodes node01 workload=ivolveApp:NoSchedule --overwrite
kubectl label node node01 project=ivolve --overwrite

echo "==> labs 11-13: namespace, quota, config, secret, pv, pvc"
kubectl apply -f prereqs.yaml

echo "==> lab 14: mysql statefulset"
kubectl apply -f mysql.yaml
kubectl rollout status statefulset/ivolvedb -n ivolve --timeout=300s

echo "==> lab 15: application deployment"
kubectl apply -f app.yaml
kubectl rollout status deployment/ivolveapp -n ivolve --timeout=300s

echo "==> cluster info for the lab 16 sizing"
kubectl describe node node01 | grep -A6 -E "^Capacity|Allocatable"

echo "==> CNI in use (lab 17)"
kubectl get pods -n kube-system | grep -Ei "calico|cilium|flannel|weave" || true

kubectl get pods,pvc,svc -n ivolve -o wide
