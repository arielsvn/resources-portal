#!/bin/bash

# This is a template for the instance-user-data.sh script for the API Server.
# For more information on instance-user-data.sh scripts, see:
# https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html

# This script will be formatted by Terraform, which will read files from
# the project into terraform variables, and then template them into
# the following script. These will then be written out to files
# so that they can be used locally.

# Change to home directory of the default user
cd /home/ubuntu

# Install and configure Nginx.
cat <<"EOF" > nginx.conf
${nginx_config}
EOF
apt-get update -y
apt-get install nginx -y
cp nginx.conf /etc/nginx/nginx.conf
service nginx restart

# Install, configure and launch our CloudWatch Logs agent
cat <<EOF >awslogs.conf
[general]
state_file = /var/lib/awslogs/agent-state

[/tmp/error.log]
file = /tmp/error.log
log_group_name = ${log_group}
log_stream_name = log-stream-api-nginx-error-${user}-${stage}

[/tmp/access.log]
file = /tmp/access.log
log_group_name = ${log_group}
log_stream_name = log-stream-api-nginx-access-${user}-${stage}

EOF

mkdir /var/lib/awslogs
wget https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py
python ./awslogs-agent-setup.py --region ${region} --non-interactive --configfile awslogs.conf
# Rotate the logs, delete after 3 days.
echo "
/tmp/error.log {
    missingok
    notifempty
    compress
    size 20k
    daily
    maxage 3
}" >> /etc/logrotate.conf
echo "
/tmp/access.log {
    missingok
    notifempty
    compress
    size 20k
    daily
    maxage 3
}" >> /etc/logrotate.conf

# Install our environment variables
cat <<"EOF" > environment
${api_environment}
EOF

chown -R ubuntu /home/ubuntu

STATIC_VOLUMES=/tmp/volumes_static
mkdir -p /tmp/volumes_static
chmod a+rwx /tmp/volumes_static

# Pull the API image.
api_docker_image=${dockerhub_repo}/resources_portal_api:${system_version}
docker pull $api_docker_image

# Migrate first.
# These database values are created after TF
# is run, so we have to pass them in programatically
docker run \
       --env-file environment \
       -e DJANGO_CONFIGURATION=Production \
       -e DATABASE_HOST=${database_host} \
       -e DATABASE_PORT=${database_port} \
       -e DATABASE_NAME=${database_name} \
       -e DATABASE_USER=${database_user} \
       -e DATABASE_PASSWORD=${database_password} \
       -e PORT=8081 \
       -v "$STATIC_VOLUMES":/tmp/www/static \
       --log-driver=awslogs \
       --log-opt awslogs-region=${region} \
       --log-opt awslogs-group=${log_group} \
       --log-opt awslogs-stream=${log_stream} \
       -p 8081:8081 \
       --name=resources_portal_migrations \
       $api_docker_image python3 manage.py migrate

# Start the API image.
docker run \
       --env-file environment \
       -e DJANGO_CONFIGURATION=Production \
       -e DATABASE_HOST=${database_host} \
       -e DATABASE_PORT=${database_port} \
       -e DATABASE_NAME=${database_name} \
       -e DATABASE_USER=${database_user} \
       -e DATABASE_PASSWORD=${database_password} \
       -e PORT=8081 \
       -v "$STATIC_VOLUMES":/tmp/www/static \
       --log-driver=awslogs \
       --log-opt awslogs-region=${region} \
       --log-opt awslogs-group=${log_group} \
       --log-opt awslogs-stream=${log_stream} \
       -p 8081:8081 \
       --name=resources_portal_api \
       -d $api_docker_image

# Don't leave secrets lying around.
rm -f environment

# Delete the cloudinit and syslog in production.
export STAGE=${stage}
if [[ $STAGE = *"prod"* ]]; then
    rm /var/log/cloud-init.log
    rm /var/log/cloud-init-output.log
    rm /var/log/syslog
fi
