# services

Start/stop-скрипты серверов для Server Manager (Запускаются как `/bin/sh script.sh start|stop`).

- lighttpd.sh — HTTP на 8080, docroot /var/mobile/Library/BasementOS/www
- dropbear.sh — SSH/SFTP на 22 (нужны host keys в /etc/dropbear)
- minecraft.sh — заглушка (TODO)
