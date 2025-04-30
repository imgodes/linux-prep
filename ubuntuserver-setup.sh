#!/bin/bash

# Funções auxiliares
install_package() {
    if ! dpkg -l | grep -q "^ii  $1 "; then
        apt-get install -y $1
    else
        echo "$1 já está instalado."
    fi
}

# Configuração NTP com servidores públicos
configure_ntp() {
    echo "Configurando NTP com servidores públicos..."
    install_package chrony
    
    cat > /etc/chrony/chrony.conf <<EOF
# Servidores NTP públicos brasileiros
server a.ntp.br iburst
server b.ntp.br iburst
server c.ntp.br iburst

# Configurações básicas
keyfile /etc/chrony/chrony.keys
driftfile /var/lib/chrony/chrony.drift
logdir /var/log/chrony
maxupdateskew 100.0
hwclockfile /etc/adjtime
rtcsync
makestep 1 3
EOF

    systemctl restart chrony
    echo "Servidores NTP configurados:"
    chronyc sources
    echo "Status de sincronização:"
    chronyc tracking
}

# Hardening de Kernel e Rede
configure_kernel_hardening() {
    echo "Aplicando hardening de kernel e rede..."

    cat > /etc/sysctl.d/99-hardening.conf <<EOF
# Prevenção contra spoofing e hardening de rede
kernel.randomize_va_space = 2
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_max_syn_backlog = 4096

# Desativar forwarding
net.ipv4.ip_forward = 0
net.ipv4.conf.all.forwarding = 0
net.ipv4.conf.default.forwarding = 0
net.ipv6.conf.all.forwarding = 0
net.ipv6.conf.default.forwarding = 0

# Proteção contra spoofing
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Desativar redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Desativar source routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# Proteção contra ICMP attacks
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_echo_ignore_all = 1

# Configurações adicionais recomendadas para SIEM/EDR
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
kernel.perf_event_paranoid = 3
kernel.module.sig_enforce = 1
EOF

    sysctl -p /etc/sysctl.d/99-hardening.conf
}

# Configuração do UFW para SIEM/EDR
configure_firewall() {
    echo "Configurando UFW para servidor SIEM/EDR..."
    
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow from 127.0.0.1
    ufw allow $1/tcp
    ufw allow 1514/udp   # Wazuh agent communication
    ufw allow 1515/tcp   # Wazuh manager cluster
    ufw allow 55000/tcp  # Wazuh DB daemon
    ufw allow https
    ufw --force enable
    
    echo "Status do UFW:"
    ufw status verbose
}

# Coleta de informações
read -p "Usuário: " USER
read -sp "Senha: " PASSWORD
echo
read -p "Pubkey SSH: " PUBKEY
read -p "Porta SSH (recomendado acima de 1024): " PORT

# Atualizar sistema
echo "Atualizando pacotes..."
apt-get update && apt-get upgrade -y

# Configuração do usuário
getent passwd $USER > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "Usuário já existe, apenas atualizando configurações."
else
    echo "Criando novo usuário..."
    useradd -m -d /home/$USER -s /bin/bash $USER
    usermod -aG sudo $USER
    echo "$USER:$PASSWORD" | chpasswd
    chage -d 0 $USER
fi

# Configuração SSH
mkdir -p /home/$USER/.ssh
echo "$PUBKEY" >> /home/$USER/.ssh/authorized_keys
chown -R $USER:$USER /home/$USER/.ssh
chmod 700 /home/$USER/.ssh
chmod 600 /home/$USER/.ssh/authorized_keys

sed -i "s/^#Port 22/Port $PORT/" /etc/ssh/sshd_config
sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

# Configuração NTP
configure_ntp

# Hardening de Kernel
configure_kernel_hardening

# Configuração do Firewall
configure_firewall $PORT

# Configuração do timezone
dpkg-reconfigure -f noninteractive tzdata

# Reiniciar serviços
systemctl restart sshd

echo ""
echo "Configuração concluída com sucesso!"
echo "=================================="
echo "Usuário: $USER"
echo "Porta SSH: $PORT"
echo "Acesso root via SSH: DESATIVADO"
echo "Autenticação por senha: DESATIVADA"
echo "NTP configurado com servidores públicos"
echo "Firewall configurado para SIEM/EDR (Wazuh)"
echo "Hardening de kernel aplicado"
echo ""
