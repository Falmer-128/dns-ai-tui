#!/bin/bash
# ==============================================================================
#  Uninstaller for DNS-AI Management Console
#  GitHub: https://github.com/Falmer-128/dns-ai-tui
# ==============================================================================

set -e

# Colors
C_YELLOW="\e[1;33m"
C_CYAN="\e[1;36m"
C_GREEN="\e[1;32m"
C_RED="\e[1;31m"
C_RESET="\e[0m"

if [ "$(id -u)" -ne 0 ]; then
    echo -e "${C_RED}Ошибка:${C_RESET} Для удаления требуются права суперпользователя."
    echo -e "Запустите команду через sudo:"
    echo -e "  ${C_CYAN}sudo ./uninstall.sh${C_RESET}"
    exit 1
fi

echo -e "${C_YELLOW}--> Отключение DNS-AI и восстановление системных настроек...${C_RESET}"
if [ -x /usr/local/bin/dns-ai ]; then
    /usr/local/bin/dns-ai off --service 2>/dev/null || true
fi

# Clean up /etc/hosts even if binary was already missing
if [ -f /etc/hosts ] && grep -q "BEGIN DNS-AI-HOSTS" /etc/hosts 2>/dev/null; then
    echo -e "${C_YELLOW}--> Очистка записей в /etc/hosts...${C_RESET}"
    python3 -c "
with open('/etc/hosts', 'r') as f:
    content = f.read()
if '# BEGIN DNS-AI-HOSTS' in content and '# END DNS-AI-HOSTS' in content:
    pre = content.split('# BEGIN DNS-AI-HOSTS')[0]
    post = content.split('# END DNS-AI-HOSTS')[1]
    with open('/etc/hosts', 'w') as f:
        f.write(pre.rstrip('\n') + '\n' + post.lstrip('\n'))
" 2>/dev/null || sed -i '/# BEGIN DNS-AI-HOSTS/,/# END DNS-AI-HOSTS/d' /etc/hosts 2>/dev/null || true
fi

echo -e "${C_YELLOW}--> Очистка drop-in файлов systemd-resolved...${C_RESET}"
rm -f /etc/systemd/resolved.conf.d/90-dns-ai.conf /etc/systemd/resolved.conf.d/dns-ai.conf 2>/dev/null || true

echo -e "${C_YELLOW}--> Удаление службы автозагрузки...${C_RESET}"
systemctl disable --now dns-ai.service 2>/dev/null || true
rm -f /etc/systemd/system/dns-ai.service
systemctl daemon-reload 2>/dev/null || true

echo -e "${C_YELLOW}--> Удаление интеграции с NetworkManager...${C_RESET}"
rm -f /etc/NetworkManager/dispatcher.d/90-dns-ai 2>/dev/null || true
rm -f /etc/NetworkManager/conf.d/90-dns-ai.conf /etc/NetworkManager/conf.d/dns-ai-resolved.conf 2>/dev/null || true
if systemctl is-active --quiet NetworkManager 2>/dev/null; then
    systemctl restart NetworkManager 2>/dev/null || systemctl reload NetworkManager 2>/dev/null || true
fi

if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
    systemctl restart systemd-resolved 2>/dev/null || true
fi

if [ -f /etc/resolv.conf.dns-ai.bak ]; then
    echo -e "${C_YELLOW}--> Восстановление резервной копии /etc/resolv.conf...${C_RESET}"
    rm -f /etc/resolv.conf
    mv -f /etc/resolv.conf.dns-ai.bak /etc/resolv.conf
fi

echo -e "${C_YELLOW}--> Удаление бинарных файлов и кэша...${C_RESET}"
rm -f /usr/local/bin/dns-ai /usr/local/bin/dns-ai-tui
rm -rf /etc/dns-ai /var/lib/dns-ai /run/dns-ai

# Remove shell aliases
remove_aliases() {
    local rc="$1"
    [ -f "$rc" ] || return 0
    sed -i '/# DNS-AI Aliases/,/alias dns-ai-update=/d' "$rc" 2>/dev/null || true
}

REAL_USER="${SUDO_USER:-$USER}"
USER_HOME=$(getent passwd "$REAL_USER" 2>/dev/null | cut -d: -f6)
if [ -n "$USER_HOME" ]; then
    remove_aliases "$USER_HOME/.zshrc"
    remove_aliases "$USER_HOME/.bashrc"
fi

echo -e "${C_GREEN}✓ DNS-AI полностью и чисто удален из системы!${C_RESET}"
