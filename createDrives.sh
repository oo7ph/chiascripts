#!/bin/bash
setupDrives(){
    local driveNo=0
    local drives=$(blkid | grep Elements | sed -n 's/.* UUID=\"\([^\"]*\)\".*/\1/p')
    local driveFile="/etc/fstab"
    local formattedStorageDirs=""

    for uuid in $drives 
    do
        local drivePath="/mnt/store/HDD-$(printf "%04d\n" $driveNo)"
        # local driveCmd="UUID=$uuid $drivePath    auto nosuid,nodev,nofail,x-gvfs-show 0 0"
        # touch "$driveFile"
        # # remove drives matching uuid
        # sed -i -e "/$uuid/d" "$driveFile"
        # echo "$driveCmd" >> "$driveFile"
        # formattedStorageDirs="$formattedStorageDirs                - $drivePath"
        mkdir "$drivePath"
        let "driveNo+=1"
    done
}

setupDrives