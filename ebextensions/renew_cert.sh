#!/bin/bash

/opt/certbot/certbot-auto \
    renew \
    --debug \
    --non-interactive \
    --standalone \
    --pre-hook "sudo service nginx stop" \
    --post-hook "sudo service nginx start" \
    --renew-hook "/usr/local/bin/renew_cert_hook.sh" \
    $CERTBOT_EXTRA_ARGS 2>&1 |
    /usr/bin/logger -t letsencrypt
