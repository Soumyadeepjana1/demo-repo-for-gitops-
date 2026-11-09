
#!/bin/bash

set -e

PROJECT="argocd-multistage-demo"
REPO_URL="https://github.com/Soumyadeepjana1/demo-repo-for-gitops-.git"
BRANCH="main"

echo "Creating ArgoCD Multi-Stage Demo..."

mkdir -p "$PROJECT"/apps/{nginx,apache,online-shop}
mkdir -p "$PROJECT"/argocd/children

cd "$PROJECT"

# NGINX
cat > apps/nginx/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx:stable
          ports:
            - containerPort: 80
EOF

cat > apps/nginx/service.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  selector:
    app: nginx
  ports:
    - port: 80
      targetPort: 80
EOF

cat > apps/nginx/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
  - service.yaml
EOF

# APACHE
cat > apps/apache/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: apache
spec:
  replicas: 2
  selector:
    matchLabels:
      app: apache
  template:
    metadata:
      labels:
        app: apache
    spec:
      containers:
        - name: apache
          image: httpd:2.4
          ports:
            - containerPort: 80
EOF

cat > apps/apache/service.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: apache
spec:
  selector:
    app: apache
  ports:
    - port: 80
      targetPort: 80
EOF

cat > apps/apache/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
  - service.yaml
EOF

# ONLINE SHOP
cat > apps/online-shop/deployment.yaml <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: online-shop
spec:
  replicas: 2
  selector:
    matchLabels:
      app: online-shop
  template:
    metadata:
      labels:
        app: online-shop
    spec:
      containers:
        - name: online-shop
          image: hashicorp/http-echo:1.0.0
          args:
            - "-text=Welcome to Online Shop"
          ports:
            - containerPort: 5678
EOF

cat > apps/online-shop/service.yaml <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: online-shop
spec:
  selector:
    app: online-shop
  ports:
    - port: 80
      targetPort: 5678
EOF

cat > apps/online-shop/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
  - service.yaml
EOF

# APPS KUSTOMIZATION
cat > apps/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - nginx
  - apache
  - online-shop
EOF

# ROOT APPLICATION
cat > argocd/root-app.yaml <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: $REPO_URL
    targetRevision: $BRANCH
    path: argocd/children
    directory:
      recurse: true
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

# CHILD APPLICATIONS
for ENV in dev staging prod
do
cat > "argocd/children/${ENV}-app.yaml" <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${ENV}-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: $REPO_URL
    targetRevision: $BRANCH
    path: apps
  destination:
    server: https://kubernetes.default.svc
    namespace: $ENV
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF
done

# README
cat > README.md <<'EOF'
# ArgoCD Multi-Stage Demo

## Architecture
Root Application
  |
  |-- Dev Application
  |-- Staging Application
  |-- Prod Application

Each environment deploys:
- Nginx
- Apache
- Online Shop

## Technologies
- Kubernetes
- Argo CD
- Kustomize
- GitHub

## Deploy
kubectl apply -f argocd/root-app.yaml

## Verify
kubectl get applications -n argocd
kubectl get pods -A
EOF

echo "Project files created!"

# GIT SETUP
git init
git branch -M "$BRANCH"
git add .
git commit -m "Initial ArgoCD multistage demo"

if git remote get-url origin >/dev/null 2>&1; then
    git remote set-url origin "$REPO_URL"
else
    git remote add origin "$REPO_URL"
fi

echo ""
echo "=================================="
echo "Project created successfully!"
echo "GitHub: $REPO_URL"
echo "=================================="

find . -type f | sort

echo ""
echo "Push your project using:"
echo "git push -u origin $BRANCH"

echo ""
echo "After pushing, deploy using:"
echo "kubectl apply -f argocd/root-app.yaml"
