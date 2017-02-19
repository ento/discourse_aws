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

config_dir=/etc/letsencrypt
domain_cert_dir=$config_dir/live/$CERT_DOMAIN
eb_cert_dir=$config_dir/live/ebcert

if [ ! -e "$domain_cert_dir/fullchain.pem" ] || [ ! -e "$domain_cert_dir/privkey.pem" ]; then
    aws s3 sync s3://$CERT_S3_BUCKET/certs/$CERT_DOMAIN "$config_dir" || true
fi

if [ ! -e "$domain_cert_dir/fullchain.pem" ] || [ ! -e "$domain_cert_dir/privkey.pem" ]; then
    # need to clear the whole directory or certbot will complain
    rm -rf "$config_dir/live" "$config_dir/archive" "$config_dir/renewal"
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
    aws s3 sync --delete "$config_dir" s3://$CERT_S3_BUCKET/certs/$CERT_DOMAIN
fi

rm -rf "$eb_cert_dir"
ln -sfT "$domain_cert_dir" "$eb_cert_dir"
