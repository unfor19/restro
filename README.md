# restro

## Requirements

- Azure CLI
  ```bash
  brew install azure-cli
  ```

## Getting Started

1. Login to Azure
   ```bash
   az login
   ```
1. Initialize Terraform
   ```bash
   terraform init
   ```
1. Plan the infra
   ```bash
   terraform plan -out .plan
   ```
1. Apply the infra
   ```bash
   terraform apply .plan
   ```
1. WIP: Deploy the app
   ```bash
   az webapp deploy --resource-group myResourceGroup-67302 --name webapp-67302 --src-path ${PWD}/backend/main.py.zip --type zip
   ```
