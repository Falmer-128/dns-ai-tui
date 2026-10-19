# DNS-AI & GeoHide Management Console & TUI 🌐🤖

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: Linux](https://img.shields.io/badge/Platform-Linux%20(Arch%20%7C%20Debian%20%7C%20Ubuntu%20%7C%20Fedora)-brightgreen.svg)](#)
[![Bash](https://img.shields.io/badge/Language-Bash%20%2F%20Python3-orange.svg)](#)
[![systemd](https://img.shields.io/badge/Service-systemd--resolved-red.svg)](#)
[![GeoHide](https://img.shields.io/badge/Provider-GeoHide%20(EU%20%7C%20US%20%7C%20RU)-6f42c1.svg)](https://geohide.ru/)
[![DNS-AI](https://img.shields.io/badge/Provider-DNS--AI-0969da.svg)](https://dns-ai.ru/)

Интерактивная консоль управления (**TUI**) и CLI-утилита для управления шифрованным **DNS-over-TLS (DoT)** и **SNI-проксированием для искусственного интеллекта** (Google Gemini, Google Antigravity, ChatGPT, Claude, OpenAI API). 

Поддерживает работу с двумя ведущими провайдерами: **[GeoHide](https://geohide.ru/)** (все 3 режима: **Европа**, **США**, **Россия**) и **[DNS-AI](https://dns-ai.ru/)**, обеспечивая отказоустойчивое переключение, автоматическую проверку обновлений IP-адресов серверов, интеллектуальный выбор живого узла и полную изоляцию от перебивания DNS со стороны интернет-провайдера или домашнего роутера.

Проект оформлен в минималистичном ретро-стиле с аккуратными рамками и цветовой индикацией, по аналогии с [zapret.installer](https://github.com/Snowy-Fluffy/zapret.installer).

---

## 📸 Интерфейс (TUI)

```text
╔════════════════════════════════════════════════════════════════════╗
║            DNS-AI & GeoHide Management Console (TUI)               ║
╚════════════════════════════════════════════════════════════════════╝
  Активный профиль: GeoHide EU (Европа — Рекомендуется)
  Состояние службы: ● РАБОТАЕТ (DoT eu.geohide.ru активен)
  Автозагрузка:     ● ВКЛЮЧЕНА (systemd service enabled)
  Google AI SNI:    143.20.64.192 (Автовыбор (быстрый живой узел с TLS))
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

## 🧭 Режимы и профили

Утилита поддерживает 4 преднастроенных профиля:

| Профиль | Провайдер | TLS Hostname | Пинг (DoT) | Локация SNI | Назначение и поддерживаемые сервисы |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`geohide-eu`** ⭐ | [GeoHide](https://geohide.ru/) | `eu.geohide.ru` | ~140–160 ms | Нидерланды / Германия | **Рекомендуемый.** Идеально для Google AI, Antigravity, Gemini, ChatGPT, Claude. |
| **`geohide-us`** | [GeoHide](https://geohide.ru/) | `us.geohide.ru` | ~300–330 ms | США | Маршрутизация всех зарубежных ИИ сервисов через американские узлы. |
| **`geohide-ru`** | [GeoHide](https://geohide.ru/) | `geohide.ru` | ~100–120 ms | Россия | Обход зарубежных блокировок сайтов РФ (Госуслуги, банки) при нахождении за границей. |
| **`dns-ai`** | [DNS-AI](https://dns-ai.ru/) | `dns.dns-ai.ru` | ~80–120 ms | Россия (DoT) / Швеция (SNI) | Классический DNS-AI DoT. SNI-проксирование для ChatGPT и Claude. |

---

## ✨ Ключевые возможности

* 🚀 **Мгновенное переключение профилей**: Переключайтесь между GeoHide (EU/US/RU) и DNS-AI одной кнопкой в TUI или командой `dns-ai profile <имя>`.
* 🤖 **Интеллектуальный SNI Failover (`determine_google_sni_ip`)**:
  * В скрипт встроен валидатор (`verify_sni_tls`), выполняющий реальный TLS-хэндшейк на 443 порт перед записью в `/etc/hosts`;
  * Если какой-либо прокси-сервер падает (как, например, узел DNS-AI `109.120.131.200`), утилита автоматически перенаправляет трафик на живые узлы GeoHide EU (`143.20.64.192`, `45.13.237.213`) либо Google Direct Anycast, предотвращая "зависание" нейросетей;
  * Полный охват всех доменов авторизации Google AI: `generativelanguage.googleapis.com`, `daily-cloudcode-pa.googleapis.com` (токены Antigravity), `cloudcode-pa`, `cloudaicompanion`, `aicode`, `businessaicode`, `aiplatform`, `gemini.google.com`.
* ⚡ **Автоматическая проверка обновлений IP онлайн**:
  * При запуске TUI в фоне быстро проверяются свежие ревизии `endpoints.json` (DNS-AI) и базы GeoHide;
  * Если провайдер ввел новые серверы или вывел старые, выводится понятный список изменений и интерактивный запрос `[Y/n]` на обновление.
* 🛡️ **Защита от утечек и изоляция NetworkManager**:
  * Автоматически отключает перебивание локального резолвера через DHCP провайдера (`ignore-auto-dns yes`);
  * Поддерживает работу с `systemd-resolved` stub (`127.0.0.53:53`) и безопасный fallback на `1.1.1.1`.
* 🧪 **Комплексная диагностика (`dns-ai test`)**:
  * Тест доступности DoT на порту 853 для всех 8 серверов (DNS-AI msk7/spb7, GeoHide EU/US/RU);
  * Тест 11 промежуточных SNI-прокси на порту 443 (ChatGPT, Claude, Google AI EU/US, Anycast);
  * Тест локального резолва системы;
  * Проверка канареечных доменов `check.dns-ai.ru` и `dnstest.geohide.ru`.
* 🔒 **Работа без root для чтения**: Команды `dns-ai test`, `dns-ai status` и `dns-ai check-ip` выполняются без прав суперпользователя.

---

## 📥 Быстрая установка

### Вариант 1: Через Git (рекомендуется)
```bash
git clone https://github.com/Falmer-128/dns-ai-tui.git /tmp/dns-ai-tui
cd /tmp/dns-ai-tui
sudo ./install.sh
```

### Вариант 2: Одной командой через curl
```bash
curl -fsSL https://raw.githubusercontent.com/Falmer-128/dns-ai-tui/main/install.sh | sudo bash
```

---

## 🕹️ Использование

### Запуск интерактивного меню (TUI)
```bash
dns-ai
# или
dns-ai-tui
```

### Быстрые команды CLI

| Команда | Описание |
| :--- | :--- |
| `dns-ai on [профиль]` | Включить DoT и маршрутизацию AI (по умолчанию `geohide-eu`) |
| `dns-ai off` | Выключить DoT и восстановить стандартный DNS |
| `dns-ai toggle` | Переключить состояние (Вкл / Выкл) |
| `dns-ai profile <имя>` | Сменить профиль (`geohide-eu`, `geohide-us`, `geohide-ru`, `dns-ai`) |
| `dns-ai test` | Запустить полную диагностику серверов DoT и SNI |
| `dns-ai check-ip` | Проверить онлайн обновление IP серверов у провайдеров |
| `dns-ai status` | Показать подробное состояние systemd-resolved и hosts |
| `dns-ai set-sni <режим>` | Настроить Google AI SNI (`auto`, `geohide-eu`, `geohide-us`, `direct`, `primary`, `manual:<ip>`, `none`) |
| `dns-ai autostart {enable\|disable}` | Управление службой автозагрузки systemd |
| `dns-ai upgrade` | Обновить исполняемый файл и службу напрямую из GitHub |
| `dns-ai reset` | Сбросить все настройки и кэш к системным по умолчанию |

### Удобные Shell-алиасы (создаются при установке)

* `dns-ai-on` — быстро включить шифрованный DNS через sudo
* `dns-ai-off` — быстро отключить через sudo
* `dns-ai-status` — просмотр сетевого статуса
* `dns-ai-test` — моментальный запуск диагностики сети и нейросетей
* `dns-ai-check` — проверка актуальности адресов онлайн
* `dns-ai-update` — принудительное обновление кэша адресов

---

## 🧪 Пример вывода диагностики (`dns-ai test`)

```text
╔════════════════════════════════════════════════════════════════════╗
║             Комплексная диагностика DNS-AI и GeoHide               ║
╚════════════════════════════════════════════════════════════════════╝
[1] Проверка источников списков серверов:
    ✓ DNS-AI endpoints.json (Serial 7) (181ms)
    ✓ GeoHide EU hosts database (163ms)

[2] Проверка серверов DNS-over-TLS (Порт 853):
    ✓ DNS-AI msk7      [45.151.102.219]: DoT OK (88.0ms)
    ✓ DNS-AI spb7      [194.87.196.13]: DoT OK (120.9ms)
    ✓ GeoHide EU #1    [143.20.64.192]: DoT OK (157.9ms)
    ✓ GeoHide EU #2    [45.13.237.213]: DoT OK (148.1ms)
    ✓ GeoHide US #1    [192.255.159.240]: DoT OK (311.5ms)
    ✓ GeoHide US #2    [192.255.159.241]: DoT OK (327.7ms)
    ✓ GeoHide RU #1    [193.233.112.67]: DoT OK (115.0ms)
    ✓ GeoHide RU #2    [193.233.112.68]: DoT OK (121.0ms)

[3] Проверка промежуточных SNI-прокси для ИИ (Порт 443 TLS):
    ✓ ChatGPT (DNS-AI SE)         [62.60.230.61    DNS-AI (SE)]: OK (187.9ms)
    ✓ ChatGPT (GeoHide EU)        [143.20.64.192   GeoHide (EU)]: OK (151.8ms)
    ✓ Claude AI (DNS-AI SE)       [62.60.230.61    DNS-AI (SE)]: OK (167.4ms)
    ✓ Claude AI (GeoHide EU)      [143.20.64.192   GeoHide (EU)]: OK (154.9ms)
    ✓ Google AI (GeoHide EU #1)   [143.20.64.192   GeoHide (EU)]: OK (141.2ms)
    ✓ Google AI (GeoHide EU #2)   [45.13.237.213   GeoHide (EU)]: OK (146.4ms)
    ✓ Antigravity Auth (EU)       [143.20.64.192   GeoHide (EU)]: OK (134.9ms)
    ✓ Gemini Web (EU)             [143.20.64.192   GeoHide (EU)]: OK (144.6ms)
    ✓ Google AI (GeoHide US)      [192.255.159.240 GeoHide (US)]: OK (354.5ms)
    ✗ Google AI (DNS-AI Primary)  [109.120.131.200 DNS-AI (US)]: FAIL (The handshake operation timed out) (узел DNS-AI упал — переключитесь на GeoHide EU)
    ✓ Google AI (Direct Anycast)  [172.217.117.4   Google Anycast]: OK (101.4ms)

[4] Текущая резолюция системы (resolvectl):
    chatgpt.com                         -> ['143.20.64.192']
    generativelanguage.googleapis.com   -> ['143.20.64.192']

[5] Проверка признака активности шифрованного DNS:
    ✓ dnstest.geohide.ru -> 143.20.64.192 (GeoHide DoT подтвержден!)
════════════════════════════════════════════════════════════════════
```

---

## 🛠️ Как это устроено под капотом

1. **DNS-over-TLS (порт 853)**: Настраивает дроп-ин конфиг `/etc/systemd/resolved.conf.d/dns-ai.conf` с параметром `DNSOverTLS=yes`. Все DNS-запросы вашего компьютера шифруются по TLS, поэтому локальный провайдер или цензор не видят доменные имена, к которым вы обращаетесь.
2. **Маршрутизация SNI (порт 443)**: Домены AI сервисов направляются через европейские/американские прокси-узлы GeoHide и DNS-AI с помощью управляемого блока в `/etc/hosts`. При этом трафик шифруется сквозным HTTPS: промежуточный узел видит только заголовок SNI (Server Name Indication) и пересылает зашифрованный поток в целевой сервис, не имея доступа к содержимому ваших диалогов.
3. **Изоляция NetworkManager**: Сетевой менеджер переводится в режим доверия `systemd-resolved`, а свойство `ipv4.ignore-auto-dns` блокирует подмешивание открытых DNS серверов роутера в периферийные интерфейсы.

---

## 🗑️ Удаление

Для полного удаления программы и восстановления стандартных сетевых настроек системы:
```bash
sudo /tmp/dns-ai-tui/uninstall.sh
# или
sudo dns-ai reset
```

---

## 📄 Лицензия

Распространяется под свободной лицензией [MIT](LICENSE). Разработано для открытого сообщества.
