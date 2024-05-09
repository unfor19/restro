#!make
.ONESHELL:
.EXPORT_ALL_VARIABLES:
.PHONY: all $(MAKECMDGOALS)

UNAME := $(shell uname)
ROOT_DIR:=${CURDIR}
BASH_PATH:=$(shell which bash)



BACKEND_DIR:=${ROOT_DIR}/backend
VENV_DIR_PATH:=${BACKEND_DIR}/.VENV
INFRA_DIR:=${ROOT_DIR}/infra


ifneq ("$(wildcard ${ROOT_DIR}/.env)","")
include ${ROOT_DIR}/.env
endif

# Azure remote state ---------
TFVAR_RESOURCE_GROUP_NAME:=${PROJECT_NAME}-rg
TFVAR_STORAGE_ACCOUNT_NAME:=${PROJECT_NAME}storage
TFVAR_STORAGE_CONTAINER_NAME:=${PROJECT_NAME}container
# ----------------------------


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
	az group create --name ${TFVAR_RESOURCE_GROUP_NAME} --location eastus

	# Create storage account
	az storage account create --resource-group ${TFVAR_RESOURCE_GROUP_NAME} --name ${TFVAR_STORAGE_ACCOUNT_NAME} --sku Standard_LRS --encryption-services blob

	# Create blob container
	az storage container create --name ${TFVAR_STORAGE_CONTAINER_NAME} --account-name ${TFVAR_STORAGE_ACCOUNT_NAME}

azure-login: ## Azure login
	@az login

azure-deploy: ## Azure deploy
	az webapp deploy --resource-group myResourceGroup-67302 --name webapp-67302 --src-path ${PWD}/backend/main.py.zip --type zip
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

backend-run: ## Run main app script
	@python ${BACKEND_DIR}/main.py
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
# --- Terraform --- END --------------------------------------------------------------
