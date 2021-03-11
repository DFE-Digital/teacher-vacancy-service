.DEFAULT_GOAL		:=help
SHELL				:=/bin/bash
DOCKER_REPOSITORY	:=dfedigital/teaching-vacancies
LOCAL_BRANCH		:=$$(git rev-parse --abbrev-ref HEAD)
LOCAL_SHA			:=$$(git rev-parse HEAD)
LOCAL_TAG			:=dev-$(LOCAL_BRANCH)-$(LOCAL_SHA)

##@ Query parameter store to display environment variables. Requires AWS credentials

.PHONY: install-fetch-config
install-fetch-config:
	[ ! -f bin/fetch_config.rb ] \
		&& curl -s https://raw.githubusercontent.com/DFE-Digital/bat-platform-building-blocks/master/scripts/fetch_config/fetch_config.rb -o bin/fetch_config.rb \
		&& chmod +x bin/fetch_config.rb \
		|| true

.PHONY: print-env
print-env: install-fetch-config ## make -s local print-env > .env
		$(if $(env), , $(error Usage: make <env> print-env))
		@bin/fetch_config.rb -s aws-ssm-parameter-path:/teaching-vacancies/$(env)/app \
			-s yaml-file:terraform/workspace-variables/$(env)_app_env.yml \
			-f shell-env-var \
			$(local_override) -d stdout $(local_filter)

##@ Set environment and corresponding configuration

.PHONY: local
local: ## local # Same values as the deployed dev environment, adapted for local developmemt
		$(eval env=dev)
		$(eval local_override=-d file:terraform/workspace-variables/local_app_env.yml -d file:terraform/workspace-variables/my_app_env.yml)
		$(eval local_filter=| sed -e '/RAILS_ENV=/d' -e '/ROLLBAR_ENV=/d')
		@bin/algolia-prefix > terraform/workspace-variables/my_app_env.yml

.PHONY: dev
dev: ## dev
		$(eval env=dev)
		$(eval var_file=$(env))
		$(eval backend_config=-backend-config="key=$(env)/app.tfstate")

.PHONY: review
review: ## review # Requires `pr_id=NNNN`
		$(if $(pr_id), , $(error Missing environment variable "pr_id"))
		$(eval env=review-pr-$(pr_id))
		$(eval export TF_VAR_environment=$(env))
		$(eval var_file=review)
		$(eval backend_config=-backend-config="key=review/$(env).tfstate")

.PHONY: staging
staging: ## staging
		$(eval env=staging)
		$(eval var_file=$(env))
		$(eval backend_config=-backend-config="key=$(env)/app.tfstate")

.PHONY: production
production: ## production # Requires `CONFIRM_PRODUCTION=true`
		$(if $(CONFIRM_PRODUCTION), , $(error Can only run with CONFIRM_PRODUCTION))
		$(eval env=production)
		$(eval var_file=$(env))
		$(eval backend_config=-backend-config="key=$(env)/app.tfstate")

##@ Docker - build, tag, and push an image from local code. Requires Docker CLI

.PHONY: build-local-image
build-local-image: ## make build-local-image
		$(eval export DOCKER_BUILDKIT=1)
		docker build \
			--build-arg BUILDKIT_INLINE_CACHE=1 \
			--cache-from $(DOCKER_REPOSITORY):builder-master \
			--cache-from $(DOCKER_REPOSITORY):builder-$(LOCAL_BRANCH) \
			--cache-from $(DOCKER_REPOSITORY):master \
			--cache-from $(DOCKER_REPOSITORY):$(LOCAL_BRANCH) \
			--cache-from $(DOCKER_REPOSITORY):$(LOCAL_TAG) \
			--tag $(DOCKER_REPOSITORY):$(LOCAL_BRANCH) \
			--tag $(DOCKER_REPOSITORY):$(LOCAL_TAG) \
			--target production \
			.

.PHONY: push-local-image
push-local-image: build-local-image ## make push-local-image # Requires active Docker Hub session (`docker login`)
		docker push $(DOCKER_REPOSITORY):$(LOCAL_BRANCH)
		docker push $(DOCKER_REPOSITORY):$(LOCAL_TAG)
		$(eval tag=$(LOCAL_TAG))

.PHONY: plan-local-image
plan-local-image: push-local-image terraform-app-plan## make passcode=MyPasscode <env> plan-local-image # Requires active Docker Hub session (`docker login`)

.PHONY: deploy-local-image
deploy-local-image: push-local-image terraform-app-plan## make passcode=MyPasscode <env> deploy-local-image # Requires active Docker Hub session (`docker login`)

##@ Plan or apply changes to dev, review, staging, or production. Requires Terraform CLI

.PHONY: check-docker-tag
check-docker-tag:
		$(if $(tag), , $(error Missing environment variable "tag"))
		$(eval export TF_VAR_paas_app_docker_image=$(DOCKER_REPOSITORY):$(tag))

.PHONY: terraform-app-init
terraform-app-init:
		$(if $(passcode), , $(error Missing environment variable "passcode"))
		$(eval export TF_VAR_paas_sso_passcode=$(passcode))
		cd terraform/app && rm -f .terraform.lock.hcl && terraform init -reconfigure -input=false $(backend_config)

.PHONY: terraform-app-plan
terraform-app-plan: terraform-app-init check-docker-tag ## make passcode=MyPasscode tag=dev-08406f04dd9eadb7df6fcda5213be880d7df37ed-20201022090714 <env> terraform-app-plan
		cd terraform/app && terraform plan -var-file ../workspace-variables/$(var_file).tfvars

.PHONY: terraform-app-apply
terraform-app-apply: terraform-app-init check-docker-tag ## make passcode=MyPasscode tag=47fd1475376bbfa16a773693133569b794408995 <env> terraform-app-apply
		cd terraform/app && terraform apply -input=false -var-file ../workspace-variables/$(var_file).tfvars -auto-approve

.PHONY: terraform-app-destroy-review
terraform-app-destroy-review: terraform-app-init ## make passcode=MyPasscode CONFIRM_DESTROY=true pr_id=2086 review terraform-app-destroy-review
		$(if $(CONFIRM_DESTROY), , $(error Can only run with CONFIRM_DESTROY))
		cd terraform/app && terraform destroy -var-file ../workspace-variables/review.tfvars -auto-approve

##@ terraform/common code. Requires privileged IAM account to run

.PHONY: terraform-common-init
terraform-common-init:
		cd terraform/common && rm -f .terraform.lock.hcl && terraform init -reconfigure -input=false

.PHONY: terraform-common-plan
terraform-common-plan: terraform-common-init ## make terraform-common-plan
		cd terraform/common && terraform plan

.PHONY: terraform-common-apply
terraform-common-apply: terraform-common-init ## make terraform-common-apply
		cd terraform/common && terraform apply

##@ terraform/monitoring. Deploys grafana, prometheus monitoring on Gov.UK PaaS

.PHONY: terraform-monitoring-init
terraform-monitoring-init:
		$(if $(passcode), , $(error Missing environment variable "passcode"))
		$(eval export TF_VAR_paas_sso_passcode=$(passcode))
		cd terraform/monitoring && rm -f .terraform.lock.hcl && terraform init -upgrade=true -reconfigure -input=false

.PHONY: terraform-monitoring-plan
terraform-monitoring-plan: terraform-monitoring-init ## make passcode=MyPasscode terraform-monitoring-plan
		cd terraform/monitoring && terraform plan -input=false

.PHONY: terraform-monitoring-apply
terraform-monitoring-apply: terraform-monitoring-init ## make passcode=MyPasscode terraform-monitoring-apply
		cd terraform/monitoring && terraform apply -input=false -auto-approve

##@ Help

.PHONY: help
help:  ## Display this help
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m\033[0m\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
