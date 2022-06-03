#!/bin/bash

cd $HOME

# Лого
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

# Переменные
if [ ! $NICKNAME ]; then
		read -p "Enter node name: " NICKNAME
		echo 'export NICKNAME='\"${NICKNAME}\" >> ~/.bash_profile
fi
if [ ! $SUBSPACE_ADDRESS ]; then
		read -p "Enter wallet: " SUBSPACE_ADDRESS
		echo 'export SUBSPACE_ADDRESS='\"${SUBSPACE_ADDRESS}\" >> ~/.bash_profile
fi
if [ ! $SPACE ]; then
		read -p "Farmer disk space (Example: 60G, 2T): " SPACE
		echo 'export SPACE='\"${SPACE}\" >> ~/.bash_profile
fi
cd $HOME
echo "Nodename: '$NICKNAME', Wallet: '$SUBSPACE_ADDRESS', Disk space: '$SPACE'"

# Обновление дистрибутива


# Зависимости
sudo apt-get install wget jq -y

# Установка
cd $HOME
mkdir $HOME/subspace; \
cd $HOME/subspace && \
wget -O subspace-node https://github.com/subspace/subspace/releases/download/gemini-1b-2022-june-02/subspace-node-ubuntu-x86_64-gemini-1b-2022-june-03
wget -O subspace-farmer https://github.com/subspace/subspace/releases/download/gemini-1b-2022-june-02/subspace-farmer-ubuntu-x86_64-gemini-1b-2022-june-03
sudo chmod +x * && \
sudo mv * /usr/local/bin/ && \
cd $HOME && \
rm -Rvf $HOME/subspace

# Смотрим версию бинарников
echo " "
echo "Version:"
subspace --version && farmer --version

# Фиксим журнал
sudo tee <<EOF >/dev/null /etc/systemd/journald.conf
Storage=persistent
EOF
sudo systemctl restart systemd-journald

# Сервис файл для ноды
sudo tee <<EOF >/dev/null /etc/systemd/system/subspaced.service
[Unit]
Description=Subspace Node
After=network.target
[Service]
Type=simple
User=$USER
ExecStart=$(which subspace) \\
--chain="gemini-1" \\
--execution="wasm" \\
--pruning=1024 \\
--keep-blocks=1024 \\
--validator \\
--name="${NICKNAME}"
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

# Запуск ноды
sudo systemctl daemon-reload && \
sudo systemctl enable subspaced && \
sudo systemctl restart subspaced

# Сервис файл для фармера
sudo tee <<EOF >/dev/null /etc/systemd/system/farmerd.service
[Unit]
Description=Subspace Farmer
After=network.target
[Service]
Type=simple
User=$USER
ExecStart=$(which farmer) farm \\
--reward-address=${SUBSPACE_ADDRESS} \\
--plot-size=${SPACE}
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

# Перезапускаем ноду и фармер
sudo systemctl daemon-reload && \
sudo systemctl enable subspaced farmerd && \
sudo systemctl restart subspaced farmerd
