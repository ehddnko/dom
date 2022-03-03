#!/bin/bash

help()
{
	echo -e "\nUsage: $(basename $0) [-n | --name] [-c | --cpu] [-m | memory]"
	echo -e "[-d | --disk] [-v | --version] [-i | --identity] [-h | --help]\n"
	echo -e "-n, --name\n\tName of Ubuntu instance.\n"
	echo -e "-c, --cpu\n\tNumber of CPUs to allocate.\n\tMinimum: 1, default: 1.\n"
	echo -e "-m, --memory\n\tAmount of memory to allocate. Positive integers, in bytes, or with K, M, G suffix.\n\tMinimum: 128M, default: 1G.\n"
	echo -e "-d, --disk\n\tDisk space to allocate. Positive integers, in bytes, or with K, M, G siffix.\n\tMinimum: 512M, default: 5G.\n"
	echo -e "-v, --version\n\tUbuntu image to launch an instance from. This can be a partial image hash or an Ubuntu release version, codename or alias.\n\tUse 'multipass find' to see what images are available.\n"
	echo -e "-i, --identity\n\tA file from which the identity key(private key) for public key authentication is read.\n"
	echo -e "-h, --help\n\tOutput a usage guide and exit successfully.\n"
}

# getopt reference: http://manpages.ubuntu.com/manpages/trusty/man1/getopt.1.html
# referred example: https://stackabuse.com/how-to-parse-command-line-arguments-in-bash/

SHORT=n:,c:,m:,d:,v:,i:,h
LONG=name:,cpu:,memory:,disk:,version:,identity:,help
OPTS=$(getopt -a --options ${SHORT} --longoptions ${LONG} -- "$@")

# Returns the count of arguments that are in short or long options
VALID_ARGS=$#

if [ "${VALID_ARGS}" -eq 0 ]; then
	help
	exit 1
fi

eval set -- "${OPTS}"

while :
do
	case "$1" in
		-n | --name)
			VM_NAME=$2
			shift 2
			;;

		-c | --cpu)
			CPU=$2
			shift 2
			;;

		-m | --memory)
			MEMORY=$2
			shift 2
			;;

		-d | --disk)
			DISK=$2
			shift 2
			;;

		-v | --version)
			UBUNTU_VERSION=$2
			shift 2
			;;

		-i | --identity)
			IDENTITY_FILE=$2
			shift 2
			;;

		-h | --help)
			help
			exit 0
			;;

		--)
			shift;
			break
			;;

		*)
			echo "Invalid option: $1" >&2
			help
			exit 1
			;;
	esac
done

# Verify all arguments are valid
if [[ ! -z "${VM_NAME}" ]]; then
	echo -e "\nInstance name: '${VM_NAME}'"
else
	echo -e "\nErr: missing instance name: '${VM_NAME}'" >&2
	exit 1
fi

if [[ ! -z "${CPU}" ]]; then
	if [[ ${CPU} -ge 1 ]]; then
		echo -e "\nNumber of CPUs: ${CPU}"
	else
		echo -e "\nErr: Invalid CPU numbers." >&2
		exit 1
	fi
else
	echo -e "\nErr: missing number of CPUs." >&2
	exit 1
fi

if [[ ! -z "${MEMORY}" ]]; then
	if [[ ${MEMORY:(-1)} =~ "K"|"M"|"G" ]]; then
		if { [[ ${MEMORY:(-1)} == "K" ]] && [[ ${MEMORY%[A-Z]} -ge 131072 ]] ;} \
		|| { [[ ${MEMORY:(-1)} == "M" ]] && [[ ${MEMORY%[A-Z]} -ge 128 ]] ;} \
		|| { [[ ${MEMORY:(-1)} == "G" ]] && [[ ${MEMORY%[A-Z]} -ge 1 ]] ;}; then
			echo -e "\nMemory size: ${MEMORY}"
		else
			echo -e "\nErr: Invalid memory size: ${MEMORY}" >&2
			exit 1
		fi
	else
		if [[ ${MEMORY:(-1)} =~ [a-z] ]]; then
			echo -e "\nErr: Lowercase letters are not supported for memory size!" >&2
			exit 1
		fi

		if [[ ${MEMORY} -ge 134217728 ]]; then
			echo -e "\nMemory size: ${MEMORY}"
		else
			echo -e "\nErr: Invalid memory size: ${MEMORY}" >&2
			exit 1
		fi
	fi
else
	echo -e "\nErr: missing memory size." >&2
	exit 1
fi

if [[ ! -z "${DISK}" ]]; then
	if [[ ${DISK:(-1)} =~ "K"|"M"|"G" ]]; then
		if { [[ ${DISK:(-1)} == "K" ]] && [[ ${DISK%[A-Z]} -ge 524288 ]] ;} \
		|| { [[ ${DISK:(-1)} == "M" ]] && [[ ${DISK%[A-Z]} -ge 512 ]] ;} \
		|| { [[ ${DISK:(-1)} == "G" ]] && [[ ${DISK%[A-Z]} -ge 1 ]] ;}; then
			echo -e "\nDisk size: ${DISK}"
		else
			echo -e "\nErr: Invalid disk size: ${DISK}" >&2
			exit 1
		fi
	else
		if [[ ${DISK:(-1)} =~ [a-z] ]]; then
			echo -e "\nErr: Lowercase letters are not supported for disk size!" >&2
			exit 1
		fi

		if [[ ${DISK} -ge 536870912 ]]; then
			echo -e "\nDisk size: ${DISK}"
		else
			echo -e "\nErr: Invalid disk size: ${DISK}" >&2
			exit 1
		fi
	fi
else
	echo -e "\nErr: missing disk size." >&2
	exit 1
fi

if [[ ! -z "${UBUNTU_VERSION}" ]]; then
	if [ "${UBUNTU_VERSION}" ]; then
		VERIFY_UBUNTU_IMAGE=`multipass find ${UBUNTU_VERSION} 2>&1 > /dev/null`
		if [ -z ${VERIFY_UBUNTU_IMAGE} ]; then
			echo -e "\nUbuntu image: '${UBUNTU_VERSION}'"
			multipass find ${UBUNTU_VERSION} 2> /dev/null
		else
			echo -e "\n${VERIFY_UBUNTU_IMAGE}" >&2
			exit 1
		fi
	else
		echo -e "\nErr: Invalid Ubuntu image: '${UBUNTU_VERSION}'" >&2
		exit 1
	fi
else
	echo -e "\nErr: missing Ubuntu image version." >&2
	exit 1
fi

if [[ ! -z "${IDENTITY_FILE}" ]]; then
	if [ -s ${IDENTITY_FILE} ]; then
		echo -e "\nIdentity file path: ${IDENTITY_FILE}"
	else
		echo -e "\nErr: Invalid identity file path: ${IDENTITY_FILE}" >&2
		exit 1
	fi
else
	echo -e "\nErr: missing SSH identity file path." >&2
	exit 1
fi

# launch ubuntu instance with user input values
echo -e "\nLaunching ubuntu instance...\n"
multipass launch -n ${VM_NAME} -c ${CPU} -m ${MEMORY} -d ${DISK} --cloud-init ./cloud-config.yaml ${UBUNTU_VERSION}

# echo -e "\nMounting host directory...\n"
# multipass mount ${MOUNT_SOURCE_PATH} ${VM_NAME}:/home/ubuntu/host/

# "Starting" means the vm was started, "Running" means it actually booted and is reachable by Multipass.
echo -e "\nChecking ${VM_NAME} status...\n"
UBUNTU_INSTANCE_STATUS=`multipass ls | grep ${VM_NAME} | awk '{print $2}'`
echo -e "'${UBUNTU_INSTANCE_STATUS}'\n"
if [[ ${UBUNTU_INSTANCE_STATUS} != "Running" ]]; then
	multipass ls
	if [[ ${UBUNTU_INSTANCE_STATUS} == "Starting" ]]; then
		echo -e "\nInstance is not reachable by Multipass! Restart multipassd and instance..."
		OS_VERSION=`uname -a | awk '{print $1}'`
		if [[ ${OS_VERSION} == "Darwin" || ${OS_VERSION} == "Linux" ]]; then
			# MacOs or Linux
			sudo pkill multipassd
		else
			# Windows
			taskkill //F //T //IM multipassd.exe
		fi
		echo -e "\nWait for running multipassd..."
		while [[ ! -z `multipass ls 2>&1 > /dev/null` ]]; do
			sleep 15
		done
		echo -e "\nStarting ${VM_NAME} instance..."
		multipass start ${VM_NAME}
	else
		echo -e "\nRunning instance failed!" >&2
		exit 1
	fi
fi

# check instance's IPv4 address
UBUNTU_INSTANCE_IP=`multipass ls | grep ${VM_NAME} | awk '{print $3}'`
if [[ ${UBUNTU_INSTANCE_IP:0:1} =~ [0-9] ]]; then
	echo -e "\nInstance's IPv4: ${UBUNTU_INSTANCE_IP}\n"
else
	echo -e "\nFailed to get instance's IPv4!\n" >&2
	exit 1
fi

# set instance as primary
echo -e "\nSetting ${VM_NAME} as primary...\n"
multipass set client.primary-name=${VM_NAME}

# unmount automatic home mount from primary instance
echo -e "\nUnmounting automatic home mount from primary instance...\n"
multipass umount ${VM_NAME}

echo -e "\nSetting up SSH inside ubuntu instance...\n"
multipass transfer setup-ssh.sh ${VM_NAME}:setup-ssh.sh
multipass exec ${VM_NAME} -- chmod +x ./setup-ssh.sh
multipass exec ${VM_NAME} -- ./setup-ssh.sh

echo -e "\nConfiguring SSH between host and ubuntu instance...\n"
UBUNTU_INSTANCE_USERNAME=`multipass exec ${VM_NAME} -- whoami`
if [ ! -f "~/.ssh/config" ]; then
	echo -e "Host ${VM_NAME}\n  HostName ${UBUNTU_INSTANCE_IP}\n  User ${UBUNTU_INSTANCE_USERNAME}\n  IdentityFile ${IDENTITY_FILE}\n  IdentitiesOnly yes" >> ~/.ssh/config
else
	echo -e "Host ${VM_NAME}\n  HostName ${UBUNTU_INSTANCE_IP}\n  User ${UBUNTU_INSTANCE_USERNAME}\n  IdentityFile ${IDENTITY_FILE}\n  IdentitiesOnly yes" > ~/.ssh/config
fi
if [ ! -f "~/.ssh/known_hosts" ]; then
	ssh-keyscan -H ${UBUNTU_INSTANCE_IP} >> ~/.ssh/known_hosts
else
	ssh-keyscan -H ${UBUNTU_INSTANCE_IP} > ~/.ssh/known_hosts
fi

echo -e "\nVerifying SSH connection...\n"
ssh -q -o BatchMode=yes ${VM_NAME} 'exit 0'
VERIFY_SSH=$?
if [ ${VERIFY_SSH} -ne 0 ]; then
	echo -e "Unable to SSH on: ${VM_NAME}\n" >&2
	echo -e "-------- SSH config --------\n`cat ~/.ssh/config`"
	exit 1
else
	echo -e "SSH connection verified!\n"
fi

echo -e "\nSetting up docker...\n"
multipass transfer setup-docker.sh ${VM_NAME}:setup-docker.sh
multipass exec ${VM_NAME} -- chmod +x ./setup-docker.sh
multipass exec ${VM_NAME} -- ./setup-docker.sh

echo -e "\nVerifying docker installation...\n"
# verify that docker engine is installed correctly
ssh ${VM_NAME} docker pull hello-world
VERIFY_DOCKER=`ssh ${VM_NAME} docker run hello-world 2>&1 > /dev/null`
if [[ -z ${VERIFY_DOCKER} ]]; then
	ssh ${VM_NAME} docker system prune -a -f > /dev/null 2>&1
	echo -e "docker installation verified!\n"
else
	echo -e "Verify docker failed: ${VERIFY_DOCKER}\n" >&2
	exit 1
fi

echo -e "\n-------- multipass version --------"
multipass version

echo -e "\n-------- multipass info --------"
multipass info ${VM_NAME}

echo -e "\n-------- instance list --------"
multipass ls

echo -e "\n-------- SSH config --------"
cat ~/.ssh/config

echo -e "\n-------- docker version --------"
multipass exec ${VM_NAME} -- docker --version

echo -e "\n-------- docker-compose version --------"
multipass exec ${VM_NAME} -- docker-compose --version

echo -e "\n-------- docker info --------"
multipass exec ${VM_NAME} -- docker info