FROM ubuntu:18.04

# Install The Common Used Tools
ADD sources.list /etc/apt/sources.list
RUN apt-get -yqq update
RUN apt-get -y install wget curl make gcc git unzip sudo

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

RUN echo '192.30.253.112   github.com' >> /etc/hosts

USER root

ENV WORKSPACE /usr/local/src/gse10b2
RUN mkdir -p ${WORKSPACE}


RUN groupadd -r openvas && useradd -r -g openvas openvas && \
chown -R openvas ${WORKSPACE} && chgrp -R openvas ${WORKSPACE}

RUN sudo chown openvas:openvas ${WORKSPACE}
WORKDIR WORKSPACE
# Download the stuffz
RUN wget -O gvm-libs-1.0-beta2.tar.gz https://github.com/greenbone/gvm-libs/archive/v1.0+beta2.tar.gz ;\
wget -O openvas-scanner-6.0-beta2.tar.gz https://github.com/greenbone/openvas-scanner/archive/v6.0+beta2.tar.gz ;\
wget -O gvmd-8.0-beta2.tar.gz https://github.com/greenbone/gvmd/archive/v8.0+beta2.tar.gz ;\
wget -O gsa-8.0-beta2.tar.gz https://github.com/greenbone/gsa/archive/v8.0+beta2.tar.gz ;\
wget -O ospd-1.3.2.tar.gz https://github.com/greenbone/ospd/archive/v1.3.2.tar.gz ;\
wget -O openvas-smb-1.0.4.tar.gz https://github.com/greenbone/openvas-smb/archive/v1.0.4.tar.gz

# unpacked
RUN find . -name \*.gz -exec tar zxvfp {} \; && rm -rf *.gz

# Become almighty root
#RUN sudo su

# install requirements
RUN apt install software-properties-common -y && \
add-apt-repository universe -y  && \
apt install -y cmake pkg-config libglib2.0-dev libgpgme11-dev \
uuid-dev libssh-gcrypt-dev libhiredis-dev \
gcc libgnutls28-dev libpcap-dev libgpgme-dev \
bison libksba-dev libsnmp-dev libgcrypt20-dev redis-server \
libsqlite3-dev libical-dev gnutls-bin doxygen \
nmap libmicrohttpd-dev libxml2-dev apt-transport-https curl \
xmltoman xsltproc gcc-mingw-w64 perl-base heimdal-dev \
libpopt-dev graphviz nodejs rpm nsis wget sshpass socat snmp


# install gvm-libs
RUN cd gvm-libs-1.0-beta2 ;\
 mkdir build ;\
 cd build ;\
 cmake .. ;\
 make ;\
 make doc-full ;\
 make install

# config and build openvas-smb
RUN   cd openvas-smb-1.0.4 ;\
 mkdir build ;\
 cd build/ ;\
 cmake .. ;\
 make ;\
 make install

# config and build scanner
RUN  cd openvas-6.0-beta2 ;\
 mkdir build ;\
 cd build/ ;\
 cmake .. ;\
 make ;\
 make doc-full ;\
 make install

# Fix redis for default openvas install
RUN cp /etc/redis/redis.conf /etc/redis/redis.orig ;\
cp /usr/local/src/gse10b2/openvas-6.0-beta2/build/doc/redis_config_examples/redis_4_0.conf /etc/redis/redis.conf ;\
sed -i 's|/usr/local/var/run/openvas-redis.pid|/var/run/redis/redis-server.pid|g' /etc/redis/redis.conf ;\
sed -i 's|/tmp/redis.sock|/var/run/redis/redis-server.sock|g' /etc/redis/redis.conf ;\
sed -i 's|dir ./|dir /var/lib/redis|g' /etc/redis/redis.conf

RUN sysctl -w net.core.somaxconn=1024
RUN sysctl vm.overcommit_memory=1
RUN echo "net.core.somaxconn=1024"  >> /etc/sysctl.conf
RUN echo "vm.overcommit_memory=1" >> /etc/sysctl.conf

ADD disable-thp.service /etc/systemd/system/disable-thp.service

#RUN systemctl daemon-reload && systemctl start disable-thp && systemctl enable disable-thp ;
RUN /etc/init.d/redis-server start

RUN touch /usr/local/etc/openvas/openvassd.conf && \
echo 'db_address = /var/run/redis/redis-server.sock' >> /usr/local/etc/openvas/openvassd.conf

# update nvt’s
RUN greenbone-nvt-sync
# reload modules
RUN ldconfig
# start openvassd
RUN openvassd
### watch "ps -ef | grep openvassd"

# config and build manager
RUN cd gvmd-8.0-beta2 ;\
 mkdir build ;\
 cd build/ ;\
 cmake .. ;\
 make ;\
 make doc-full ;\
 make install

RUN curl --silent --show-error https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add - ;\
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list ;\
sudo apt-get update ;\
sudo apt-get install yarn

# configure and install gsa
RUN cd gsa-8.0-beta2 ;\
 mkdir build ;\
 cd build/ ;\
 cmake .. ;\
 make ;\
 make doc-full ;\
 make install

# fix certs && create admin user
RUN gvm-manage-certs -a && gvmd --create-user=admin

# start evrytnhg to test is out..
COPY entrypoint.sh /usr/local/bin/

EXPOSE 80, 443, 9200

ENTRYPOINT ['entrypoint.sh']