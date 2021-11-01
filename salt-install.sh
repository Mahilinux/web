#!/bin/bash
# created by Mahesh

# get the latest online repository
sudo rpm --import https://repo.saltproject.io/py3/redhat/7/x86_64/latest/SALTSTACK-GPG-KEY.pub
curl -fsSL https://repo.saltproject.io/py3/redhat/7/x86_64/latest.repo | sudo tee /etc/yum.repos.d/salt.repo

# Install Salt-Minion
yum -y install salt-minion >/dev/null

# restart and enable the services
systemctl --now enable salt-minion > /dev/null

# fix resolv.conf issue
cat >/etc/resolv.conf <<EOL
search corp.service-now.com reddog.microsoft.com
nameserver 10.230.4.50
nameserver 10.15.10.49
EOL

# chattr +i /etc/resolv.conf

# set the grains
salt-call grains.setval servicenow "{'env': 'Test', 'region': 'Americas', 'manual': 'No'}"

# run the minion jobs
salt-call state.sls modules.ansible > /dev/null
salt-call state.sls modules.sudoers >/dev/null

echo "Salt-Minion has been successfully installed"
