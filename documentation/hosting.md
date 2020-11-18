# Hosting

Teaching Vacancies is hosted on GOV.UK PaaS. When onboarded you will get access to `dfe-teacher-services` organization and the relevant spaces.

These are the running applications:

- https://dev.teaching-vacancies.service.gov.uk (Dev)
- https://staging.teaching-vacancies.service.gov.uk (Staging)
- https://teaching-vacancies.service.gov.uk (Production)

Plus all the ephemeral review apps that are created when a PR is created on GitHub, and destroyed when the PR is merged.

## Install Cloud Foundry CLI on Mac

```bash
brew install cloudfoundry/tap/cf-cli@7
```

## Login

```bash
CF_API_ENDPOINT=https://api.london.cloud.service.gov.uk
CF_ORG=dfe-teacher-services
```

`$CF_SPACE` is the environment(space) you want to deal with, these are the available ones:

* teaching-vacancies-dev
* teaching-vacancies-staging
* teaching-vacancies-production
* teaching-vacancies-monitoring
* teaching-vacancies-review

For convenience and for security reasons we recommend to use SSO to login:

```bash
cf login --sso -a $CF_API_ENDPOINT -o $CF_ORG -s $CF_SPACE
```

If you need to login with a service account to access production environment:

```bash
cf login -a $CF_API_ENDPOINT -u $CF_USERNAME -p $CF_PASSWORD -o $CF_ORG -s $CF_SPACE
```

## Check space users

```bash
cf space-users $CF_ORG $CF_SPACE
```

## Check organization users

```bash
cf org-users $CF_ORG -a
```

## Set/unset SpaceDeveloper role

```bash
cf set-space-role USER_ID $CF_ORG $CF_SPACE SpaceDeveloper
cf unset-space-role USER_ID $CF_ORG $CF_SPACE SpaceDeveloper
```

## Check running apps

```bash
cf apps
```

There should be 2 apps (more in the case of review apps space):

- webapp: it has a route to serve requests from users
- worker: it subscribe to redis to run asynchronous jobs

## Check running services

```bash
cf services
```

## Check app health and status

```bash
cf app <app_name>
```

## Check environment variables

```bash
cf env <app_name>
```

## Set environment variable

Environment variables are stored in AWS SSM Parameter store and in the repository. Terraform sets them automatically when it deploys the applications to GOV.UK PaaS.

Should you wish to override an individual variable directly:

```bash
cf set-env <app_name> ENV_VAR_NAME env_var_value
cf restart <app_name> --strategy rolling
```

Remember to restart the app, using `--strategy rolling` if you wish to avoid downtime.
In the case of changing environment variables used only by the app, `restart` is sufficient and `restage` is unnecessary:

```bash
cf restart <app_name> --strategy rolling
```

## SSH into app

```bash
cf ssh <app_name>
```

## Access Rails console

```bash
cf ssh <app_name>
cd /teacher-vacancy
/usr/local/bin/bundle exec rails console
```

## Run task

```bash
cf run-task <app_name> -c "rails task:name"
```

## Deploy to dev or staging via commandline

This builds and deploys a Docker image from local code.

```bash
passcode=<passcode> make <environment> deploy-local-image
```
performs these steps:

- Builds and tags a Docker image from local code
- Pushes the image to Docker Hub
- Runs terraform to deploy the docker image

You need:
- Write access to Docker Hub `dfedigital/teaching-vacancies` repository. Ask in #digital-tools-support should you require it.
- `SpaceDeveloper` role in the paas space you want to deploy to
- Log in to Docker Hub (with `docker login`) and GOV.UK PaaS in your terminal
- Obtain SSO passcode from https://login.london.cloud.service.gov.uk/passcode

```bash
make dev deploy-local-image # Deploy to dev
make staging deploy-local-image # Deploy to staging
```

## Deploy to dev or staging via a commit to GitHub

This builds and deploys a Docker image from code in `dev` or `staging` branches.

Push to the `dev` or `staging` branch.
The GitHub actions workflow [deploy_branch.yml](/.github/workflows/deploy_branch.yml) performs these steps:

- Builds and tags a Docker image from code in the GitHub branch
- Pushes the image to Docker Hub
- Deploys the Docker image to PaaS
- Sends a Slack notification to the `#twd_tv_dev` channel

## CI/CD with GitHub Actions

Tests run every time is pushed on a branch.

When a PR is approved and merged into `master` branch an automatic deploy is triggered to `production` environment.

## Maintenance windows for GOV.UK PaaS Postgres and Redis services

From [Redis maintenance times](https://docs.cloud.service.gov.uk/deploying_services/redis/#redis-maintenance-times)

> Every Redis service has a maintenance window of Sunday 11pm to Monday 1:30am UTC every week.

From [PostgreSQL maintenance times](https://docs.cloud.service.gov.uk/deploying_services/postgresql/#postgresql-maintenance-times):

> Each PostgreSQL service you create will have a randomly-assigned weekly 30 minute maintenance window, during which there may be brief downtime. Select a high availability (HA) plan to minimise this downtime. Minor version upgrades (for example from 9.4.1 to 9.4.2) are applied during this maintenance window.
>
> Window start times will vary from 22:00 to 06:00 UTC.

Discussed with Product Owner

- Redis - leave as Sunday 23:00 to Monday 01:30
- Postgres staging - set as Tuesday 23:16 to Tuesday 23:46
- Postgres production - set as Wednesday 23:16 to Wednesday 23:46

With the intention being:
- maintenance overnight on Sunday, Tuesday, Wednesday mean any issues can be remediated on working days (Monday, Wednesday, Thursday)
- this avoid Tuesday as sprint ceremonies day, and Friday when fewer people are working
- staging happens a day before production, so that we can detect failures in the lower environment first

We set these with the CloudFoundry CLI commands, opting for the safer option of applying this configuration change during a maintenance window:
```
cf update-service teaching-vacancies-postgres-staging -p small-11 -c '{"apply_at_maintenance_window": true, "preferred_maintenance_window": "tue:23:16-tue:23:46"}'
cf update-service teaching-vacancies-postgres-production -p medium-ha-11 -c '{"apply_at_maintenance_window": true, "preferred_maintenance_window": "wed:23:16-wed:23:46"}'
```

## Backup/Restore GOV.UK PaaS Postgres service database

Install Conduit plugin

```bash
cf install-plugin conduit
```

### Backup

```bash
cf conduit $CF_POSTGRES_SERVICE_ORIGIN -- pg_dump -x --no-owner -c -f backup.sql
```

### Restore

```bash
cf conduit $CF_POSTGRES_SERVICE_TARGET -- psql < backup.sql
```

## Set up a new environment
- Create file `terraform/workspace-variables/<env>.tfvars`
- Create file `terraform/workspace-variables/<env>_app_env.yml`
- Create SSM parameters of type `SecureString`:
  - `/tvs/<env>/app/BIG_QUERY_API_JSON_KEY`
  - `/tvs/<env>/app/GOOGLE_API_JSON_KEY`
  - `/tvs/<env>/app/secrets`
  - `/tvs/<env>/infra/secrets`
- Run:
  ```shell
  export TF_VAR_paas_sso_passcode=<passcode obtained from https://login.london.cloud.service.gov.uk/passcode>
  export TF_WORKSPACE=<env>
  export TF_VAR_paas_app_docker_image=dfedigital/teaching-vacancies:<tag>
  terraform init terraform/app
  terraform apply -var-file terraform/workspace-variables/<env>.tfvars terraform/app
  ```