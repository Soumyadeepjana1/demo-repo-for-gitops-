# ArgoCD Multi-Stage Demo

Repository: https://github.com/Soumyadeepjana1/demo-repo-for-gitops-.git

Branch: master

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
