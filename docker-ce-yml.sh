#!/bin/bash

if grep -q "VERSION_ID=\"10\"" /etc/os-release; then
  echo "Этот скрипт не может быть выполнен на Debian 10."
  exit 1
fi

# Здесь идет код скрипта, который должен быть выполнен на всех системах, кроме Debian 10

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Проверяем, выполняется ли скрипт от имени пользователя root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Запустите скрипт с правами root${NC}"
  exit
fi

# Проверяем, установлен ли Docker
if [ -x "$(command -v docker)" ]; then
  echo -e "${GREEN}Docker уже установлен${NC}"
else
  # Проверяем, какое распределение используется, и устанавливаем необходимые зависимости
  if [ -f /etc/debian_version ]; then
    apt-get update
    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
  elif [ -f /etc/redhat-release ]; then
    dnf install -y dnf-plugins-core
    dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    dnf install -y curl
  else
    echo -e "${RED}Неподдерживаемое распределение${NC}"
    exit
  fi

  # Устанавливаем Docker
  curl -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh

  # Запускаем и включаем службу Docker
  systemctl start docker
  systemctl enable docker

  echo -e "${GREEN}Docker успешно установлен${NC}"
fi

# Устанавливаем Docker Compose
LATEST_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep "tag_name" | cut -d '"' -f 4)
if [ -x "$(command -v docker-compose)" ]; then
  INSTALLED_VERSION=$(docker-compose version --short)
  if [ "$LATEST_VERSION" == "$INSTALLED_VERSION" ]; then
    echo -e "${GREEN}Установлена последняя версия Docker Compose${NC}"
  else
    echo -e "${YELLOW}Обнаружена устаревшая версия Docker Compose${NC}"
    read -p "Хотите обновить Docker Compose? (y/n) " update_docker_compose
    case $update_docker_compose in
      [Yy]* ) 
        rm /usr/local/bin/docker-compose &&  curl -L "https://github.com/docker/compose/releases/download/$LATEST_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose &&  chmod +x /usr/local/bin/docker-compose && echo -e "${GREEN}Docker Compose успешно обновлен${NC}"
        ;;
      [Nn]* ) 
        echo -e "${YELLOW}Продолжаем выполнение скрипта без обновления Docker Compose${NC}"
        ;;
      * ) 
        echo -e "${RED}Неправильный ввод. Продолжаем выполнение скрипта без обновления Docker Compose${NC}"
        ;;
    esac
  fi
else
  curl -L "https://github.com/docker/compose/releases/download/$LATEST_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose &&  chmod +x /usr/local/bin/docker-compose && echo -e "${GREEN}Docker Compose успешно установлен${NC}"
fi
