# restro

[![Backend CI](https://github.com/unfor19/restro/actions/workflows/backend-ci.yaml/badge.svg)](https://github.com/unfor19/restro/actions/workflows/backend-ci.yaml) [![Backend CD](https://github.com/unfor19/restro/actions/workflows/backend-cd.yaml/badge.svg)](https://github.com/unfor19/restro/actions/workflows/backend-cd.yaml)

<div style="text-align: center;">
<img alt="logo" width="100%" src="https://github.com/unfor19/restro/blob/main/assets/logo.webp?raw=true" />
</div>

A simple restaurant recommendation system.

This project helped me transition my AWS knowledge to Azure, which I've written about in the [JOURNEY.md](https://github.com/unfor19/restro/blob/main/JOURNEY.md) file.

[Demo on YouTube](https://www.youtube.com/watch?v=_6gIZ5G2_WM&ab_channel=MeirGabay)

## Architecture

<details>

<summary>Click to expand/collapse</summary>

![Architecture](https://github.com/unfor19/restro/blob/main/assets/restro.architecture.png?raw=true)

</details>

## Requirements

- [Azure Account](https://azure.microsoft.com/en-us/free/) with Pay-As-You-Go subscription
- [Cloudflare Account](https://dash.cloudflare.com/sign-up)
- [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) - 1.5.0 or higher
- [Docker](https://docs.docker.com/get-docker/)
- [Python](https://github.com/pyenv/pyenv) - 3.9 or higher
- Package managers apps:
  - macOS - [HomeBrew](https://brew.sh/)
    ```bash
    brew install make azure-cli
    ```
  - Windows - [Chocolatey](https://chocolatey.org/)
    ```powershell
    # PowerShell as Administrator
    choco -y install make azure-cli
    ```

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

#### Azure Service Principal

This setup creates an Azure Service Principal so GitHub Actions can authenticate with Azure.

1. Login to Azure

   ```bash
   make azure-login
   ```

1. List available subscriptions

   ```bash
   make azure-service-principal-list
   ```

   Sample output

   ```
   Name           CloudName    SubscriptionId                        TenantId                              State    IsDefault
   -------------  -----------  ------------------------------------  ------------------------------------  -------  -----------
   Pay-As-You-Go  AzureCloud   00000000-0000-0000-0000-000000000000  12345678-0000-0000-0000-000000000000  Enabled  True
   ```

1. Copy **SubscriptionId** and set it in `.env`
   ```bash
   SUBSCRIPTION_ID=00000000-0000-0000-0000-000000000000
   ```
1. Create the Service Principal
   ```bash
   make azure-service-principal-create
   ```
1. Copy the output JSON and save it in a safe place
1. [Add the service principal as a GitHub secret](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure?tabs=azure-portal%2Clinux#add-the-service-principal-as-a-github-secret)
1. The app is now ready to be deployed with GitHub Actions to Azure

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

### Backend

1. Login to Azure
   ```bash
   make azure-login
   ```
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

## Local Development

1. Prepare the backend environment
   ```bash
   make backend-prepare
   ```
2. Install requirements
   ```bash
   make backend-install
   ```
3. Run services locally - [mongo](https://www.mongodb.com/) and [mongo-express](https://github.com/mongo-express/mongo-express)
   ```bash
   make services-up
   ```
4. Run the app locally - access [http://127.0.0.1:5000](http://localhost:5000)
   ```bash
   make backend-run
   ```

## Authors

Created and maintained by [Meir Gabay](https://meirg.co.il)

## License

This project is licensed under the MIT License - see the [LICENSE](https://github.com/unfor19/restro/blob/main/LICENSE) file for details
