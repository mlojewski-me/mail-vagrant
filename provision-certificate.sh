#!/bin/bash
set -eux

config_fqdn=$(hostname --fqdn)
ca_file_name='root-ca'
ca_common_name='Root CA'

mkdir -p /vagrant/tls/pki
cd /vagrant/tls/pki

# create the CA certificate.
if [ ! -f $ca_file_name-crt.pem ]; then
    openssl genrsa \
        -out $ca_file_name-key.pem \
        2048 \
        2>/dev/null
    chmod 400 $ca_file_name-key.pem
    openssl req -new \
        -sha256 \
        -subj "/CN=$ca_common_name" \
        -key $ca_file_name-key.pem \
        -out $ca_file_name-csr.pem
    openssl x509 -req -sha256 \
        -signkey $ca_file_name-key.pem \
        -extensions a \
        -extfile <(echo "[a]
            basicConstraints=critical,CA:TRUE,pathlen:0
            keyUsage=critical,digitalSignature,keyCertSign,cRLSign
            ") \
        -days 365 \
        -in  $ca_file_name-csr.pem \
        -out $ca_file_name-crt.pem
    openssl x509 \
        -in $ca_file_name-crt.pem \
        -outform der \
        -out $ca_file_name-crt.der
    # dump the certificate contents (for logging purposes).
    #openssl x509 -noout -text -in $ca_file_name-crt.pem
fi

# trust the CA.
if [ ! -f /usr/local/share/ca-certificates/$ca_file_name.crt ]; then
    cp $ca_file_name-crt.pem /usr/local/share/ca-certificates/$ca_file_name.crt
    update-ca-certificates -v
fi

if [ "$config_fqdn" != '' ] && [ ! -f $config_fqdn-crt.pem ]; then
    openssl genrsa \
        -out $config_fqdn-key.pem \
        2048 \
        2>/dev/null
    chmod 400 $config_fqdn-key.pem
    openssl req -new \
        -sha256 \
        -subj "/CN=$config_fqdn" \
        -key $config_fqdn-key.pem \
        -out $config_fqdn-csr.pem
    openssl x509 -req -sha256 \
        -CA $ca_file_name-crt.pem \
        -CAkey $ca_file_name-key.pem \
        -CAcreateserial \
        -extensions a \
        -extfile <(echo "[a]
            subjectAltName=DNS:$config_fqdn
            extendedKeyUsage=critical,serverAuth
            ") \
        -days 365 \
        -in  $config_fqdn-csr.pem \
        -out $config_fqdn-crt.pem
    openssl pkcs12 -export \
        -keyex \
        -inkey $config_fqdn-key.pem \
        -in $config_fqdn-crt.pem \
        -certfile $config_fqdn-crt.pem \
        -passout pass: \
        -out $config_fqdn-key.p12
    # dump the certificate contents (for logging purposes).
    #openssl x509 -noout -text -in $config_fqdn-crt.pem
    #openssl pkcs12 -info -nodes -passin pass: -in $config_fqdn-key.p12
fi
