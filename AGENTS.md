# AGENTS.md

Правила для агента в этом репо. Сначала прочитай `HANDOFF.md` — там контекст проекта.

## Что это
BasementOS: system shell для iPhone 4S (iOS 8.4.1, armv7, 512 МБ RAM, landscape 960x640). Objective-C + UIKit + Theos, `.deb`. Пакет `com.basementos.shell`.

## Сборка
- Локально НЕ собирать (нет кросс-тулчейна). Сборка = GitHub Actions (`.github/workflows/build.yml`): macOS runner, theos, `make package FINALPACKAGE=1`, artifact `packages/*.deb`.
- Верификация изменений локальная = статическая: grep на мусор/несбалансированные `@implementation`/`@end`, сверка `BasementOS_FILES` в Makefile с реальными файлами в `src/`.

## Язык и API — жёстко
- Цель: `TARGET := iphone:clang:latest:8.4.1`, `ARCHS = armv7`, ARC, `-lsqlite3`.
- **Только iOS 8-совместимые API**: `UIAlertController` ок; НЕТ UIStackView, WKWebView, NSLayoutAnchor, layoutGuides.
- **NSTask нельзя** (private/broken). Сокеты/процессы — `src/BOSProcess.{h,m}` (fork + execv + pipe, kill через скан `/proc/*/cmdline` + killall фолбэк).
- UI-фреймворк на ходу не подменять; вся тема — через singleton `BOSTheme` (палитра + флаг-файл `/var/mobile/Library/BasementOS/light_theme`). Цвета хардкодить нельзя.
- SQLite — только через singleton `BOSDatabase` (база `/var/mobile/Library/BasementOS/basementos.sqlite`; таблицы `notes(id,text)`, `events(id,event_date,title)` — колонки именно в таком порядке, `state(key,value)`).
- `/proc/%d/comm` на iOS ненадёжен — в `BOSProcess` уже используется cmdline; не менять на comm.

## Структурные заморочки
- `BOSHomeViewController.m` импортирует заголовки ВСЕХ 7 под-экранов (Clock, Calendar, Notes, Files, Servers, Terminal, Settings) — новый экран требует правки и Makefile, и home.
- Сервисные скрипты (lighttpd/dropbear/minecraft) живут в `resources/services/` — так они попадают в bundle; вызываются как `/bin/sh script.sh start|stop`, не напрямую (exec-бит в bundle не гарантирован).
- Новый `.m` не соберётся, пока не добавлен в `BasementOS_FILES`.

## Запись файлов
- Пиши файлы целиком (Write tool) или кусками через heredoc (`cat > file <<'EOF'`, правка — `cat >>`). Никогда не генерируй «разогревочный» код, цепочки `stringByAppendingString:`, фейковые идентификаторы — прошлый агент так корраптил исходники (см. HANDOFF.md).
- После каждой записи проверяй хвост: `tail`.

## Пользователь
Русский, коротко и без формальностей. Не коммитить/не пушить самому — пользователь сам даёт GitHub-репозиторий и токен, CI собирает `.deb`.
