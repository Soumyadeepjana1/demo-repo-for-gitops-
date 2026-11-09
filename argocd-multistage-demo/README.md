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
