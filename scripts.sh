screen -r chia

ssh-copy-id chia@HD-0000.local

cd /root/; rm -r ./setup; git clone https://github.com/oo7ph/chiascripts.git setup; chmod -R 777 setup/

scp -r ~/.chia/mainnet/config/ssl/ca user@HD-0004.local:/root/setup

chia init -c ~/setup/ca 

chia configure --set-farmer-peer HD-0000.local:8447; chia start harvester; cat /root/.chia/mainnet/config/config.yaml | grep HD-0000.local

./setup/setup.sh

export NVM_DIR="/root/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

sed -i '/reboot su/d' /hive/etc/crontab.root

chia-dashboard-satellite


ssh chia@HD-0000.local 'bash -s' < createDrives.sh







rsync -P testfile.test rsync://chia@HD-0000.local:12000/store/HDD-0000
sed -i 's|rsyncd_path: /store|rsyncd_path: /mnt/store|g' /root/.config/plotman/plotman.yaml
