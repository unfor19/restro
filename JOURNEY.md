# Journey

## First thoughts

I need to develop a web application that provides a RESTful API to get recommendations for restaurants.

I'm thinking of developing a few [Azure Functions](https://azure.microsoft.com/en-us/products/functions) in Python, and use [Azure Cosmos DB](https://azure.microsoft.com/en-us/services/cosmos-db) to store the restaurants and their properties.

A sample data structure for a restaurant could be:

```json
{
  "id": "1",
  "name": "Pizza hut",
  "style": "Italian",
  "address": "wherever street 99, somewhere",
  "openHour": "09:00",
  "clouseHour": "23:00",
  "vegetarian": true
}
```

I will need to create a few endpoints:

- `GET /restaurants` - returns a list of all restaurants.
- `POST /restaurants` - adds a new restaurant to the list.
- `GET /restaurants/{id}` - returns a specific restaurant.
- `DELETE /restaurants/{id}` - deletes a specific restaurant.
- `GET /restaurants/recommendation` - returns a restaurant recommendation based on the query parameters.

All requests should be logged into a logging system, like they would with AWS CloudWatch, on Azure it's called [Azure Monitor](https://azure.microsoft.com/en-us/services/monitor).

## Starting the project

I found a good starting point - https://www.linkedin.com/pulse/azure-function-python-deployment-terraform-huaifeng-qin-jfjtc/

Since Azure is absolutely new to me, I'll first start by creating a dummy function and deploying it to Azure. Once the infra is ready, I'll cover the CI/CD part. After everything is ready, I'll write down the "actual app" that I'm supposed to develop - "restro" :D

Super pivot - I've realized it's an overkill to deploy such a large set of infrastructure, so I'll start by creating [Azure App Service](https://learn.microsoft.com/en-us/azure/app-service/getting-started?pivots=stack-python) and deploy a simple Flask app. I feel that Azure App Service is like AWS ECS Fargate.

This looks awesome - https://learn.microsoft.com/en-us/azure/app-service/provision-resource-terraform

- Setting up Terraform to authenticate with Azure - https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/azure_cli

## We have a Makefile

I've created a Makefile to make my life easier. I can now run `make infra-init` to initialize the Terraform infra, `make infra-plan` to see the changes, and `make infra-apply` to apply the changes.

Same goes for the `backend`, which is the API app that I'm going to develop.

## Custom Domain

Since I own https://meirg.co.il, I've added `restro.meirg.co.il` as a custom domain to the Azure App Service. I needed to add a TXT record to my DNS provider, and then add the domain to the Azure App Service. The DNS records was added according to the error that was raised during `make infra-apply`.

## But the Database

So far I've used a dummy variable to store the restaurants. I need to replace it with a real database. I've decided to use [MongoDB Atlas](https://www.mongodb.com/cloud/atlas) since I'm familiar with it. I've created a new cluster manually via the GUI. The next step is to create a new database and a new user. I'll use the `pymongo` library to connect to the database.

As mentioned in the README.md, I intend to do a [peering connection](https://www.mongodb.com/docs/atlas/security-vpc-peering/) between the Azure App Service and the MongoDB Atlas cluster. I've created a new VNet in Azure, and a new peering connection in MongoDB Atlas.

## Pivot the DB

Apparently, MongoDB Atlas supports Peering Connection for non-shared clusters, so I'm dropping this idea, even though it was fun configuring the VNet and the peering connection.

I've decided to use the [Azure Cosmos DB](https://azure.microsoft.com/en-us/services/cosmos-db) since it's a managed service and I don't need to worry about the infrastructure.

Yalla adding it to Terraform, use the CosmoDB MongoDB flavor.
