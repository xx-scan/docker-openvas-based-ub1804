#!/usr/bin/env bash

cd /usr/local/src
sudo mkdir gse10b2
sudo chown $USER:$USER gse10b2

#sudo tzselect &&  ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
sudo ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

cd gse10b2
wget -O gvm-libs-1.0-beta2.tar.gz https://github.com/greenbone/gvm-libs/archive/v1.0+beta2.tar.gz ;\
wget -O openvas-scanner-6.0-beta2.tar.gz https://github.com/greenbone/openvas-scanner/archive/v6.0+beta2.tar.gz ;\
wget -O gvmd-8.0-beta2.tar.gz https://github.com/greenbone/gvmd/archive/v8.0+beta2.tar.gz ;\
wget -O gsa-8.0-beta2.tar.gz https://github.com/greenbone/gsa/archive/v8.0+beta2.tar.gz ;\
wget -O ospd-1.3.2.tar.gz https://github.com/greenbone/ospd/archive/v1.3.2.tar.gz ;\
wget -O openvas-smb-1.0.4.tar.gz https://github.com/greenbone/openvas-smb/archive/v1.0.4.tar.gz

find . -name \*.gz -exec tar zxvfp {} \;

sudo su

apt install software-properties-common -y && \
add-apt-repository universe -y;\
apt install -y cmake pkg-config libglib2.0-dev libgpgme11-dev uuid-dev libssh-gcrypt-dev libhiredis-dev \
gcc libgnutls28-dev libpcap-dev libgpgme-dev bison libksba-dev libsnmp-dev libgcrypt20-dev redis-server \
libsqlite3-dev libical-dev gnutls-bin doxygen nmap libmicrohttpd-dev libxml2-dev apt-transport-https curl \
xmltoman xsltproc gcc-mingw-w64 perl-base heimdal-dev libpopt-dev graphviz nodejs rpm nsis wget sshpass socat snmp


cd gvm-libs-1.0-beta2 ;\
 mkdir build ;\
 cd build ;\
 cmake .. ;\
 make ;\
 make doc-full ;\
 make install ;\
 cd /usr/local/src/gse10b2


 cd openvas-smb-1.0.4 ;\
 mkdir build ;\
 cd build/ ;\
 cmake .. ;\
 make ;\
 make install ;\
 cd /usr/local/src/gse10b2


 cd openvas-6.0-beta2 ;\
 mkdir build ;\
 cd build/ ;\
 cmake .. ;\
 make ;\
 make doc-full ;\
 make install ;\
 cd /usr/local/src/gse10b2

cp /etc/redis/redis.conf /etc/redis/redis.orig ;\
cp /usr/local/src/gse10b2/openvas-6.0-beta2/build/doc/redis_config_examples/redis_4_0.conf /etc/redis/redis.conf ;\
sed -i 's|/usr/local/var/run/openvas-redis.pid|/var/run/redis/redis-server.pid|g' /etc/redis/redis.conf ;\
sed -i 's|/tmp/redis.sock|/var/run/redis/redis-server.sock|g' /etc/redis/redis.conf ;\
sed -i 's|dir ./|dir /var/lib/redis|g' /etc/redis/redis.conf

sysctl -w net.core.somaxconn=1024
sysctl vm.overcommit_memory=1

echo "net.core.somaxconn=1024"  >> /etc/sysctl.conf
echo "vm.overcommit_memory=1" >> /etc/sysctl.conf

cat << EOF > /etc/systemd/system/disable-thp.service
[Unit]
Description=Disable Transparent Huge Pages (THP)

[Service]
Type=simple
ExecStart=/bin/sh -c "echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled && echo 'never' > /sys/kernel/mm/transparent_hugepage/defrag"

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload ;\
systemctl start disable-thp ;\
systemctl enable disable-thp ;\
systemctl restart redis-server
cat << EOF > /usr/local/etc/openvas/openvassd.conf
db_address = /var/run/redis/redis-server.sock
EOF

greenbone-nvt-sync && ldconfig && openvassd

cd gvmd-8.0-beta2 ;\
 mkdir build ;\
 cd build/ ;\
 cmake .. ;\
 make ;\
 make doc-full ;\
 make install ;\
 cd /usr/local/src/gse10b2

curl --silent --show-error https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - ;\
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list ;\
sudo apt-get update ;\
sudo apt-get install yarn

cd gsa-8.0-beta2 ;\
 mkdir build ;\
 cd build/ ;\
 cmake .. ;\
 make ;\
 make doc-full ;\
 make install ;\
 cd /usr/local/src/gse10b2


cd /root/ rm -rf /usr/local/src/gse10b2

gvm-manage-certs -a && gvmd --create-user=admin


gvmd ;\
openvassd ;\
gsad