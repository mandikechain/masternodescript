#!/bin/bash

PORT=11965
RPCPORT=11966
CONF_DIR=~/.xmd
COINZIP='https://github.com/mandikechain/XMD/releases/download/1.0/xmd-1.0.0-x86_64-linux-gnu.zip'

cd ~
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}$0 must be run as root.${NC}"
   exit 1
fi

function configure_systemd {
  cat << EOF > /etc/systemd/system/xmd.service
[Unit]
Description=Mandike Service
After=network.target
[Service]
User=root
Group=root
Type=forking
ExecStart=/usr/local/bin/mandiked
ExecStop=-/usr/local/bin/mandike-cli stop
Restart=always
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5
[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  sleep 2
  systemctl enable xmd.service
  systemctl start xmd.service
}

echo ""
echo ""
DOSETUP="y"

if [ $DOSETUP = "y" ]  
then
  apt-get update
  apt install zip unzip git curl wget -y
  cd /usr/local/bin/
  wget $COINZIP
  unzip xmd-1.0.0-x86_64-linux-gnu.zip
  rm mandike-qt mandike-tx xmd-1.0.0-x86_64-linux-gnu.zip
  chmod +x mandike*
  
  mkdir -p $CONF_DIR
  cd $CONF_DIR

fi

 IP=$(curl -s4 api.ipify.org)
 echo ""
 echo "Configure your masternodes now!"
 echo "Detecting IP address:$IP"
 echo ""
 echo "Enter masternode private key"
 read PRIVKEY
 
  echo "rpcuser=user"`shuf -i 100000-10000000 -n 1` >> mandike.conf_TEMP
  echo "rpcpassword=pass"`shuf -i 100000-10000000 -n 1` >> mandike.conf_TEMP
  echo "rpcallowip=127.0.0.1" >> mandike.conf_TEMP
  echo "rpcport=$RPCPORT" >> mandike.conf_TEMP
  echo "listen=1" >> mandike.conf_TEMP
  echo "server=1" >> mandike.conf_TEMP
  echo "daemon=1" >> mandike.conf_TEMP
  echo "maxconnections=250" >> mandike.conf_TEMP
  echo "masternode=1" >> mandike.conf_TEMP
  echo "" >> mandike.conf_TEMP
  echo "port=$PORT" >> mandike.conf_TEMP
  echo "externalip=$IP:$PORT" >> mandike.conf_TEMP
  echo "masternodeaddr=$IP:$PORT" >> mandike.conf_TEMP
  echo "masternodeprivkey=$PRIVKEY" >> mandike.conf_TEMP
  mv mandike.conf_TEMP mandike.conf
  cd
  echo ""
  echo -e "Your ip is ${GREEN}$IP:$PORT${NC}"

	## Config Systemctl
	configure_systemd
  
echo ""
echo "Commands:"
echo -e "Start Mandike Service: ${GREEN}systemctl start xmd${NC}"
echo -e "Check Mandike Status Service: ${GREEN}systemctl status xmd${NC}"
echo -e "Stop Mandike Service: ${GREEN}systemctl stop xmd${NC}"
echo -e "Check Masternode Status: ${GREEN}mandike-cli getmasternodestatus${NC}"

echo ""
echo -e "${GREEN}Mandike Masternode Installation Done${NC}"
exec bash
exit
