#!/bin/bash
read USER
read PASSWORD
read HOME
read PUBKEY
getent passwd $1 > /dev/null 2&>1
if [ $? -eq 0 ]; then
    echo "Usuário já criado"
else
  useradd -m -d /home/$1 -s /bin/bash $1
	usermod -aG sudo $1
	echo "$2" >> /home/eferreira/.ssh/authorized_keys
	chown -R $1:$1 /home/$1/.ssh
	find /home -iname "*ssh" -exec chmod 700 {} \;
	find /home -iname "authorized_keys*" -exec chmod 600 {} \;
	echo '$1:$3' | chpasswd
	chage -d 0 $1
fi
