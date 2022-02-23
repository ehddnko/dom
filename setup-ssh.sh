#!/bin/bash

echo -e "\nSetting up SSH configuration...\n"
SSH_PRIVATE_KEY_PATH=`ls -1 ~/.ssh/ssh_host_* | sed -e 's/\.pub$//' | uniq -c | awk '{print $2}'`
echo -e "Host github.com\n  User git\n  IdentityFile ${SSH_PRIVATE_KEY_PATH}\n  IdentitiesOnly yes" > ~/.ssh/config
ssh-keyscan -H github.com >> ~/.ssh/known_hosts

exit 0