#!/bin/bash
getent passwd $1 > /dev/null 2&>1
if [ $? -eq 0 ]; then
    echo "Usuário já criado"
else
  useradd -m -d /home/$1 -s /bin/bash $1
	usermod -aG sudo $1
	echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCfM7SlBeW6aOmbzZFKND4+9oSPM2V6SXdEcLcuGl/cSCOhZpXZ74ZUUCUVj2AJ4Tl9AY1AuPAMwoC7evsBkilnGjCVEmDt3WSWd+A/d3rho5vCN2iAAi95lf7bXNUN/Q8SudrFs+3oPU9TWXZ+WZkmq0tdBA+YB9ovVX5rgMn4fwr3iofc9qHPODTdlL5dbsymMsy29r3YeC96YBhlUH6rD28nU2bxz97hkSc0Nz62NL84N2DBqO+THn94g1kSrXBL13/uPLNKYZdf46Eq7bXCLXacSbhKv1zh4PB0TSdu8z+aSjG6U8VjQQbi+p0snY2mN2LscT+LaWzk3c2Gk/vZ rsa-key-20210930" >> /home/eferreira/.ssh/authorized_keys
	chown -R $1:$1 /home/$1/.ssh
	find /home -iname "*ssh" -exec chmod 700 {} \;
	find /home -iname "authorized_keys*" -exec chmod 600 {} \;
	echo '$1:Ks%KD!0%wYITmk8WsEOC' | chpasswd
	chage -d 0 $1
fi
