#!/bin/bash -ex

mkdir -p /etc/ssl
if [ ! -e /etc/ssl/dhparams.pem ]; then
    openssl dhparam -out /etc/ssl/dhparams.pem 2048
fi

mkdir -p /opt/certbot
if [ ! -e /opt/certbot/certbot-auto ]; then
     wget https://dl.eff.org/certbot-auto -O /opt/certbot/certbot-auto
     chmod a+x /opt/certbot/certbot-auto
fi

source /etc/letsencrypt_backup/functions.sh

if cert_missing; then
    restore_cert
fi

if cert_missing; then
    clean_cert
    /opt/certbot/certbot-auto \
        certonly \
        --debug \
        --non-interactive \
        --email $CERT_EMAIL \
        --agree-tos \
        --standalone \
        --domains $CERT_DOMAIN \
        --keep-until-expiring \
        --pre-hook "service nginx stop" \
        $CERTBOT_EXTRA_ARGS
    backup_cert
fi

link_eb_cert
