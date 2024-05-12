# restro

A simple restaurant recommendation system.

This project helped me transition my AWS knowledge to Azure, which I've written about in the [JOURNEY.md](https://github.com/unfor19/restro/blob/main/JOURNEY.md) file.

## Requirements

- [Azure account](https://azure.microsoft.com/en-us/free/) with Pay-as-you-go subscription
- [Cloudflare Account](https://dash.cloudflare.com/sign-up)
- Brew - [make](https://www.gnu.org/software/make/), [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
  ```bash
  brew install azure-cli
  ```
- [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) - 1.5.0 or higher
- [Docker](https://docs.docker.com/get-docker/)
- [Python](https://github.com/pyenv/pyenv) - **Must use version 3.9**

## Setup

One-time setup steps to prepare the environment.

### Azure

1. Clone the repository
1. Copy `env` to `.env` and update the values
   ```bash
   cp env .env
   ```
1. Login to Azure
   ```bash
   make azure-login
   ```
1. Create a remote state storage in Azure
   ```bash
   make azure-remote-state-init
   ```

### Cloudflare

I'm using Cloudflare to protect the website with a custom password. The site is accessible only by users with the custom password in the header. If you wish to strengthen the security, you can add more rules to the WAF, like "Rate Limiting".

1. Navigate to [Cloudflare dashboard](https://dash.cloudflare.com/)
2. **Websites** > Select website > **Security** > **WAF** > **Custom rules** > **+ Create rule**
3. Edit expression > Set to the below expression, replace `restro.meirg.co.il` with your domain, `my-custom-header-name with` your custom header name, and `my_cuStOm_passw0rd` with your custom password.
   ```
   (http.host eq "restro.meirg.co.il" and all(http.request.headers["my-custom-header-name"][*] ne "my_cuStOm_passw0rd"))
   ```
   - **Action** > **Block**
   - **With response type** > **Default Cloudflare WAF block page**

## Getting Started

### Infra

1. Login to Azure
   ```bash
   make azure-login
   ```
1. Initialize Terraform
   ```bash
   make infra-init
   ```
1. Modify the infrastructure
1. Plan the infra

   ```bash
   make infra-plan
   ```

1. Apply the infra
   ```bash
   make infra-apply
   ```
   **NOTE:** For the first time, it will probably fail due to missing `TXT` record in Cloudflare. Add the TXT record to Cloudflare and run `make infra-plan` followed by `make infra-apply` again.
1. Update `.env` with the output values.
   ```
   make infra-update-dotenv
   ```

### Services

For local development, you can run the services using Docker.

Currently supported services: `mongo` and `mongo-express`

1. Run the services
   ```bash
   make services-up
   ```
1. Cleanup - Remove the services
   ```bash
   make services-down
   ```

### Backend

1. Login to Azure
   ```bash
   make azure-login
   ```
1. Prepare the backend environment
   ```bash
   make backend-prepare
   ```
1. Install requirements
   ```bash
   make backend-install
   ```
1. Run the app locally - access [http://127.0.0.1:5000](http://localhost:5000)
   ```bash
   # Required by the backend - runs mongodb
   make services-up
   ```
   ```bash
   make backend-run
   ```
1. Add features to the backend
1. Build and Package the app
   ```bash
   make backend-build
   ```
1. Push Docker image
   ```bash
   make backend-push
   ```
1. Deploy the app to Azure
   ```bash
   make backend-deploy
   ```
