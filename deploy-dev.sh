#!/bin/bash -x

# todo: document
# credstash put discourse_db_password env=$env_name
# credstash put discourse_smtp_password env=$env_name

source ./common-variables.sh

env_name=discourse-dev
zip_file=sourcebundle.zip

version_label=$(aws ecr list-images --repository-name=$docker_repository | jq -r '.imageIds[0].imageTag')
docker_tag=$docker_registry/$docker_repository:$version_label

rm -f $zip_file

cat Dockerfile.tmpl | DOCKER_TAG=$docker_tag envsubst > Dockerfile

aws s3 sync s3://$s3_bucket/ebextensions .ebextensions --delete

zip -r $zip_file Dockerfile Dockerrun.aws.json .ebextensions

# todo: document
# eval $(aws ecr get-login)
# http://docs.aws.amazon.com/AmazonECR/latest/userguide/Registries.html#registry_auth
# aws ecr create-repository --repository-name discourse_web
# http://docs.aws.amazon.com/AmazonECR/latest/userguide/ECR_AWSCLI.html#AWSCLI_create_repository
docker push $docker_tag

aws elasticbeanstalk delete-application-version \
    --application-name $app_name \
    --version-label $version_label \
    --delete-source-bundle

aws s3 cp $zip_file s3://$s3_bucket/$version_label.zip

aws elasticbeanstalk create-application-version \
    --application-name $app_name \
    --version-label $version_label \
    --source-bundle S3Bucket="$s3_bucket",S3Key="$version_label.zip"

aws elasticbeanstalk update-environment \
    --application-name $app_name \
    --environment-name $env_name \
    --version-label $version_label
