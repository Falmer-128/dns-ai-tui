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
    echo -e "${C_RED}Ошибка:${C_RESET} Для установки требуются права суперпользователя."
    echo -e "Запустите команду через sudo:"
    echo -e "  ${C_CYAN}curl -fsSL https://raw.githubusercontent.com/Falmer-128/dns-ai-tui/dev/install.sh | sudo bash${C_RESET}"
    echo -e "или:"
    echo -e "  ${C_CYAN}sudo ./install.sh${C_RESET}"
    exit 1
fi

REPO_RAW="https://raw.githubusercontent.com/Falmer-128/dns-ai-tui/dev"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"

# Check and install requirements with proper distro adaptors
install_dependencies() {
    echo -e "${C_CYAN}--> Проверка системных зависимостей...${C_RESET}"

    local needed=()
    command -v curl >/dev/null 2>&1 || needed+=("curl")
    command -v python3 >/dev/null 2>&1 || needed+=("python3")

    # Distro-specific package manager resolution
    if command -v apt-get >/dev/null 2>&1; then
        if ! dpkg -s ca-certificates >/dev/null 2>&1; then
            needed+=("ca-certificates")
        fi
        if ! command -v resolvectl >/dev/null 2>&1 && ! systemctl list-unit-files 2>/dev/null | grep -q "systemd-resolved.service"; then
            needed+=("systemd-resolved")
        fi

        if [ ${#needed[@]} -gt 0 ]; then
            echo -e "${C_YELLOW}--> Установка недостающих пакетов через apt-get: ${needed[*]}${C_RESET}"
            DEBIAN_FRONTEND=noninteractive apt-get update -y
            DEBIAN_FRONTEND=noninteractive apt-get install -y "${needed[@]}"
        fi

    elif command -v pacman >/dev/null 2>&1; then
        local pac_pkgs=()
        command -v curl >/dev/null 2>&1 || pac_pkgs+=("curl")
        command -v python3 >/dev/null 2>&1 || pac_pkgs+=("python")
        if [ ${#pac_pkgs[@]} -gt 0 ]; then
            echo -e "${C_YELLOW}--> Установка недостающих пакетов через pacman: ${pac_pkgs[*]}${C_RESET}"
            pacman -S --needed --noconfirm "${pac_pkgs[@]}"
        fi

    elif command -v dnf >/dev/null 2>&1; then
        local dnf_pkgs=()
        command -v curl >/dev/null 2>&1 || dnf_pkgs+=("curl")
        command -v python3 >/dev/null 2>&1 || dnf_pkgs+=("python3")
        if ! command -v resolvectl >/dev/null 2>&1; then
            dnf_pkgs+=("systemd-resolved")
        fi
        if [ ${#dnf_pkgs[@]} -gt 0 ]; then
            echo -e "${C_YELLOW}--> Установка недостающих пакетов через dnf: ${dnf_pkgs[*]}${C_RESET}"
            dnf install -y "${dnf_pkgs[@]}"
        fi

    elif command -v zypper >/dev/null 2>&1; then
        local zyp_pkgs=()
        command -v curl >/dev/null 2>&1 || zyp_pkgs+=("curl")
        command -v python3 >/dev/null 2>&1 || zyp_pkgs+=("python3")
        if [ ${#zyp_pkgs[@]} -gt 0 ]; then
            echo -e "${C_YELLOW}--> Установка через zypper: ${zyp_pkgs[*]}${C_RESET}"
            zypper --non-interactive install "${zyp_pkgs[@]}"
        fi
    fi

    # Activate systemd-resolved if available
    if systemctl list-unit-files 2>/dev/null | grep -q "systemd-resolved.service"; then
        echo -e "${C_CYAN}--> Активация службы systemd-resolved...${C_RESET}"
        systemctl enable --now systemd-resolved 2>/dev/null || true
    fi

    # Configure NetworkManager to route through systemd-resolved
    if systemctl is-active --quiet NetworkManager 2>/dev/null && [ -d /etc/NetworkManager/conf.d ]; then
        echo -e "${C_CYAN}--> Интеграция NetworkManager с systemd-resolved...${C_RESET}"
        cat << 'NM_CONF' > /etc/NetworkManager/conf.d/90-dns-ai.conf
[main]
dns=systemd-resolved
NM_CONF
        # Remove deprecated old config if exists
        rm -f /etc/NetworkManager/conf.d/dns-ai-resolved.conf 2>/dev/null || true
        systemctl restart NetworkManager 2>/dev/null || systemctl reload NetworkManager 2>/dev/null || true
    fi

    # Ensure /etc/resolv.conf points to systemd-resolved stub
    if [ -d /run/systemd/resolve ] || [ -f /run/systemd/resolve/stub-resolv.conf ]; then
        local current_link
        current_link=$(readlink /etc/resolv.conf 2>/dev/null || true)
        if [ "$current_link" != "/run/systemd/resolve/stub-resolv.conf" ] && [ "$current_link" != "../run/systemd/resolve/stub-resolv.conf" ]; then
            echo -e "${C_CYAN}--> Привязка /etc/resolv.conf к stub-resolv.conf...${C_RESET}"
            if [ -e /etc/resolv.conf ] && [ ! -L /etc/resolv.conf ]; then
                cp -p /etc/resolv.conf /etc/resolv.conf.dns-ai.bak 2>/dev/null || true
            fi
            ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf.tmp.$$
            mv -Tf /etc/resolv.conf.tmp.$$ /etc/resolv.conf 2>/dev/null || mv -f /etc/resolv.conf.tmp.$$ /etc/resolv.conf
        fi
    fi
}

install_dependencies

# Determine source of files (local directory vs GitHub)
TMP_SRC=""
if [ -n "${BASH_SOURCE[0]}" ] && [ -f "$SCRIPT_DIR/dns-ai" ] && [ -f "$SCRIPT_DIR/dns-ai.service" ]; then
    SRC_DIR="$SCRIPT_DIR"
else
    echo -e "${C_CYAN}--> Загрузка компонентов dns-ai из GitHub...${C_RESET}"
    TMP_SRC=$(mktemp -d /tmp/dns-ai-install.XXXXXX)
    if ! curl -fsSL --max-time 15 "$REPO_RAW/dns-ai" -o "$TMP_SRC/dns-ai" || \
       ! curl -fsSL --max-time 15 "$REPO_RAW/dns-ai.service" -o "$TMP_SRC/dns-ai.service" || \
       ! curl -fsSL --max-time 15 "$REPO_RAW/90-dns-ai" -o "$TMP_SRC/90-dns-ai"; then
        echo -e "${C_RED}Ошибка: Не удалось загрузить установочные файлы с GitHub.${C_RESET}"
        rm -rf "$TMP_SRC"
        exit 1
    fi
    SRC_DIR="$TMP_SRC"
fi

# Copy binary
echo -e "${C_CYAN}--> Установка исполняемого файла /usr/local/bin/dns-ai...${C_RESET}"
mkdir -p /usr/local/bin /etc/dns-ai /var/lib/dns-ai /run/dns-ai
cp -f "$SRC_DIR/dns-ai" /usr/local/bin/dns-ai
chmod 755 /usr/local/bin/dns-ai
ln -sf /usr/local/bin/dns-ai /usr/local/bin/dns-ai-tui

# Install systemd service
echo -e "${C_CYAN}--> Настройка системной службы автозагрузки (systemd)...${C_RESET}"
mkdir -p /etc/systemd/system
cp -f "$SRC_DIR/dns-ai.service" /etc/systemd/system/dns-ai.service
chmod 644 /etc/systemd/system/dns-ai.service
systemctl daemon-reload

# Install NetworkManager dispatcher hook if NM exists
if [ -d /etc/NetworkManager/dispatcher.d ] && [ -f "$SRC_DIR/90-dns-ai" ]; then
    echo -e "${C_CYAN}--> Установка хука NetworkManager dispatcher...${C_RESET}"
    cp -f "$SRC_DIR/90-dns-ai" /etc/NetworkManager/dispatcher.d/90-dns-ai
    chown root:root /etc/NetworkManager/dispatcher.d/90-dns-ai
    chmod 755 /etc/NetworkManager/dispatcher.d/90-dns-ai
fi

# Clean up temp source if used
[ -n "$TMP_SRC" ] && rm -rf "$TMP_SRC"

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
USER_HOME=$(getent passwd "$REAL_USER" 2>/dev/null | cut -d: -f6)
if [ -n "$USER_HOME" ]; then
    setup_shell_aliases "$USER_HOME/.zshrc"
    setup_shell_aliases "$USER_HOME/.bashrc"
fi

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
