#!/bin/bash


echo # Instala banco de dados PostgreeSQL 16 com Timescaledb no Debian 12 para Zabbix 7.0 LTS com Nginx

echo ####################################################
echo # "Atualizando arquivo /etc/apt/source.list" #######
echo ####################################################

# Define o IP do servidor Zabbix #
IP_SERVIDOR="172.17.1.6"

sed -i 's|deb http://deb.debian.org/debian/ bookworm main non-free-firmware|& contrib non-free|' /etc/apt/sources.list
sed -i 's|deb-src http://deb.debian.org/debian/ bookworm main non-free-firmware|& contrib non-free|' /etc/apt/sources.list
sed -i 's|deb http://security.debian.org/debian-security bookworm-security main non-free-firmware|& contrib non-free|' /etc/apt/sources.list
sed -i 's|deb-src http://security.debian.org/debian-security bookworm-security main non-free-firmware|& contrib non-free|' /etc/apt/sources.list
sed -i 's|deb http://deb.debian.org/debian/ bookworm-updates main non-free-firmware|& contrib non-free|' /etc/apt/sources.list
sed -i 's|deb-src http://deb.debian.org/debian/ bookworm-updates main non-free-firmware|& contrib non-free|' /etc/apt/sources.list

echo "Atualizando Linux"
apt update -y
apt upgrade -y
apt update -y


echo "Tunning no Kernel"
apt install firmware-linux firmware-linux-free firmware-linux-nonfree -y

echo "Instalando o chrony"
apt install -y chrony
systemctl enable --now chrony
systemctl start chronyd


apt-get install vim wget curl tcpdump perl sshpass btop htop telnet gnupg gnupg2 apt-transport-https sudo nmap libsnmp-dev build-essential lsb-release ncdu htop zstd -y
wget remontti.com.br/debian; bash debian; su -

echo # Adiciona o repositório do PostgreSQL 16
sudo sh -c 'echo "deb https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
apt update -y
sudo apt install -y postgresql-16

systemctl enable --now postgresql
systemctl restart postgresql


echo # Trocar para o usuário postgres e executar os comandos no PostgreSQL
su - postgres -c "psql -c \"ALTER USER postgres PASSWORD '1234@Mudar';\""
su - postgres -c "psql -c \"CREATE EXTENSION adminpack;\""
echo echo "Extensões criadas com sucesso e senha do usuário postgres alterada para 1234@Mudar."

sudo -u postgres psql -c "CREATE USER zabbix WITH PASSWORD '1234@Mudar';"

echo # Cria o banco de dados 'zabbix' e atribui ao usuário 'zabbix'
sudo -u postgres createdb -O zabbix zabbix

#PGPASSWORD='1234@Mudar' sudo -u postgres createdb -O zabbix zabbix



# Substitui as linhas conforme especificado diretamente no arquivo
sed -i 's/local\s\+all\s\+postgres\s\+peer/local   all             postgres                                md5/' /etc/postgresql/16/main/pg_hba.conf
sed -i 's/local\s\+all\s\+all\s\+peer/local   all             all                                     md5/' /etc/postgresql/16/main/pg_hba.conf
sudo sed -i 's/^host\s\+all\s\+all\s\+127\.0\.0\.1\/32\s\+scram-sha-256$/host    all             all             0.0.0.0\/0            md5/' /etc/postgresql/16/main/pg_hba.conf
sudo sed -i 's/^host\s\+all\s\+all\s\+::1\/128\s\+scram-sha-256$/host    all             all             ::\/0                 md5/' /etc/postgresql/16/main/pg_hba.conf

echo "Modificações no arquivo pg_hba.conf concluídas com sucesso."



echo # Altera o listen para permitir acesso de qualquer lugar no banco
sudo sed -i "s/^#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/16/main/postgresql.conf

echo # Reinicia o banco #
systemctl restart postgresql


echo #Instala o Zabbix Agent#

wget https://repo.zabbix.com/zabbix/7.0/debian/pool/main/z/zabbix-release/zabbix-release_latest+debian12_all.deb
sudo dpkg -i zabbix-release_latest+debian12_all.deb
sudo apt update -y

sudo apt install zabbix-agent -y

sudo sed -i "s/^Server=.*/Server=$IP_SERVIDOR/" /etc/zabbix/zabbix_agentd.conf
sudo sed -i "s/^Hostname=.*/Hostname=Zabbix Banco/" /etc/zabbix/zabbix_agentd.conf

sudo systemctl enable --now zabbix-agent
sudo systemctl restart zabbix-agent




echo " ##### Instala complemento MegaUpload ##### "

wget https://mega.nz/linux/repo/Debian_12/amd64/megacmd-Debian_12_amd64.deb

dpkg -i megacmd-Debian_12_amd64.deb
apt --fix-broken install -y
dpkg -i megacmd-Debian_12_amd64.deb
