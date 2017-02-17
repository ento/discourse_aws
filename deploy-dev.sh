#!/bin/bash -ex

source ./common-variables.sh

out_dir=sourcebundle
zip_file=sourcebundle.zip

image_tag=$(aws ecr list-images --repository-name=$docker_repository | jq -r '.imageIds | sort_by(.imageTag) | .[-1].imageTag')
docker_tag=$docker_registry/$docker_repository:$image_tag
build_tag=b`date +"%Y%m%d-%H%M%S"`
version_label=$image_tag-$build_tag

rm -rf $out_dir $zip_file
mkdir -p $out_dir/.ebextensions

cat Dockerfile.tmpl | DOCKER_TAG=$docker_tag envsubst > $out_dir/Dockerfile
cp ../ebextensions/* $out_dir/.ebextensions/ || true
cp ebextensions/* $out_dir/.ebextensions/
cp Dockerrun.aws.json $out_dir/

(
    cd $out_dir/
    zip -r $zip_file Dockerfile Dockerrun.aws.json .ebextensions
)

aws s3 cp $out_dir/$zip_file s3://$s3_bucket/$version_label.zip

aws elasticbeanstalk create-application-version \
    --application-name $app_name \
    --version-label $version_label \
    --source-bundle S3Bucket="$s3_bucket",S3Key="$version_label.zip"

aws elasticbeanstalk update-environment \
    --application-name $app_name \
    --environment-name $dev_env_name \
    --version-label $version_label
