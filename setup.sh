#!/bin/bash

# V0.04

#####################################
# Install chia stuff
#####################################
setupChia (){
	# Checkout the source and install
	git clone https://github.com/Chia-Network/chia-blockchain.git /usr/lib/chia-blockchain -b latest --recurse-submodules
	
	# Make the log dir
	mkdir /root/chialogs
	
	cd /usr/lib/chia-blockchain

	# Install chia
	sudo sh /usr/lib/chia-blockchain/install.sh

	# Activate Chia
	. ./activate

	chia init

	pip install --force-reinstall git+https://github.com/ericaltendorf/plotman@main

	plotman config generate
}

#####################################
# Add chrontab for plotman on boot
#####################################
setupChron (){
	local chronFile="/hive/etc/crontab.root"
	local croncmd="@reboot rm /mnt/TMP-0000/*; su -c \"screen -dmS chia bash -c '. /usr/lib/chia-blockchain/activate; plotman interactive; exec bash'\""

	grep -qxF "$croncmd" "$chronFile" || echo "$croncmd" >> "$chronFile"
}

#####################################
#Setup All Element Drives Plugged in
#####################################
setupTmpDrives () {
	local driveNo=0
	local drives=($(blkid | grep nvme | sed -n 's/.* UUID=\"\([^\"]*\)\".*/\1/p';))
	local driveFile="/etc/fstab"
	local formattedTmpDirs=""

	for uuid in $drives 
	do
		local drivePath="/mnt/TMP-$(printf "%04d\n" $driveNo)"
		local driveCmd="UUID=$uuid $drivePath    auto nosuid,nodev,nofail,x-gvfs-show 0 0"
		touch "$driveFile"
		# remove drives matching uuid
		sed -i -e "/$uuid/d" "$driveFile"
		echo "$driveCmd" >> "$driveFile"
		formattedTmpDirs="$formattedTmpDirs                - $drivePath"
	    let "driveNo+=1"
	done
	echo "$formattedTmpDirs" | sed 's/\\n/\\\\n/g'
}

setupStorage (){
	local driveNo=0
	local drives=($(blkid | grep Elements | sed -n 's/.* UUID=\"\([^\"]*\)\".*/\1/p';))
	local driveFile="/etc/fstab"
	local formattedStorageDirs=""

	for uuid in $drives 
	do
		local drivePath="/mnt/store/HDD-$(printf "%04d\n" $driveNo)"
		local driveCmd="UUID=$uuid $drivePath    auto nosuid,nodev,nofail,x-gvfs-show 0 0"
		touch "$driveFile"
		# remove drives matching uuid
		sed -i -e "/$uuid/d" "$driveFile"
		echo "$driveCmd" >> "$driveFile"
		formattedStorageDirs="$formattedStorageDirs                - $drivePath"
	    let "driveNo+=1"
	done
	echo "$formattedStorageDirs" | sed 's/\\n/\\\\n/g'
}

pathSetup(){
	local envConfig="/etc/environment"
	local chronTabConfig="/hive/etc/crontab.root"
	local newPath="PATH=\"$PATH:/usr/lib/chia-blockchain/venv/bin:snap/bin\""
	sed -i -e "/PATH=/c$newPath" "$chronTabConfig"
	sed -i -e "/PATH=/c$newPath" "$envConfig"
}

envSetup (){
	sudo apt-get update
	sudo apt-get upgrade -y
	sudo apt install python-pip
	sudo mkfs.ntfs -f /dev/nvme0n1
	sudo apt install snapd
	sudo snap install duf-utility
}

archiveSetup(){
	sudo systemctl unmask avahi-daemon.service
	sudo systemctl start avahi-daemon.service
	sudo systemctl enable avahi-daemon.service
	sudo apt install avahi-utils 
	sudo ssh-keygen
	sudo ssh-copy-id -i ~/.ssh/id_rsa.pub chia@HD-0000.local
}

dashboardSetup() {
	curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh | bash
	export NVM_DIR="/root/.nvm"
	[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
	nvm install v12
	npm i -g chia-dashboard-satellite
}

read -p "Setup ENV?" -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    envSetup
fi
read -p "Setup Archiving?" -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    archiveSetup
fi
read -p "Setup Paths?" -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    pathSetup
fi
read -p "Setup Chia?" -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
	[ ! -d "/usr/lib/chia-blockchain/" ] && setupChia
fi
read -p "Setup Chia Drives?" -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    plotmanConfig='/root/.config/plotman/plotman.yaml'
	formattedTmpDriveList=$(setupTmpDrives)
	sed "s|<TEMP DIRS>|$formattedTmpDriveList|" "/root/setup/plotman_template.yaml" > "$plotmanConfig"
	formattedStorageDriveList=$(setupStorage)
	sed -i "s|<DIST DIRS>|$formattedStorageDriveList|" "$plotmanConfig"
fi
read -p "Setup Chron?" -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
   setupChron
fi

read -p "Setup Dashboard?" -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
   dashboardSetup
fi

# envSetup
# pathSetup
# plotmanConfig='/root/.config/plotman/plotman.yaml'
# formattedTmpDriveList=$(setupTmpDrives)
# sed "s|<TEMP DIRS>|$formattedTmpDriveList|" "plotman_template.yaml" > "$plotmanConfig"
# formattedStorageDriveList=$(setupStorage)
# sed -i "s|<DIST DIRS>|$formattedStorageDriveList|" "$plotmanConfig"
# [ ! -d "/usr/lib/chia-blockchain/" ] && setupChia
# setupChron
