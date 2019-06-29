#!/bin/bash
yum install git curl -y >/dev/null 2&>1
RTCD=`echo $?`
if [ $RTCD != 0 ]; then
echo "Git client did not installed"
fi

# Configure git
curl -L https://bootstrap.saltstack.com -o install_salt.sh 
sh /root/install_salt.sh -M
git clone https://github.com/Mahilinux/srv.git
mv /root/srv/* /srv
rm -rf /root/srv
