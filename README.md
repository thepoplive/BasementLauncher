# BasementLauncher

Jailbreak-лаунчер для **iPhone 4S (iOS 8.4.1)**: Objective-C + UIKit + Theos, SQLite, MD3-стиль.
Бывший BasementOS (репо переименовано, пакет `com.basementos.launcher`).

## Режимы
- **Portrait (по умолчанию)** — рабочий стол: виджеты (часы, календарь, погода) + сетка 7 модулей (Clock, Calendar, Notes, Files, Servers, Terminal, Settings)
- **CarPlay (landscape)** — левый рельс (Apps / 2 недавних / Volume / Terminal), плавающий овал с временем+датой справа сверху, 2×2 виджета (Weather, Calendar, Clock, Battery)

## Настройки
Лайаут (portrait/CarPlay), обои-градиенты (4 шт.), акцентный цвет (6), светлая/тёмная тема.

## Сборка
Локально НЕ собирать. GitHub Actions: `make package FINALPACKAGE=1` → artifact `packages/*.deb`.
Ручной: `export THEOS=/path/to/theos && make package FINALPACKAGE=1`.

Линковка: свежие хедеры (latest) + `SYSROOT=iPhoneOS10.3.sdk` из theos/sdks (последний SDK с armv7 tbds) + `-Wl,-U,_objc_msgSend_stret`.

## Данные
- База: `/var/mobile/Library/BasementOS/basementos.sqlite` (notes/events/state)
- Состояние в `state`: `mode`, `wallpaper`, `accent`, `recents`, `weather`
- Флаг светлой темы: `/var/mobile/Library/BasementOS/light_theme`
- Погода: `http://wttr.in/?format=%t+%C` (кэш в state)
