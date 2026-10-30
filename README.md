# DNS-AI & GeoHide Management Console & TUI 🌐🤖

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: Linux](https://img.shields.io/badge/Platform-Linux%20(Arch%20%7C%20Debian%20%7C%20Ubuntu%20%7C%20Fedora)-brightgreen.svg)](#)
[![Python 3](https://img.shields.io/badge/Language-Python%203%20(stdlib)-blue.svg)](#)
[![systemd](https://img.shields.io/badge/Service-systemd--resolved-red.svg)](#)

Интерактивная консоль управления (**TUI**) и CLI-утилита для настройки шифрованного **DNS-over-TLS (DoT)** через сервисы **GeoHide** и **DNS-AI**, с раздельным автоматическим **SNI-проксированием для зарубежных нейросетей** (Google Gemini, Google Antigravity, ChatGPT, Claude) и встроенной защитой от потери интернета.

Проект оформлен в минималистичном ретро-стиле с красивыми рамками и цветовой индикацией, по аналогии с [zapret.installer](https://github.com/Snowy-Fluffy/zapret.installer).

---

## 📸 Интерфейс (TUI)

```text
╔════════════════════════════════════════════════════════════════════╗
║            DNS-AI & GeoHide Management Console (TUI)               ║
╚════════════════════════════════════════════════════════════════════╝
  Активный профиль: GeoHide EU (Европа — Рекомендуется)
  Состояние службы: ● РАБОТАЕТ (DoT eu.geohide.ru активен)
  Автозагрузка:     ● ВКЛЮЧЕНА (systemd service enabled)
  Google AI SNI:    143.20.64.192 (auto)
  Защита от утечек: NetworkManager DHCP DNS изолирован, Fallback=1.1.1.1
 
  0) Выйти
  1) Выключить шифрованный DNS
  2) Сменить профиль (GeoHide EU / US / RU | DNS-AI)
  3) Полный тест доступности (DoT, SNI, AI сервисы)
  4) Настройка Google AI / Antigravity SNI узла
  5) Управление автозагрузкой (Systemd)
  6) Проверить и применить обновление IP серверов (Check & Sync)
  7) Обновить программу из GitHub (Self-update)
  8) Подробная системная сводка (resolvectl status)
  9) Сбросить все настройки сети до стандартных

  Репозиторий проекта: https://github.com/Falmer-128/dns-ai-tui
```

---

## ✨ Возможности (v2.0 Architecture)

* 🚀 **Удобный TUI-интерфейс & CLI**: Быстрое включение, выключение и переключение параметров в один клик без ручного редактирования конфигов.
* 🐍 **Чистый Python 3 Core (stdlib only)**: Полное отсутствие внешних pip-зависимостей, работа из коробки на любом современном Linux.
* 🔒 **Транзакционная машина состояний и `flock`**:
  * Состояние хранится в `/var/lib/dns-ai/state.json`;
  * Межпроцессная блокировка через `/run/dns-ai/state.lock`;
  * Атомарная запись конфигов через временные файлы (`os.replace`) и синхронизация директорий (`fsync`).
* 📡 **NetworkManager Dispatcher (`90-dns-ai`)**:
  * Автоматический тихий `reconcile` при переключении Wi-Fi, смене DHCP-аренды или выходе из сна (suspend/resume);
  * Асинхронный запуск без блокировки подключения к сети.
* 🛡️ **Безопасное управление `/etc/hosts`**:
  * Защита от повреждения файла при потере маркеров (`# BEGIN DNS-AI-HOSTS` / `# END DNS-AI-HOSTS`);
  * Поддержка bind-mount и symlink в контейнерах без сбоев.
* 🤖 **Умная маршрутизация Google AI / Antigravity**:
  * Строгая проверка TLS-сертификатов (`CERT_REQUIRED`, `server_hostname`);
  * Фильтрация приватных подсетей и прямых диапазонов Google;
  * Автоматическое переключение на стабильный резервный узел (`143.20.64.55`), если основной прокси висит;
  * Полная поддержка всех служебных доменов: `generativelanguage`, `daily-cloudcode-pa` (проверка токена), `cloudcode-pa`, `alkalimakersuite-pa.clients6`, `aicode`, `businessaicode`.
* ⚡ **Hardened systemd-служба**:
  * Защита от дедлока при загрузке ОС (`After=time-sync.target`, `NetworkManager-wait-online.service`);
  * Диагностические команды (`status`, `test`, `help`) доступны без root.
* 🧪 **Комплексный автотест (`dns-ai test`)**: Проверка DoT (порт 853), проверка TLS-хэндшейка для ChatGPT, OpenAI API, Claude, Google AI Primary/Backup, проверка локального DNS-резолва.
* 🔄 **Автообновление программы (`dns-ai upgrade`)**: Атомарное обновление бинарника из GitHub с валидацией синтаксиса перед установкой.

---

## 📥 Быстрая установка

### Вариант 1: Одной командой (через Git)
```bash
git clone https://github.com/Falmer-128/dns-ai-tui.git /tmp/dns-ai-tui
cd /tmp/dns-ai-tui
sudo ./install.sh
```

### Вариант 2: Загрузка через curl (после публикации на GitHub)
```bash
curl -fsSL https://raw.githubusercontent.com/Falmer-128/dns-ai-tui/main/install.sh | sudo bash
```

---

## 🕹️ Использование

### Запуск интерактивного меню (TUI)
Просто введите в терминале:
```bash
dns-ai
# или
dns-ai-tui
```

### Быстрые команды CLI
Вы можете использовать `dns-ai` напрямую в терминале или в скриптах:

| Команда | Описание |
| :--- | :--- |
| `dns-ai-on` или `dns-ai on` | Включить DNS-over-TLS и маршрутизацию AI |
| `dns-ai-off` или `dns-ai off` | Выключить DNS-AI и вернуть системные DNS |
| `dns-ai toggle` | Переключить состояние (On/Off) |
| `dns-ai test` | Запустить полную диагностику DoT и SNI серверов |
| `dns-ai status` | Показать текущее состояние resolved и hosts |
| `dns-ai update` | Обновить базу актуальных серверов с dns-ai.ru |
| `dns-ai upgrade` | Обновить саму программу до последней версии из GitHub |
| `dns-ai autostart enable` | Добавить службу в автозагрузку systemd |
| `dns-ai autostart disable` | Убрать службу из автозагрузки systemd |
| `dns-ai set-sni backup` | Принудительно направить Google AI на резервный узел |
| `dns-ai set-sni auto` | Включить автовыбор SNI узла с TLS-проверкой |
| `dns-ai reset` | Полный сброс параметров к заводским |

---

## 🧪 Пример вывода диагностики (`dns-ai test`)

```text
╔════════════════════════════════════════════════════════════════════╗
║                Комплексная диагностика DNS-AI                      ║
╚════════════════════════════════════════════════════════════════════╝
[1] Проверка официального списка endpoints.json:
    ✓ https://dns-ai.ru/endpoints.json (512ms, Serial 7)

[2] Проверка серверов DNS-over-TLS (Порт 853):
    ✓ 194.87.196.13:853 DoT доступен (163.9ms)
    ✓ 45.151.102.219:853 DoT доступен (197.1ms)
    ℹ 186.246.49.127 — выведен из эксплуатации (retired upstream)

[3] Проверка промежуточных SNI-прокси для ИИ (Порт 443 TLS):
    ✓ ChatGPT              [62.60.230.61]: OK (278.1ms)
    ✓ OpenAI API           [62.60.230.61]: OK (280.1ms)
    ✓ Claude AI            [62.60.230.61]: OK (253.0ms)
    ✗ Google AI Primary    [109.120.131.200]: FAIL (TLS handshake timed out)
    ✓ Google AI Backup     [143.20.64.55]: OK (260.9ms)

[4] Текущая локальная резолюция в системе:
    generativelanguage.googleapis.com -> ['143.20.64.55']
════════════════════════════════════════════════════════════════════
```

---

## 🗑️ Удаление

Для полного удаления программы и восстановления стандартных сетевых настроек:
```bash
sudo /tmp/dns-ai-tui/uninstall.sh
# или
sudo dns-ai reset
```

---

## 📄 Лицензия

Распространяется под свободной лицензией [MIT](LICENSE). Разработано для сообщества.
