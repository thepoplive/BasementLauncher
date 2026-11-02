# BasementOS

Jailbreak system shell для **iPhone 4S (iOS 8.4.1)**: Objective-C + UIKit + Theos, SQLite, landscape 960x640, тёмная MD3-inspired тема (акцент #B69DF8).

## Модули
- **Home** — сетка из 7 плиток + живые часы
- **Clock** — часы + секундомер с кругами
- **Calendar** — события в SQLite (`+ Add event`, тап по строке = удалить)
- **Notes** — заметки в SQLite (title/body, тап = редактировать)
- **Files** — браузер от `/var/mobile`, превью текстовых файлов
- **Servers** — lighttpd (:8080), dropbear (:22), Minecraft (TODO)
- **Terminal** — sh через fork/exec + pipe
- **Settings** — светлая/тёмная тема, About

## Сборка
Локально НЕ собирать — жмёт 512 МБ RAM телефона-агента. Сборка через GitHub Actions: пуш → `make package FINALPACKAGE=1` (macOS runner + theos) → artifact `packages/*.deb`.

Ручной вариант (если есть theos):
```sh
export THEOS=/path/to/theos
make package FINALPACKAGE=1
```

## Установка
```sh
dpkg -i com.basementos.shell_*.deb
```

## Данные
- База: `/var/mobile/Library/BasementOS/basementos.sqlite` (notes / events / state)
- Флаг светлой темы: `/var/mobile/Library/BasementOS/light_theme`
- Web docroot: `/var/mobile/Library/BasementOS/www`
