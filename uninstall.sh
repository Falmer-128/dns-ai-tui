#!/bin/bash
# ==============================================================================
#  Uninstaller for DNS-AI Management Console
# ==============================================================================

set -e

# Colors
C_YELLOW="\e[1;33m"
C_GREEN="\e[1;32m"
C_RED="\e[1;31m"
C_RESET="\e[0m"

if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        exec sudo bash "$0" "$@"
    else
        echo -e "${C_RED}Ошибка: Запустите деинсталлятор с правами root (sudo).${C_RESET}"
        exit 1
    fi
fi

echo -e "${C_YELLOW}--> Отключение DNS-AI и восстановление системных настроек...${C_RESET}"
/usr/local/bin/dns-ai off 2>/dev/null || true

echo -e "${C_YELLOW}--> Удаление службы автозагрузки...${C_RESET}"
systemctl disable --now dns-ai.service 2>/dev/null || true
rm -f /etc/systemd/system/dns-ai.service
systemctl daemon-reload

echo -e "${C_YELLOW}--> Удаление интеграции с NetworkManager...${C_RESET}"
rm -f /etc/NetworkManager/conf.d/dns-ai-resolved.conf
systemctl reload NetworkManager 2>/dev/null || true

if [ -f /etc/resolv.conf.dns-ai.bak ]; then
    echo -e "${C_YELLOW}--> Восстановление резервной копии /etc/resolv.conf...${C_RESET}"
    rm -f /etc/resolv.conf
    mv -f /etc/resolv.conf.dns-ai.bak /etc/resolv.conf
fi

echo -e "${C_YELLOW}--> Удаление бинарных файлов и кэша...${C_RESET}"
rm -f /usr/local/bin/dns-ai /usr/local/bin/dns-ai-tui
rm -rf /etc/dns-ai

echo -e "${C_GREEN}✓ DNS-AI полностью удален из системы!${C_RESET}"
