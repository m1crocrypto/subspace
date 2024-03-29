#!/bin/bash

cd $HOME

#Logo
curl -s https://raw.githubusercontent.com/m1crocrypto/other/main/logo.sh | bash && sleep 1

exists()
{
  command -v "$1" >/dev/null 2>&1
}
if exists curl; then
	echo ''
else
  sudo apt install curl -y < "/dev/null"
fi

#Variables
if [ ! $NICKNAME ]; then
		read -p "Enter node name: " NICKNAME
		echo 'export NICKNAME='\"${NICKNAME}\" >> ~/.bash_profile
fi
if [ ! $SUBSPACE_ADDRESS ]; then
		read -p "Enter wallet: " SUBSPACE_ADDRESS
		echo 'export SUBSPACE_ADDRESS='\"${SUBSPACE_ADDRESS}\" >> ~/.bash_profile
fi
cd $HOME
source ~/.bash_profile
echo "Nodename: '$NICKNAME', Wallet: '$SUBSPACE_ADDRESS'."

#Upgrade
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install wget -y

#Install
cd $HOME
mkdir $HOME/subspace; \
cd $HOME/subspace && \
wget https://github.com/subspace/subspace/releases/download/snapshot-2022-mar-09/subspace-farmer-ubuntu-x86_64-snapshot-2022-mar-09 -O farmer && \
wget https://github.com/subspace/subspace/releases/download/snapshot-2022-mar-09/subspace-node-ubuntu-x86_64-snapshot-2022-mar-09 -O subspace && \
sudo chmod +x * && \
sudo mv * /usr/local/bin/ && \
cd $HOME && \
rm -Rvf $HOME/subspace
farmer --version && subspace --version

#Service
sudo tee <<EOF >/dev/null /etc/systemd/system/subspaced.service
[Unit]
Description=Subspace Node
After=network.target
[Service]
Type=simple
User=$USER
ExecStart=$(which subspace) \\
--chain testnet \\
--wasm-execution compiled \\
--execution wasm \\
--bootnodes "/dns/farm-rpc.subspace.network/tcp/30333/p2p/12D3KooWPjMZuSYj35ehced2MTJFf95upwpHKgKUrFRfHwohzJXr" \\
--rpc-cors all \\
--rpc-methods unsafe \\
--ws-external \\
--validator \\
--telemetry-url "wss://telemetry.polkadot.io/submit/ 1" \\
--telemetry-url "wss://telemetry.subspace.network/submit 1" \\
--name $NICKNAME
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

#Start
sudo systemctl daemon-reload && \
sudo systemctl enable subspaced && \
sudo systemctl restart subspaced

#Service_farmer
sudo tee <<EOF >/dev/null /etc/systemd/system/farmerd.service
[Unit]
Description=Subspace Farmer
After=network.target
[Service]
Type=simple
User=$USER
ExecStart=$(which farmer) farm --reward-address=$SUBSPACE_ADDRESS
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

#Start_farmer
sudo systemctl daemon-reload && \
sudo systemctl enable farmerd && \
sudo systemctl restart farmerd

source ~/.bash_profile
