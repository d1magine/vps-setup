#!/bin/bash

#---------------------------- 1. Обновление системы -----------------------------------
apt update && apt upgrade -y
apt autoremove -y
apt clean

#---------------------------- 2. Переименование хоста -----------------------------------
read -p "Введите новое имя для хоста: " hostname

hostnamectl set-hostname "$hostname"

sed -i "s/^127\.0\.1\.1.*/127.0.1.1 $hostname/" /etc/hosts

#---------------------------- 3. Создание пользователя -----------------------------------
read -p "Введите имя нового пользователя: " username

while true; do
	read -rsp "Введите пароль для нового пользователя: " password
	echo
    read -rsp "Повторите пароль: " password_confirm
	echo

    if [[ "$password" == "$password_confirm" && -n "$password" ]]; then
        break;
    else
		echo "Пароли не совпадают или пустые!"
	fi
done

useradd -mG sudo -s /bin/bash "$username"
echo "$username:$password" | chpasswd

# Запретить логиниться под root
usermod -s /usr/sbin/nologin root

#---------------------------- 4. Настройка SSH -----------------------------------
# Смена порта SSH
while true; do
	read -p "Введите новый порт для SSH (в диапазонe от 1024 до 65535): " ssh_port
	
	if [[ "$ssh_port" =~ ^[0-9]+$ ]] && ((ssh_port >= 1024 && ssh_port <= 65535)); then
		break
	else
		echo "Введите корректный порт в диапазоне от 1024 до 65535!"
	fi
done

echo "Port $ssh_port" > /etc/ssh/sshd_config.d/custom.conf

# Копирование SSH ключа
read -p "Введите IP-адрес сервера: " server_ip
echo "Введите следующую команду на локальной машине для копирования SSH ключа:"
echo "ssh-copy-id $username@$server_ip"
read -rp  "Нажмите Enter после того, как скопировали SSH ключ..."

cat >> /etc/ssh/sshd_config.d/custom.conf <<EOF
PermitRootLogin no
PasswordAuthentication no
PermitEmptyPasswords no
PubkeyAuthentication yes
EOF

# Перезапуск SSH
systemctl restart sshd

#---------------------------- 5. Firewall -----------------------------------
apt install ufw -y

ufw default deny incoming
ufw default allow outgoing

ufw allow "$ssh_port"/tcp

ufw enable

#---------------------------- 6. Утилиты  -----------------------------------
apt install curl git vim bash-completion -y
# Применение bash-completion
source /etc/bash-completion
