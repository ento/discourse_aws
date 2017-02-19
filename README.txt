Discourse on AWS Elastic Beanstalk. Also Terraform modules.

## what's where
- postgres: rds
- email: ses
- rails + redis: docker on beanstalk
- passwords for postgres and email: credstash
- ssl: let's encrypt + nginx on the ec2 instance managed by elastic beanstalk

## what's different from launcher
- skips db:migrate and assets:precompile on bootstrap
- uses a custom boot script:
  - fetch passwords and export as environment variables
  - run db:migrate and assets:precompie

## config

- git clone ... ./discourse_eb
- ./ebextensions/*.config
  - any file in here will be copied to the sourcebundle for elastic beanstalk
  - for setting up ssh keys
- ./containers/app.yml
  - this file, if present, will be merged with ./discourse_eb/containers/app.yml
  - for configuring plugins to install

## dev setup

- setup domain name: cname -> cname_prefix.region.elasticbeanstalk.com
- make a new ses user/password
- write your own terraform config by combining modules in ./tfmodules
- plug in ses username to terraform and other variables
- whenever you expect certbot to do its thing, deploy strategy should be AllAtOnce
- terraform apply
- change db password on rds
- credstash put discourse_db_password.discourse-dev
- credstash put discourse_smtp_password.discourse-dev
- build.sh
- docker push
- deploy-dev.sh

## getting ready for let's encrypt production serer

- ssh to the instance
- sudo find /etc/letsencrypt -iname "discourse.noredink.com*" | xargs rm -rf
- also delete on s3

## prod setup

- write your own terraform config by combining modules in ./tfmodules
- setup variables
- whenever you expect certbot to do its thing, deploy strategy should be AllAtOnce
- terraform apply
- change db password on rds
- setup domain name: cname -> cname_prefix.region.elasticbeanstalk.com
- credstash put discourse_db_password.discourse-prod
- credstash put discourse_smtp_password.discourse-prod
- deploy-prod.sh

## community setup

- set email domains whitelist
- add google login
- sign up through google oauth and log out
- grant admin to the second user
- delete first user
- disable local login
- setup s3 upload
- setup s3 backup
- setup wizard

## upgrading

- build.sh
- docker push
- deploy-dev.sh
- deploy-prod.sh
