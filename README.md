# restro

## Requirements

- Azure account with Pay-as-you-go subscription
- Brew - [make](https://www.gnu.org/software/make/) and [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
  ```bash
  brew install azure-cli make
  ```
- [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) - 1.5.0 or higher

## Setup

1. Clone the repository
1. Copy `env` to `.env` and update the values
   ```bash
   cp env.sample .env
   ```
1. Login to Azure
   ```bash
   make azure-login
   ```
1. Create a remote state storage in Azure
   ```bash
   make azure-remote-state-init
   ```

## Getting Started

1. Login to Azure
   ```bash
   az login
   ```

### Infra

1. Initialize Terraform
   ```bash
   make infra-init
   ```
1. Plan the infra

   ```bash
   make infra-plan
   ```

1. Apply the infra
   ```bash
   make infra-apply
   ```
1. Update `.env` with the output values
   ```
   make infra-update-dotenv
   ```

### Backend

1. Prepare the backend environment
   ```bash
   make backend-prepare
   ```
1. Install requirements
   ```bash
   make backend-install
   ```
1. Run the app locally - access [http://localhost:8081](http://localhost:8081)
   ```bash
   make backend-run
   ```
1. Package the app
   ```bash
   make backend-package
   ```
1. Deploy the app
   ```bash
   make backend-deploy
   ```
