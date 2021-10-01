#!/bin/bash
read -p "Usuário: " USER
read -p "Senha: " PASSWORD
read -p "Pubkey: " PUBKEY
getent passwd $USER > /dev/null 2&>1
if [ $? -eq 0 ]; then
    echo "Usuário já criado"
else
  	useradd -m -d /home/$USER -s /bin/bash $USER
	usermod -aG sudo $USER
	mkdir -p /home/$USER/.ssh
	echo "$PUBKEY" >> /home/$USER/.ssh/authorized_keys
	chown -R $USER:$USER /home/$USER/.ssh
	find /home -iname "*ssh" -exec chmod 700 {} \;
	find /home -iname "authorized_keys*" -exec chmod 600 {} \;
	echo "$USER:$PASSWORD" | chpasswd
	chage -d 0 $USER
fi

sed -i 's/#Port 22/Port 7022/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords no/' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin/PermitRootLogin/' /etc/ssh/sshd_config
sed -i 's/#AuthorizedKeysFile/AuthorizedKeysFile/' /etc/ssh/sshd_config
sed -i 's/#PubkeyAuthentication/PubkeyAuthentication/' /etc/ssh/sshd_config
