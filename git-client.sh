#!/bin/bash
yum install git curl -y >/dev/null 2&>1
RTCD=`echo $?`
if [ $RTCD != 0 ]; then
echo "Git client did not installed"
fi

# Configure git
curl -L https://bootstrap.saltstack.com -o /tmp/install_salt.sh 
sh /tmp/install_salt.sh -M
git clone https://github.com/mahi-linux/srv.git /tmp/srv
mv /tmp/srv/* /srv
rm -rf /tmp/srv
rm -rf /tmp/install_salt.sh
