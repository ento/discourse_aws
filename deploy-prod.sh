#!/bin/bash -ex

source ./common-variables.sh

dev_version_label=$(
    aws elasticbeanstalk describe-environments \
        --application-name $app_name \
        --environment-name $dev_env_name \
        --output text \
        --query 'Environments[0].[VersionLabel]')

aws elasticbeanstalk update-environment \
    --application-name $app_name \
    --environment-name $prod_env_name \
    --version-label $dev_version_label \
    --option-setting Namespace=aws:elasticbeanstalk:application:environment,OptionName=CERTBOT_EXTRA_ARGS,Value=
