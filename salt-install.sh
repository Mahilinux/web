#!/bin/bash
# created by Mahesh

# get the latest online repository
sudo rpm --import https://repo.saltproject.io/py3/redhat/7/x86_64/latest/SALTSTACK-GPG-KEY.pub
curl -fsSL https://repo.saltproject.io/py3/redhat/7/x86_64/latest.repo | sudo tee /etc/yum.repos.d/salt.repo

# Install Salt-Minion
yum -y install salt-minion >/dev/null

# restart and enable the services
systemctl --now enable salt-minion > /dev/null

# set the grains
salt-call grains.setval servicenow "{'env': 'Test', 'region': 'Americas', 'manual': 'No'}"

# run the minion jobs
salt-call state.highstate > /dev/null
salt-call state.highstate >/dev/null

echo "Salt-Minion has been successfully installed"
