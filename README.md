# DNS-AI Management Console & TUI 🌐🤖

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: Linux](https://img.shields.io/badge/Platform-Linux%20(Arch%20%7C%20Debian%20%7C%20Ubuntu%20%7C%20Fedora)-brightgreen.svg)](#)
[![Bash](https://img.shields.io/badge/Language-Bash%20%2F%20Python3-orange.svg)](#)
[![systemd](https://img.shields.io/badge/Service-systemd--resolved-red.svg)](#)

Интерактивная консоль управления (**TUI**) и CLI-утилита для настройки шифрованного **DNS-over-TLS (DoT)** через сервис **DNS-AI**, с автоматическим управлением **SNI-проксированием для зарубежных нейросетей** (Google Gemini, Google Antigravity, ChatGPT, Claude) и встроенной защитой от потери интернета.

Проект оформлен в минималистичном ретро-стиле с красивыми рамками и цветовой индикацией, по аналогии с [zapret.installer](https://github.com/Snowy-Fluffy/zapret.installer).

---

## 📸 Интерфейс (TUI)

```text
╔════════════════════════════════════════════════════════════════════╗
║                  DNS-AI Management Console                         ║
╚════════════════════════════════════════════════════════════════════╝
  Служба DNS-AI:  ● РАБОТАЕТ (DoT dns.dns-ai.ru активен)
  Автозагрузка:   ● ВКЛЮЧЕНА (systemd service enabled)
  Google AI SNI:  143.20.64.55 (Автоматический выбор (с проверкой TLS))
  Защита сбоев:   FallbackDNS=1.1.1.1 8.8.8.8

  0) Выйти
  1) Выключить DNS-AI
  2) Полный тест доступности (DoT, SNI, AI сервисы)
  3) Управление автозагрузкой (Systemd)
  4) Настройка Google AI SNI узла
  5) Обновить список адресов (endpoints.json)
  6) Ручной ввод DNS IP
  7) Подробная системная сводка (resolvectl)
  8) Сбросить все настройки сети до стандартных

  Репозиторий проекта: https://github.com/Falmer-128/dns-ai-tui
```

---

## ✨ Возможности

* 🚀 **Удобный TUI-интерфейс**: Быстрое включение, выключение и переключение параметров в один клик без ручного редактирования конфигов.
* 🛡️ **Защита от падения интернета (`FallbackDNS`)**: Официальный DNS-AI глушит обычные DNS-запросы (порт 53) и при строгом DoT любая задержка обрывает интернет. Данная консоль добавляет защитный `FallbackDNS=1.1.1.1 8.8.8.8`, предотвращая отвалы браузера и системы.
* 🤖 **Умная маршрутизация Google AI / Antigravity**:
  * Встроенная предпроверка (`verify_sni_tls`) на этапе хэндшейка TLS 443;
  * Автоматическое переключение на стабильный резервный узел (`143.20.64.55`), если основной прокси (`109.120.131.200`) висит;
  * Полная поддержка всех служебных доменов: `generativelanguage`, `daily-cloudcode-pa` (проверка токена), `cloudcode-pa`, `alkalimakersuite-pa.clients6`, `aicode`, `businessaicode`.
* ⚡ **Встроенная автозагрузка (systemd)**: Включение/выключение запуска при загрузке системы через пункт меню или команду `dns-ai autostart enable`.
* 🧪 **Комплексный автотест (`dns-ai test`)**: Проверка DoT (порт 853), проверка TLS-хэндшейка для ChatGPT, OpenAI API, Claude, Google AI Primary/Backup, проверка локального DNS-резолва.
* 🔄 **Автообновление адресов**: Синхронизация с официальным `endpoints.json` (dns-ai.ru / GitHub).

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
