#!/bin/bash
# /etc/letsencrypt_backup/functions.sh

config_dir=/etc/letsencrypt
config_archive=/etc/letsencrypt.tgz
domain_cert_dir=$config_dir/live/$CERT_DOMAIN
eb_cert_dir=$config_dir/live/ebcert
s3_url=s3://$CERT_S3_BUCKET/certs/$CERT_DOMAIN.tgz

backup_cert() {
    pushd $(dirname "$config_archive")
    rm -f "$config_archive"
    tar cfzv "$config_archive" $(basename "$config_dir")
    popd
    aws s3 cp "$config_archive" $s3_url
}

restore_cert() {
    aws s3 cp $s3_url "$config_archive" || true
    if [ -f "$config_archive" ]; then
        pushd $(dirname "$config_archive")
        tar xfzv "$config_archive"
        popd
    fi
}

clean_cert() {
    # need to clear the whole directory or certbot will complain
    rm -rf "$config_dir/live" "$config_dir/archive" "$config_dir/renewal"
}

link_eb_cert() {
    rm -rf "$eb_cert_dir"
    ln -sfT "$domain_cert_dir" "$eb_cert_dir"
}

cert_missing() {
    [ ! -e "$domain_cert_dir/fullchain.pem" ] || [ ! -e "$domain_cert_dir/privkey.pem" ]
}
