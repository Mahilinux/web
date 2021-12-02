#!/bin/bash
# Created by Mahesh
# This script will extract public and private certs/keys from the wildcard (.pfx) certificate
# Place the pfx zip file in /tmp folder

# unzip the certificate
rm -rf /tmp/certs
unzip /tmp/wc.corp.service-now.com.zip -d /tmp/certs

# Get the certificate and password from Thycotic
pfx_file=/tmp/certs/wc.corp.service-now.com.pfx
pfx_pass_in='xxxxxxx'
pfx_pass_out='abc123'

# Convert to PEM
# openssl pkcs12 -in testuser1.pfx -out temp.pem -passout pass:"${pfx_pass_out}" -passin pass:"${pfx_pass_in}"
# openssl x509 -in temp.pem -noout -enddate

# Key extracting

echo "Extracting encrypted key"
openssl pkcs12 -in $pfx_file -nocerts -out host.encrypted.key -passout pass:"${pfx_pass_out}" -passin pass:"${pfx_pass_in}"

echo "Decrypt encrypted key"
openssl rsa -in host.encrypted.key -out host.key -passin pass:"${pfx_pass_out}"

echo "Delete encrypted key"
rm -rf host.encrypted.key

# Certficate extracting

echo "Get your domain certificate"
openssl pkcs12 -in $pfx_file -clcerts -nokeys -out host.crt -passin pass:"${pfx_pass_in}"

echo "Get your CA certificate"
openssl pkcs12 -in $pfx_file -cacerts -out bundle.crt -passout pass:"${pfx_pass_out}" -passin pass:"${pfx_pass_in}"

echo "Concat the 2 .crt files into a chained.crt"
cat host.crt bundle.crt > ssl-bundle.crt

echo "Delete the bundle.crt and domain.tld.crt files"
rm -rf host.crt bundle.crt

echo "Validate certificate"
#openssl x509 -noout -text -in ssl-bundle.crt | grep CA
echo "cert hash"
openssl x509 -noout -modulus -in ssl-bundle.crt | openssl md5 >/tmp/pub.key

echo "cert key"
openssl rsa -noout -modulus -in host.key | openssl md5 >/tmp/priv.key

#echo "csr"
#openssl req -noout -modulus -in CSR.csr | openssl md5

diff /tmp/pub.key /tmp/priv.key >/dev/null

if [ $? -ne 0 ] ;then
echo "Certificates are invalid"
exit
else
echo "Certificates are valid"
fi

echo "Get certificate expiry date"
openssl x509 -enddate -noout -in ssl-bundle.crt
