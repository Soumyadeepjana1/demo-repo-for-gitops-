
#!/bin/bash

set -e

PROJECT="argocd-multistage-demo"
REPO_URL="https://github.com/Soumyadeepjana1/demo-repo-for-gitops-.git"

echo "Creating project structure..."

# Directories
mkdir -p "$PROJECT/apps/nginx"
mkdir -p "$PROJECT/apps/apache"
mkdir -p "$PROJECT/apps/online-shop"
mkdir -p "$PROJECT/argocd/children"

cd "$PROJECT"

# ==================================
# NGINX
# ==================================

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
  type: ClusterIP
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

# ==================================
# APACHE
# ==================================

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
  type: ClusterIP
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

# ==================================
# ONLINE SHOP
# ==================================

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
  type: ClusterIP
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

# ==================================
# APPS KUSTOMIZATION
# ==================================

cat > apps/kustomization.yaml <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - nginx
  - apache
  - online-shop
EOF

# ==================================
# ROOT APPLICATION
# ==================================

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
    targetRevision: main
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

# ==================================
# DEV APPLICATION
# ==================================

cat > argocd/children/dev-app.yaml <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: dev-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: $REPO_URL
    targetRevision: main
    path: apps
  destination:
    server: https://kubernetes.default.svc
    namespace: dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF

# ==================================
# STAGING APPLICATION
# ==================================

cat > argocd/children/staging-app.yaml <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: staging-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: $REPO_URL
    targetRevision: main
    path: apps
  destination:
    server: https://kubernetes.default.svc
    namespace: staging
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF

# ==================================
# PROD APPLICATION
# ==================================

cat > argocd/children/prod-app.yaml <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: prod-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: $REPO_URL
    targetRevision: main
    path: apps
  destination:
    server: https://kubernetes.default.svc
    namespace: prod
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF

# ==================================
# README
# ==================================

cat > README.md <<'EOF'
# ArgoCD Multi-Stage Demo

## Repository Structure

- apps/
  - nginx/
  - apache/
  - online-shop/
- argocd/
  - root-app.yaml
  - children/
    - dev-app.yaml
    - staging-app.yaml
    - prod-app.yaml

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
EOF

echo ""
echo "Project structure created successfully!"
echo "Repository: $REPO_URL"
echo ""
echo "Generated files:"
find . -type f | sort
