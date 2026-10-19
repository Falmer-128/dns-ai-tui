#!/bin/bash
# ==============================================================================
#  Installer for DNS-AI Management Console (TUI & CLI)
#  GitHub: https://github.com/Falmer-128/dns-ai-tui
# ==============================================================================

set -e

# Colors
C_CYAN="\e[1;36m"
C_GREEN="\e[1;32m"
C_YELLOW="\e[1;33m"
C_RED="\e[1;31m"
C_RESET="\e[0m"

echo -e "${C_CYAN}╔════════════════════════════════════════════════════════════════════╗${C_RESET}"
echo -e "${C_CYAN}║            Установка DNS-AI Management Console (TUI)               ║${C_RESET}"
echo -e "${C_CYAN}╚════════════════════════════════════════════════════════════════════╝${C_RESET}"

# Root check
if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        exec sudo bash "$0" "$@"
    else
        echo -e "${C_RED}Ошибка: Запустите скрипт установки с правами root (sudo).${C_RESET}"
        exit 1
    fi
fi

# Detect directory of installer
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check requirements
echo -e "${C_CYAN}--> Проверка системных зависимостей...${C_RESET}"
for dep in curl python3 systemctl; do
    if ! command -v "$dep" >/dev/null 2>&1; then
        echo -e "${C_RED}Ошибка: Не найдена необходимая утилита: $dep${C_RESET}"
        exit 1
    fi
done

# Ensure systemd-resolved is installed
if ! command -v resolvectl >/dev/null 2>&1 && ! [ -d /run/systemd/resolve ]; then
    echo -e "${C_YELLOW}Предупреждение: systemd-resolved не обнаружен. Рекомендуется установить его.${C_RESET}"
fi

# Copy binary
echo -e "${C_CYAN}--> Установка исполняемого файла /usr/local/bin/dns-ai...${C_RESET}"
mkdir -p /usr/local/bin
cp -f "$SCRIPT_DIR/dns-ai" /usr/local/bin/dns-ai
chmod 755 /usr/local/bin/dns-ai

# Symlink dns-ai-tui
ln -sf /usr/local/bin/dns-ai /usr/local/bin/dns-ai-tui

# Install systemd service
echo -e "${C_CYAN}--> Настройка системной службы автозагрузки (systemd)...${C_RESET}"
mkdir -p /etc/systemd/system
cp -f "$SCRIPT_DIR/dns-ai.service" /etc/systemd/system/dns-ai.service
chmod 644 /etc/systemd/system/dns-ai.service
systemctl daemon-reload

# Setup aliases in shells
setup_shell_aliases() {
    local rc="$1"
    [ -f "$rc" ] || return 0
    if ! grep -q "alias dns-ai=" "$rc" 2>/dev/null; then
        cat << 'ALIASES' >> "$rc"

# DNS-AI Aliases
alias dns-ai='/usr/local/bin/dns-ai'
alias dns-ai-tui='/usr/local/bin/dns-ai'
alias dns-ai-on='sudo /usr/local/bin/dns-ai on'
alias dns-ai-off='sudo /usr/local/bin/dns-ai off'
alias dns-ai-status='/usr/local/bin/dns-ai status'
alias dns-ai-test='/usr/local/bin/dns-ai test'
alias dns-ai-update='sudo /usr/local/bin/dns-ai update'
ALIASES
    fi
}

REAL_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$REAL_USER")
setup_shell_aliases "$USER_HOME/.zshrc"
setup_shell_aliases "$USER_HOME/.bashrc"

echo ""
echo -e "${C_GREEN}✓ Установка успешно завершена!${C_RESET}"
echo -e "----------------------------------------------------------------------"
echo -e "  Запуск TUI консоли:     ${C_CYAN}dns-ai${C_RESET}"
echo -e "  Быстрое включение:      ${C_GREEN}dns-ai-on${C_RESET}  (или: ${C_CYAN}dns-ai on${C_RESET})"
echo -e "  Быстрое выключение:     ${C_YELLOW}dns-ai-off${C_RESET} (или: ${C_CYAN}dns-ai off${C_RESET})"
echo -e "  Диагностика сети и AI:  ${C_CYAN}dns-ai test${C_RESET}"
echo -e "  Автозагрузка:           ${C_CYAN}dns-ai autostart enable${C_RESET}"
echo -e "----------------------------------------------------------------------"
echo ""
