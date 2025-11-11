# Kubernetes Cheat Sheet (Beginner → Expert)

> A practical reference covering installation, core concepts, kubectl usage, workloads, networking, storage, configs, Helm, debugging, and security.

---

## Table of Contents

1. Introduction & Installation
2. kubectl Basics
3. Core Concepts
4. Workloads & Controllers
5. Services & Networking
6. Config & Secrets
7. Storage
8. Deployments & Rollouts
9. Helm Basics
10. Monitoring & Logging
11. Debugging & Troubleshooting
12. Security & RBAC
13. Best Practices
14. Useful Commands Summary

---

# 1. Introduction & Installation

**What is Kubernetes?**

* Open-source container orchestration system for automating deployment, scaling, and management of containerized apps.
* Manages clusters of nodes, schedules workloads, handles networking, and ensures self-healing.

**Core components**

* Node: worker machine (VM or physical).
* Pod: smallest deployable unit (one or more containers).
* Service: stable networking endpoint.
* Deployment: declarative way to run Pods.
* ConfigMap/Secret: external configuration.
* PersistentVolume/Claim: storage abstraction.
* kube-apiserver, etcd, controller-manager, scheduler (control plane).

**Install (options)**

* Local dev: `minikube`, `kind` (Kubernetes in Docker), or Docker Desktop.
* Cloud: GKE (Google), EKS (AWS), AKS (Azure).
* Production: kubeadm, managed services, or distributions (RKE, k3s, OpenShift).

Check cluster:

```bash
kubectl version --short
kubectl cluster-info
kubectl get nodes
```

---

# 2. kubectl Basics

**Common syntax**

```bash
kubectl [command] [TYPE] [NAME] [flags]
```

**Resource types**

* `pods`, `deployments`, `services`, `nodes`, `configmaps`, `secrets`, `ingress`, `namespaces`, etc.

**Examples**

```bash
kubectl get pods
kubectl get deployments
kubectl describe pod mypod
kubectl logs mypod
kubectl exec -it mypod -- /bin/sh
```

**Context & namespace**

```bash
kubectl config get-contexts
kubectl config use-context mycluster
kubectl config set-context --current --namespace=dev
```

---

# 3. Core Concepts

* **Pod**: basic execution unit; ephemeral.
* **ReplicaSet**: ensures fixed number of Pod replicas.
* **Deployment**: declarative updates to ReplicaSets/Pods.
* **Service**: exposes Pods via stable DNS name/IP.
* **Namespace**: logical cluster partition.
* **ConfigMap/Secret**: externalized configuration.
* **Ingress**: HTTP routing into cluster.
* **PersistentVolume/Claim**: storage binding.

---

# 4. Workloads & Controllers

**Pod example**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mypod
spec:
  containers:
    - name: nginx
      image: nginx:1.25
      ports:
        - containerPort: 80
```

**Deployment example**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
        - name: app
          image: myimage:1.0
          ports:
            - containerPort: 8080
```

**StatefulSet example**

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
  serviceName: mysql
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        ports:
        - containerPort: 3306
        volumeMounts:
        - name: data
          mountPath: /var/lib/mysql
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
```

**DaemonSet example**

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
spec:
  selector:
    matchLabels:
      app: fluentd
  template:
    metadata:
      labels:
        app: fluentd
    spec:
      containers:
      - name: fluentd
        image: fluent/fluentd:v1.14
        volumeMounts:
        - name: varlogcontainers
          mountPath: /var/log/containers
      volumes:
      - name: varlogcontainers
        hostPath:
          path: /var/log/containers
```

**Job & CronJob**

```yaml
# Job
apiVersion: batch/v1
kind: Job
metadata:
  name: batch-job
spec:
  template:
    spec:
      containers:
      - name: job
        image: busybox
        command: ["echo","Hello"]
      restartPolicy: Never
  backoffLimit: 4

# CronJob
apiVersion: batch/v1
kind: CronJob
metadata:
  name: hello
spec:
  schedule: "*/1 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: hello
            image: busybox
            command: ["echo", "Hello World"]
          restartPolicy: OnFailure
```

---

# 5. Services & Networking

**Service types**

* ClusterIP (default): internal cluster-only access.
* NodePort: exposes via static port on each Node.
* LoadBalancer: provisions external LB (cloud only).
* ExternalName: DNS CNAME redirect.

**Service example**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: myservice
spec:
  selector:
    app: myapp
  ports:
    - port: 80
      targetPort: 8080
  type: ClusterIP
```

**Network Policy example**

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-web
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: api
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: db
    ports:
    - protocol: TCP
      port: 5432
  - to: []
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53
```

**Ingress**

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myingress
spec:
  rules:
  - host: myapp.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myservice
            port:
              number: 80
```

---

# 6. Config & Secrets

**ConfigMap**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: myconfig
  data:
    APP_ENV: production
    TIMEOUT: "30"
```

Mount as env:

```yaml
envFrom:
  - configMapRef:
      name: myconfig
```

**Secret**

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mysecret
type: Opaque
data:
  password: cGFzc3dvcmQ=   # base64 encoded
```

Mount as env:

```yaml
env:
  - name: DB_PASS
    valueFrom:
      secretKeyRef:
        name: mysecret
        key: password
```

---

# 7. Storage

**PersistentVolumeClaim (PVC)**

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mypvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
```

Pod usage:

```yaml
volumes:
  - name: data
    persistentVolumeClaim:
      claimName: mypvc
containers:
  - name: app
    image: busybox
    volumeMounts:
      - mountPath: /data
        name: data
```

---

# 8. Deployments & Rollouts

**Rolling update**

```bash
kubectl rollout status deployment myapp
kubectl rollout history deployment myapp
kubectl rollout undo deployment myapp
```

**Update image**

```bash
kubectl set image deployment/myapp app=myimage:2.0
```

---

# 9. Helm Basics

**What is Helm?**

* Kubernetes package manager.
* Charts = templates for K8s manifests.

**Commands**

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install mydb bitnami/mysql
helm upgrade mydb bitnami/mysql --set image.tag=8.0
helm list
helm uninstall mydb
```

---

# 10. Monitoring & Logging

**Logs**

```bash
kubectl logs podname
kubectl logs -f podname
kubectl logs -f -l app=myapp   # by label
```

**Events**

```bash
kubectl get events --sort-by=.metadata.creationTimestamp
```

**Metrics**

* Metrics Server: `kubectl top nodes`, `kubectl top pods`.
* Prometheus + Grafana for full monitoring.

---

# 11. Debugging & Troubleshooting

**Get shell inside Pod**

```bash
kubectl exec -it podname -- sh
```

**Describe resources**

```bash
kubectl describe pod podname
kubectl describe svc svcname
```

**Debugging tips**

* Check events: `kubectl get events`
* Check pending Pods: often storage or scheduling issues.
* Use ephemeral debug container (1.18+):

```bash
kubectl debug podname -it --image=busybox
```

**Port-forward**

```bash
kubectl port-forward svc/myservice 8080:80
```

---

# 12. Security & RBAC

**RBAC Role & Binding**

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
subjects:
- kind: User
  name: alice
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

**Security tips**

* Use `PodSecurityPolicy` (deprecated → Pod Security Admission).
* Run containers as non-root.
* Use `networkPolicies` to limit Pod traffic.
* Limit service accounts and RBAC permissions.

---

# 13. Best Practices

* Use namespaces to isolate environments.
* Keep manifests in Git, practice GitOps.
* Resource requests/limits for all containers.
* Readiness/Liveness probes for health.
* Use labels/annotations consistently.
* Avoid `:latest` image tag.
* Automate rollouts with CI/CD.
* Monitor costs with resource quotas.

---

# 14. Useful Commands Summary

**Pods/Deployments**

```bash
kubectl get pods
kubectl describe pod podname
kubectl create -f pod.yaml
kubectl delete pod podname
kubectl scale deployment myapp --replicas=5
```

**Services/Ingress**

```bash
kubectl get svc
kubectl expose deployment myapp --type=LoadBalancer --port=80 --target-port=8080
kubectl get ingress
```

**Config & Secrets**

```bash
kubectl get configmaps
kubectl get secrets
```

**Storage**

```bash
kubectl get pv
kubectl get pvc
```

**Cluster/System**

```bash
kubectl get nodes
kubectl top pods
kubectl top nodes
kubectl get events
```

**Helm**

```bash
helm install NAME CHART
helm upgrade NAME CHART
helm uninstall NAME
```

---

# Quick Reference: One-liners

* Restart deployment:

```bash
kubectl rollout restart deployment myapp
```

* Delete all Pods in namespace:

```bash
kubectl delete pods --all -n mynamespace
```

* Force delete stuck Pod:

```bash
kubectl delete pod podname --grace-period=0 --force
```

* Switch namespace:

```bash
kubectl config set-context --current --namespace=myns
```

---
*End of cheat sheet — happy Kuberneting!*
