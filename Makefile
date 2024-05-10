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

PACKAGE_FILENAME:=${PROJECT_NAME}.${PACKAGE_VERSION}.zip
PACKAGE_FILE_PATH:=${ROOT_DIR}/${PACKAGE_FILENAME}

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

backend-build:
	@cd ${BACKEND_DIR} && \
	rm -f ${PACKAGE_FILE_PATH} && \
	echo ${PACKAGE_VERSION} > ${BACKEND_VERSION_PATH} && \
	zip -rq ${PACKAGE_FILE_PATH} app.py antenv/ requirements.txt version && \
	ls -lh ${PACKAGE_FILE_PATH}

build: backend-build

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
	az webapp deploy --resource-group ${RESOURCE_GROUP_NAME} --name ${WEBAPP_NAME} --src-path ${PACKAGE_FILE_PATH} --type zip

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

infra-update-dotenv:
	@RESOURCE_GROUP_NAME=$(shell cd ${INFRA_DIR} && terraform output resource_group_name) && \
		WEBAPP_NAME=$(shell cd ${INFRA_DIR} && terraform output webapp_name) && \
		sed -i '' -e "s/RESOURCE_GROUP_NAME=.*/RESOURCE_GROUP_NAME=$${RESOURCE_GROUP_NAME}/" ${ROOT_DIR}/.env && \
		sed -i '' -e "s/WEBAPP_NAME=.*/WEBAPP_NAME=$${WEBAPP_NAME}/" ${ROOT_DIR}/.env

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
