#!/bin/bash

if [ "$1" = "" ] || [ "$1" = "help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $(basename $0) [ubuntu instance name]"
    exit 1
fi

VM_NAME=$1

echo -e "\nRemoving '${VM_NAME}' instance...\n"

VALID_INSTANCE=`multipass ls | grep ${VM_NAME} | awk '{print $1}'`
if [ -z ${VALID_INSTANCE} ]; then
	echo -e "No instance: ${VM_NAME}\n"
	exit 1
fi

VM_IP=`multipass info ${VM_NAME} | grep 'IPv4' | awk '{print $2}'`
if [ ! -z ${VM_IP} ]; then
	echo -e "\nDeleting '${VM_IP}' from 'known_hosts'...\n"
	ssh-keygen -R ${VM_IP}
fi

echo -e "\nDeleting '${VM_NAME}' from multipass...\n"
multipass delete ${VM_NAME}
multipass purge