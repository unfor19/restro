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

## Hooray "app is in the air" 🚀

I've deployed the app to Azure App Service, and it's working! I've added a few restaurants to the database, and I can get them via the API. I've also added a few logs to the Azure Monitor.

I can develop the app locally easily by using the commands `make services-up` and `make run` - It runs mongodb and the app locally in development, so the development cycle is quite fast.

To test my app manually (at least for now) I've added created a Postman collections for both `https://127.0.0.0:5000` and `https://restro.meirg.co.il`. Here's my exported collection -

<details>

<summary>Expand/Collapse - restro-localhost.postman_collection.json</summary>

```json
{
  "info": {
    "_postman_id": "007e8c60-06ed-4f5a-83d4-6a474a71ffed",
    "name": "restro-localhost",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json",
    "_exporter_id": "9776480"
  },
  "item": [
    {
      "name": "restaurants",
      "request": {
        "method": "GET",
        "header": [],
        "url": {
          "raw": "{{BASE_URL}}/restaurants",
          "host": ["{{BASE_URL}}"],
          "path": ["restaurants"]
        }
      },
      "response": []
    },
    {
      "name": "version",
      "request": {
        "method": "GET",
        "header": [],
        "url": {
          "raw": "{{BASE_URL}}/version",
          "host": ["{{BASE_URL}}"],
          "path": ["version"]
        }
      },
      "response": []
    },
    {
      "name": "health",
      "request": {
        "method": "GET",
        "header": [],
        "url": {
          "raw": "{{BASE_URL}}/health",
          "host": ["{{BASE_URL}}"],
          "path": ["health"]
        }
      },
      "response": []
    },
    {
      "name": "root",
      "request": {
        "method": "GET",
        "header": [],
        "url": {
          "raw": "{{BASE_URL}}/",
          "host": ["{{BASE_URL}}"],
          "path": [""]
        }
      },
      "response": []
    },
    {
      "name": "restaurants/recommendation",
      "request": {
        "method": "GET",
        "header": [],
        "url": {
          "raw": "{{BASE_URL}}/restaurants/recommendation?style=chinese",
          "host": ["{{BASE_URL}}"],
          "path": ["restaurants", "recommendation"],
          "query": [
            {
              "key": "vegetarian",
              "value": "no",
              "disabled": true
            },
            {
              "key": "style",
              "value": "chinese"
            }
          ]
        }
      },
      "response": []
    },
    {
      "name": "restaurants/generate",
      "request": {
        "method": "POST",
        "header": [],
        "url": {
          "raw": "{{BASE_URL}}/restaurants/generate",
          "host": ["{{BASE_URL}}"],
          "path": ["restaurants", "generate"]
        }
      },
      "response": []
    }
  ],
  "event": [
    {
      "listen": "prerequest",
      "script": {
        "type": "text/javascript",
        "exec": [""]
      }
    },
    {
      "listen": "test",
      "script": {
        "type": "text/javascript",
        "exec": [""]
      }
    }
  ],
  "variable": [
    {
      "key": "BASE_URL",
      "value": "http://127.0.0.1:5000",
      "type": "string"
    }
  ]
}
```

</details>

I'm checking the logs of the app with Azure by navigating to:

1. [Azure Portal](https://portal.azure.com/)
2. **App Services** > Select app > **Monitoring** > **Log stream**

Next steps:

1. App
2. Azure Budget - I've added a budget alert to the Resource Group, the default is **20$ per month**, but I haven't tested the way it alerts and stops the services, so I should test it.
3. Add a CI/CD pipeline to the project.
   1. Azure
      1. Create an API key and then create a secret in GitHub.
   2. GitHub
      1. Create a CI for building the app
      2. Create a CD for deploying the app - I don't intend to host artifacts, so the deployment will be done directly from the GitHub repo by building the given `tag/branch/version`, this is not smart, but so am I 😄
         1. For infra
         2. For backend (app)
4. Draw the infra with [app.diagrams.net](https://app.diagrams.net/) - Sounds funny that I don't it in the end, but on the other hand, I had no idea what I'm about to do in the beginning, since I wasn't familiar with Azure at all. I think it's a good idea to draw the infra now, after I've done everything, to see if I've missed something.
5. Add `CONTRIBUTING.md` - I've added a few notes about how to go through the local development process of this project, but I think it's a good idea to add a `CONTRIBUTING.md` file.

Future improvements:

1.  Security test - Inspect possible vulnerabilities of the infrastructure, I performed a very simple test of trying to access https://restro.meirg.co.il without the right header and I get blocked by Cloudflare, which is great. I should perform a more thorough test.
2.  Load testing - A simple [ab](https://httpd.apache.org/docs/2.4/programs/ab.html) testing to realize the load on the app.
3.  Autoscaling - I haven't configured autoscaling for the Azure App Service, so I should do that.
4.  Thorough understanding of the used services - I've used Azure App Service and Azure Cosmos DB, but I haven't read the docs thoroughly, so I might have missed some important configurations.
5.  Monitoring - I've added a few logs to the Azure Monitor, but I should add more logs and alerts.
6.  Support multiple environment - I've used a single environment, but I should support multiple environments like `dev`, `staging`, and `prod`. Should be easy enough since I'm using Terraform 🙃
7.  Unittests - I haven't written any tests, so I should write some tests for the app; That is very unprofessional of me 😅. Usually I do it during the development process, but then again, this project was a mystery all the way. I preferred having an app that is up and running, and now I can go crazy and test it. I feel comfortable enough to keep it public, even though it's wasn't battle-tested, since it's protected behind Cloudflare 💪🏻.
