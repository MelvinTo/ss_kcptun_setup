#!/bin/bash

# This script is to install shadowsocks and kcp (optional) on a native ubuntu OS image
# (Beta)

function perr_and_exit()
{
  echo "$1" >&2
  exit 1
}

if [[ ! $(whoami) =~ "root" ]]; then
  echo "This script requires root privilege!"
  exit 1
fi

SERVER_NAME=""
echo -n "Please input the hostname or ip address of this server:"
while read line
do
  SERVER_NAME="$line"
  break
done

echo "Confirm that hostname/ip is $SERVER_NAME"

#sudo apt-get update
#sudo apt-get -y install golang git

useradd ss -m -s /bin/bash

#export GOPATH=/home/ss/gocode

#su - ss -c "GOPATH=/home/ss/gocode go get github.com/shadowsocks/shadowsocks-go/cmd/shadowsocks-server"

#su - ss -c "mkdir -p ss"

# prepare shadowsocks server
su - ss -c "wget https://github.com/MelvinTo/ss_kcptun_setup/raw/master/shadowsocks-server -O shadowsocks-server"

# prepare qr terminal tool
su - ss -c "wget https://github.com/MelvinTo/ss_kcptun_setup/raw/master/qrcode-terminal -O qrcode-terminal"
su - ss -c "chmod +x shadowsocks-server qrcode-terminal"

# prepare systemd service

cat > /etc/systemd/system/ss.service <<EOF
[Unit]
Description=Shadowsocks Server
After=network.target

[Service]
ExecStart=/home/ss/shadowsocks-server -c /home/ss/ss-config.json
Restart=always
User=ss

[Install]
WantedBy=multi-user.target
EOF

RANDOM_PASSWORD=$(date +%s | sha256sum | base64 | head -c 16)

# prepare ss config file
cat > /home/ss/ss-config.json <<EOF
{
    "from": "firewalla",
    "server_port":8488,
    "password":"$RANDOM_PASSWORD",
    "method": "aes-256-cfb",
    "timeout":600,
    "server": "$SERVER_NAME"
}
EOF

systemctl enable ss
systemctl start ss

su - ss -c "cat /home/ss/ss-config.json | /home/ss/qrcode-terminal -"
