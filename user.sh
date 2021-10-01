#!/bin/bash
read USER
read PASSWORD
read HOME
read PUBKEY
getent passwd $1 > /dev/null 2&>1
if [ $? -eq 0 ]; then
    echo "Usuário já criado"
else
  useradd -m -d /home/$USER -s /bin/bash $USER
	usermod -aG sudo $USER
	echo "$2" >> /home/$USER/.ssh/authorized_keys
	chown -R $USER:$USER /home/$USER/.ssh
	find /home -iname "*ssh" -exec chmod 700 {} \;
	find /home -iname "authorized_keys*" -exec chmod 600 {} \;
	echo '$USER:$PASSWORD' | chpasswd
	chage -d 0 $USER
fi
