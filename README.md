Tooling to deploy Discourse on AWS.

## what's where

- Postgres: RDS
- Rails + Redis: Docker container on Elastic Beanstalk Single Instance deployment
- Docker registry: ECR
- Files and backups: S3
- Outgoing email: SES
- Incoming email + bounce handling: SES + S3 + AWS Lambda
- Passwords for RDS and SES: credstash
- SSL: Let's Encrypt + nginx on the EC2 instance managed by Elastic Beanstalk
- Infrastructure management: Terraform

## what's different from the official launcher

- Skips `db:migrate` and `assets:precompile` on bootstrap
- Uses a custom boot script to:
  - Fetch passwords and export as environment variables
  - Run `db:migrate` and `assets:precompie`
  - Execute the original boot script

## hardcoded assumptions

- We will have one Elastic Beanstalk application named `discourse`
- and two Elastic Beanstalk environments: `discourse-dev` and `discourse-prod`

## directory layout

```
path/to/your/configs
  discourse_aws/ # this repo
  containers/app.yml           # optional pups template to customize the Docker build
  ebextensions/                # optional Elastic Beanstalk configs
  dev/*.tf                     # mix and match modules from discourse_aws/tfmodules..
  prod/*.tf                    # to build AWS resources according to your needs.
```

- `discourse_aws/`
  - bring in this repo in whatever way you like: git submodule, git subtree, or a plain git clone
- `./containers/app.yml`
  - this file, if present, will be merged with this repo's `./containers/app.yml`
  - useful for configuring plugins to install (see: `./samples/app.yml`)
- `./ebextensions/*.config`
  - any file in here will be copied to the sourcebundle for Elastic Beanstalk
  - useful for setting up SSH keys on the EC2 instance (see: `./samples/ssl.config`)

## prerequisites

- install [Terraform](https://www.terraform.io/)
- set up [credstash](https://github.com/fugue/credstash)
- set up your domain name of choice
  - CNAME -> cname_prefix.your_aws_region.elasticbeanstalk.com
  - MX -> inbound-smtp.your_ses_region.amazonaws.com
- set up SES
  - make a new SES user/password
  - verify your sender domain or email address
  - make a receipt rule set and make it active
  - request production access (this can be done later)

## dev setup

- write your own Terraform config by combining modules in `./tfmodules`  (see: `./samples/main.tf`)
  - consider setting `certbot_extra_args` to `--staging` first to test SSL setup
- plug in Terraform variables
  - SES username
  - domain name
  - etc
- initial deploy strategy should be AllAtOnce
  - plus whenever you expect certbot to create a new certificate
- `terraform apply`
- change db password on RDS
- `credstash put discourse_db_password.discourse-dev`
- `credstash put discourse_smtp_password.discourse-dev`
- `./build.sh`
  - builds and tags a Discourse docker image as `vYYYYmmdd-HHMMSS`
- do a `docker push`: exact command will be printed out by `build.sh`
- `./deploy-dev.sh`
  - creates and deploys an application version using the latest docker image on ECR: `vYYYYmmdd-HHMMSS-bYYYYmmdd-HHMMSS`
- change deploy strategy to Immutable to avoid downtime during deploys

## prod setup

same as dev setup except for:

- `credstash put discourse_db_password.discourse-prod`
- `credstash put discourse_smtp_password.discourse-prod`
- deploy script is `./deploy-prod.sh`
  - deploys the same application version as `discourse-dev` environment's

## community setup

- setup s3 upload (otherwise your uploads will be wiped after the next deploy)
- setup s3 backup (optional)
- secure login (optional)
  - set email domains whitelist
  - add Google login or another 3rd party auth provider of your choice
  - sign up through the 3rd party auth provider
  - as the first admin user, grant admin to the second user
  - delete the first user
  - disable local login
- set up incoming email (advised to meet SES's bounce handling guidelines)
  - generate an master API key under Admin > API, go to the Lambda function for receiving email, and set the API key as `DISCOURSE_API_KEY` enivonment variable
  - manual polling enabled
  - reply by email address
  - reply by email enabled
  - test email receiver by using one of the test email addresses at http://docs.aws.amazon.com/ses/latest/DeveloperGuide/mailbox-simulator.html
- go through the setup wizard

## getting ready for let's encrypt production server

- ssh into the instance
- delete staging certs `sudo find /etc/letsencrypt -iname "$your_discourse_hostname*" | xargs rm -rf`
- also delete on s3
- remove `--staging` from `certbot_extra_args`. empty string is okay
- redeploy through Elastic Beanstalk console or another `./deploy-dev.sh` / `./deploy-prod.sh`

## upgrading

- `./build.sh`
- `docker push`
- `./deploy-dev.sh`
- `./deploy-prod.sh`
