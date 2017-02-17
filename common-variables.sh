#!/bin/bash -x

app_name=discourse
dev_env_name=discourse-dev
prod_env_name=discourse-prod

account_id=$(aws sts get-caller-identity --output text --query 'Account')
region=$(aws configure get region)

if [ -z "$account_id" ] || [ -z "$region" ]; then
    echo "Could not determine your AWS account ID. Check out the log above."
    echo "(Is awscli installed? Do you have access credentials set up?)"
    exit 1
fi

docker_registry=$account_id.dkr.ecr.$region.amazonaws.com
docker_repository=discourse_web

# todo: document you need this s3 bucket
s3_bucket=discourse-sourcebundles-$account_id
