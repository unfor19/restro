#!make
.ONESHELL:
.EXPORT_ALL_VARIABLES:
.PHONY: all $(MAKECMDGOALS)

UNAME := $(shell uname)
ROOT_DIR:=${CURDIR}
BASH_PATH:=$(shell which bash)


SERVICES_DIR:=${ROOT_DIR}/services
BACKEND_DIR:=${ROOT_DIR}/backend
REQUIREMENTS_FILE_PATH:=${BACKEND_DIR}/requirements.txt
BACKEND_VERSION_PATH:=${BACKEND_DIR}/version
VENV_DIR_PATH:=${BACKEND_DIR}/antenv
INFRA_DIR:=${ROOT_DIR}/infra

ifneq ("$(wildcard ${ROOT_DIR}/.env)","")
include ${ROOT_DIR}/.env
endif

TF_VAR_project_name:=${PROJECT_NAME}
STATE_RESOURCE_GROUP_NAME:=${TF_VAR_project_name}-rg-tfstate
STATE_STORAGE_ACCOUNT_NAME:=${PROJECT_NAME}storagetfstate
STATE_STORAGE_CONTAINER_NAME:=${PROJECT_NAME}containertfstate


RESOURCE_GROUP_NAME=${PROJECT_NAME}-rg-${TF_VAR_random_integer}
WEBAPP_NAME=${PROJECT_NAME}-${TF_VAR_random_integer}



# --- OS Settings --- START ------------------------------------------------------------
# Windows
ifneq (,$(findstring NT, $(UNAME)))
_OS:=windows
VENV_BIN_ACTIVATE:=${VENV_DIR_PATH}/Scripts/activate.bat

endif
# macOS
ifneq (,$(findstring Darwin, $(UNAME)))
_OS:=macos
VENV_BIN_ACTIVATE:=${VENV_DIR_PATH}/bin/activate
endif

ifneq (,$(findstring Linux, $(UNAME)))
_OS:=linux
VENV_BIN_ACTIVATE:=${VENV_DIR_PATH}/bin/activate
endif
# --- OS Settings --- END --------------------------------------------------------------

SHELL:=${BASH_PATH}


ifneq (,$(wildcard ${VENV_BIN_ACTIVATE}))
ifeq (${_OS},macos)
SHELL:=source ${VENV_BIN_ACTIVATE} && ${SHELL}
endif
ifeq (${_OS},windows)
SHELL:=${VENV_BIN_ACTIVATE} && ${SHELL}
endif
endif

ifndef PACKAGE_VERSION
PACKAGE_VERSION:=99.99.99rc99e
endif


ifndef DOCKER_REGISTRY
DOCKER_REGISTRY:=docker.io
endif

ifndef DOCKER_OWNER
DOCKER_OWNER:=unfor19
endif


ifndef DOCKER_IMAGE
DOCKER_IMAGE:=${DOCKER_REGISTRY}/${DOCKER_OWNER}/${PROJECT_NAME}
endif

ifndef DOCKER_TAG
DOCKER_TAG:=${PACKAGE_VERSION}
endif
TF_VAR_docker_tag:= ${DOCKER_TAG}

ifndef DOCKER_IMAGE_TAG
DOCKER_IMAGE_TAG:=${DOCKER_IMAGE}:${DOCKER_TAG}
endif

# Removes blank rows - fgrep -v fgrep
# Replace ":" with "" (nothing)
# Print a beautiful table with column
help: ## Print this menu
	@echo
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's~:.* #~~' | column -t -s'#'
	@echo
usage: help


# To validate env vars, add "validate-MY_ENV_VAR"
# as a prerequisite to the relevant target/step
validate-%:
	@if [[ -z '${${*}}' ]]; then \
		echo 'ERROR: Environment variable $* not set' && \
		exit 1 ; \
	fi

print-vars: ## Print env vars
	@echo "CI=${CI}"

# --- Azure --- START ------------------------------------------------------------
##
###Azure
##---
azure-remote-state-init: ## Azure remote state init
	# Source - https://learn.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage?tabs=azure-cli
	# Create resource group
	az group create --name ${STATE_RESOURCE_GROUP_NAME} --location eastus

	# Create storage account
	az storage account create --resource-group ${STATE_RESOURCE_GROUP_NAME} --name ${STATE_STORAGE_ACCOUNT_NAME} --sku Standard_LRS --encryption-services blob

	# Create blob container
	az storage container create --name ${STATE_STORAGE_CONTAINER_NAME} --account-name ${STATE_STORAGE_ACCOUNT_NAME}

azure-service-principal-list: ## Azure service principal list
	az account list --output table

azure-service-principal-create: validate-SUBSCRIPTION_ID validate-RESOURCE_GROUP_NAME ## Azure service principal create
	# Source - https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure?tabs=azure-portal%2Clinux#create-a-service-principal
	az ad sp create-for-rbac --name ${PROJECT_NAME} --role contributor \
														--scopes /subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_NAME} \
														--json-auth

azure-login: ## Azure login
	@az login
# --- Azure --- END --------------------------------------------------------------

# --- Backend --- START ------------------------------------------------------------
##
###Backend
##---
backend-prepare: ## Create a Python virtual environment with venv
	python -m venv ${VENV_DIR_PATH} && \
	python -m pip install -U pip wheel setuptools build twine && \
	ls ${VENV_DIR_PATH}

backend-install: ## Install Python packages
## Provide PACKAGE_NAME=<package_name> to install a specific package
## Example: make venv-install PACKAGE_NAME=requests
	@if [[ -f "${REQUIREMENTS_FILE_PATH}" ]]; then \
		echo "Installing packages from ${REQUIREMENTS_FILE_PATH}" && \
		ls ${REQUIREMENTS_FILE_PATH} && \
		pip install -r "${REQUIREMENTS_FILE_PATH}" ${PACKAGE_NAME} ; \
	elif [[ -n "${PACKAGE_NAME}" ]]; then \
		echo "Installing package ${PACKAGE_NAME}" ; \
		pip install -U ${PACKAGE_NAME} ; \
	else \
		echo "ERROR: No requirements.txt file found and no package name provided" ; \
		exit 1 ; \
	fi

backend-requirements-update: ## Update requirements.txt with current packages
	pip freeze | grep -v '\-e' > ${REQUIREMENTS_FILE_PATH} && \
	cat ${REQUIREMENTS_FILE_PATH}

backend-freeze: ## List installed packages
	pip freeze

backend-build: validate-PACKAGE_VERSION validate-DOCKER_IMAGE_TAG validate-BACKEND_DIR
	@cd ${BACKEND_DIR} && \
	docker build --build-arg PACKAGE_VERSION=${PACKAGE_VERSION} --platform linux/amd64 -t ${DOCKER_IMAGE_TAG} .

backend-push:
	@docker push ${DOCKER_IMAGE_TAG}

build: backend-build
push: backend-push

backend-docker: ## Run
	docker run -it -e DB_CONNECTION_STRING=mongodb://root:example@mongo:27017 \
		--network services_restro -p 8000:8000 --rm ${DOCKER_IMAGE_TAG}

backend-run: ## Run main app script
	@cd ${BACKEND_DIR} && \
	FLASK_PORT=5000 FLASK_DEBUG=true flask run
run: backend-run

backend-run-prod: ## Run main app script in production mode
	@cd ${BACKEND_DIR} && \
	gunicorn -w 4 'app:app'
run-prod: backend-run-prod

# https://learn.microsoft.com/en-us/cli/azure/webapp?view=azure-cli-latest#az-webapp-deploy
backend-deploy:
	az webapp config container set --name ${WEBAPP_NAME} --resource-group ${RESOURCE_GROUP_NAME} --container-image-name ${DOCKER_OWNER}/${PROJECT_NAME}:${PACKAGE_VERSION}


deploy: backend-deploy
# --- Backend --- END --------------------------------------------------------------



# --- Infra --- START ------------------------------------------------------------
##
###Infra
##---
infra-init: ## Infra init
	@cd ${INFRA_DIR} && \
	terraform init

infra-plan: ## Infra plan
	@cd ${INFRA_DIR} && \
	terraform plan -out .infra.plan

infra-apply: ## Infra apply
	@cd ${INFRA_DIR} && \
	terraform apply .infra.plan
	
infra-outputs: ## Infra outputs
	@cd ${INFRA_DIR} && \
	terraform output
# --- Terraform --- END --------------------------------------------------------------


# --- Services --- START ------------------------------------------------------------
##
###Services
##---
.services-up-post:
	@echo "Services are up"
	@echo "MongoDB: mongodb://root:example@localhost:27017/"
	@echo "Mongo Express: http://localhost:8081"

services-up: ## Run services
	@cd ${SERVICES_DIR} && \
	docker-compose up -d && \
	cd ${ROOT_DIR} && \
	$(MAKE) .services-up-post

services-down: ## Stop services
	@cd ${SERVICES_DIR} && \
	docker-compose down --remove-orphans --volumes

# --- Services --- END --------------------------------------------------------------
