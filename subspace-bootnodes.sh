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
VER=$(wget -qO- https://api.github.com/repos/subspace/subspace/releases/latest | jq -r ".tag_name") && \
wget https://github.com/subspace/subspace/releases/download/${VER}/subspace-farmer-ubuntu-x86_64-${VER} -O farmer && \
wget https://github.com/subspace/subspace/releases/download/${VER}/subspace-node-ubuntu-x86_64-${VER} -O subspace && \
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
--pruning=1324 \\
--keep-blocks=1324 \\
--validator \\
--reserved-nodes="/dns/bootstrap-0.gemini-1b.subspace.network/tcp/30333/p2p/12D3KooWF9CgB8bDvWCvzPPZrWG3awjhS7gPFu7MzNPkF9F9xWwc" \\
--reserved-nodes="/dns/bootstrap-1.gemini-1b.subspace.network/tcp/30333/p2p/12D3KooWLrpSArNaZ3Hvs4mABwYGDY1Rf2bqiNTqUzLm7koxedQQ" \\
--reserved-nodes="/dns/bootstrap-10.gemini-1b.subspace.network/tcp/30333/p2p/12D3KooWNGf1qr5411JwPHgwqftjEL6RgFRUEFnsJpTMx6zKEdWn" \\
--reserved-nodes="/dns/bootstrap-11.gemini-1b.subspace.network/tcp/30333/p2p/12D3KooWM7Qe4rVfzUAMucb5GTs3m4ts5ZrFg83LZnLhRCjmYEJK" \\
--reserved-nodes="/dns/bootstrap-2.gemini-1b.subspace.network/tcp/30333/p2p/12D3KooWNN5uuzPtDNtWoLU28ZDCQP7HTdRjyWbNYo5EA6fZDAMD" \\
--reserved-nodes="/dns/bootstrap-3.gemini-1b.subspace.network/tcp/30333/p2p/12D3KooWM47uyGtvbUFt5tmWdFezNQjwbYZmWE19RpWhXgRzuEqh" \\
--reserved-nodes="/dns/bootstrap-4.gemini-1b.subspace.network/tcp/30333/p2p/12D3KooWNMEKxFZm9mbwPXfQ3LQaUgin9JckCq7TJdLS2UnH6E7z" \\
--reserved-nodes="/dns/bootstrap-5.gemini-1b.subspace.network/tcp/30333/p2p/12D3KooWFfEtDmpb8BWKXoEAgxkKAMfxU2yGDq8nK87MqnHvXsok" \\
--reserved-nodes="/dns/bootstrap-6.gemini-1b.subspace.network/tcp/30333/p2p/12D3KooWHSeob6t43ukWAGnkTcQEoRaFSUWphGDCKF1uefG2UGDh" \\
--reserved-nodes="/dns/bootstrap-7.gemini-1b.subspace.network/tcp/30333/p2p/12D3KooWKwrGSmaGJBD29agJGC3MWiA7NZt34Vd98f6VYgRbV8hH" \\
--reserved-nodes="/dns/bootstrap-8.gemini-1b.subspace.network/tcp/30333/p2p/12D3KooWCXFrzVGtAzrTUc4y7jyyvhCcNTAcm18Zj7UN46whZ5Bm" \\
--reserved-nodes="/dns/bootstrap-9.gemini-1b.subspace.network/tcp/30333/p2p/12D3KooWNGxWQ4sajzW1akPRZxjYM5TszRtsCnEiLhpsGrsHrFC6" \\
--reserved-only \\
--name="${NICKNAME}"
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
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

